import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_files_models.dart';
import '../common/openai_json_support.dart';
import '../common/openai_json_value.dart';

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

Future<OpenAIFileDownload> sendOpenAIFileDownload({
  required TransportClient transport,
  required TransportRequest request,
  required String fileId,
}) async {
  final response = await transport.send(request);
  return OpenAIFileDownload(
    fileId: fileId,
    bytes: openAIRequiredBytes(
      response.body,
      path: 'file_download.body',
      sourceName: 'OpenAI file download',
    ),
    headers: response.headers,
  );
}
