import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_options.dart';
import 'anthropic_request_json.dart';

const String anthropicInterleavedThinkingBeta =
    'interleaved-thinking-2025-05-14';
const String anthropicMcpClientBeta = 'mcp-client-2025-04-04';
const String anthropicExtendedCacheTtlBeta = 'extended-cache-ttl-2025-04-11';
const String anthropicFilesApiBeta = 'files-api-2025-04-14';

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

  void collectBodyFeatures({
    required Map<String, Object?> body,
    required AnthropicGenerateTextOptions providerOptions,
    required Set<String> betaFeatures,
  }) {
    final mcpServers = providerOptions.mcpServers;
    if (mcpServers != null && mcpServers.isNotEmpty) {
      betaFeatures.add(anthropicMcpClientBeta);
    }

    if (containsAnthropicCacheControl(body)) {
      betaFeatures.add(anthropicExtendedCacheTtlBeta);
    }

    if (containsAnthropicFileSource(body)) {
      betaFeatures.add(anthropicFilesApiBeta);
    }
  }

  List<String> sorted(Set<String> betaFeatures) {
    return betaFeatures.toList(growable: false)..sort();
  }
}
