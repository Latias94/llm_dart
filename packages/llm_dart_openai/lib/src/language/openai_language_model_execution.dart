import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_language_model_prepared_call.dart';

Future<GenerateTextResult> sendOpenAILanguageModelGenerateCall({
  required TransportClient transport,
  required PreparedOpenAILanguageModelCall preparedCall,
}) {
  return sendProviderModelRequest(
    transport: transport,
    request: preparedCall.transportRequest,
    decode: (body, _) => preparedCall.routeAdapter.decodeGenerateResponse(
      body: body,
      warnings: preparedCall.warnings,
    ),
  );
}

Stream<LanguageModelStreamEvent> sendOpenAILanguageModelStreamCall({
  required TransportClient transport,
  required PreparedOpenAILanguageModelCall preparedCall,
  required bool includeRawChunks,
}) {
  return sendProviderLanguageModelStreamRequest(
    transport: transport,
    request: preparedCall.transportRequest,
    warnings: preparedCall.warnings,
    includeRawChunks: includeRawChunks,
    decode: ({required stream, required includeRawChunks}) {
      return preparedCall.routeAdapter.decodeStreamEvents(
        stream: stream,
        includeRawChunks: includeRawChunks,
      );
    },
  );
}
