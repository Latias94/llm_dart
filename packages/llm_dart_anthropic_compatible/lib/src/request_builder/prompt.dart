part of 'package:llm_dart_anthropic_compatible/request_builder.dart';

extension AnthropicRequestBuilderPrompt on AnthropicRequestBuilder {
  Map<String, dynamic> buildRequestBodyFromPrompt(
    Prompt prompt,
    List<Tool>? tools,
    bool stream,
  ) {
    return buildRequestFromPrompt(prompt, tools, stream).body;
  }

  /// Build request body and tool name mapping from a `Prompt` IR.
  ///
  /// This preserves the message/part structure inside provider wire format
  /// instead of forcing `Prompt.toChatMessages()` (which emits one `ChatMessage`
  /// per part).
  AnthropicBuiltRequest buildRequestFromPrompt(
    Prompt prompt,
    List<Tool>? tools,
    bool stream,
  ) {
    final processedTools = _processTools(const [], tools);
    final toolNameMapping = _createToolNameMapping(processedTools);

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
    _addTools(body, processedTools, toolNameMapping);
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

    return AnthropicBuiltRequest(body: body, toolNameMapping: toolNameMapping);
  }

  ProcessedMessages _processPrompt(
    Prompt prompt,
    ToolNameMapping toolNameMapping,
  ) {
    final anthropicMessages = <Map<String, dynamic>>[];
    final systemContentBlocks = <Map<String, dynamic>>[];
    final systemMessages = <String>[];

    for (final message in prompt.messages) {
      if (message.role == ChatRole.system) {
        systemContentBlocks.addAll(_convertPromptSystemMessage(message));
      } else {
        anthropicMessages.add(_convertPromptMessage(message, toolNameMapping));
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
        case ToolCallPart():
        case ToolResultPart():
          throw const InvalidRequestError(
            'System messages cannot contain non-text prompt parts.',
          );
      }
    }

    return blocks;
  }

  Map<String, dynamic> _convertPromptMessage(
    PromptMessage message,
    ToolNameMapping toolNameMapping,
  ) {
    final content = <Map<String, dynamic>>[];

    final messageCacheControl =
        _cacheControlFromProviderOptions(message.providerOptions) ??
            _defaultCacheControl;

    for (var i = 0; i < message.parts.length; i++) {
      final part = message.parts[i];
      final isLastPart = i == message.parts.length - 1;

      final partCacheControl =
          _cacheControlFromProviderOptions(part.providerOptions);

      Map<String, dynamic>? effectiveCacheControlForPart;

      switch (part) {
        case TextPart(:final text):
          effectiveCacheControlForPart =
              partCacheControl ?? (isLastPart ? messageCacheControl : null);
          content.add({
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
            content.add({
              'type': 'text',
              'text': text,
              if (effectiveCacheControlForPart != null)
                'cache_control': effectiveCacheControlForPart,
            });
          }

          effectiveCacheControlForPart =
              partCacheControl ?? (isLastPart ? messageCacheControl : null);
          content.add({
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

        case ImageUrlPart():
          throw const InvalidRequestError(
            'ImageUrlPart is not supported by the Anthropic Messages API. '
            'Download the image and send it as ImagePart (base64) instead.',
          );

        case FilePart(:final mime, :final data, :final text):
          if (mime.mimeType != 'application/pdf') {
            throw InvalidRequestError(
              'FilePart (${mime.mimeType}) is not supported by the Anthropic '
              'Messages API. Only application/pdf is supported.',
            );
          }

          if (text != null && text.isNotEmpty) {
            effectiveCacheControlForPart =
                partCacheControl ?? (isLastPart ? messageCacheControl : null);
            content.add({
              'type': 'text',
              'text': text,
              if (effectiveCacheControlForPart != null)
                'cache_control': effectiveCacheControlForPart,
            });
          }

          effectiveCacheControlForPart =
              partCacheControl ?? (isLastPart ? messageCacheControl : null);
          content.add({
            'type': 'document',
            'source': {
              'type': 'base64',
              'media_type': 'application/pdf',
              'data': base64Encode(data),
            },
            if (effectiveCacheControlForPart != null)
              'cache_control': effectiveCacheControlForPart,
          });
          break;

        case ToolCallPart(:final toolCall):
          if (message.role != ChatRole.assistant) {
            throw const InvalidRequestError(
              'ToolCallPart must be emitted from an assistant message.',
            );
          }

          final toolCallCacheControl =
              _cacheControlFromProviderOptions(toolCall.providerOptions);
          effectiveCacheControlForPart = partCacheControl ??
              toolCallCacheControl ??
              (isLastPart ? messageCacheControl : null);

          try {
            final input = jsonDecode(toolCall.function.arguments);
            final requestName =
                toolNameMapping.requestNameForFunction(toolCall.function.name);
            content.add({
              'type': 'tool_use',
              'id': toolCall.id,
              'name': requestName,
              'input': input,
              if (effectiveCacheControlForPart != null)
                'cache_control': effectiveCacheControlForPart,
            });
          } catch (e) {
            throw InvalidRequestError(
              'Invalid JSON tool call arguments for tool '
              '"${toolCall.function.name}": $e',
            );
          }
          break;

        case ToolResultPart(:final toolResult):
          if (message.role != ChatRole.user) {
            throw const InvalidRequestError(
              'ToolResultPart must be emitted from a user message.',
            );
          }

          final toolResultCacheControl =
              _cacheControlFromProviderOptions(toolResult.providerOptions);
          effectiveCacheControlForPart = partCacheControl ??
              toolResultCacheControl ??
              (isLastPart ? messageCacheControl : null);

          final resultContent = toolResult.function.arguments;
          final isError = _toolResultIsError(resultContent, toolResult);

          content.add({
            'type': 'tool_result',
            'tool_use_id': toolResult.id,
            'content': resultContent,
            'is_error': isError,
            if (effectiveCacheControlForPart != null)
              'cache_control': effectiveCacheControlForPart,
          });
          break;
      }
    }

    return {
      'role': message.role.name,
      'content': content,
    };
  }
}
