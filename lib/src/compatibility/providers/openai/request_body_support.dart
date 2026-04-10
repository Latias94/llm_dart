import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../providers/openai/config.dart';
import '../../../../utils/reasoning_utils.dart';
import '../../../config/legacy_config_keys.dart';
import '../../../config/legacy_provider_options.dart';
import 'client.dart';
import 'config_views.dart';

/// Builds OpenAI-compatible request messages while preserving the legacy
/// compatibility rule that config-level system prompts are only prepended when
/// the caller did not already provide an explicit system message.
List<Map<String, dynamic>> buildOpenAICompatApiMessages({
  required OpenAIClient client,
  required OpenAIRequestCompatibilityConfigView requestConfig,
  required List<ChatMessage> messages,
}) {
  final apiMessages = client.buildApiMessages(messages);
  final hasSystemMessage =
      messages.any((message) => message.role == ChatRole.system);

  if (!hasSystemMessage && requestConfig.systemPrompt != null) {
    apiMessages.insert(0, {
      'role': 'system',
      'content': requestConfig.systemPrompt,
    });
  }

  return apiMessages;
}

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
  body.addAll(
    ReasoningUtils.getMaxTokensParams(
      model: requestConfig.model,
      maxTokens: requestConfig.maxTokens,
    ),
  );

  if (requestConfig.temperature != null &&
      !ReasoningUtils.shouldDisableTemperature(requestConfig.model)) {
    body['temperature'] = requestConfig.temperature;
  }

  if (requestConfig.topP != null &&
      !ReasoningUtils.shouldDisableTopP(requestConfig.model)) {
    body['top_p'] = requestConfig.topP;
  }

  if (requestConfig.topK != null) {
    body['top_k'] = requestConfig.topK;
  }

  if (requestConfig.jsonSchema case final schema?) {
    body['response_format'] = buildOpenAICompatStructuredOutputFormat(schema);
  }

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

  final isOpenAIReasoningModel = client.providerId == 'openai' &&
      ReasoningUtils.isOpenAIReasoningModel(requestConfig.model);

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

  if (includeVerbosity) {
    final verbosity = getOpenAIFamilyProviderOption<String>(
      config: config,
      providerId: client.providerId,
      key: LegacyExtensionKeys.verbosity,
    );
    if (verbosity != null) {
      body['verbosity'] = verbosity;
    }
  }

  if (flattenExtraBody) {
    final extraBody = body['extra_body'];
    if (extraBody is Map) {
      body.addAll(Map<String, dynamic>.from(extraBody));
      body.remove('extra_body');
    }
  }
}

/// Builds the OpenAI structured-output request shape while preserving the
/// compatibility rule that `additionalProperties` defaults to `false`.
Map<String, dynamic> buildOpenAICompatStructuredOutputFormat(
  StructuredOutputFormat schema,
) {
  final responseFormat = <String, dynamic>{
    'type': 'json_schema',
    'json_schema': schema.toJson(),
  };

  if (schema.schema != null) {
    final schemaMap = Map<String, dynamic>.from(schema.schema!);
    if (!schemaMap.containsKey('additionalProperties')) {
      schemaMap['additionalProperties'] = false;
    }

    responseFormat['json_schema'] = {
      'name': schema.name,
      if (schema.description != null) 'description': schema.description,
      'schema': schemaMap,
      if (schema.strict != null) 'strict': schema.strict,
    };
  }

  return responseFormat;
}

/// Reads a provider option from the transitional namespaced bag when the
/// OpenAI-family compatibility client has a stable namespace, and otherwise
/// falls back to the flat legacy extension key.
T? getOpenAIFamilyProviderOption<T>({
  required OpenAIConfig config,
  required String providerId,
  required String key,
}) {
  final originalConfig = config.originalConfig;
  if (originalConfig == null) {
    return config.getExtension<T>(key);
  }

  final namespace = switch (providerId) {
    'openai' => LegacyProviderOptionNamespaces.openai,
    'openrouter' => LegacyProviderOptionNamespaces.openrouter,
    _ => null,
  };

  if (namespace == null) {
    return originalConfig.getExtension<T>(key);
  }

  return getLegacyProviderOption<T>(originalConfig, namespace, key);
}
