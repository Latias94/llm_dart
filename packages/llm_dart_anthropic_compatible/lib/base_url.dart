/// Anthropic-compatible base URL helpers.
library;

import 'package:llm_dart_provider_utils/utils/config_utils.dart';

/// Normalize an Anthropic-compatible base URL to ensure it ends with `/v1/`.
///
/// Many compatibility docs use `.../anthropic` (without `/v1`). The protocol
/// implementation uses endpoint paths like `messages`, so we normalize to a
/// `/v1/` base.
String normalizeAnthropicCompatibleBaseUrl(String baseUrl) {
  final normalized = ConfigUtils.normalizeBaseUrl(baseUrl);
  if (normalized.endsWith('/anthropic/')) {
    return '${normalized}v1/';
  }
  return normalized;
}
