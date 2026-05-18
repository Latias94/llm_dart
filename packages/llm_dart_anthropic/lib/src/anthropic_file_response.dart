import 'anthropic_api.dart';
import 'anthropic_file_types.dart';
import 'anthropic_value.dart';

AnthropicFileDescriptor decodeAnthropicFileDescriptorResponse(
  Object? body, {
  required String responseName,
}) {
  return AnthropicFileDescriptor.fromJson(
    decodeAnthropicJsonObject(
      body,
      responseName: responseName,
    ),
  );
}

AnthropicFileListResponse decodeAnthropicFileListResponse(Object? body) {
  return AnthropicFileListResponse.fromJson(
    decodeAnthropicJsonObject(
      body,
      responseName: 'file list',
    ),
  );
}

AnthropicFileDownload decodeAnthropicFileDownload({
  required String fileId,
  required Object? body,
  required Map<String, String> headers,
}) {
  return AnthropicFileDownload(
    fileId: fileId,
    bytes: anthropicRequiredBytes(
      body,
      path: 'download.body',
      sourceName: 'Anthropic file download',
    ),
    headers: headers,
  );
}
