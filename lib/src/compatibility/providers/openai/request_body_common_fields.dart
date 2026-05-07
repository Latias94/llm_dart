part of 'request_body_support.dart';

/// Applies the common OpenAI-family request fields shared by chat-completions
/// and Responses compatibility request builders.
void applyOpenAICompatCommonRequestFields({
  required Map<String, dynamic> body,
  required OpenAIClient client,
  required OpenAIConfig config,
  required OpenAIRequestCompatibilityConfigView requestConfig,
  bool includeVerbosity = false,
  bool flattenExtraBody = false,
}) {
  _OpenAICompatCommonRequestFieldSupport(
    client: client,
    config: config,
    requestConfig: requestConfig,
  ).apply(
    body,
    includeVerbosity: includeVerbosity,
    flattenExtraBody: flattenExtraBody,
  );
}

final class _OpenAICompatCommonRequestFieldSupport {
  final OpenAIClient client;
  final OpenAIConfig config;
  final OpenAIRequestCompatibilityConfigView requestConfig;

  const _OpenAICompatCommonRequestFieldSupport({
    required this.client,
    required this.config,
    required this.requestConfig,
  });

  void apply(
    Map<String, dynamic> body, {
    required bool includeVerbosity,
    required bool flattenExtraBody,
  }) {
    _applyGenerationControls(body);
    _applyStructuredOutput(body);
    _applyStandardRequestFields(body);
    _applyOpenAIFamilyProviderOptions(body);

    if (includeVerbosity) {
      _applyVerbosity(body);
    }

    if (flattenExtraBody) {
      _flattenExtraBody(body);
    }
  }

  void _applyGenerationControls(Map<String, dynamic> body) {
    body.addAll(
      OpenAICompatReasoningRequestSupport.getMaxTokensParams(
        model: requestConfig.model,
        maxTokens: requestConfig.maxTokens,
      ),
    );

    if (requestConfig.temperature != null &&
        !OpenAICompatReasoningRequestSupport.shouldDisableTemperature(
          requestConfig.model,
        )) {
      body['temperature'] = requestConfig.temperature;
    }

    if (requestConfig.topP != null &&
        !OpenAICompatReasoningRequestSupport.shouldDisableTopP(
          requestConfig.model,
        )) {
      body['top_p'] = requestConfig.topP;
    }

    if (requestConfig.topK != null) {
      body['top_k'] = requestConfig.topK;
    }
  }

  void _applyStructuredOutput(Map<String, dynamic> body) {
    if (requestConfig.jsonSchema case final schema?) {
      body['response_format'] = buildOpenAICompatStructuredOutputFormat(schema);
    }
  }

  void _applyStandardRequestFields(Map<String, dynamic> body) {
    if (requestConfig.stopSequences case final stopSequences?
        when stopSequences.isNotEmpty) {
      body['stop'] = stopSequences;
    }

    if (requestConfig.user case final user?) {
      body['user'] = user;
    }

    if (requestConfig.serviceTier case final serviceTier?) {
      body['service_tier'] = serviceTier.value;
    }
  }

  void _applyOpenAIFamilyProviderOptions(Map<String, dynamic> body) {
    final isOpenAIReasoningModel = client.providerId == 'openai' &&
        OpenAICompatReasoningRequestSupport.isOpenAIReasoningModel(
          requestConfig.model,
        );

    final frequencyPenalty = getOpenAIFamilyProviderOption<double>(
      config: config,
      providerId: client.providerId,
      key: LegacyExtensionKeys.frequencyPenalty,
    );
    if (frequencyPenalty != null && !isOpenAIReasoningModel) {
      body['frequency_penalty'] = frequencyPenalty;
    }

    final presencePenalty = getOpenAIFamilyProviderOption<double>(
      config: config,
      providerId: client.providerId,
      key: LegacyExtensionKeys.presencePenalty,
    );
    if (presencePenalty != null && !isOpenAIReasoningModel) {
      body['presence_penalty'] = presencePenalty;
    }

    final logitBias = getOpenAIFamilyProviderOption<Map<String, double>>(
      config: config,
      providerId: client.providerId,
      key: LegacyExtensionKeys.logitBias,
    );
    if (logitBias != null && logitBias.isNotEmpty && !isOpenAIReasoningModel) {
      body['logit_bias'] = logitBias;
    }

    final seed = getOpenAIFamilyProviderOption<int>(
      config: config,
      providerId: client.providerId,
      key: LegacyExtensionKeys.seed,
    );
    if (seed != null) {
      body['seed'] = seed;
    }

    final parallelToolCalls = getOpenAIFamilyProviderOption<bool>(
      config: config,
      providerId: client.providerId,
      key: LegacyExtensionKeys.parallelToolCalls,
    );
    if (parallelToolCalls != null) {
      body['parallel_tool_calls'] = parallelToolCalls;
    }

    final logprobs = getOpenAIFamilyProviderOption<bool>(
      config: config,
      providerId: client.providerId,
      key: LegacyExtensionKeys.logprobs,
    );
    if (logprobs != null && !isOpenAIReasoningModel) {
      body['logprobs'] = logprobs;
    }

    final topLogprobs = getOpenAIFamilyProviderOption<int>(
      config: config,
      providerId: client.providerId,
      key: LegacyExtensionKeys.topLogprobs,
    );
    if (topLogprobs != null && !isOpenAIReasoningModel) {
      body['top_logprobs'] = topLogprobs;
    }
  }

  void _applyVerbosity(Map<String, dynamic> body) {
    final verbosity = getOpenAIFamilyProviderOption<String>(
      config: config,
      providerId: client.providerId,
      key: LegacyExtensionKeys.verbosity,
    );
    if (verbosity != null) {
      body['verbosity'] = verbosity;
    }
  }

  void _flattenExtraBody(Map<String, dynamic> body) {
    final extraBody = body['extra_body'];
    if (extraBody is Map) {
      body.addAll(Map<String, dynamic>.from(extraBody));
      body.remove('extra_body');
    }
  }
}
