import 'package:llm_dart_core/llm_dart_core.dart';

String _baseProviderId(String providerId) {
  final idx = providerId.indexOf('.');
  if (idx <= 0) return providerId;
  return providerId.substring(0, idx);
}

String _normalizeRawToolName({
  required String providerId,
  required String rawToolName,
}) {
  final base = _baseProviderId(providerId);

  // xAI Responses API uses tool type `code_interpreter` for the `code_execution`
  // tool. Vercel AI SDK normalizes this to `code_execution`.
  if (base == 'xai' && rawToolName == 'code_interpreter') {
    return 'code_execution';
  }

  return rawToolName;
}

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

  ProviderTool? tryFind(String pid) {
    final exactId = '$pid.$trimmed';
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

  final direct = tryFind(providerId);
  if (direct != null) return direct;

  final base = _baseProviderId(providerId);
  if (base != providerId) {
    final aliased = tryFind(base);
    if (aliased != null) return aliased;
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

  final normalizedRawToolName = _normalizeRawToolName(
    providerId: providerId,
    rawToolName: trimmed,
  );

  final tool = findProviderToolByRawName(
    providerId: providerId,
    rawToolName: normalizedRawToolName,
    providerTools: providerTools,
  );
  final name = tool?.name;
  if (name != null && name.trim().isNotEmpty) return name;

  return normalizedRawToolName;
}
