import 'package:llm_dart_provider/llm_dart_provider.dart';

UnsupportedError unsupportedOpenAIResponsesPromptPart({
  required String role,
  required PromptPart part,
}) {
  return UnsupportedError(
    'OpenAI Responses $role prompt messages do not support '
    '${part.runtimeType} parts.',
  );
}

UnsupportedError unsupportedOpenAIResponsesUserFileDataMediaType(
  String mediaType,
) {
  return UnsupportedError(
    'OpenAI Responses user file prompt parts do not support in-memory '
    'file data for media type $mediaType. Use a URI or an OpenAI provider '
    'reference, or use application/pdf for byte data.',
  );
}

UnsupportedError missingOpenAIResponsesPdfFileData() {
  return UnsupportedError(
    'OpenAI Responses user PDF file prompt parts require bytes, a URI, '
    'or an OpenAI provider reference.',
  );
}
