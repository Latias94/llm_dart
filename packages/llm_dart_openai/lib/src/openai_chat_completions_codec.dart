import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'openai_chat_completions_support.dart';
import 'openai_model_capabilities.dart';
import 'openai_options.dart';
import 'openai_response_format.dart';
import 'openai_streaming_support.dart';
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
  final List<Object?> logprobs = [];
  String? responseId;
  DateTime? responseTimestamp;
  String? responseModelId;
  UsageStats? usage;
  String? rawFinishReason;
  bool hasResponseMetadata = false;
  bool hasToolCalls = false;
  final OpenAIStreamPartState textParts = OpenAIStreamPartState();
  final OpenAIStreamPartState reasoningParts = OpenAIStreamPartState();
  final Set<String> emittedSourceIds = {};
  final OpenAIIndexedToolCallAccumulator toolCalls =
      OpenAIIndexedToolCallAccumulator();
}

final class OpenAIChatCompletionsCodec {
  final String providerNamespace;

  const OpenAIChatCompletionsCodec({
    this.providerNamespace = 'openai',
  });

  OpenAIChatCompletionsSupport get _support => OpenAIChatCompletionsSupport(
        providerNamespace: providerNamespace,
      );

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

    if (providerOptions.common.instructions != null) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support instructions. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.maxToolCalls != null) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support maxToolCalls. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.metadata != null) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support metadata. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.truncation != null) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support truncation. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.include case final include?
        when include.isNotEmpty) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support include. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.promptCacheKey != null) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support promptCacheKey in the current family-safe mainline. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.promptCacheRetention != null) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support promptCacheRetention in the current family-safe mainline. Use the Responses API mainline instead.',
      );
    }

    if (providerOptions.common.safetyIdentifier != null) {
      throw UnsupportedError(
        'OpenAI-family chat-completions requests do not support safetyIdentifier in the current family-safe mainline. Use the Responses API mainline instead.',
      );
    }

    final warnings = <ModelWarning>[];
    final messages = <Map<String, Object?>>[];
    final systemMessageMode = _resolveSystemMessageMode(
      modelId,
      providerOptions.common,
    );

    for (final message in prompt) {
      messages.addAll(
        _encodePromptMessage(
          message,
          warnings,
          systemMessageMode: systemMessageMode,
        ),
      );
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
      if (providerOptions.common.user != null)
        'user': providerOptions.common.user,
      if (providerNamespace == 'openai' &&
          providerOptions.common.reasoningEffort != null)
        'reasoning_effort': providerOptions.common.reasoningEffort!.value,
      if (providerNamespace == 'openai' &&
          providerOptions.common.maxCompletionTokens != null)
        'max_completion_tokens': providerOptions.common.maxCompletionTokens,
      if (providerOptions.common.logprobs != null) 'logprobs': true,
      if (providerOptions.common.logprobs case final logprobs?)
        'top_logprobs': _encodeChatTopLogProbs(logprobs),
      if (providerOptions.xaiSearch != null)
        'search_parameters': providerOptions.xaiSearch!.toJson(),
    };

    _applyOpenAICompatibilityRules(
      modelId: modelId,
      providerOptions: providerOptions.common,
      body: body,
      warnings: warnings,
    );

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
    final textLogprobs = _decodeChatLogprobs(choice?['logprobs']);

    final decodedText = _support.decodeAssistantText(message);
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
            'logprobs': textLogprobs,
          }),
        ),
      );
    }

    final toolCalls = _support.decodeToolCalls(
      _asList(message['tool_calls']),
    );
    content.addAll(toolCalls);
    content.addAll(_support.decodeTopLevelSources(response));

    return GenerateTextResult(
      content: content,
      finishReason: _mapFinishReason(_asString(choice?['finish_reason'])),
      rawFinishReason: _asString(choice?['finish_reason']),
      responseId: _asString(response['id']),
      responseTimestamp: _decodeResponseTimestamp(response),
      responseModelId: _asString(response['model']),
      usage: _decodeUsage(_asMap(response['usage'])),
      providerMetadata: _support.responseMetadata(
        response,
        choice,
        logprobs: textLogprobs,
      ),
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
    final textLogprobs = _decodeChatLogprobs(choice['logprobs']);
    final chunkUsage = _decodeUsage(_asMap(chunk['usage']));
    if (chunkUsage != null) {
      state.usage = chunkUsage;
    }

    yield* _support.decodeChunkSources(
      chunk,
      responseId: state.responseId,
      emittedSourceIds: state.emittedSourceIds,
    );

    final reasoningDelta = _extractReasoningDelta(delta);
    yield* decodeOpenAIReasoningDeltaEvents(
      state: state.reasoningParts,
      id: _reasoningId,
      delta: reasoningDelta,
      startMetadata: () => _providerMetadata({
        'responseId': state.responseId,
      }),
      deltaMetadata: () => _providerMetadata({
        'responseId': state.responseId,
      }),
    );

    final contentDelta = _extractContentDelta(delta);
    yield* decodeOpenAITextDeltaEvents(
      state: state.textParts,
      id: _textId,
      delta: contentDelta,
      aggregateLogprobs: state.logprobs,
      deltaLogprobs: textLogprobs,
      startMetadata: () => _providerMetadata({
        'responseId': state.responseId,
        'logprobs': textLogprobs,
      }),
      deltaMetadata: () => _providerMetadata({
        'responseId': state.responseId,
        'logprobs': textLogprobs,
      }),
    );

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

      final startEvent = maybeCreateOpenAIToolInputStartEvent(
        toolState: toolState,
        fallbackToolCallId: 'tool_$index',
        metadata: () => _providerMetadata({
          'responseId': state.responseId,
          'toolIndex': index,
        }),
      );
      if (startEvent != null) {
        yield startEvent;
      }

      final deltaEvent = maybeCreateOpenAIToolInputDeltaEvent(
        toolState: toolState,
        fallbackToolCallId: 'tool_$index',
        delta: deltaResult.argumentsDelta,
        metadata: () => _providerMetadata({
          'responseId': state.responseId,
          'toolIndex': index,
        }),
      );
      if (deltaEvent != null) {
        yield deltaEvent;
      }
    }

    final rawFinishReason = _asString(choice['finish_reason']);
    if (rawFinishReason == null) {
      return;
    }

    state.rawFinishReason = rawFinishReason;

    final textEndEvent = maybeCreateOpenAITextEndEvent(
      state: state.textParts,
      id: _textId,
      metadata: () => _providerMetadata({
        'responseId': state.responseId,
        'logprobs': textLogprobs,
      }),
    );
    if (textEndEvent != null) {
      yield textEndEvent;
    }

    final reasoningEndEvent = maybeCreateOpenAIReasoningEndEvent(
      state: state.reasoningParts,
      id: _reasoningId,
      metadata: () => _providerMetadata({
        'responseId': state.responseId,
      }),
    );
    if (reasoningEndEvent != null) {
      yield reasoningEndEvent;
    }

    yield* _finalizeToolCalls(state);

    yield FinishEvent(
      finishReason: _mapFinishReason(rawFinishReason),
      rawFinishReason: rawFinishReason,
      usage: state.usage,
      providerMetadata: _providerMetadata({
        'responseId': state.responseId,
        'systemFingerprint': _asString(chunk['system_fingerprint']),
        if (state.logprobs.isNotEmpty)
          'logprobs': List<Object?>.unmodifiable(state.logprobs),
      }),
    );
  }

  List<Map<String, Object?>> _encodePromptMessage(
    PromptMessage message,
    List<ModelWarning> warnings, {
    required OpenAISystemMessageMode systemMessageMode,
  }) {
    if (message is SystemPromptMessage) {
      if (systemMessageMode == OpenAISystemMessageMode.remove) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.other,
            field: 'prompt.system',
            message: 'system messages are removed for this model',
          ),
        );
        return const [];
      }

      return [
        {
          'role': systemMessageMode.value,
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

      final encodedText = textParts.join();
      return [
        {
          'role': 'assistant',
          'content': encodedText,
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

  OpenAISystemMessageMode _resolveSystemMessageMode(
    String modelId,
    OpenAIGenerateTextOptions options,
  ) {
    if (options.systemMessageMode case final mode?) {
      return mode;
    }

    final capabilities = getOpenAIModelCapabilities(modelId);
    final isReasoningModel =
        options.forceReasoning ?? capabilities.isReasoningModel;

    return isReasoningModel
        ? OpenAISystemMessageMode.developer
        : capabilities.systemMessageMode;
  }

  void _applyOpenAICompatibilityRules({
    required String modelId,
    required OpenAIGenerateTextOptions providerOptions,
    required Map<String, Object?> body,
    required List<ModelWarning> warnings,
  }) {
    if (providerNamespace != 'openai') {
      return;
    }

    final isReasoningModel =
        _usesOpenAIReasoningCompatibility(modelId, providerOptions);
    final reasoningEffort = providerOptions.reasoningEffort;
    final capabilities = getOpenAIModelCapabilities(modelId);

    if (isReasoningModel) {
      final supportsNonReasoningParameters =
          reasoningEffort == OpenAIReasoningEffort.none &&
              capabilities.supportsNonReasoningParameters;

      if (!supportsNonReasoningParameters) {
        _removeBodyFieldWithWarning(
          body,
          'temperature',
          warnings,
          warning: const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'temperature',
            message: 'temperature is not supported for reasoning models',
          ),
        );
        _removeBodyFieldWithWarning(
          body,
          'top_p',
          warnings,
          warning: const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'topP',
            message: 'topP is not supported for reasoning models',
          ),
        );
        _removeBodyFieldWithWarning(
          body,
          'logprobs',
          warnings,
          warning: const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'logprobs',
            message: 'logprobs is not supported for reasoning models',
          ),
        );
        _removeBodyFieldWithWarning(
          body,
          'top_logprobs',
          warnings,
          warning: const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'topLogProbs',
            message: 'topLogprobs is not supported for reasoning models',
          ),
        );
      }

      final maxTokens = body.remove('max_tokens');
      if (maxTokens != null && !body.containsKey('max_completion_tokens')) {
        body['max_completion_tokens'] = maxTokens;
      }
    }

    _applyOpenAIServiceTierCompatibility(
      modelId: modelId,
      body: body,
      warnings: warnings,
    );
  }

  void _applyOpenAIServiceTierCompatibility({
    required String modelId,
    required Map<String, Object?> body,
    required List<ModelWarning> warnings,
  }) {
    final serviceTier = body['service_tier'];
    final capabilities = getOpenAIModelCapabilities(modelId);
    if (serviceTier == 'flex' && !capabilities.supportsFlexProcessing) {
      body.remove('service_tier');
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'serviceTier',
          message:
              'flex processing is only available for o3, o4-mini, and gpt-5 models',
        ),
      );
    }

    if (serviceTier == 'priority' && !capabilities.supportsPriorityProcessing) {
      body.remove('service_tier');
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'serviceTier',
          message:
              'priority processing is only available for supported models (gpt-4, gpt-5, gpt-5-mini, o3, o4-mini) and requires Enterprise access. gpt-5-nano is not supported',
        ),
      );
    }
  }

  void _removeBodyFieldWithWarning(
    Map<String, Object?> body,
    String key,
    List<ModelWarning> warnings, {
    required ModelWarning warning,
  }) {
    if (!body.containsKey(key)) {
      return;
    }

    body.remove(key);
    warnings.add(warning);
  }

  bool _usesOpenAIReasoningCompatibility(
    String modelId,
    OpenAIGenerateTextOptions options,
  ) {
    if (providerNamespace != 'openai') {
      return false;
    }

    return options.forceReasoning ??
        getOpenAIModelCapabilities(modelId).isReasoningModel;
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
      providerMetadata: _support.providerMetadata({
        'responseId': state.responseId,
      }),
    );
  }

  _ToolCallDeltaResult _consumeToolCallDelta(
    Map<String, Object?> toolCall,
    OpenAIChatCompletionsStreamState state,
  ) {
    final index = _asInt(toolCall['index']) ?? state.toolCalls.length;
    final function = _asMap(toolCall['function']) ?? const <String, Object?>{};
    final argumentsDelta = _asString(function['arguments']);
    if (argumentsDelta != null && argumentsDelta.isNotEmpty) {
      state.hasToolCalls = true;
    }

    final toolState = state.toolCalls.resolve(
      index,
      toolCallId: _asString(toolCall['id']),
      toolName: _asString(function['name']),
    );
    toolState.update(argumentsDelta: argumentsDelta);

    return _ToolCallDeltaResult(
      index: index,
      toolState: toolState,
      argumentsDelta: argumentsDelta,
    );
  }

  Iterable<TextStreamEvent> _finalizeToolCalls(
    OpenAIChatCompletionsStreamState state,
  ) sync* {
    for (final entry in state.toolCalls.sortedEntries()) {
      final toolState = entry.value;
      ProviderMetadata? metadata() => _providerMetadata({
            'responseId': state.responseId,
            'toolIndex': entry.key,
          });
      final startEvent = maybeCreateOpenAIToolInputStartEvent(
        toolState: toolState,
        fallbackToolCallId: 'tool_${entry.key}',
        metadata: metadata,
      );
      if (startEvent != null) {
        yield startEvent;
      }

      final resolvedInput = resolveOpenAIStreamToolInput(
        toolState: toolState,
        fallbackToolCallId: 'tool_${entry.key}',
      );
      if (resolvedInput.decodeError != null) {
        yield createOpenAIToolInputErrorEvent(
          input: resolvedInput,
          metadata: metadata,
        );
        continue;
      }

      final endEvent = maybeCreateOpenAIToolInputEndEvent(
        toolState: toolState,
        fallbackToolCallId: 'tool_${entry.key}',
        metadata: metadata,
      );
      if (endEvent != null) {
        yield endEvent;
      }
      yield ToolCallEvent(
        toolCall: ToolCallContent(
          toolCallId: resolvedInput.toolCallId,
          toolName: resolvedInput.toolName,
          input: resolvedInput.decodedInput,
        ),
        providerMetadata: metadata(),
      );
    }
    state.toolCalls.clear();
  }

  int _encodeChatTopLogProbs(OpenAILogProbs logprobs) {
    return logprobs.topLogProbs ?? 0;
  }

  List<Object?>? _decodeChatLogprobs(Object? value) {
    final logprobs = _asMap(value);
    return _jsonListOrNull(logprobs?['content']);
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
    return firstOpenAINonEmptyString([
      _asString(delta['reasoning_content']),
      _asString(delta['reasoning']),
      _asString(delta['thinking']),
    ]);
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

  List<Object?>? _jsonListOrNull(Object? value) {
    if (value is List<Object?>) {
      return value;
    }

    if (value is List) {
      return List<Object?>.from(value);
    }

    return null;
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

final class _ToolCallDeltaResult {
  final int index;
  final OpenAIStreamToolCallState? toolState;
  final String? argumentsDelta;

  const _ToolCallDeltaResult({
    required this.index,
    required this.toolState,
    required this.argumentsDelta,
  });
}
