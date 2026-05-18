import 'package:llm_dart_transport/llm_dart_transport.dart';

Map<String, Object?> decodeGoogleJsonObject(
  Object? body, {
  String? responseName,
}) {
  final sourceName = responseName == null || responseName.isEmpty
      ? 'Google'
      : 'Google $responseName';
  return JsonObjectResponseDecoder.decode(
    body,
    sourceName: sourceName,
  );
}
