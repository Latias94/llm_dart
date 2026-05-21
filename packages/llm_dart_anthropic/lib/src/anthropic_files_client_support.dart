import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'anthropic_file_response.dart';
import 'anthropic_file_types.dart';

Future<T> sendAnthropicFilesJsonModel<T>({
  required TransportClient transport,
  required TransportRequest request,
  required T Function(Object? body) decode,
}) async {
  return sendProviderModelRequest(
    transport: transport,
    request: request,
    decode: (body, _) => decode(body),
  );
}

Future<AnthropicFileDownload> sendAnthropicFileDownload({
  required TransportClient transport,
  required TransportRequest request,
  required String fileId,
}) async {
  return sendProviderModelRequest(
    transport: transport,
    request: request,
    decode: (body, headers) => decodeAnthropicFileDownload(
      fileId: fileId,
      body: body,
      headers: headers,
    ),
  );
}

Future<void> sendAnthropicFilesDelete({
  required TransportClient transport,
  required TransportRequest request,
}) async {
  await sendProviderModelRequest(
    transport: transport,
    request: request,
    decode: (_, __) {},
  );
}
