import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import 'client.dart';
import 'openai_request_config.dart';

/// OpenAI-compatible request builder for Chat Completions.
///
/// This mirrors the pattern used by `llm_dart_anthropic_compatible`:
/// - compatibility layer owns request JSON construction
/// - provider packages stay thin (defaults + small adapters)
class OpenAIRequestBuilder {
  final OpenAIRequestConfig config;

  const OpenAIRequestBuilder(this.config);

  Map<String, dynamic> buildChatCompletionsRequestBody(
    OpenAIClient client, {
    required List<ChatMessage> messages,
    required List<Tool>? tools,
    required bool stream,
  }) {
    final providerId = client.providerId;
    final isGroq = providerId == 'groq' || providerId == 'groq-openai';
    final isDeepSeek =
        providerId == 'deepseek' || providerId == 'deepseek-openai';
    final isXai = providerId == 'xai' || providerId == 'xai-openai';
    final apiMessages = client.buildApiMessages(messages);

    // Prefer explicit system messages over config.systemPrompt.
    final hasSystemMessage = messages.any((m) => m.role == ChatRole.system);
    if (!hasSystemMessage && config.systemPrompt != null) {
      apiMessages.insert(0, {'role': 'system', 'content': config.systemPrompt});
    }

    final body = <String, dynamic>{
      'model': config.model,
      'messages': apiMessages,
      'stream': stream,
    };

    body.addAll(
      ReasoningUtils.getMaxTokensParams(
        model: config.model,
        maxTokens: config.maxTokens,
      ),
    );

    if (config.temperature != null) body['temperature'] = config.temperature;
    if (config.topP != null) body['top_p'] = config.topP;
    if (config.topK != null) body['top_k'] = config.topK;

    body.addAll(
      ReasoningUtils.getReasoningEffortParams(
        providerId: providerId,
        model: config.model,
        reasoningEffort: config.reasoningEffort,
        maxTokens: config.maxTokens,
      ),
    );

    final effectiveTools = tools ?? config.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      body['tools'] = effectiveTools.map((t) => t.toJson()).toList();

      final effectiveToolChoice = config.toolChoice;
      if (effectiveToolChoice != null) {
        body['tool_choice'] = _convertToolChoice(effectiveToolChoice);
      }
    }

    if (config.jsonSchema != null) {
      final structuredOutputs = isGroq
          ? (config.getProviderOption<bool>('structuredOutputs') ?? true)
          : true;

      if (!structuredOutputs && isGroq) {
        body['response_format'] = const {'type': 'json_object'};
      } else {
        final schema = config.jsonSchema!;
        final responseFormat = <String, dynamic>{
          'type': 'json_schema',
          'json_schema': schema.toJson(),
        };

        // Ensure additionalProperties is set to false for OpenAI compliance.
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

        body['response_format'] = responseFormat;
      }
    }

    if (config.stopSequences != null && config.stopSequences!.isNotEmpty) {
      body['stop'] = config.stopSequences;
    }

    final userFromOptions = config.getProviderOption<String>('user');
    final effectiveUser = userFromOptions ?? config.user;
    if (effectiveUser != null) body['user'] = effectiveUser;

    final serviceTierFromOptions =
        isGroq ? config.getProviderOption<String>('serviceTier') : null;
    if (serviceTierFromOptions != null) {
      body['service_tier'] = serviceTierFromOptions;
    } else if (config.serviceTier != null) {
      body['service_tier'] = config.serviceTier!.value;
    }

    // OpenAI-style optional params (best-effort; provider owns validation).
    final frequencyPenalty =
        config.getProviderOption<double>('frequencyPenalty');
    if (frequencyPenalty != null) {
      body['frequency_penalty'] = frequencyPenalty;
    }

    final presencePenalty = config.getProviderOption<double>('presencePenalty');
    if (presencePenalty != null) {
      body['presence_penalty'] = presencePenalty;
    }

    final logitBias =
        config.getProviderOption<Map<String, double>>('logitBias');
    if (logitBias != null && logitBias.isNotEmpty) {
      body['logit_bias'] = logitBias;
    }

    final seed = config.getProviderOption<int>('seed');
    if (seed != null) {
      body['seed'] = seed;
    }

    final parallelToolCalls =
        config.getProviderOption<bool>('parallelToolCalls');
    if (parallelToolCalls != null) {
      body['parallel_tool_calls'] = parallelToolCalls;
    }

    final logprobs = config.getProviderOption<bool>('logprobs');
    if (logprobs != null) {
      body['logprobs'] = logprobs;
    }

    final topLogprobs = config.getProviderOption<int>('topLogprobs');
    if (topLogprobs != null) {
      body['top_logprobs'] = topLogprobs;
    }

    final verbosity = config.getProviderOption<String>('verbosity');
    if (verbosity != null) {
      body['verbosity'] = verbosity;
    }

    if (isGroq) {
      final reasoningFormat =
          config.getProviderOption<String>('reasoningFormat');
      if (reasoningFormat != null) {
        body['reasoning_format'] = reasoningFormat;
      }

      // Forward raw string to support Groq-only values (`default`, `none`).
      final reasoningEffortRaw =
          config.getProviderOption<String>('reasoningEffort');
      if (reasoningEffortRaw != null) {
        body['reasoning_effort'] = reasoningEffortRaw;
      }
    }

    // DeepSeek supports OpenAI-style `response_format` but may not implement
    // OpenAI structured outputs. Provide a raw escape hatch via providerOptions.
    if (isDeepSeek && !body.containsKey('response_format')) {
      final responseFormat =
          config.getProviderOption<Map<String, dynamic>>('responseFormat');
      if (responseFormat != null && responseFormat.isNotEmpty) {
        body['response_format'] = responseFormat;
      }
    }

    // xAI (Grok) live search: `search_parameters` request body field.
    //
    // We intentionally treat this as provider-specific (not standardized). The
    // provider is the source of truth for supported shapes/validation.
    if (isXai) {
      final liveSearchEnabled =
          config.getProviderOption<bool>('liveSearch') == true;
      final searchParameters =
          config.getProviderOption<Map<String, dynamic>>('searchParameters');

      if (liveSearchEnabled || searchParameters != null) {
        body['search_parameters'] = searchParameters ??
            const {
              'mode': 'auto',
              'sources': [
                {'type': 'web'},
              ],
            };
      }
    }

    final extraBodyFromConfig = config.extraBody;
    if (extraBodyFromConfig != null && extraBodyFromConfig.isNotEmpty) {
      body.addAll(extraBodyFromConfig);
    }

    return body;
  }

  /// OpenAI-compatible `tool_choice` expects:
  /// - string values for `auto` / `none` / `required`
  /// - object values for specific function tool selection
  ///
  /// This matches Vercel AI SDK behavior for Chat Completions.
  dynamic _convertToolChoice(ToolChoice toolChoice) {
    return switch (toolChoice) {
      AutoToolChoice() => 'auto',
      NoneToolChoice() => 'none',
      AnyToolChoice() => 'required',
      SpecificToolChoice() => toolChoice.toJson(),
    };
  }
}
