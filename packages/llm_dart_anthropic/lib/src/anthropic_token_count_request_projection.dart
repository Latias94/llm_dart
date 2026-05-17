import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_options.dart';

final class AnthropicTokenCountRequestProjection {
  final Map<String, Object?> body;
  final List<String> betaFeatures;
  final List<ModelWarning> warnings;

  AnthropicTokenCountRequestProjection({
    required Map<String, Object?> body,
    List<String> betaFeatures = const [],
    List<ModelWarning> warnings = const [],
  })  : body = Map.unmodifiable(body),
        betaFeatures = List.unmodifiable(betaFeatures),
        warnings = List.unmodifiable(warnings);
}

final class AnthropicTokenCountRequestProjector {
  const AnthropicTokenCountRequestProjector();

  AnthropicTokenCountRequestProjection project({
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

    return AnthropicTokenCountRequestProjection(
      body: {
        'model': baseBody['model'],
        'messages': baseBody['messages'],
        if (baseBody['system'] case final system?) 'system': system,
        if (baseBody['thinking'] case final thinking?) 'thinking': thinking,
        if (baseBody['mcp_servers'] case final mcpServers?)
          'mcp_servers': mcpServers,
        if (baseBody['tools'] case final encodedTools?) 'tools': encodedTools,
        if (baseBody['tool_choice'] case final encodedToolChoice?)
          'tool_choice': encodedToolChoice,
      },
      betaFeatures: baseBetaFeatures,
      warnings: warnings,
    );
  }
}
