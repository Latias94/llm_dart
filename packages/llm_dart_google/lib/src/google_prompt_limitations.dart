import 'package:llm_dart_provider/llm_dart_provider.dart';

UnsupportedError unsupportedGooglePromptPart({
  required String role,
  required PromptPart part,
}) {
  return UnsupportedError(
    'Google $role prompt messages do not support ${part.runtimeType} parts.',
  );
}

UnsupportedError unsupportedGooglePromptMessage(PromptMessage message) {
  return UnsupportedError(
    'Google prompt projection does not support ${message.runtimeType} messages.',
  );
}

UnsupportedError missingGoogleUserBinaryData() {
  return UnsupportedError(
    'Google user binary prompt parts require in-memory bytes, text, a URI, '
    'or a Google provider reference.',
  );
}

UnsupportedError unsupportedGoogleAssistantFileData() {
  return UnsupportedError(
    'Google assistant file prompt parts require in-memory bytes. '
    'Assistant-side file text, URIs, and provider references are not supported.',
  );
}
