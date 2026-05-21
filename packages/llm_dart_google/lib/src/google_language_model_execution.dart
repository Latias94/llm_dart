import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'google_language_model_stream.dart';

Stream<LanguageModelStreamEvent> sendGoogleLanguageModelStreamCall({
  required TransportClient transport,
  required TransportRequest request,
  required List<ModelWarning> warnings,
  required bool includeRawChunks,
}) {
  return sendProviderLanguageModelStreamRequest(
    transport: transport,
    request: request,
    warnings: warnings,
    includeRawChunks: includeRawChunks,
    decode: ({required stream, required includeRawChunks}) {
      return decodeGoogleLanguageModelStreamEvents(
        stream: stream,
        includeRawChunks: includeRawChunks,
      );
    },
  );
}
