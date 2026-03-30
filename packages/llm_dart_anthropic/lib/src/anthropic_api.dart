import 'dart:convert';

const String anthropicDefaultBaseUrl = 'https://api.anthropic.com/v1';
const String anthropicDefaultVersion = '2023-06-01';

Uri resolveAnthropicUri(String baseUrl, String path) {
  final normalizedBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
  return Uri.parse(normalizedBaseUrl).resolve(path);
}

Map<String, String> buildAnthropicHeaders({
  required String apiKey,
  required String anthropicVersion,
  Map<String, String> defaultHeaders = const {},
  Map<String, String>? extraHeaders,
  Iterable<String> betaFeatures = const [],
  String? accept,
  bool includeJsonContentType = false,
}) {
  final mergedHeaders = <String, String>{
    'x-api-key': apiKey,
    'anthropic-version': anthropicVersion,
    if (includeJsonContentType) 'content-type': 'application/json',
    if (accept != null) 'accept': accept,
    ...withoutAnthropicBetaHeader(defaultHeaders),
    if (extraHeaders != null) ...withoutAnthropicBetaHeader(extraHeaders),
  };

  final mergedBetas = <String>{
    for (final value in betaFeatures) ...parseAnthropicBetaHeaderValue(value),
    ...parseAnthropicBetaHeaderValue(defaultHeaders['anthropic-beta']),
    ...parseAnthropicBetaHeaderValue(extraHeaders?['anthropic-beta']),
  }.toList(growable: false)
    ..sort();

  if (mergedBetas.isNotEmpty) {
    mergedHeaders['anthropic-beta'] = mergedBetas.join(',');
  }

  return mergedHeaders;
}

Iterable<String> parseAnthropicBetaHeaderValue(String? value) sync* {
  if (value == null) {
    return;
  }

  for (final segment in value.split(',')) {
    final normalized = segment.trim().toLowerCase();
    if (normalized.isNotEmpty) {
      yield normalized;
    }
  }
}

Map<String, String> withoutAnthropicBetaHeader(Map<String, String> headers) {
  final filtered = <String, String>{};
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == 'anthropic-beta') {
      continue;
    }

    filtered[entry.key] = entry.value;
  }
  return filtered;
}

Map<String, Object?> decodeAnthropicJsonObject(Object? body) {
  if (body is Map<String, Object?>) {
    return body;
  }

  if (body is Map) {
    return Map<String, Object?>.from(body);
  }

  if (body is String) {
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      return Map<String, Object?>.from(decoded);
    }
  }

  throw StateError(
    'Expected an Anthropic JSON object response but received ${body.runtimeType}.',
  );
}
