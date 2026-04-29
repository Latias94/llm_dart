import 'dart:convert';

import 'ollama_options.dart';

String normalizeOllamaBaseUrl(String? baseUrl) {
  final normalized =
      (baseUrl == null || baseUrl.isEmpty) ? ollamaDefaultBaseUrl : baseUrl;
  return normalized.endsWith('/')
      ? normalized.substring(0, normalized.length - 1)
      : normalized;
}

String? normalizeOllamaApiKey(String? apiKey) {
  if (apiKey == null || apiKey.isEmpty) {
    return null;
  }

  return apiKey;
}

Uri resolveOllamaUri(String baseUrl, String path) {
  final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
  return Uri.parse('$baseUrl/$normalizedPath');
}

Map<String, String> buildOllamaHeaders({
  String? apiKey,
  String? contentType,
  String? accept = 'application/json',
  Map<String, String> headers = const {},
}) {
  return {
    if (contentType != null) 'content-type': contentType,
    if (accept != null) 'accept': accept,
    if (apiKey case final auth?) 'authorization': 'Bearer $auth',
    ...headers,
  };
}

Map<String, Object?> decodeOllamaJsonObject(
  Object? body, {
  required String responseName,
}) {
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
    'Expected an Ollama $responseName JSON object but received ${body.runtimeType}.',
  );
}
