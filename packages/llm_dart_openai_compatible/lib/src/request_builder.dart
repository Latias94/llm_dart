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

  Map<String, dynamic> _convertToolToChatCompletionsFormat(Tool tool) {
    final json = tool.toOpenAIChatCompletionsJson();

    // OpenAI strict tools require `additionalProperties: false` in parameters.
    if (tool.strict == true) {
      final function = json['function'];
      if (function is Map<String, dynamic>) {
        final parameters = function['parameters'];
        if (parameters is Map<String, dynamic>) {
          function['parameters'] = addAdditionalPropertiesToJsonSchema(
            parameters,
          );
        } else if (parameters is Map) {
          function['parameters'] = addAdditionalPropertiesToJsonSchema(
            Map<String, dynamic>.from(parameters),
          );
        }
      } else if (function is Map) {
        final functionMap = Map<String, dynamic>.from(function);
        final parameters = functionMap['parameters'];
        if (parameters is Map<String, dynamic>) {
          functionMap['parameters'] = addAdditionalPropertiesToJsonSchema(
            parameters,
          );
        } else if (parameters is Map) {
          functionMap['parameters'] = addAdditionalPropertiesToJsonSchema(
            Map<String, dynamic>.from(parameters),
          );
        }
        json['function'] = functionMap;
      }
    }

    return json;
  }

  Map<String, dynamic> buildChatCompletionsRequestBodyFromPrompt(
    OpenAIClient client, {
    required Prompt prompt,
    required List<Tool>? tools,
    List<ProviderTool>? providerTools,
    required bool stream,
  }) {
    final providerId = client.providerId;
    final isGroq = providerId == 'groq' || providerId == 'groq-openai';
    final isDeepSeek =
        providerId == 'deepseek' || providerId == 'deepseek-openai';
    final isXai = providerId == 'xai' || providerId == 'xai-openai';

    final apiMessages = client.buildApiMessagesFromPrompt(prompt);

    // Prefer explicit system messages over config.systemPrompt.
    final hasSystemMessage =
        prompt.messages.any((m) => m.role == PromptRole.system);
    if (!hasSystemMessage && config.systemPrompt != null) {
      apiMessages.insert(0, {'role': 'system', 'content': config.systemPrompt});
    }

    final body = <String, dynamic>{
      'model': config.model,
      'messages': apiMessages,
      'stream': stream,
    };

    final includeUsage = config.getProviderOption<bool>('includeUsage') ??
        config.getProviderOption<bool>('include_usage');
    if (stream && includeUsage == true) {
      body['stream_options'] = const {'include_usage': true};
    }

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
    final toolsJson = <Map<String, dynamic>>[
      ..._convertProviderToolsForChatCompletions(
        providerId: providerId,
        providerTools: providerTools,
      ),
      ...?effectiveTools?.map(_convertToolToChatCompletionsFormat),
    ];

    if (toolsJson.isNotEmpty) {
      body['tools'] = toolsJson;

      final effectiveToolChoice = config.toolChoice;
      // Provider-native tools may not support `tool_choice`. Only emit tool
      // choice when function tools are present.
      if (effectiveToolChoice != null &&
          effectiveTools != null &&
          effectiveTools.isNotEmpty) {
        body['tool_choice'] = _convertToolChoice(effectiveToolChoice);
      }
    }

    if (config.jsonSchema != null) {
      final supportsStructuredOutputs =
          config.getProviderOption<bool>('supportsStructuredOutputs') ?? true;

      final structuredOutputs = isGroq
          ? (config.getProviderOption<bool>('structuredOutputs') ?? true)
          : true;

      if ((!structuredOutputs && isGroq) || !supportsStructuredOutputs) {
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
      final returnCitations =
          config.getProviderOption<bool>('returnCitations') ??
              config.getProviderOption<bool>('return_citations');

      Map<String, dynamic>? effectiveSearch;
      if (searchParameters != null) {
        effectiveSearch = Map<String, dynamic>.from(searchParameters);
      } else if (liveSearchEnabled) {
        // AI SDK parity: default to web + x sources.
        effectiveSearch = {
          'mode': 'auto',
          'sources': const [
            {'type': 'web'},
            {'type': 'x'},
          ],
        };
      }

      if (effectiveSearch != null) {
        // AI SDK parity: `return_citations` belongs under `search_parameters`.
        if (returnCitations == true) {
          effectiveSearch['return_citations'] = true;
        }

        // Best-effort compatibility for camelCase keys.
        if (effectiveSearch['return_citations'] == null &&
            effectiveSearch['returnCitations'] is bool) {
          effectiveSearch['return_citations'] =
              effectiveSearch['returnCitations'];
        }

        body['search_parameters'] = effectiveSearch;
      }
    }

    final extraBodyFromConfig = config.extraBody;
    if (extraBodyFromConfig != null && extraBodyFromConfig.isNotEmpty) {
      body.addAll(extraBodyFromConfig);
    }

    return body;
  }

  Map<String, dynamic> buildChatCompletionsRequestBody(
    OpenAIClient client, {
    required List<ChatMessage> messages,
    required List<Tool>? tools,
    List<ProviderTool>? providerTools,
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

    final includeUsage = config.getProviderOption<bool>('includeUsage') ??
        config.getProviderOption<bool>('include_usage');
    if (stream && includeUsage == true) {
      body['stream_options'] = const {'include_usage': true};
    }

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
    final toolsJson = <Map<String, dynamic>>[
      ..._convertProviderToolsForChatCompletions(
        providerId: providerId,
        providerTools: providerTools,
      ),
      ...?effectiveTools?.map(_convertToolToChatCompletionsFormat),
    ];

    if (toolsJson.isNotEmpty) {
      body['tools'] = toolsJson;

      final effectiveToolChoice = config.toolChoice;
      if (effectiveToolChoice != null &&
          effectiveTools != null &&
          effectiveTools.isNotEmpty) {
        body['tool_choice'] = _convertToolChoice(effectiveToolChoice);
      }
    }

    if (config.jsonSchema != null) {
      final supportsStructuredOutputs =
          config.getProviderOption<bool>('supportsStructuredOutputs') ?? true;

      final structuredOutputs = isGroq
          ? (config.getProviderOption<bool>('structuredOutputs') ?? true)
          : true;

      if ((!structuredOutputs && isGroq) || !supportsStructuredOutputs) {
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
      final returnCitations =
          config.getProviderOption<bool>('returnCitations') ??
              config.getProviderOption<bool>('return_citations');

      Map<String, dynamic>? effectiveSearch;
      if (searchParameters != null) {
        effectiveSearch = Map<String, dynamic>.from(searchParameters);
      } else if (liveSearchEnabled) {
        // AI SDK parity: default to web + x sources.
        effectiveSearch = {
          'mode': 'auto',
          'sources': const [
            {'type': 'web'},
            {'type': 'x'},
          ],
        };
      }

      if (effectiveSearch != null) {
        // AI SDK parity: `return_citations` belongs under `search_parameters`.
        if (returnCitations == true) {
          effectiveSearch['return_citations'] = true;
        }

        // Best-effort compatibility for camelCase keys.
        if (effectiveSearch['return_citations'] == null &&
            effectiveSearch['returnCitations'] is bool) {
          effectiveSearch['return_citations'] =
              effectiveSearch['returnCitations'];
        }

        body['search_parameters'] = effectiveSearch;
      }
    }

    final extraBodyFromConfig = config.extraBody;
    if (extraBodyFromConfig != null && extraBodyFromConfig.isNotEmpty) {
      body.addAll(extraBodyFromConfig);
    }

    return body;
  }

  List<Map<String, dynamic>> _convertProviderToolsForChatCompletions({
    required String providerId,
    List<ProviderTool>? providerTools,
  }) {
    final tools = providerTools;
    if (tools == null || tools.isEmpty) return const [];

    final isGroq = providerId == 'groq' || providerId == 'groq-openai';
    if (!isGroq) return const [];

    final out = <Map<String, dynamic>>[];
    var hasBrowserSearch = false;
    for (final tool in tools) {
      final id = tool.id.trim();
      if (id.isEmpty) continue;

      final enabled = tool.args['enabled'];
      if (enabled is bool && enabled == false) continue;

      if (id == 'groq.browser_search') {
        if (!hasBrowserSearch) {
          out.add(const {'type': 'browser_search'});
          hasBrowserSearch = true;
        }
      }
    }

    return out;
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
