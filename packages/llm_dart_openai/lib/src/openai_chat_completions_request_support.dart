part of 'openai_chat_completions_codec.dart';

extension _OpenAIChatCompletionsCodecRequestSupport
    on OpenAIChatCompletionsCodec {
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
    required FileData? data,
    required ProviderMetadata? metadata,
  }) {
    return data?.providerReference?.requireProvider(
          providerNamespace,
          context: '$providerNamespace file prompt part',
        ) ??
        _asString(
          _providerMetadataValues(
            metadata,
            namespace: providerNamespace,
          )?['fileId'],
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
}
