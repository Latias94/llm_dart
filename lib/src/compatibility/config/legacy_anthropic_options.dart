import '../../../providers/anthropic/mcp_models.dart';
import 'legacy_config_keys.dart';
import 'legacy_provider_options.dart';

final class LegacyAnthropicOptions {
  final bool reasoning;
  final int? thinkingBudgetTokens;
  final bool interleavedThinking;
  final Map<String, dynamic>? metadata;
  final String? container;
  final List<AnthropicMCPServer>? mcpServers;

  const LegacyAnthropicOptions({
    required this.reasoning,
    required this.thinkingBudgetTokens,
    required this.interleavedThinking,
    required this.metadata,
    required this.container,
    required this.mcpServers,
  });
}

LegacyAnthropicOptions legacyAnthropicOptions(
  LegacyProviderOptionView options,
) {
  return LegacyAnthropicOptions(
    reasoning:
        options.getWithFlatFallback<bool>(LegacyExtensionKeys.reasoning) ??
            false,
    thinkingBudgetTokens: options.getWithFlatFallback<int>(
      LegacyExtensionKeys.thinkingBudgetTokens,
    ),
    interleavedThinking: options.getWithFlatFallback<bool>(
          LegacyExtensionKeys.interleavedThinking,
        ) ??
        false,
    metadata: options.getWithFlatFallback<Map<String, dynamic>>(
      LegacyExtensionKeys.metadata,
    ),
    container:
        options.getWithFlatFallback<String>(LegacyExtensionKeys.container),
    mcpServers: options.getWithFlatFallback<List<AnthropicMCPServer>>(
      LegacyExtensionKeys.mcpServers,
    ),
  );
}
