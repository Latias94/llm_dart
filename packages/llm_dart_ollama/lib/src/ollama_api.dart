import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'ollama_api_options.dart';

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
  return JsonObjectResponseDecoder.decode(
    body,
    sourceName: 'Ollama $responseName',
  );
}
