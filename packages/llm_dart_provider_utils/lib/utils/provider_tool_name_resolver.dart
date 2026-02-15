import 'package:llm_dart_core/llm_dart_core.dart';

/// Find a matching [ProviderTool] for a provider-native tool name.
///
/// Matching rules (best-effort, deterministic):
/// 1. Exact id match: `[providerId].[rawToolName]`
/// 2. Prefix id match: ids that start with `[providerId].[rawToolName]_` or
///    `[providerId].[rawToolName].` (e.g. `openai.web_search_preview`,
///    `anthropic.web_search_20250305`)
ProviderTool? findProviderToolByRawName({
  required String providerId,
  required String rawToolName,
  List<ProviderTool>? providerTools,
}) {
  final trimmed = rawToolName.trim();
  if (trimmed.isEmpty) return null;

  final tools = providerTools;
  if (tools == null || tools.isEmpty) return null;

  final exactId = '$providerId.$trimmed';
  for (final t in tools) {
    if (t.id == exactId) return t;
  }

  for (final t in tools) {
    final id = t.id;
    if (id.startsWith('${exactId}_') || id.startsWith('$exactId.')) {
      return t;
    }
  }

  return null;
}

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

  final tool = findProviderToolByRawName(
    providerId: providerId,
    rawToolName: trimmed,
    providerTools: providerTools,
  );
  final name = tool?.name;
  if (name != null && name.trim().isNotEmpty) return name;

  return trimmed;
}
