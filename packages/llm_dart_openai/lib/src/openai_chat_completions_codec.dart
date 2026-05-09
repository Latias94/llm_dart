import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

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

final class OpenAIChatCompletionsStreamState extends OpenAIStreamState {
  final Set<String> emittedSourceIds = {};
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
    return _encodeRequest(
      modelId: modelId,
      prompt: prompt,
      tools: tools,
      toolChoice: toolChoice,
      options: options,
      providerOptions: providerOptions,
      stream: stream,
    );
  }

  GenerateTextResult decodeGenerateResponse(
    Map<String, Object?> response, {
    List<ModelWarning> warnings = const [],
  }) =>
      _decodeGenerateResponse(response, warnings: warnings);

  Iterable<TextStreamEvent> decodeStreamChunk(
    Map<String, Object?> chunk,
    OpenAIChatCompletionsStreamState state,
  ) sync* {
    yield* _decodeOpenAIChatCompletionsStreamChunk(this, chunk, state);
  }

  OpenAIChatCompletionsRequest _encodeRequest({
    required String modelId,
    required List<PromptMessage> prompt,
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required GenerateTextOptions options,
    required ResolvedOpenAIGenerateTextOptions providerOptions,
    required bool stream,
  }) {
    _validateUnsupportedChatCompletionsProviderOptions(providerOptions);

    final warnings = <ModelWarning>[];
    final messages = <Map<String, Object?>>[];
    final systemMessageMode = _resolveSystemMessageMode(
      modelId,
      providerOptions.common,
    );
    final deepseekOptions =
        providerNamespace == 'deepseek' ? providerOptions.deepseek : null;
    final deepseekLogprobs = deepseekOptions?.logprobs;
    final deepseekTopLogprobs = deepseekOptions?.topLogprobs;
    final deepseekFrequencyPenalty = deepseekOptions?.frequencyPenalty;
    final deepseekPresencePenalty = deepseekOptions?.presencePenalty;
    final deepseekResponseFormat = deepseekOptions?.responseFormat;
    final commonLogprobs = providerOptions.common.logprobs;

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
      if (deepseekLogprobs != null) 'logprobs': deepseekLogprobs,
      if (deepseekLogprobs == null && commonLogprobs != null) 'logprobs': true,
      if (deepseekTopLogprobs != null) 'top_logprobs': deepseekTopLogprobs,
      if (deepseekTopLogprobs == null && commonLogprobs != null)
        'top_logprobs': _encodeChatTopLogProbs(commonLogprobs),
      if (providerNamespace == 'deepseek' && deepseekFrequencyPenalty != null)
        'frequency_penalty': deepseekFrequencyPenalty,
      if (providerNamespace == 'deepseek' && deepseekPresencePenalty != null)
        'presence_penalty': deepseekPresencePenalty,
      if (providerOptions.xaiSearch != null)
        'search_parameters': providerOptions.xaiSearch!.toJson(),
    };

    _applyOpenAICompatibilityRules(
      modelId: modelId,
      providerOptions: providerOptions.common,
      body: body,
      warnings: warnings,
    );
    _applyDeepSeekCompatibilityRules(
      modelId: modelId,
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
    } else if (providerNamespace == 'deepseek' &&
        deepseekResponseFormat != null) {
      body['response_format'] = deepseekResponseFormat;
    }

    return OpenAIChatCompletionsRequest(
      body: body,
      warnings: warnings,
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
              :final toolName,
              :final toolOutput,
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
              'content': _encodeToolOutput(toolOutput),
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
      if (_openAIFileId(
        data: part.data,
      )
          case final fileId?) {
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

  void _validateUnsupportedChatCompletionsProviderOptions(
    ResolvedOpenAIGenerateTextOptions providerOptions,
  ) {
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

  void _applyDeepSeekCompatibilityRules({
    required String modelId,
    required Map<String, Object?> body,
    required List<ModelWarning> warnings,
  }) {
    if (providerNamespace != 'deepseek' || !modelId.contains('reasoner')) {
      return;
    }

    _removeBodyFieldWithWarning(
      body,
      'logprobs',
      warnings,
      warning: const ModelWarning(
        type: ModelWarningType.unsupported,
        field: 'logprobs',
        message: 'logprobs is not supported for DeepSeek reasoner models',
      ),
    );
    _removeBodyFieldWithWarning(
      body,
      'top_logprobs',
      warnings,
      warning: const ModelWarning(
        type: ModelWarningType.unsupported,
        field: 'topLogprobs',
        message: 'topLogprobs is not supported for DeepSeek reasoner models',
      ),
    );
    _removeBodyFieldWithWarning(
      body,
      'frequency_penalty',
      warnings,
      warning: const ModelWarning(
        type: ModelWarningType.unsupported,
        field: 'frequencyPenalty',
        message: 'frequencyPenalty has no effect on DeepSeek reasoner models',
      ),
    );
    _removeBodyFieldWithWarning(
      body,
      'presence_penalty',
      warnings,
      warning: const ModelWarning(
        type: ModelWarningType.unsupported,
        field: 'presencePenalty',
        message: 'presencePenalty has no effect on DeepSeek reasoner models',
      ),
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

  String? _openAIFileId({
    required FileData data,
  }) {
    return data.providerReference?.requireProvider(
      providerNamespace,
      context: '$providerNamespace file prompt part',
    );
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

  GenerateTextResult _decodeGenerateResponse(
    Map<String, Object?> response, {
    List<ModelWarning> warnings = const [],
  }) {
    _throwIfError(response);

    final choice = _firstChoice(response);
    final message = _asMap(choice?['message']) ?? const <String, Object?>{};
    final content = <ContentPart>[];
    final textLogprobs = _decodeChatLogprobs(choice?['logprobs']);
    final rawFinishReason = _asString(choice?['finish_reason']);

    final decodedText = _support.decodeAssistantText(message);
    if (decodedText.reasoning case final reasoning? when reasoning.isNotEmpty) {
      content.add(
        ReasoningContentPart(
          reasoning,
          providerMetadata: _support.providerMetadata({
            'finishReason': rawFinishReason,
          }),
        ),
      );
    }

    if (decodedText.text.isNotEmpty) {
      content.add(
        TextContentPart(
          decodedText.text,
          providerMetadata: _support.providerMetadata({
            'finishReason': rawFinishReason,
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
      finishReason: _mapFinishReason(rawFinishReason),
      rawFinishReason: rawFinishReason,
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

  List<Object?>? _decodeChatLogprobs(Object? value) {
    final logprobs = _asMap(value);
    return _jsonListOrNull(logprobs?['content']);
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

  Map<String, Object?>? _firstChoice(Map<String, Object?> response) {
    final choices = _asList(response['choices']);
    if (choices.isEmpty) {
      return null;
    }

    return _asMap(choices.first);
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

  Iterable<TextStreamEvent> _finalizeToolCalls(
    OpenAIChatCompletionsStreamState state,
    _ChatCompletionsStreamMetadataAdapter metadata,
  ) sync* {
    for (final entry in state.toolCalls.sortedEntries()) {
      final toolState = entry.value;
      final startEvent = maybeCreateOpenAIToolInputStartEvent(
        toolState: toolState,
        fallbackToolCallId: 'tool_${entry.key}',
        metadata: () => metadata.tool(entry.key),
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
          metadata: () => metadata.tool(entry.key),
        );
        continue;
      }

      final endEvent = maybeCreateOpenAIToolInputEndEvent(
        toolState: toolState,
        fallbackToolCallId: 'tool_${entry.key}',
        metadata: () => metadata.tool(entry.key),
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
        providerMetadata: metadata.tool(entry.key),
      );
    }
    state.toolCalls.clear();
  }

  int _encodeChatTopLogProbs(OpenAILogProbs logprobs) {
    return logprobs.topLogProbs ?? 0;
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

  String _encodeJsonString(Object? value) {
    if (value == null) {
      return '{}';
    }

    if (value is String) {
      return value;
    }

    return jsonEncode(value);
  }

  String _encodeToolOutput(ToolOutput output) {
    if (output is ExecutionDeniedToolOutput) {
      return output.reason ?? 'Tool execution denied';
    }

    if (output is ContentToolOutput) {
      return _encodeContentToolOutput(output.parts);
    }

    final value = output.value;
    if (value == null) {
      return output.isError ? 'Tool execution failed' : 'null';
    }

    if (value is String) {
      return value;
    }

    return jsonEncode(value);
  }

  String _encodeContentToolOutput(List<ToolOutputContentPart> parts) {
    return jsonEncode([
      for (final part in parts) _encodeContentToolOutputPart(part),
    ]);
  }

  Map<String, Object?> _encodeContentToolOutputPart(
    ToolOutputContentPart part,
  ) {
    return switch (part) {
      TextToolOutputContentPart(:final text, :final providerMetadata) => {
          'type': 'text',
          'text': text,
          if (providerMetadata != null)
            'providerMetadata': providerMetadata.toJsonMap(),
        },
      JsonToolOutputContentPart(:final value, :final providerMetadata) => {
          'type': 'json',
          'value': _normalizeJsonValue(value),
          if (providerMetadata != null)
            'providerMetadata': providerMetadata.toJsonMap(),
        },
      FileToolOutputContentPart(
        :final mediaType,
        :final filename,
        :final data,
        :final providerMetadata,
      ) =>
        {
          'type': 'file',
          'mediaType': mediaType,
          if (filename != null) 'filename': filename,
          'data': _encodeFileData(data),
          if (providerMetadata != null)
            'providerMetadata': providerMetadata.toJsonMap(),
        },
      CustomToolOutputContentPart(
        :final kind,
        :final data,
        :final providerMetadata,
      ) =>
        {
          'type': 'custom',
          'kind': kind,
          if (data != null) 'data': _normalizeJsonValue(data),
          if (providerMetadata != null)
            'providerMetadata': providerMetadata.toJsonMap(),
        },
    };
  }

  Map<String, Object?> _encodeFileData(FileData data) {
    return switch (data) {
      FileBytesData(:final bytes) => {
          'type': 'bytes',
          'bytes': {
            'encoding': 'base64',
            'data': base64Encode(bytes),
          },
        },
      FileUrlData(:final uri) => {
          'type': 'url',
          'uri': uri.toString(),
        },
      FileTextData(:final text) => {
          'type': 'text',
          'text': text,
        },
      FileProviderReferenceData(:final providerReference) => {
          'type': 'provider-reference',
          'providerReference': providerReference.toJsonMap(),
        },
    };
  }

  Object? _normalizeJsonValue(Object? value) {
    return normalizeJsonValue(value);
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

Iterable<TextStreamEvent> _decodeOpenAIChatCompletionsStreamChunk(
  OpenAIChatCompletionsCodec codec,
  Map<String, Object?> chunk,
  OpenAIChatCompletionsStreamState state,
) sync* {
  final metadata = _ChatCompletionsStreamMetadataAdapter(
    support: codec._support,
    state: state,
    chunk: chunk,
  );
  captureOpenAIResponseMetadata(
    state: state,
    responseId: codec._asString(chunk['id']),
    responseModelId: codec._asString(chunk['model']),
    responseTimestamp: codec._decodeResponseTimestamp(chunk),
  );
  final metadataEvent = maybeCreateOpenAIResponseMetadataEvent(
    state: state,
    metadata: metadata.response,
  );
  if (metadataEvent != null) {
    yield metadataEvent;
  }

  final choice = codec._firstChoice(chunk);
  if (choice == null) {
    if (codec._asMap(chunk['error']) case final error?) {
      yield ErrorEvent(
        ModelError.fromUnknown(
          error,
          kind: ModelErrorKind.provider,
        ),
      );
    }
    return;
  }

  final delta = codec._asMap(choice['delta']) ?? const <String, Object?>{};
  final textLogprobs = codec._decodeChatLogprobs(choice['logprobs']);
  captureOpenAIResponseMetadata(
    state: state,
    usage: codec._decodeUsage(codec._asMap(chunk['usage'])),
  );

  yield* codec._support.decodeChunkSources(
    chunk,
    responseId: state.responseId,
    emittedSourceIds: state.emittedSourceIds,
  );

  final reasoningDelta = codec._extractReasoningDelta(delta);
  yield* decodeOpenAIReasoningDeltaEvents(
    state: state.reasoningParts,
    id: OpenAIChatCompletionsCodec._reasoningId,
    delta: reasoningDelta,
    startMetadata: metadata.reasoning,
    deltaMetadata: metadata.reasoning,
  );

  final contentDelta = codec._extractContentDelta(delta);
  yield* decodeOpenAITextDeltaEvents(
    state: state.textParts,
    id: OpenAIChatCompletionsCodec._textId,
    delta: contentDelta,
    aggregateLogprobs: state.logprobs,
    deltaLogprobs: textLogprobs,
    startMetadata: () => metadata.text(textLogprobs),
    deltaMetadata: () => metadata.text(textLogprobs),
  );

  for (final rawToolCall in codec._asList(delta['tool_calls'])) {
    final toolCall = codec._asMap(rawToolCall);
    if (toolCall == null) {
      continue;
    }

    final rawIndex = codec._asInt(toolCall['index']);
    final index = rawIndex ?? state.toolCalls.length;
    final function =
        codec._asMap(toolCall['function']) ?? const <String, Object?>{};
    final deltaResult = consumeOpenAIToolCallDelta(
      state: state,
      index: rawIndex,
      fallbackIndex: index,
      fallbackToolCallId: 'tool_$index',
      toolCallId: codec._asString(toolCall['id']),
      toolName: codec._asString(function['name']),
      argumentsDelta: codec._asString(function['arguments']),
    );
    final toolState = deltaResult.toolState;
    if (toolState.toolCallId == null || toolState.toolName == null) {
      continue;
    }

    final startEvent = maybeCreateOpenAIToolInputStartEvent(
      toolState: toolState,
      fallbackToolCallId: 'tool_$index',
      metadata: () => metadata.tool(index),
    );
    if (startEvent != null) {
      yield startEvent;
    }

    final deltaEvent = maybeCreateOpenAIToolInputDeltaEvent(
      toolState: toolState,
      fallbackToolCallId: 'tool_$index',
      delta: deltaResult.argumentsDelta,
      metadata: () => metadata.tool(index),
    );
    if (deltaEvent != null) {
      yield deltaEvent;
    }
  }

  final rawFinishReason = codec._asString(choice['finish_reason']);
  if (rawFinishReason == null) {
    return;
  }

  captureOpenAIResponseMetadata(
    state: state,
    rawFinishReason: rawFinishReason,
  );

  final textEndEvent = maybeCreateOpenAITextEndEvent(
    state: state.textParts,
    id: OpenAIChatCompletionsCodec._textId,
    metadata: () => metadata.text(textLogprobs),
  );
  if (textEndEvent != null) {
    yield textEndEvent;
  }

  final reasoningEndEvent = maybeCreateOpenAIReasoningEndEvent(
    state: state.reasoningParts,
    id: OpenAIChatCompletionsCodec._reasoningId,
    metadata: metadata.reasoning,
  );
  if (reasoningEndEvent != null) {
    yield reasoningEndEvent;
  }

  yield* codec._finalizeToolCalls(state, metadata);

  yield FinishEvent(
    finishReason: codec._mapFinishReason(rawFinishReason),
    rawFinishReason: rawFinishReason,
    usage: state.usage,
    providerMetadata: metadata.finish(),
  );
}

final class _ChatCompletionsStreamMetadataAdapter {
  final OpenAIChatCompletionsSupport support;
  final OpenAIChatCompletionsStreamState state;
  final Map<String, Object?> chunk;

  const _ChatCompletionsStreamMetadataAdapter({
    required this.support,
    required this.state,
    required this.chunk,
  });

  ProviderMetadata? response() => support.providerMetadata({
        'responseId': state.responseId,
      });

  ProviderMetadata? reasoning() => support.providerMetadata({
        'responseId': state.responseId,
      });

  ProviderMetadata? text(List<Object?>? logprobs) => support.providerMetadata({
        'responseId': state.responseId,
        'logprobs': logprobs,
      });

  ProviderMetadata? tool(int index) => support.providerMetadata({
        'responseId': state.responseId,
        'toolIndex': index,
      });

  ProviderMetadata? finish() => support.providerMetadata({
        'responseId': state.responseId,
        'systemFingerprint': chunk['system_fingerprint'] is String
            ? chunk['system_fingerprint'] as String
            : null,
        if (state.logprobs.isNotEmpty)
          'logprobs': List<Object?>.unmodifiable(state.logprobs),
      });
}
