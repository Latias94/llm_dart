import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_json_support.dart';
import 'google_result_codec.dart';

GenerateTextResult decodeGoogleLanguageModelGenerateResponse({
  required Object? body,
  required List<ModelWarning> warnings,
  GoogleGenerateContentResultCodec resultCodec =
      const GoogleGenerateContentResultCodec(),
}) {
  return resultCodec.decodeResponse(
    decodeGoogleJsonObject(body),
    warnings: warnings,
  );
}
