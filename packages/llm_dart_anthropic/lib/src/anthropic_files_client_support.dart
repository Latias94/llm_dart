import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'anthropic_file_response.dart';
import 'anthropic_file_types.dart';

Future<T> sendAnthropicFilesJsonModel<T>({
  required TransportClient transport,
  required TransportRequest request,
  required T Function(Object? body) decode,
}) async {
  final response = await transport.send(request);
  return decode(response.body);
}

Future<AnthropicFileDownload> sendAnthropicFileDownload({
  required TransportClient transport,
  required TransportRequest request,
  required String fileId,
}) async {
  final response = await transport.send(request);
  return decodeAnthropicFileDownload(
    fileId: fileId,
    body: response.body,
    headers: response.headers,
  );
}

Future<void> sendAnthropicFilesDelete({
  required TransportClient transport,
  required TransportRequest request,
}) async {
  await transport.send(request);
}
