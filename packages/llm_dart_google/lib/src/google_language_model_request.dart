import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_generate_content_codec.dart';
import 'google_language_model_support.dart';
import 'google_options.dart';

GoogleGenerateContentRequest encodeGoogleLanguageModelRequest({
  required String modelId,
  required GenerateTextRequest request,
  required GoogleChatModelSettings settings,
  GoogleGenerateContentCodec requestCodec = const GoogleGenerateContentCodec(),
}) {
  return requestCodec.encodeRequest(
    modelId: modelId,
    prompt: request.prompt,
    tools: request.tools,
    toolChoice: request.toolChoice,
    options: request.options,
    settings: settings,
    providerOptions: resolveGoogleProviderOptions(request),
  );
}
