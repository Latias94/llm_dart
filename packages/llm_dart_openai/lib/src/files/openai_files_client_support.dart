import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
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
  return sendProviderModelRequest(
    transport: transport,
    request: request,
    decode: (body, _) => decode(
      decodeOpenAIJsonObject(body, responseName: responseName),
    ),
  );
}

Future<OpenAIFileDownload> sendOpenAIFileDownload({
  required TransportClient transport,
  required TransportRequest request,
  required String fileId,
}) async {
  return sendProviderModelRequest(
    transport: transport,
    request: request,
    decode: (body, headers) => OpenAIFileDownload(
      fileId: fileId,
      bytes: openAIRequiredBytes(
        body,
        path: 'file_download.body',
        sourceName: 'OpenAI file download',
      ),
      headers: headers,
    ),
  );
}
