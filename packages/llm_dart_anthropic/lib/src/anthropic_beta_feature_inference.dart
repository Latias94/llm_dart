import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_beta_features.dart';
import 'anthropic_options.dart';

final class AnthropicBetaFeatureInference {
  const AnthropicBetaFeatureInference();

  void collectThinkingFeatures({
    required AnthropicGenerateTextOptions providerOptions,
    required bool extendedThinking,
    required Set<String> betaFeatures,
    required List<ModelWarning> warnings,
  }) {
    if (providerOptions.interleavedThinking != true) {
      return;
    }

    if (!extendedThinking) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'interleavedThinking',
          message:
              'interleavedThinking requires extendedThinking to be enabled. The beta header has not been added.',
        ),
      );
      return;
    }

    betaFeatures.add(anthropicInterleavedThinkingBeta);
  }

  void collectProviderOptionFeatures({
    required AnthropicGenerateTextOptions providerOptions,
    required Set<String> betaFeatures,
  }) {
    final mcpServers = providerOptions.mcpServers;
    if (mcpServers != null && mcpServers.isNotEmpty) {
      betaFeatures.add(anthropicMcpClientBeta);
    }
  }

  List<String> sorted(Set<String> betaFeatures) {
    return sortedAnthropicBetaFeatures(betaFeatures);
  }
}
