import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_options.dart';
import 'anthropic_prompt_blocks.dart';
import 'anthropic_request_json.dart';
import 'anthropic_tool_configuration.dart';

const int _defaultMaxTokens = 1024;
const int _defaultThinkingBudgetTokens = 1024;
const String _interleavedThinkingBeta = 'interleaved-thinking-2025-05-14';
const String _mcpClientBeta = 'mcp-client-2025-04-04';
const String _extendedCacheTtlBeta = 'extended-cache-ttl-2025-04-11';
const String _filesApiBeta = 'files-api-2025-04-14';

final class AnthropicEncodedMessagesRequest {
  final Map<String, Object?> body;
  final List<String> betaFeatures;
  final List<ModelWarning> warnings;

  AnthropicEncodedMessagesRequest({
    required Map<String, Object?> body,
    List<String> betaFeatures = const [],
    List<ModelWarning> warnings = const [],
  })  : body = Map.unmodifiable(body),
        betaFeatures = List.unmodifiable(betaFeatures),
        warnings = List.unmodifiable(warnings);
}

final class AnthropicRequestOptionsEncoder {
  const AnthropicRequestOptionsEncoder();

  AnthropicEncodedMessagesRequest buildMessagesRequest({
    required String modelId,
    required AnthropicEncodedPrompt prompt,
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required GenerateTextOptions options,
    required AnthropicChatModelSettings settings,
    required AnthropicGenerateTextOptions providerOptions,
    required bool stream,
    required List<ModelWarning> warnings,
  }) {
    final betaFeatures = <String>{};
    final sharedReasoning = options.reasoning;
    final sharedRequestsThinking = sharedReasoning != null &&
        sharedReasoning.enabled != false &&
        (sharedReasoning.enabled == true ||
            sharedReasoning.budgetTokens != null ||
            sharedReasoning.effort != null);
    final extendedThinking =
        providerOptions.extendedThinking ?? sharedRequestsThinking;
    final interleavedThinking = providerOptions.interleavedThinking == true;
    final mcpServers = providerOptions.mcpServers;
    final nativeTools = providerOptions.tools ?? settings.tools;
    final deferredToolNames =
        providerOptions.deferredToolNames ?? settings.deferredToolNames;
    var maxTokens = options.maxOutputTokens ?? _defaultMaxTokens;
    final temperature = _normalizeTemperature(
      options.temperature,
      warnings: warnings,
    );
    double? topP = options.topP;
    int? topK = options.topK;
    Map<String, Object?>? thinking;

    if (sharedReasoning?.effort != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'options.reasoning.effort',
          message:
              'Anthropic extended thinking uses a token budget; shared reasoning.effort is ignored.',
        ),
      );
    }

    if (sharedReasoning?.enabled == false &&
        (sharedReasoning?.budgetTokens != null ||
            sharedReasoning?.effort != null)) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'options.reasoning',
          message:
              'options.reasoning.enabled=false disables shared Anthropic thinking; budgetTokens and effort are ignored.',
        ),
      );
    }

    if (providerOptions.thinkingBudgetTokens != null && !extendedThinking) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'thinkingBudgetTokens',
          message:
              'thinkingBudgetTokens is ignored when extendedThinking is not enabled.',
        ),
      );
    }

    if (extendedThinking) {
      var thinkingBudget = providerOptions.thinkingBudgetTokens ??
          sharedReasoning?.budgetTokens ??
          _defaultThinkingBudgetTokens;
      if (providerOptions.thinkingBudgetTokens != null &&
          sharedReasoning?.budgetTokens != null) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.compatibility,
            field: 'options.reasoning.budgetTokens',
            message:
                'Anthropic providerOptions.thinkingBudgetTokens overrides shared options.reasoning.budgetTokens.',
          ),
        );
      } else if (providerOptions.thinkingBudgetTokens == null &&
          sharedReasoning?.budgetTokens == null) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.compatibility,
            field: 'thinkingBudgetTokens',
            message:
                'thinkingBudgetTokens is required when extendedThinking is enabled. Using the default budget of 1024 tokens.',
          ),
        );
      } else if (thinkingBudget < _defaultThinkingBudgetTokens) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.compatibility,
            field: 'thinkingBudgetTokens',
            message:
                'Anthropic extended thinking requires a minimum budget of 1024 tokens. The budget has been raised to 1024.',
          ),
        );
        thinkingBudget = _defaultThinkingBudgetTokens;
      }

      if (temperature != null) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'temperature',
            message: 'temperature is not supported when thinking is enabled.',
          ),
        );
      }

      if (topP != null) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'topP',
            message: 'topP is not supported when thinking is enabled.',
          ),
        );
        topP = null;
      }

      if (topK != null) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'topK',
            message: 'topK is not supported when thinking is enabled.',
          ),
        );
        topK = null;
      }

      maxTokens += thinkingBudget;
      thinking = {
        'type': 'enabled',
        'budget_tokens': thinkingBudget,
      };
    } else if (temperature != null && topP != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'topP',
          message: 'topP is ignored when temperature is set for Anthropic.',
        ),
      );
      topP = null;
    }

    if (interleavedThinking) {
      if (!extendedThinking) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.compatibility,
            field: 'interleavedThinking',
            message:
                'interleavedThinking requires extendedThinking to be enabled. The beta header has not been added.',
          ),
        );
      } else {
        betaFeatures.add(_interleavedThinkingBeta);
      }
    }

    validateAnthropicThinkingCompatibleToolChoice(
      extendedThinking: extendedThinking,
      toolChoice: toolChoice,
    );

    final toolConfiguration = resolveAnthropicToolConfiguration(
      tools: tools,
      nativeTools: nativeTools,
      toolChoice: toolChoice,
      deferredToolNames: deferredToolNames,
      toolsCacheControl: providerOptions.toolsCacheControl,
      warnings: warnings,
    );

    final body = <String, Object?>{
      'model': modelId,
      'messages': prompt.messages,
      'max_tokens': maxTokens,
      'stream': stream,
      if (prompt.system.isNotEmpty) 'system': prompt.system,
      if (!extendedThinking && temperature != null) 'temperature': temperature,
      if (options.stopSequences != null && options.stopSequences!.isNotEmpty)
        'stop_sequences': options.stopSequences,
      if (topP != null) 'top_p': topP,
      if (topK != null) 'top_k': topK,
      if (thinking != null) 'thinking': thinking,
      if (providerOptions.serviceTier != null)
        'service_tier': providerOptions.serviceTier,
      if (providerOptions.metadata != null &&
          providerOptions.metadata!.isNotEmpty)
        'metadata': normalizeAnthropicJsonObject(
          providerOptions.metadata!,
          path: 'metadata',
        ),
      if (providerOptions.container != null)
        'container': providerOptions.container,
      if (mcpServers != null && mcpServers.isNotEmpty)
        'mcp_servers': mcpServers.map((server) => server.toJson()).toList(),
      if (toolConfiguration.tools != null) 'tools': toolConfiguration.tools,
      if (toolConfiguration.toolChoice != null)
        'tool_choice': toolConfiguration.toolChoice,
    };

    if (mcpServers != null && mcpServers.isNotEmpty) {
      betaFeatures.add(_mcpClientBeta);
    }

    if (containsAnthropicCacheControl(body)) {
      betaFeatures.add(_extendedCacheTtlBeta);
    }

    if (containsAnthropicFileSource(body)) {
      betaFeatures.add(_filesApiBeta);
    }

    final sortedBetas = betaFeatures.toList(growable: false)..sort();

    return AnthropicEncodedMessagesRequest(
      body: body,
      betaFeatures: sortedBetas,
      warnings: warnings,
    );
  }

  AnthropicEncodedMessagesRequest buildTokenCountRequest({
    required Map<String, Object?> baseBody,
    required List<String> baseBetaFeatures,
    required List<ModelWarning> baseWarnings,
    required AnthropicGenerateTextOptions providerOptions,
  }) {
    final warnings = <ModelWarning>[
      ...baseWarnings,
    ];

    if (providerOptions.serviceTier != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'serviceTier',
          message:
              'Anthropic token counting ignores serviceTier. The value has not been sent.',
        ),
      );
    }

    if (providerOptions.metadata != null &&
        providerOptions.metadata!.isNotEmpty) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'metadata',
          message:
              'Anthropic token counting ignores metadata. The value has not been sent.',
        ),
      );
    }

    if (providerOptions.container != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'container',
          message:
              'Anthropic token counting ignores container. The value has not been sent.',
        ),
      );
    }

    final body = <String, Object?>{
      'model': baseBody['model'],
      'messages': baseBody['messages'],
      if (baseBody['system'] case final system?) 'system': system,
      if (baseBody['thinking'] case final thinking?) 'thinking': thinking,
      if (baseBody['mcp_servers'] case final mcpServers?)
        'mcp_servers': mcpServers,
      if (baseBody['tools'] case final encodedTools?) 'tools': encodedTools,
      if (baseBody['tool_choice'] case final encodedToolChoice?)
        'tool_choice': encodedToolChoice,
    };

    return AnthropicEncodedMessagesRequest(
      body: body,
      betaFeatures: baseBetaFeatures,
      warnings: warnings,
    );
  }

  double? _normalizeTemperature(
    double? value, {
    required List<ModelWarning> warnings,
  }) {
    if (value == null) {
      return null;
    }

    if (value > 1) {
      warnings.add(
        ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'temperature',
          message:
              '$value exceeds Anthropic maximum temperature of 1.0. It has been clamped to 1.0.',
        ),
      );
      return 1;
    }

    if (value < 0) {
      warnings.add(
        ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'temperature',
          message:
              '$value is below Anthropic minimum temperature of 0. It has been clamped to 0.',
        ),
      );
      return 0;
    }

    return value;
  }
}
