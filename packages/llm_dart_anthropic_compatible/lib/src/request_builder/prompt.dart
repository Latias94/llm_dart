part of 'package:llm_dart_anthropic_compatible/request_builder.dart';

extension AnthropicRequestBuilderPrompt on AnthropicRequestBuilder {
  Map<String, dynamic> buildRequestBodyFromPrompt(
    Prompt prompt,
    List<Tool>? tools,
    bool stream, {
    List<ProviderTool>? providerTools,
  }) {
    return buildRequestFromPrompt(
      prompt,
      tools,
      stream,
      providerTools: providerTools,
    ).body;
  }

  /// Build request body and tool name mapping from a `Prompt` IR.
  ///
  /// This preserves the message/part structure inside provider wire format
  /// instead of forcing `Prompt.toChatMessages()` (which emits one `ChatMessage`
  /// per part).
  AnthropicBuiltRequest buildRequestFromPrompt(
    Prompt prompt,
    List<Tool>? tools,
    bool stream, {
    List<ProviderTool>? providerTools,
  }) {
    final effectiveProviderTools = mergeProviderToolsById(
      config.originalConfig?.providerTools,
      providerTools,
    );

    final processedTools = _processTools(const [], tools);
    final toolNameMapping = _createToolNameMapping(
      processedTools,
      providerTools: effectiveProviderTools,
    );

    final processedData = _processPrompt(prompt, toolNameMapping);

    if (processedData.anthropicMessages.isEmpty) {
      throw const InvalidRequestError(
          'At least one non-system message is required');
    }

    _validateMessageSequence(processedData.anthropicMessages);

    final body = <String, dynamic>{
      'model': config.model,
      'messages': processedData.anthropicMessages,
      'max_tokens': config.maxTokens ?? 1024,
      'stream': stream,
    };

    _addSystemContent(body, processedData);
    _addTools(
      body,
      processedTools,
      toolNameMapping,
      providerTools: effectiveProviderTools,
    );
    _addOptionalParameters(body);

    final extraBodyFromConfig = config.extraBody;
    if (extraBodyFromConfig != null && extraBodyFromConfig.isNotEmpty) {
      body.addAll(extraBodyFromConfig);
    }

    final extraBody = body['extra_body'] as Map<String, dynamic>?;
    if (extraBody != null) {
      body.addAll(extraBody);
      body.remove('extra_body');
    }

    return AnthropicBuiltRequest(
      body: body,
      toolNameMapping: toolNameMapping,
      providerTools: effectiveProviderTools,
    );
  }

  ProcessedMessages _processPrompt(
    Prompt prompt,
    ToolNameMapping toolNameMapping,
  ) {
    final anthropicMessages = <Map<String, dynamic>>[];
    final systemContentBlocks = <Map<String, dynamic>>[];
    final systemMessages = <String>[];
    var didSeeNonSystemMessage = false;

    for (final message in prompt.messages) {
      if (message.role == PromptRole.system) {
        if (didSeeNonSystemMessage) {
          throw const InvalidRequestError(
            'Multiple system messages that are separated by user/assistant '
            'messages are not supported. Put all system content at the '
            'beginning of the prompt.',
          );
        }
        systemContentBlocks.addAll(_convertPromptSystemMessage(message));
      } else {
        didSeeNonSystemMessage = true;
        anthropicMessages.addAll(
          _convertPromptMessageSegments(message, toolNameMapping),
        );
      }
    }

    return ProcessedMessages(
      anthropicMessages: anthropicMessages,
      systemContentBlocks: systemContentBlocks,
      systemMessages: systemMessages,
    );
  }

