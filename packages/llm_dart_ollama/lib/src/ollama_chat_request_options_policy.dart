import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'ollama_generate_text_options.dart';

final class OllamaChatRequestOptionsProjection {
  final Map<String, Object?> options;
  final Object? responseFormat;
  final bool? reasoning;

  OllamaChatRequestOptionsProjection({
    required Map<String, Object?> options,
    this.responseFormat,
    this.reasoning,
  }) : options = Map.unmodifiable(options);
}

final class OllamaChatRequestOptionsPolicy {
  const OllamaChatRequestOptionsPolicy();

  OllamaGenerateTextOptions? resolveProviderOptions(
    GenerateTextRequest request,
  ) {
    return resolveProviderInvocationOptions<OllamaGenerateTextOptions>(
      request.callOptions.providerOptions,
      parameterName: 'request.callOptions.providerOptions',
      expectedTypeName: 'OllamaGenerateTextOptions',
      usageContext: 'Ollama language models',
    );
  }

  OllamaChatRequestOptionsProjection project({
    required GenerateTextOptions options,
    required OllamaGenerateTextOptions? providerOptions,
    required List<ModelWarning> warnings,
  }) {
    final sharedReasoning = _resolveSharedReasoning(
      options.reasoning,
      warnings: warnings,
    );
    final effectiveReasoning = providerOptions?.reasoning ?? sharedReasoning;
    if (providerOptions?.reasoning != null && sharedReasoning != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'options.reasoning',
          message:
              'Ollama providerOptions.reasoning overrides shared options.reasoning.',
        ),
      );
    }

    _warnUnsupportedSharedOptions(
      options,
      warnings: warnings,
    );

    return OllamaChatRequestOptionsProjection(
      options: _encodeSamplingOptions(
        options: options,
        providerOptions: providerOptions,
      ),
      responseFormat: _resolveResponseFormat(
        options.responseFormat,
        warnings: warnings,
      ),
      reasoning: effectiveReasoning,
    );
  }

  bool? _resolveSharedReasoning(
    GenerateTextReasoningOptions? reasoning, {
    required List<ModelWarning> warnings,
  }) {
    if (reasoning == null) {
      return null;
    }

    if (reasoning.effort != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'options.reasoning.effort',
          message:
              'Ollama reasoning is a provider toggle; shared reasoning.effort is ignored.',
        ),
      );
    }

    if (reasoning.budgetTokens != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'options.reasoning.budgetTokens',
          message:
              'Ollama reasoning is a provider toggle; shared reasoning.budgetTokens is ignored.',
        ),
      );
    }

    return reasoning.enabled;
  }

  void _warnUnsupportedSharedOptions(
    GenerateTextOptions options, {
    required List<ModelWarning> warnings,
  }) {
    if (options.frequencyPenalty != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'options.frequencyPenalty',
          message:
              'Ollama does not support shared frequencyPenalty; use provider-native sampling options when needed.',
        ),
      );
    }

    if (options.presencePenalty != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'options.presencePenalty',
          message:
              'Ollama does not support shared presencePenalty; use provider-native sampling options when needed.',
        ),
      );
    }
  }

  Object? _resolveResponseFormat(
    ResponseFormat? responseFormat, {
    required List<ModelWarning> warnings,
  }) {
    return switch (responseFormat) {
      null || TextResponseFormat() => null,
      JsonResponseFormat(
        schema: final schema,
        name: final name,
        description: final description,
        strict: final strict,
      ) =>
        () {
          if (name != null || description != null || strict != null) {
            warnings.add(
              const ModelWarning(
                type: ModelWarningType.compatibility,
                field: 'options.responseFormat',
                message:
                    'Ollama only supports the shared JSON schema body. responseFormat name, description, and strict are ignored.',
              ),
            );
          }
          return schema.toJson();
        }(),
    };
  }

  Map<String, Object?> _encodeSamplingOptions({
    required GenerateTextOptions options,
    required OllamaGenerateTextOptions? providerOptions,
  }) {
    return <String, Object?>{
      if (options.temperature != null) 'temperature': options.temperature,
      if (options.topP != null) 'top_p': options.topP,
      if (options.topK != null) 'top_k': options.topK,
      if (options.maxOutputTokens != null)
        'num_predict': options.maxOutputTokens,
      if (options.seed != null) 'seed': options.seed,
      if (options.stopSequences case final stopSequences?
          when stopSequences.isNotEmpty)
        'stop': stopSequences,
      if (providerOptions?.numCtx != null) 'num_ctx': providerOptions!.numCtx,
      if (providerOptions?.numGpu != null) 'num_gpu': providerOptions!.numGpu,
      if (providerOptions?.numThread != null)
        'num_thread': providerOptions!.numThread,
      if (providerOptions?.numBatch != null)
        'num_batch': providerOptions!.numBatch,
      if (providerOptions?.numa != null) 'numa': providerOptions!.numa,
    };
  }
}
