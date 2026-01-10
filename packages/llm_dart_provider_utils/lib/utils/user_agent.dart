library;

/// Version string used for default User-Agent headers across the workspace.
///
/// This file is updated by `tool/bump_version.dart`.
const String llmDartVersion = '0.11.0-alpha.1';

String defaultUserAgentForProvider(String providerId) {
  final id = providerId.trim();
  if (id.isEmpty) return 'llm_dart/unknown/$llmDartVersion';
  return 'llm_dart/${id.toLowerCase()}/$llmDartVersion';
}

bool hasHeaderIgnoreCase(Map<String, String> headers, String headerName) {
  final needle = headerName.toLowerCase();
  return headers.keys.any((k) => k.toLowerCase() == needle);
}
