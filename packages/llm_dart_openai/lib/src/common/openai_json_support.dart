import 'package:llm_dart_transport/llm_dart_transport.dart';

Map<String, Object?> decodeOpenAIJsonObject(
  Object? body, {
  String? responseName,
}) {
  final sourceName = responseName == null || responseName.isEmpty
      ? 'OpenAI'
      : 'OpenAI $responseName';
  return JsonObjectResponseDecoder.decode(
    body,
    sourceName: sourceName,
  );
}
