import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'ollama_api.dart';
import 'ollama_chat_request_codec.dart';
import 'ollama_chat_response_codec.dart';

OllamaChatResponseCodec buildOllamaChatResponseCodec({
  required String modelId,
}) {
  return OllamaChatResponseCodec(modelId: modelId);
}

GenerateTextResult decodeOllamaChatGenerateResponse({
  required Object? body,
  required OllamaChatResponseCodec responseCodec,
  required OllamaPreparedChatRequest preparedRequest,
}) {
  return responseCodec.decodeGenerateResponse(
    decodeOllamaJsonObject(
      body,
      responseName: 'chat response',
    ),
    warnings: preparedRequest.warnings,
  );
}
