library;

import 'runtime_user_agent_stub.dart'
    if (dart.library.io) 'runtime_user_agent_io.dart'
    if (dart.library.html) 'runtime_user_agent_web.dart';

/// Version string used for default User-Agent headers across the workspace.
///
/// This file is updated by `tool/bump_version.dart`.
const String llmDartVersion = '0.11.0-alpha.1';

String defaultUserAgentForProvider(String providerId) {
  final id = providerId.trim();
  if (id.isEmpty) return 'llm_dart/unknown/$llmDartVersion';
  return 'llm_dart/${id.toLowerCase()}/$llmDartVersion';
}

String runtimeUserAgent() => getRuntimeEnvironmentUserAgent();

List<String> defaultUserAgentSuffixPartsForProvider(String providerId) => [
      defaultUserAgentForProvider(providerId),
      runtimeUserAgent(),
    ];

String defaultUserAgentHeaderValueForProvider(String providerId) =>
    defaultUserAgentSuffixPartsForProvider(providerId).join(' ');

bool hasHeaderIgnoreCase(Map<String, String> headers, String headerName) {
  final needle = headerName.toLowerCase();
  return headers.keys.any((k) => k.toLowerCase() == needle);
}

String? getHeaderValueIgnoreCase(
    Map<String, String> headers, String headerName) {
  final needle = headerName.toLowerCase();
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == needle) return entry.value;
  }
  return null;
}

Map<String, String> withUserAgentSuffix(
  Map<String, String> headers,
  List<String> suffixParts,
) {
  final updated = <String, String>{...headers};

  String? existing;
  final keysToRemove = <String>[];
  for (final entry in updated.entries) {
    if (entry.key.toLowerCase() == 'user-agent') {
      existing = entry.value;
      keysToRemove.add(entry.key);
    }
  }
  for (final k in keysToRemove) {
    updated.remove(k);
  }

  final ua = <String>[
    if (existing != null && existing.trim().isNotEmpty) existing.trim(),
    ...suffixParts.where((p) => p.trim().isNotEmpty).map((p) => p.trim()),
  ].join(' ');

  if (ua.isNotEmpty) {
    updated['User-Agent'] = ua;
  }

  return updated;
}
