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
