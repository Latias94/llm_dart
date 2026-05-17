import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_api.dart';
import 'anthropic_result_codec.dart';

GenerateTextResult decodeAnthropicLanguageModelGenerateResponse({
  required Object? body,
  required List<ModelWarning> warnings,
  AnthropicMessagesResultCodec resultCodec =
      const AnthropicMessagesResultCodec(),
}) {
  return resultCodec.decodeResponse(
    decodeAnthropicJsonObject(body),
    warnings: warnings,
  );
}
