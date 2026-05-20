import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_json_support.dart';

Future<T> sendOpenAIFilesJsonModel<T>({
  required TransportClient transport,
  required TransportRequest request,
  required String responseName,
  required T Function(Map<String, Object?> json) decode,
}) async {
  final response = await transport.send(request);
  return decode(
    decodeOpenAIJsonObject(response.body, responseName: responseName),
  );
}
