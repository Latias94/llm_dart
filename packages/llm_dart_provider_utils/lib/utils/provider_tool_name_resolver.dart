import 'package:llm_dart_core/llm_dart_core.dart';

/// Resolve a stable tool name for provider-native tools using [ProviderTool.name]
/// when available.
///
/// Providers often emit protocol-specific tool types (e.g. `web_search_20250305`,
/// `web_search_call`). For AI SDK parity, we prefer a stable, user-facing name
/// configured in [LLMConfig.providerTools].
String resolveProviderToolName({
  required String providerId,
  required String rawToolName,
  List<ProviderTool>? providerTools,
}) {
  final trimmed = rawToolName.trim();
  if (trimmed.isEmpty) return rawToolName;

  final tools = providerTools;
  if (tools == null || tools.isEmpty) return trimmed;

  final exactId = '$providerId.$trimmed';
  for (final t in tools) {
    if (t.id != exactId) continue;
    final name = t.name;
    if (name != null && name.trim().isNotEmpty) return name;
  }

  final basePrefix = exactId;
  for (final t in tools) {
    final name = t.name;
    if (name == null || name.trim().isEmpty) continue;

    final id = t.id;
    if (id == basePrefix ||
        id.startsWith('$basePrefix.') ||
        id.startsWith('${basePrefix}_')) {
      return name;
    }
  }

  return trimmed;
}