  List<Map<String, dynamic>> _convertPromptSystemMessage(
      PromptMessage message) {
    final blocks = <Map<String, dynamic>>[];

    if (message.parts.isEmpty) return blocks;

    final messageCacheControl =
        _cacheControlFromProviderOptions(message.providerOptions) ??
            _defaultCacheControl;

    for (var i = 0; i < message.parts.length; i++) {
      final part = message.parts[i];

      final partCacheControl =
          _cacheControlFromProviderOptions(part.providerOptions);

      final cacheControl = partCacheControl ??
          (i == message.parts.length - 1 ? messageCacheControl : null);

      switch (part) {
        case TextPart(:final text):
          blocks.add({
            'type': 'text',
            'text': text,
            if (cacheControl != null) 'cache_control': cacheControl,
          });
        case ImagePart():
        case ImageUrlPart():
        case FilePart():
        case FileUrlPart():
        case FileIdPart():
        case ToolCallPart():
        case ToolResultPart():
        case ToolApprovalResponsePart():
        case ToolApprovalRequestPart():
          throw const InvalidRequestError(
            'System messages cannot contain non-text prompt parts.',
          );
      }
    }

    return blocks;
  }

  List<Map<String, dynamic>> _convertPromptMessageSegments(
    PromptMessage message,
    ToolNameMapping toolNameMapping,
  ) {
    String roleToAnthropicWire(PromptRole role) {
      return switch (role) {
        PromptRole.user => 'user',
        PromptRole.assistant => 'assistant',
        // Anthropic Messages API does not have a dedicated `tool` role.
        // Tool results are represented as `tool_result` blocks in `user` messages.
        PromptRole.tool => 'user',
        PromptRole.system => 'system',
      };
    }

    // Protocol-internal: if we have provider-native Anthropic content blocks
    // attached (e.g. persisted assistant messages with thinking signatures),
    // preserve them verbatim to maintain multi-step tool use continuity.
    final anthropicPayload = message.protocolPayloads['anthropic'];
    if (anthropicPayload is Map) {
      final rawBlocks = anthropicPayload['contentBlocks'];
      if (rawBlocks is List && rawBlocks.isNotEmpty) {
        final blocks = rawBlocks
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList(growable: false);
        if (blocks.isNotEmpty) {
          return [
            {
              'role': roleToAnthropicWire(message.role),
              'content': blocks,
            },
          ];
        }
      }
    }

    final segments = <Map<String, dynamic>>[];

    final currentContent = <Map<String, dynamic>>[];
    PromptRole currentRole = message.role;
    var currentWireRole = roleToAnthropicWire(currentRole);

    void flush() {
      if (currentContent.isEmpty) return;
      segments.add({
        'role': currentWireRole,
        'content': List<Map<String, dynamic>>.from(currentContent),
      });
      currentContent.clear();
    }

    final messageCacheControl =
        _cacheControlFromProviderOptions(message.providerOptions) ??
            _defaultCacheControl;

    for (var i = 0; i < message.parts.length; i++) {
      final part = message.parts[i];
      final isLastPart = i == message.parts.length - 1;

      final partCacheControl =
          _cacheControlFromProviderOptions(part.providerOptions);

      Map<String, dynamic>? effectiveCacheControlForPart;

      PromptRole effectiveRole = message.role;
      if (part case ToolCallPart(:final overrideRole)) {
        effectiveRole = overrideRole ?? message.role;
      } else if (part case ToolResultPart(:final overrideRole)) {
        effectiveRole = overrideRole ?? message.role;
      }

      final effectiveWireRole = roleToAnthropicWire(effectiveRole);
      if (effectiveWireRole != currentWireRole) {
        flush();
        currentRole = effectiveRole;
        currentWireRole = effectiveWireRole;
      }

      switch (part) {
        case TextPart(:final text):
          effectiveCacheControlForPart =
              partCacheControl ?? (isLastPart ? messageCacheControl : null);
          currentContent.add({
            'type': 'text',
            'text': text,
            if (effectiveCacheControlForPart != null)
              'cache_control': effectiveCacheControlForPart,
          });
          break;

        case ImagePart(:final mime, :final data, :final text):
          if (text != null && text.isNotEmpty) {
            effectiveCacheControlForPart =
                partCacheControl ?? (isLastPart ? messageCacheControl : null);
            currentContent.add({
              'type': 'text',
              'text': text,
              if (effectiveCacheControlForPart != null)
                'cache_control': effectiveCacheControlForPart,
            });
          }

          effectiveCacheControlForPart =
              partCacheControl ?? (isLastPart ? messageCacheControl : null);
          currentContent.add({
            'type': 'image',
            'source': {
              'type': 'base64',
              'media_type': mime.mimeType,
              'data': base64Encode(data),
            },
            if (effectiveCacheControlForPart != null)
              'cache_control': effectiveCacheControlForPart,
          });
          break;

        case ImageUrlPart(:final url, :final text):
          if (text != null && text.isNotEmpty) {
            effectiveCacheControlForPart =
                partCacheControl ?? (isLastPart ? messageCacheControl : null);
            currentContent.add({
              'type': 'text',
              'text': text,
              if (effectiveCacheControlForPart != null)
                'cache_control': effectiveCacheControlForPart,
            });
          }

          final trimmed = url.trim();
          final isHttp =
              trimmed.startsWith('http://') || trimmed.startsWith('https://');
          if (!isHttp) {
            throw InvalidRequestError(
              'ImageUrlPart must be an http(s) URL. Got: "$url"',
            );
          }

          effectiveCacheControlForPart =
              partCacheControl ?? (isLastPart ? messageCacheControl : null);
          currentContent.add({
            'type': 'image',
            'source': {
              'type': 'url',
              'url': trimmed,
            },
            if (effectiveCacheControlForPart != null)
              'cache_control': effectiveCacheControlForPart,
          });
          break;

        case FilePart(:final mime, :final data, :final text):
          if (mime.mimeType != 'application/pdf' &&
              mime.mimeType != 'text/plain') {
            throw InvalidRequestError(
              'FilePart (${mime.mimeType}) is not supported by the Anthropic '
              'Messages API. Only application/pdf and text/plain are supported.',
            );
          }

          if (text != null && text.isNotEmpty) {
            effectiveCacheControlForPart =
                partCacheControl ?? (isLastPart ? messageCacheControl : null);
            currentContent.add({
              'type': 'text',
              'text': text,
              if (effectiveCacheControlForPart != null)
                'cache_control': effectiveCacheControlForPart,
            });
          }

          effectiveCacheControlForPart =
              partCacheControl ?? (isLastPart ? messageCacheControl : null);

          final docOptions = _documentOptionsFromProviderOptions(
            part.providerOptions,
          );

          final source = mime.mimeType == 'text/plain'
              ? <String, dynamic>{
                  'type': 'text',
                  'media_type': 'text/plain',
                  'data': utf8.decode(data, allowMalformed: true),
                }
              : <String, dynamic>{
                  'type': 'base64',
                  'media_type': 'application/pdf',
                  'data': base64Encode(data),
                };

          currentContent.add({
            'type': 'document',
            'source': source,
            if (docOptions.title != null) 'title': docOptions.title,
            if (docOptions.context != null) 'context': docOptions.context,
            if (docOptions.citationsEnabled) 'citations': {'enabled': true},
            if (effectiveCacheControlForPart != null)
              'cache_control': effectiveCacheControlForPart,
          });
          break;

        case FileUrlPart(:final mime, :final url, :final text):
          if (mime.mimeType != 'application/pdf' &&
              mime.mimeType != 'text/plain') {
            throw InvalidRequestError(
              'FileUrlPart (${mime.mimeType}) is not supported by the Anthropic '
              'Messages API. Only application/pdf and text/plain are supported.',
            );
          }

          if (text != null && text.isNotEmpty) {
            effectiveCacheControlForPart =
                partCacheControl ?? (isLastPart ? messageCacheControl : null);
            currentContent.add({
              'type': 'text',
              'text': text,
              if (effectiveCacheControlForPart != null)
                'cache_control': effectiveCacheControlForPart,
            });
          }

          final trimmed = url.trim();
          final isHttp =
              trimmed.startsWith('http://') || trimmed.startsWith('https://');
          if (!isHttp) {
            throw InvalidRequestError(
              'FileUrlPart must be an http(s) URL. Got: "$url"',
            );
          }

          effectiveCacheControlForPart =
              partCacheControl ?? (isLastPart ? messageCacheControl : null);

          final docOptions = _documentOptionsFromProviderOptions(
            part.providerOptions,
          );

          currentContent.add({
            'type': 'document',
            'source': {
              'type': 'url',
              'url': trimmed,
            },
            if (docOptions.title != null) 'title': docOptions.title,
            if (docOptions.context != null) 'context': docOptions.context,
            if (docOptions.citationsEnabled) 'citations': {'enabled': true},
            if (effectiveCacheControlForPart != null)
              'cache_control': effectiveCacheControlForPart,
          });
          break;

        case FileIdPart(:final mime, :final id):
          throw InvalidRequestError(
            'FileIdPart (${mime.mimeType}) is not supported by the Anthropic '
            'Messages API. Use FilePart (base64/text) or FileUrlPart (url) instead. '
            'Got id: "$id"',
          );

        case ToolCallPart(
            :final toolCallId,
            :final toolName,
            :final input,
          ):
          if (effectiveRole != PromptRole.assistant) {
            throw const InvalidRequestError(
              'ToolCallPart must be emitted from an assistant message.',
            );
          }

          effectiveCacheControlForPart =
              partCacheControl ?? (isLastPart ? messageCacheControl : null);

          if (input is! Map) {
            throw InvalidRequestError(
              'Anthropic tool_use input must be an object. '
              'Got ${input.runtimeType} for tool "$toolName".',
            );
          }

          final requestName = toolNameMapping.requestNameForFunction(toolName);
          currentContent.add({
            'type': 'tool_use',
            'id': toolCallId,
            'name': requestName,
            'input': input,
            if (effectiveCacheControlForPart != null)
              'cache_control': effectiveCacheControlForPart,
          });
          break;

        case ToolResultPart(
            :final toolCallId,
            :final output,
          ):
          if (effectiveRole != PromptRole.tool) {
            throw const InvalidRequestError(
              'ToolResultPart must be emitted from a tool message.',
            );
          }

          final toolResultCacheControl =
              _cacheControlFromProviderOptions(output.providerOptions);
          effectiveCacheControlForPart = partCacheControl ??
              toolResultCacheControl ??
              (isLastPart ? messageCacheControl : null);

          String resultContent;
          switch (output) {
            case ToolResultTextOutput(:final value):
            case ToolResultErrorTextOutput(:final value):
              resultContent = value;
              break;

            case ToolResultExecutionDeniedOutput(:final reason):
              resultContent = (reason != null && reason.trim().isNotEmpty)
                  ? reason.trim()
                  : 'Tool execution denied.';
              break;

            case ToolResultJsonOutput(:final value):
            case ToolResultErrorJsonOutput(:final value):
              resultContent = jsonEncode(value);
              break;

            case ToolResultContentOutput():
              resultContent = jsonEncode(output.toJson()['value']);
              break;
          }

          final mergedProviderOptions = <String, Map<String, dynamic>>{
            ...part.providerOptions,
            for (final entry in output.providerOptions.entries)
              entry.key: {
                ...?part.providerOptions[entry.key],
                ...entry.value,
              },
          };
          final isError = output is ToolResultErrorTextOutput ||
              output is ToolResultErrorJsonOutput ||
              _toolResultIsError(resultContent, mergedProviderOptions);

          currentContent.add({
            'type': 'tool_result',
            'tool_use_id': toolCallId,
            'content': resultContent,
            'is_error': isError,
            if (effectiveCacheControlForPart != null)
              'cache_control': effectiveCacheControlForPart,
          });
          break;

        case ToolApprovalResponsePart():
          throw const InvalidRequestError(
            'ToolApprovalResponsePart is not supported by the Anthropic Messages API.',
          );

        case ToolApprovalRequestPart():
          // Prompt metadata only; not required for Anthropic requests.
          break;
      }
    }

    flush();
    return List<Map<String, dynamic>>.unmodifiable(segments);
  }
}
