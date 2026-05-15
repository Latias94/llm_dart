import 'package:llm_dart_provider/llm_dart_provider.dart';

Map<String, Object?> normalizeAnthropicJsonObject(
  Object? value, {
  required String path,
}) {
  final normalized = normalizeJsonValue(value, path: path);
  if (normalized case final Map<String, Object?> map) {
    return map;
  }

  throw UnsupportedError('Expected a JSON object at $path.');
}

bool containsAnthropicCacheControl(Object? value) {
  if (value is Map) {
    if (value.containsKey('cache_control')) {
      return true;
    }

    for (final nestedValue in value.values) {
      if (containsAnthropicCacheControl(nestedValue)) {
        return true;
      }
    }
    return false;
  }

  if (value is List) {
    return value.any(containsAnthropicCacheControl);
  }

  return false;
}

bool containsAnthropicFileSource(Object? value) {
  if (value is Map) {
    if (value['type'] == 'file' && value.containsKey('file_id')) {
      return true;
    }

    for (final nestedValue in value.values) {
      if (containsAnthropicFileSource(nestedValue)) {
        return true;
      }
    }
    return false;
  }

  if (value is List) {
    return value.any(containsAnthropicFileSource);
  }

  return false;
}
