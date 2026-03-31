import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'openai_response_format.dart';
import 'resolved_openai_options.dart';

final class OpenAIChatCompletionsRequest {
  final Map<String, Object?> body;
  final List<ModelWarning> warnings;

  OpenAIChatCompletionsRequest({
    required Map<String, Object?> body,
    List<ModelWarning> warnings = const [],
  })  : body = Map.unmodifiable(body),
        warnings = List.unmodifiable(warnings);
}

final class OpenAIChatCompletionsStreamState {
  String? responseId;
  DateTime? responseTimestamp;
  String? responseModelId;
  UsageStats? usage;
  String? rawFinishReason;
  bool hasResponseMetadata = false;
  bool startedText = false;
  bool endedText = false;
  bool startedReasoning = false;
  bool endedReasoning = false;
  bool hasToolCalls = false;
  final Set<String> emittedSourceIds = {};
  final Map<int, _OpenAIChatCompletionsToolCallState> _toolCallsByIndex = {};
}

final class OpenAIChatCompletionsCodec {
  final String providerNamespace;

  const OpenAIChatCompletionsCodec({
    this.providerNamespace = 'openai',
  });

  OpenAIChatCompletionsRequest encodeRequest({
    required String modelId,
    required List<PromptMessage> prompt,
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required GenerateTextOptions options,
    required ResolvedOpenAIGenerateTextOptions providerOptions,
    required bool stream,
  }) {
    if (providerOptions.common.previousResponseId != null) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support previousResponseId. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.builtInTools case final builtInTools?
        when builtInTools.isNotEmpty) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support OpenAI built-in tools. Use the Responses API mainline instead.',
      );
    }

    final warnings = <ModelWarning>[];
    final messages = <Map<String, Object?>>[];

    for (final message in prompt) {
      messages.addAll(_encodePromptMessage(message, warnings));
    }

    final body = <String, Object?>{
      'model': modelId,
      'messages': messages,
      'stream': stream,
      if (options.maxOutputTokens != null)
        'max_tokens': options.maxOutputTokens,
      if (options.temperature != null) 'temperature': options.temperature,
      if (options.stopSequences != null && options.stopSequences!.isNotEmpty)
        'stop': options.stopSequences,
      if (options.topP != null) 'top_p': options.topP,
      if (options.topK != null) 'top_k': options.topK,
      if (providerOptions.common.parallelToolCalls != null)
        'parallel_tool_calls': providerOptions.common.parallelToolCalls,
      if (providerOptions.common.serviceTier != null)
        'service_tier': providerOptions.common.serviceTier,
      if (providerOptions.common.verbosity != null)
        'verbosity': providerOptions.common.verbosity,
      if (providerOptions.xaiSearch != null)
        'search_parameters': providerOptions.xaiSearch!.toJson(),
    };

    final encodedTools = _encodeTools(tools);
    if (encodedTools.isNotEmpty) {
      body['tools'] = encodedTools;
      final encodedToolChoice = _encodeToolChoice(
        toolChoice,
        hasFunctionTools: tools.isNotEmpty,
      );
      if (encodedToolChoice != null) {
        body['tool_choice'] = encodedToolChoice;
      }
    }

    if (providerOptions.common.responseFormat case final responseFormat?) {
      body['response_format'] = _encodeResponseFormat(responseFormat);
    }

    return OpenAIChatCompletionsRequest(
      body: body,
      warnings: warnings,
    );
  }

  GenerateTextResult decodeGenerateResponse(
    Map<String, Object?> response, {
    List<ModelWarning> warnings = const [],
  }) {
    _throwIfError(response);

    final choice = _firstChoice(response);
    final message = _asMap(choice?['message']) ?? const <String, Object?>{};
    final content = <ContentPart>[];

    final decodedText = _decodeAssistantText(message);
    if (decodedText.reasoning case final reasoning? when reasoning.isNotEmpty) {
      content.add(
        ReasoningContentPart(
          reasoning,
          providerMetadata: _providerMetadata({
            'finishReason': _asString(choice?['finish_reason']),
          }),
        ),
      );
    }

    if (decodedText.text.isNotEmpty) {
      content.add(
        TextContentPart(
          decodedText.text,
          providerMetadata: _providerMetadata({
            'finishReason': _asString(choice?['finish_reason']),
          }),
        ),
      );
    }

    final toolCalls = _decodeToolCalls(
      _asList(message['tool_calls']),
    );
    content.addAll(toolCalls);
    content.addAll(_decodeTopLevelSources(response));

    return GenerateTextResult(
      content: content,
      finishReason: _mapFinishReason(_asString(choice?['finish_reason'])),
      rawFinishReason: _asString(choice?['finish_reason']),
      responseId: _asString(response['id']),
      responseTimestamp: _decodeResponseTimestamp(response),
      responseModelId: _asString(response['model']),
      usage: _decodeUsage(_asMap(response['usage'])),
      providerMetadata: _responseMetadata(response, choice),
      warnings: warnings,
    );
  }

  Iterable<TextStreamEvent> decodeStreamChunk(
    Map<String, Object?> chunk,
    OpenAIChatCompletionsStreamState state,
  ) sync* {
    if (!state.hasResponseMetadata) {
      _captureResponseMetadata(chunk, state);
      final metadataEvent = _buildResponseMetadataEvent(state);
      if (metadataEvent != null) {
        state.hasResponseMetadata = true;
        yield metadataEvent;
      }
    }

    final choice = _firstChoice(chunk);
    if (choice == null) {
      if (_asMap(chunk['error']) case final error?) {
        yield ErrorEvent(
          ModelError.fromUnknown(
            error,
            kind: ModelErrorKind.provider,
          ),
        );
      }
      return;
    }

    final delta = _asMap(choice['delta']) ?? const <String, Object?>{};
    final chunkUsage = _decodeUsage(_asMap(chunk['usage']));
    if (chunkUsage != null) {
      state.usage = chunkUsage;
    }

    yield* _decodeChunkSources(
      chunk,
      state,
    );

    final reasoningDelta = _extractReasoningDelta(delta);
    if (reasoningDelta != null && reasoningDelta.isNotEmpty) {
      if (!state.startedReasoning) {
        state.startedReasoning = true;
        yield ReasoningStartEvent(
          id: _reasoningId,
          providerMetadata: _providerMetadata({
            'responseId': state.responseId,
          }),
        );
      }

      yield ReasoningDeltaEvent(
        id: _reasoningId,
        delta: reasoningDelta,
        providerMetadata: _providerMetadata({
          'responseId': state.responseId,
        }),
      );
    }

    final contentDelta = _extractContentDelta(delta);
    if (contentDelta != null && contentDelta.isNotEmpty) {
      if (!state.startedText) {
        state.startedText = true;
        yield TextStartEvent(
          id: _textId,
          providerMetadata: _providerMetadata({
            'responseId': state.responseId,
          }),
        );
      }

      yield TextDeltaEvent(
        id: _textId,
        delta: contentDelta,
        providerMetadata: _providerMetadata({
          'responseId': state.responseId,
        }),
      );
    }

    for (final rawToolCall in _asList(delta['tool_calls'])) {
      final toolCall = _asMap(rawToolCall);
      if (toolCall == null) {
        continue;
      }

      final deltaResult = _consumeToolCallDelta(toolCall, state);
      final index = deltaResult.index;
      final toolState = deltaResult.toolState;
      if (toolState == null ||
          toolState.toolCallId == null ||
          toolState.toolName == null) {
        continue;
      }

      if (!toolState.startEmitted) {
        toolState.startEmitted = true;
        yield ToolInputStartEvent(
          toolCallId: toolState.toolCallId!,
          toolName: toolState.toolName!,
          providerExecuted: false,
          isDynamic: false,
          providerMetadata: _providerMetadata({
            'responseId': state.responseId,
            'toolIndex': index,
          }),
        );
      }

      if (deltaResult.argumentsDelta case final argumentsDelta?
          when argumentsDelta.isNotEmpty) {
        yield ToolInputDeltaEvent(
          toolCallId: toolState.toolCallId!,
          delta: argumentsDelta,
          providerMetadata: _providerMetadata({
            'responseId': state.responseId,
            'toolIndex': index,
          }),
        );
      }
    }

    final rawFinishReason = _asString(choice['finish_reason']);
    if (rawFinishReason == null) {
      return;
    }

    state.rawFinishReason = rawFinishReason;

    if (state.startedText && !state.endedText) {
      state.endedText = true;
      yield TextEndEvent(
        id: _textId,
        providerMetadata: _providerMetadata({
          'responseId': state.responseId,
        }),
      );
    }

    if (state.startedReasoning && !state.endedReasoning) {
      state.endedReasoning = true;
      yield ReasoningEndEvent(
        id: _reasoningId,
        providerMetadata: _providerMetadata({
          'responseId': state.responseId,
        }),
      );
    }

    yield* _finalizeToolCalls(state);

    yield FinishEvent(
      finishReason: _mapFinishReason(rawFinishReason),
      rawFinishReason: rawFinishReason,
      usage: state.usage,
      providerMetadata: _providerMetadata({
        'responseId': state.responseId,
        'systemFingerprint': _asString(chunk['system_fingerprint']),
      }),
    );
  }

  List<Map<String, Object?>> _encodePromptMessage(
    PromptMessage message,
    List<ModelWarning> warnings,
  ) {
    if (message is SystemPromptMessage) {
      return [
        {
          'role': 'system',
          'content': _joinTextParts(
            role: 'system',
            parts: message.parts,
          ),
        },
      ];
    }

    if (message is UserPromptMessage) {
      return [
        _encodeUserPromptMessage(message),
      ];
    }

    if (message is AssistantPromptMessage) {
      final textParts = <String>[];
      final encodedToolCalls = <Map<String, Object?>>[];

      for (final part in message.parts) {
        switch (part) {
          case TextPromptPart(:final text):
            textParts.add(text);
          case ToolCallPromptPart(
              :final toolCallId,
              :final toolName,
              :final input,
              :final providerExecuted,
              :final isDynamic,
            ):
            if (providerExecuted || isDynamic) {
              warnings.add(
                const ModelWarning(
                  type: ModelWarningType.unsupported,
                  field: 'prompt.assistant.parts',
                  message:
                      'Chat-completions replay drops provider-executed or dynamic assistant tool calls.',
                ),
              );
              continue;
            }

            encodedToolCalls.add({
              'id': toolCallId,
              'type': 'function',
              'function': {
                'name': toolName,
                'arguments': _encodeJsonString(input),
              },
            });
          case ReasoningPromptPart():
          case ReasoningFilePromptPart():
          case CustomPromptPart():
          case ToolApprovalRequestPromptPart():
          case ToolApprovalResponsePromptPart():
          case ImagePromptPart():
          case FilePromptPart():
          case ToolResultPromptPart():
            warnings.add(
              ModelWarning(
                type: ModelWarningType.unsupported,
                field: 'prompt.assistant.parts',
                message:
                    'Chat-completions replay dropped unsupported assistant part: ${part.runtimeType}.',
              ),
            );
        }
      }

      if (textParts.isEmpty && encodedToolCalls.isEmpty) {
        return const [];
      }

      return [
        {
          'role': 'assistant',
          if (textParts.isNotEmpty) 'content': textParts.join(),
          if (encodedToolCalls.isNotEmpty) 'tool_calls': encodedToolCalls,
        },
      ];
    }

    if (message is ToolPromptMessage) {
      final encoded = <Map<String, Object?>>[];

      for (final part in message.parts) {
        switch (part) {
          case ToolResultPromptPart(
              :final toolCallId,
              :final output,
              :final toolName,
              :final isError,
            ):
            if (toolName.startsWith('mcp.')) {
              warnings.add(
                const ModelWarning(
                  type: ModelWarningType.unsupported,
                  field: 'prompt.tool.parts',
                  message:
                      'Chat-completions replay drops provider-native MCP tool results.',
                ),
              );
              continue;
            }

            encoded.add({
              'role': 'tool',
              'tool_call_id': toolCallId,
              'content': _encodeToolOutput(
                output: output,
                isError: isError,
              ),
            });
          case ToolApprovalResponsePromptPart():
            warnings.add(
              const ModelWarning(
                type: ModelWarningType.unsupported,
                field: 'prompt.tool.parts',
                message:
                    'Chat-completions replay does not support tool approval responses.',
              ),
            );
          case TextPromptPart():
          case ReasoningPromptPart():
          case ReasoningFilePromptPart():
          case CustomPromptPart():
          case ToolCallPromptPart():
          case ToolApprovalRequestPromptPart():
          case ImagePromptPart():
          case FilePromptPart():
            warnings.add(
              ModelWarning(
                type: ModelWarningType.unsupported,
                field: 'prompt.tool.parts',
                message:
                    'Chat-completions replay dropped unsupported tool prompt part: ${part.runtimeType}.',
              ),
            );
        }
      }

      return encoded;
    }

    throw UnsupportedError(
      'Unsupported prompt message type: ${message.runtimeType}.',
    );
  }

  Map<String, Object?> _encodeUserPromptMessage(UserPromptMessage message) {
    if (message.parts.every((part) => part is TextPromptPart)) {
      return {
        'role': 'user',
        'content': _joinTextParts(
          role: 'user',
          parts: message.parts,
        ),
      };
    }

    final content = <Map<String, Object?>>[];
    for (var index = 0; index < message.parts.length; index++) {
      final part = message.parts[index];
      switch (part) {
        case TextPromptPart(:final text):
          content.add({
            'type': 'text',
            'text': text,
          });
        case ImagePromptPart(
            :final mediaType,
            :final uri,
            :final bytes,
            :final providerMetadata,
          ):
          content.add(
            _encodeImageContentPart(
              mediaType: mediaType,
              uri: uri,
              bytes: bytes,
              metadata: providerMetadata,
            ),
          );
        case FilePromptPart():
          content.add(
            _encodeFileContentPart(
              part,
              index: index,
            ),
          );
        case ReasoningPromptPart():
        case ReasoningFilePromptPart():
        case CustomPromptPart():
        case ToolCallPromptPart():
        case ToolApprovalRequestPromptPart():
        case ToolResultPromptPart():
        case ToolApprovalResponsePromptPart():
          throw UnsupportedError(
            'Unsupported user prompt part for chat-completions requests: ${part.runtimeType}.',
          );
      }
    }

    return {
      'role': 'user',
      'content': content,
    };
  }

  Map<String, Object?> _encodeImageContentPart({
    required String mediaType,
    Uri? uri,
    List<int>? bytes,
    ProviderMetadata? metadata,
  }) {
    final openaiMetadata = _providerMetadataValues(
      metadata,
      namespace: 'openai',
    );
    final imageUrl = uri?.toString() ??
        (bytes == null
            ? null
            : 'data:${_normalizeImageMediaTypeForDataUrl(mediaType)};base64,'
                '${base64Encode(bytes)}');
    if (imageUrl == null) {
      throw UnsupportedError(
        'User image prompt parts need either a URI or bytes.',
      );
    }

    return {
      'type': 'image_url',
      'image_url': {
        'url': imageUrl,
        if (_asString(openaiMetadata?['imageDetail']) case final imageDetail?)
          'detail': imageDetail,
      },
    };
  }

  Map<String, Object?> _encodeFileContentPart(
    FilePromptPart part, {
    required int index,
  }) {
    if (part.mediaType.startsWith('image/')) {
      return _encodeImageContentPart(
        mediaType: part.mediaType,
        uri: part.uri,
        bytes: part.bytes,
        metadata: part.providerMetadata,
      );
    }

    if (part.mediaType.startsWith('audio/')) {
      if (part.uri != null) {
        throw UnsupportedError(
          'OpenAI-family chat-completions audio file prompt parts do not support URIs. Provide bytes instead.',
        );
      }

      final bytes = part.bytes;
      if (bytes == null) {
        throw UnsupportedError(
          'OpenAI-family chat-completions audio file prompt parts need bytes.',
        );
      }

      return {
        'type': 'input_audio',
        'input_audio': {
          'data': base64Encode(bytes),
          'format': _encodeAudioFormat(part.mediaType),
        },
      };
    }

    if (part.mediaType == 'application/pdf') {
      final openaiMetadata = _providerMetadataValues(
        part.providerMetadata,
        namespace: 'openai',
      );
      if (_asString(openaiMetadata?['fileId']) case final fileId?) {
        return {
          'type': 'file',
          'file': {
            'file_id': fileId,
          },
        };
      }

      if (part.uri != null) {
        throw UnsupportedError(
          'OpenAI-family chat-completions PDF file prompt parts do not support URIs. Provide bytes instead.',
        );
      }

      final bytes = part.bytes;
      if (bytes == null) {
        throw UnsupportedError(
          'OpenAI-family chat-completions PDF file prompt parts need bytes.',
        );
      }

      return {
        'type': 'file',
        'file': {
          'filename': part.filename ?? 'part-$index.pdf',
          'file_data': 'data:application/pdf;base64,${base64Encode(bytes)}',
        },
      };
    }

    throw UnsupportedError(
      'OpenAI-family chat-completions requests do not support file prompt media type ${part.mediaType}.',
    );
  }

  String _encodeAudioFormat(String mediaType) {
    return switch (mediaType) {
      'audio/wav' => 'wav',
      'audio/mpeg' => 'mp3',
      'audio/mp3' => 'mp3',
      _ => throw UnsupportedError(
          'OpenAI-family chat-completions requests do not support audio file media type $mediaType.',
        ),
    };
  }

  String _normalizeImageMediaTypeForDataUrl(String mediaType) {
    if (mediaType == 'image/*') {
      return 'image/jpeg';
    }

    return mediaType;
  }

  Map<String, Object?>? _providerMetadataValues(
    ProviderMetadata? metadata, {
    required String namespace,
  }) {
    final value = metadata?[namespace];
    if (value is Map<String, Object?>) {
      return value;
    }

    if (value is Map) {
      return Map<String, Object?>.from(value);
    }

    return null;
  }

  String _joinTextParts({
    required String role,
    required List<PromptPart> parts,
  }) {
    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is! TextPromptPart) {
        throw UnsupportedError(
          'OpenAI-family chat-completions requests only support text $role prompt parts for now. Received ${part.runtimeType}.',
        );
      }

      if (buffer.isNotEmpty) {
        buffer.write('\n\n');
      }
      buffer.write(part.text);
    }

    return buffer.toString();
  }

  List<Map<String, Object?>> _encodeTools(
    List<FunctionToolDefinition> tools,
  ) {
    return [
      for (final tool in tools)
        {
          'type': 'function',
          'function': {
            'name': tool.name,
            if (tool.description != null) 'description': tool.description,
            'parameters': tool.inputSchema.toJson(),
            if (tool.strict != null) 'strict': tool.strict,
          },
        },
    ];
  }

  Object? _encodeToolChoice(
    ToolChoice? toolChoice, {
    required bool hasFunctionTools,
  }) {
    if (!hasFunctionTools || toolChoice == null) {
      return null;
    }

    return switch (toolChoice) {
      AutoToolChoice() => 'auto',
      RequiredToolChoice() => 'required',
      NoneToolChoice() => 'none',
      SpecificToolChoice(toolName: final toolName) => {
          'type': 'function',
          'function': {
            'name': toolName,
          },
        },
    };
  }

  Map<String, Object?> _encodeResponseFormat(
    OpenAIJsonSchemaResponseFormat responseFormat,
  ) {
    return {
      'type': 'json_schema',
      'json_schema': {
        'name': responseFormat.name,
        if (responseFormat.description != null)
          'description': responseFormat.description,
        if (responseFormat.schema != null)
          'schema': _ensureJsonSchemaObject(responseFormat.schema!),
        if (responseFormat.strict != null) 'strict': responseFormat.strict,
      },
    };
  }

  Map<String, Object?> _ensureJsonSchemaObject(Map<String, Object?> schema) {
    final normalized = Map<String, Object?>.from(schema);
    if (!normalized.containsKey('additionalProperties')) {
      normalized['additionalProperties'] = false;
    }
    return normalized;
  }

  List<ToolCallContentPart> _decodeToolCalls(List<Object?> rawToolCalls) {
    final result = <ToolCallContentPart>[];

    for (final rawToolCall in rawToolCalls) {
      final toolCall = _asMap(rawToolCall);
      if (toolCall == null) {
        continue;
      }

      final toolCallId = _asString(toolCall['id']);
      final function = _asMap(toolCall['function']);
      final toolName = _asString(function?['name']);
      if (toolCallId == null || toolName == null) {
        continue;
      }

      final encodedArguments = _asString(function?['arguments']) ?? '{}';
      result.add(
        ToolCallContentPart(
          ToolCallContent(
            toolCallId: toolCallId,
            toolName: toolName,
            input: _tryDecodeJsonValue(encodedArguments).value,
          ),
          providerMetadata: _providerMetadata({
            'toolCallId': toolCallId,
          }),
        ),
      );
    }

    return result;
  }

  List<SourceContentPart> _decodeTopLevelSources(
      Map<String, Object?> response) {
    final citations = _asList(response['citations']);
    if (citations.isEmpty) {
      return const [];
    }

    final sources = <SourceContentPart>[];
    for (var index = 0; index < citations.length; index++) {
      final rawCitation = citations[index];
      final url = _asString(rawCitation);
      if (url == null || url.isEmpty) {
        continue;
      }

      sources.add(
        SourceContentPart(
          SourceReference(
            kind: SourceReferenceKind.url,
            sourceId: url,
            uri: Uri.tryParse(url),
            title: url,
            providerMetadata: _providerMetadata({
              'citationIndex': index,
            }),
          ),
        ),
      );
    }

    return sources;
  }

  Iterable<SourceEvent> _decodeChunkSources(
    Map<String, Object?> chunk,
    OpenAIChatCompletionsStreamState state,
  ) sync* {
    final citations = _asList(chunk['citations']);
    if (citations.isEmpty) {
      return;
    }

    for (var index = 0; index < citations.length; index++) {
      final rawCitation = citations[index];
      final url = _asString(rawCitation);
      if (url == null || url.isEmpty || !state.emittedSourceIds.add(url)) {
        continue;
      }

      yield SourceEvent(
        SourceReference(
          kind: SourceReferenceKind.url,
          sourceId: url,
          uri: Uri.tryParse(url),
          title: url,
          providerMetadata: _providerMetadata({
            'responseId': state.responseId,
            'citationIndex': index,
          }),
        ),
      );
    }
  }

  _DecodedAssistantText _decodeAssistantText(Map<String, Object?> message) {
    final reasoningBuffer = StringBuffer();
    final textBuffer = StringBuffer();

    final explicitReasoning = _extractReasoningText(message);
    if (explicitReasoning != null && explicitReasoning.isNotEmpty) {
      reasoningBuffer.write(explicitReasoning);
    }

    final content = message['content'];
    if (content is String) {
      _splitThinkingAndText(
        content,
        reasoningBuffer: reasoningBuffer,
        textBuffer: textBuffer,
      );
    } else if (content is List) {
      for (final rawPart in content) {
        final part = _asMap(rawPart);
        if (part == null) {
          continue;
        }

        final type = _asString(part['type']);
        final text = _asString(part['text']) ??
            _asString(part['content']) ??
            _asString(part['output_text']);
        if (type == 'reasoning' || type == 'reasoning_content') {
          if (text != null && text.isNotEmpty) {
            reasoningBuffer.write(text);
          }
          continue;
        }

        if (text != null && text.isNotEmpty) {
          _splitThinkingAndText(
            text,
            reasoningBuffer: reasoningBuffer,
            textBuffer: textBuffer,
          );
        }
      }
    }

    return _DecodedAssistantText(
      text: textBuffer.toString(),
      reasoning: reasoningBuffer.isEmpty ? null : reasoningBuffer.toString(),
    );
  }

  void _splitThinkingAndText(
    String value, {
    required StringBuffer reasoningBuffer,
    required StringBuffer textBuffer,
  }) {
    final thinkingMatches = RegExp(r'<think>(.*?)</think>', dotAll: true)
        .allMatches(value)
        .map((match) => match.group(1)?.trim())
        .whereType<String>()
        .where((text) => text.isNotEmpty)
        .toList(growable: false);

    for (final thinking in thinkingMatches) {
      reasoningBuffer.write(thinking);
    }

    final filtered =
        value.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '');
    if (filtered.isNotEmpty) {
      textBuffer.write(filtered);
    }
  }

  String? _extractReasoningText(Map<String, Object?> message) {
    final candidates = [
      _asString(message['reasoning_content']),
      _asString(message['reasoning']),
      _asString(message['thinking']),
    ];

    for (final candidate in candidates) {
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }

    return null;
  }

  void _captureResponseMetadata(
    Map<String, Object?> chunk,
    OpenAIChatCompletionsStreamState state,
  ) {
    final responseId = _asString(chunk['id']);
    final responseModelId = _asString(chunk['model']);
    final created = _asInt(chunk['created']);
    if (responseId == null && responseModelId == null && created == null) {
      return;
    }

    state.responseId = responseId;
    state.responseModelId = responseModelId;
    if (created != null) {
      state.responseTimestamp = DateTime.fromMillisecondsSinceEpoch(
        created * 1000,
        isUtc: true,
      );
    }
  }

  ResponseMetadataEvent? _buildResponseMetadataEvent(
    OpenAIChatCompletionsStreamState state,
  ) {
    if (state.responseId == null &&
        state.responseModelId == null &&
        state.responseTimestamp == null) {
      return null;
    }

    return ResponseMetadataEvent(
      responseId: state.responseId,
      timestamp: state.responseTimestamp,
      modelId: state.responseModelId,
      providerMetadata: _providerMetadata({
        'responseId': state.responseId,
      }),
    );
  }

  _ToolCallDeltaResult _consumeToolCallDelta(
    Map<String, Object?> toolCall,
    OpenAIChatCompletionsStreamState state,
  ) {
    final index = _asInt(toolCall['index']) ?? state._toolCallsByIndex.length;
    final toolState = state._toolCallsByIndex.putIfAbsent(
      index,
      () => _OpenAIChatCompletionsToolCallState(index: index),
    );

    final toolCallId = _asString(toolCall['id']);
    if (toolCallId != null && toolCallId.isNotEmpty) {
      toolState.toolCallId = toolCallId;
    }

    final function = _asMap(toolCall['function']) ?? const <String, Object?>{};
    final toolName = _asString(function['name']);
    if (toolName != null && toolName.isNotEmpty) {
      toolState.toolName = toolName;
    }

    final argumentsDelta = _asString(function['arguments']);
    if (argumentsDelta != null && argumentsDelta.isNotEmpty) {
      state.hasToolCalls = true;
      toolState.arguments.write(argumentsDelta);
    }

    return _ToolCallDeltaResult(
      index: index,
      toolState: toolState,
      argumentsDelta: argumentsDelta,
    );
  }

  Iterable<TextStreamEvent> _finalizeToolCalls(
    OpenAIChatCompletionsStreamState state,
  ) sync* {
    for (final entry in state._toolCallsByIndex.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key))) {
      final toolState = entry.value;
      final toolCallId = toolState.toolCallId ?? 'tool_${entry.key}';
      final toolName = toolState.toolName ?? 'function';

      if (!toolState.startEmitted) {
        toolState.startEmitted = true;
        yield ToolInputStartEvent(
          toolCallId: toolCallId,
          toolName: toolName,
          providerExecuted: false,
          isDynamic: false,
          providerMetadata: _providerMetadata({
            'responseId': state.responseId,
            'toolIndex': entry.key,
          }),
        );
      }

      final encodedArguments =
          toolState.arguments.isEmpty ? '{}' : toolState.arguments.toString();
      final decodedArguments = _tryDecodeJsonValue(encodedArguments);
      if (decodedArguments.error != null) {
        yield ToolInputErrorEvent(
          toolCallId: toolCallId,
          toolName: toolName,
          input: encodedArguments,
          errorText: _formatInvalidToolInputError(
            toolName,
            decodedArguments.error!,
          ),
          providerExecuted: false,
          isDynamic: false,
          providerMetadata: _providerMetadata({
            'responseId': state.responseId,
            'toolIndex': entry.key,
          }),
        );
        continue;
      }

      yield ToolInputEndEvent(
        toolCallId: toolCallId,
        providerMetadata: _providerMetadata({
          'responseId': state.responseId,
          'toolIndex': entry.key,
        }),
      );
      yield ToolCallEvent(
        toolCall: ToolCallContent(
          toolCallId: toolCallId,
          toolName: toolName,
          input: decodedArguments.value,
        ),
        providerMetadata: _providerMetadata({
          'responseId': state.responseId,
          'toolIndex': entry.key,
        }),
      );
    }
    state._toolCallsByIndex.clear();
  }

  ProviderMetadata? _responseMetadata(
    Map<String, Object?> response,
    Map<String, Object?>? choice,
  ) {
    return _providerMetadata({
      'serviceTier': _asString(response['service_tier']),
      'systemFingerprint': _asString(response['system_fingerprint']),
      'finishReason': _asString(choice?['finish_reason']),
    });
  }

  ProviderMetadata? _providerMetadata(Map<String, Object?> values) {
    final scopedValues = <String, Object?>{};
    for (final entry in values.entries) {
      if (entry.value != null) {
        scopedValues[entry.key] = entry.value;
      }
    }

    if (scopedValues.isEmpty) {
      return null;
    }

    return ProviderMetadata({
      providerNamespace: scopedValues,
    });
  }

  UsageStats? _decodeUsage(Map<String, Object?>? usage) {
    if (usage == null) {
      return null;
    }

    final inputTokens = _asInt(usage['prompt_tokens']);
    final outputTokens = _asInt(usage['completion_tokens']);
    final totalTokens = _asInt(usage['total_tokens']) ??
        ((inputTokens != null && outputTokens != null)
            ? inputTokens + outputTokens
            : null);
    final completionDetails = _asMap(usage['completion_tokens_details']);

    return UsageStats(
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalTokens: totalTokens,
      reasoningTokens: _asInt(completionDetails?['reasoning_tokens']),
    );
  }

  FinishReason _mapFinishReason(String? rawReason) {
    return switch (rawReason) {
      null || 'stop' => FinishReason.stop,
      'length' => FinishReason.maxTokens,
      'tool_calls' => FinishReason.toolCalls,
      'content_filter' => FinishReason.contentFilter,
      'cancelled' => FinishReason.aborted,
      _ => FinishReason.other,
    };
  }

  String? _extractContentDelta(Map<String, Object?> delta) {
    return _asString(delta['content']);
  }

  String? _extractReasoningDelta(Map<String, Object?> delta) {
    final candidates = [
      _asString(delta['reasoning_content']),
      _asString(delta['reasoning']),
      _asString(delta['thinking']),
    ];

    for (final candidate in candidates) {
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }

    return null;
  }

  Map<String, Object?>? _firstChoice(Map<String, Object?> response) {
    final choices = _asList(response['choices']);
    if (choices.isEmpty) {
      return null;
    }

    return _asMap(choices.first);
  }

  String _encodeJsonString(Object? value) {
    if (value == null) {
      return '{}';
    }

    if (value is String) {
      return value;
    }

    return jsonEncode(value);
  }

  String _encodeToolOutput({
    required Object? output,
    required bool isError,
  }) {
    if (output == null) {
      return isError ? 'Tool execution failed' : 'null';
    }

    if (output is String) {
      return output;
    }

    return jsonEncode(output);
  }

  _DecodedJsonValue _tryDecodeJsonValue(String value) {
    try {
      return _DecodedJsonValue(
        value: jsonDecode(value),
      );
    } on FormatException catch (error) {
      return _DecodedJsonValue(
        value: value,
        error: error,
      );
    } catch (error) {
      return _DecodedJsonValue(
        value: value,
        error: FormatException(error.toString()),
      );
    }
  }

  String _formatInvalidToolInputError(
    String toolName,
    FormatException error,
  ) {
    final message = error.message.trim();
    if (message.isEmpty) {
      return 'Invalid JSON tool arguments for "$toolName".';
    }

    return 'Invalid JSON tool arguments for "$toolName": $message';
  }

  void _throwIfError(Map<String, Object?> response) {
    final error = _asMap(response['error']);
    if (error == null) {
      return;
    }

    final message = _asString(error['message']) ?? 'OpenAI response error';
    final type = _asString(error['type']);
    final code = error['code'];
    throw StateError(
      'OpenAI chat-completions error: $message'
      '${type == null ? '' : ' (type: $type)'}'
      '${code == null ? '' : ' (code: $code)'}',
    );
  }

  Map<String, Object?>? _asMap(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }

    if (value is Map) {
      return Map<String, Object?>.from(value);
    }

    return null;
  }

  List<Object?> _asList(Object? value) {
    if (value is List<Object?>) {
      return value;
    }

    if (value is List) {
      return List<Object?>.from(value);
    }

    return const [];
  }

  String? _asString(Object? value) {
    return value is String ? value : null;
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return null;
  }

  DateTime? _decodeResponseTimestamp(Map<String, Object?> response) {
    final created = _asInt(response['created']);
    if (created == null) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(
      created * 1000,
      isUtc: true,
    );
  }

  static const String _textId = 'text_0';
  static const String _reasoningId = 'reasoning_0';
}

final class _OpenAIChatCompletionsToolCallState {
  final int index;
  String? toolCallId;
  String? toolName;
  final StringBuffer arguments = StringBuffer();
  bool startEmitted = false;

  _OpenAIChatCompletionsToolCallState({
    required this.index,
  });
}

final class _DecodedAssistantText {
  final String text;
  final String? reasoning;

  const _DecodedAssistantText({
    required this.text,
    this.reasoning,
  });
}

final class _ToolCallDeltaResult {
  final int index;
  final _OpenAIChatCompletionsToolCallState? toolState;
  final String? argumentsDelta;

  const _ToolCallDeltaResult({
    required this.index,
    required this.toolState,
    required this.argumentsDelta,
  });
}

final class _DecodedJsonValue {
  final Object? value;
  final FormatException? error;

  const _DecodedJsonValue({
    required this.value,
    this.error,
  });
}
