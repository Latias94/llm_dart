part of 'openai_responses_codec.dart';

extension _OpenAIResponsesCodecRequestSupport on OpenAIResponsesCodec {
  void _applyOpenAIReasoningCompatibility({
    required OpenAIGenerateTextOptions providerOptions,
    required Map<String, Object?> body,
    required List<ModelWarning> warnings,
    required bool isReasoningModel,
    required OpenAIModelCapabilities capabilities,
  }) {
    final reasoningEffort = providerOptions.reasoningEffort;

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
      }

      return;
    }

    if (reasoningEffort != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'reasoningEffort',
          message: 'reasoningEffort is not supported for non-reasoning models',
        ),
      );
    }
  }

  void _applyOpenAIServiceTierCompatibility({
    required Map<String, Object?> body,
    required List<ModelWarning> warnings,
    required OpenAIModelCapabilities capabilities,
  }) {
    final serviceTier = body['service_tier'];
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

  List<String>? _resolveInclude(
    OpenAIGenerateTextOptions providerOptions, {
    required bool isReasoningModel,
    required bool store,
  }) {
    final values = <String>{};

    if (providerOptions.include case final include?) {
      for (final item in include) {
        values.add(item.value);
      }
    }

    if (providerOptions.logprobs != null) {
      values.add(OpenAIResponsesInclude.messageOutputTextLogprobs.value);
    }

    if (!store && isReasoningModel) {
      values.add(OpenAIResponsesInclude.reasoningEncryptedContent.value);
    }

    if (values.isEmpty) {
      return null;
    }

    return values.toList(growable: false);
  }

  int? _encodeResponsesTopLogProbs(OpenAILogProbs? logprobs) {
    if (logprobs == null) {
      return null;
    }

    return logprobs.topLogProbs ?? OpenAILogProbs.responsesMaxTopLogProbs;
  }

  Map<String, Object?>? _encodeOpenAICompactionItem(
    CustomPromptPart part, {
    required bool store,
    required bool hasConversation,
  }) {
    final data = part.data is Map
        ? Map<String, Object?>.from(part.data as Map)
        : const <String, Object?>{};
    final metadata = _providerMetadataValues(
      part.providerMetadata,
      namespace: 'openai',
    );
    final id = _asString(metadata?['itemId']) ?? _asString(data['id']);
    final encryptedContent = _asString(metadata?['encryptedContent']) ??
        _asString(data['encrypted_content']) ??
        _asString(data['encryptedContent']);

    if (hasConversation && id != null) {
      return null;
    }

    if (store && id != null) {
      return _encodeItemReference(id);
    }

    if (id == null || encryptedContent == null) {
      return null;
    }

    final item = <String, Object?>{
      'type': 'compaction',
      'id': id,
      'encrypted_content': encryptedContent,
    };

    for (final entry in data.entries) {
      if (entry.key == 'type' ||
          entry.key == 'id' ||
          entry.key == 'encrypted_content' ||
          entry.key == 'encryptedContent') {
        continue;
      }
      item[entry.key] = entry.value;
    }

    return item;
  }

  Map<String, Object?> _encodeItemReference(String id) {
    return {
      'type': 'item_reference',
      'id': id,
    };
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

  String _encodeJsonString(Object? value) {
    if (value == null) {
      return '{}';
    }

    if (value is String) {
      return value;
    }

    return jsonEncode(value);
  }

  List<Map<String, Object?>> _encodeTools({
    required List<FunctionToolDefinition> tools,
    required List<OpenAIBuiltInTool>? builtInTools,
  }) {
    final encoded = <Map<String, Object?>>[
      for (final tool in tools)
        {
          'type': 'function',
          'name': tool.name,
          if (tool.description != null) 'description': tool.description,
          'parameters': tool.inputSchema.toJson(),
          if (tool.strict != null) 'strict': tool.strict,
        },
    ];

    if (builtInTools != null) {
      encoded.addAll(
        builtInTools.map((tool) => tool.toJson()),
      );
    }

    return encoded;
  }

  Map<String, Object?>? _encodeToolChoice(
    ToolChoice? toolChoice, {
    required bool hasFunctionTools,
  }) {
    if (!hasFunctionTools || toolChoice == null) {
      return null;
    }

    return switch (toolChoice) {
      AutoToolChoice() => const {'type': 'auto'},
      RequiredToolChoice() => const {'type': 'required'},
      NoneToolChoice() => const {'type': 'none'},
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
          'schema': _ensureOpenAIJsonSchemaObject(responseFormat.schema!),
        if (responseFormat.strict != null) 'strict': responseFormat.strict,
      },
    };
  }

  Map<String, Object?> _ensureOpenAIJsonSchemaObject(
    Map<String, Object?> schema,
  ) {
    final normalized = Map<String, Object?>.from(schema);
    if (!normalized.containsKey('additionalProperties')) {
      normalized['additionalProperties'] = false;
    }
    return normalized;
  }

  String _encodeToolOutput(ToolOutput output) {
    if (output is ExecutionDeniedToolOutput) {
      return output.reason ?? 'Tool execution denied';
    }

    if (output is ContentToolOutput) {
      throw UnsupportedError(
        'OpenAI Responses tool result replay does not support ContentToolOutput yet.',
      );
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

  String? _openAIFileId({
    required FileData data,
  }) {
    return data.providerReference?.requireProvider(
      'openai',
      context: 'OpenAI file prompt part',
    );
  }
}
