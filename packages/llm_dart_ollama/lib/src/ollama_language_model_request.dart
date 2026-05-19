import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'ollama_chat_request_codec.dart';
import 'ollama_model_settings.dart';

OllamaChatModelSettings resolveOllamaChatModelSettings(
  ProviderModelOptions settings,
) {
  return resolveProviderModelOptions<OllamaChatModelSettings>(
    settings,
    parameterName: 'settings',
    expectedTypeName: 'OllamaChatModelSettings',
    usageContext: 'Ollama chat models',
  );
}

OllamaChatRequestCodec buildOllamaChatRequestCodec({
  required String modelId,
  required OllamaChatModelSettings settings,
}) {
  return OllamaChatRequestCodec(
    modelId: modelId,
    settings: settings,
  );
}

Future<OllamaPreparedChatRequest> prepareOllamaChatRequest({
  required OllamaChatRequestCodec requestCodec,
  required GenerateTextRequest request,
  required bool stream,
}) {
  return requestCodec.encode(
    request: request,
    stream: stream,
  );
}
