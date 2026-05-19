import 'anthropic_beta_features.dart';

List<String> inferAnthropicPromptBetaFeatures({
  required List<Map<String, Object?>> system,
  required List<Map<String, Object?>> messages,
}) {
  final betaFeatures = <String>{};

  if (containsAnthropicCacheControl(system) ||
      containsAnthropicCacheControl(messages)) {
    betaFeatures.add(anthropicExtendedCacheTtlBeta);
  }

  if (containsAnthropicFileSource(system) ||
      containsAnthropicFileSource(messages)) {
    betaFeatures.add(anthropicFilesApiBeta);
  }

  return sortedAnthropicBetaFeatures(betaFeatures);
}
