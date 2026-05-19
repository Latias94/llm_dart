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

UnsupportedError missingOpenAIResponsesUserImageData(String message) {
  return UnsupportedError(message);
}

UnsupportedError missingOpenAIResponsesToolOutputImageData() {
  return UnsupportedError(
    'OpenAI Responses tool output image parts require in-memory bytes, a URI, or an OpenAI provider reference.',
  );
}

UnsupportedError missingOpenAIResponsesToolOutputFileData() {
  return UnsupportedError(
    'OpenAI Responses tool output file part requires in-memory bytes, text, a URI, or an OpenAI provider reference.',
  );
}

ModelWarning emptyOpenAIResponsesReasoningPartWarning(String reasoningId) {
  return ModelWarning(
    type: ModelWarningType.other,
    field: 'prompt.assistant.reasoning',
    message:
        'Cannot append empty reasoning part to existing reasoning sequence. Skipping reasoning part with itemId "$reasoningId".',
  );
}

const nonOpenAIResponsesReasoningPartWarning = ModelWarning(
  type: ModelWarningType.other,
  field: 'prompt.assistant.reasoning',
  message:
      'Non-OpenAI reasoning parts without itemId or encryptedContent are not sent to the OpenAI Responses API',
);

const openAIResponsesReasoningStoreFalseWarning = ModelWarning(
  type: ModelWarningType.other,
  field: 'prompt.assistant.reasoning',
  message:
      'Reasoning parts without encrypted content are not supported when store is false. Skipping reasoning parts.',
);

ModelWarning openAIResponsesToolResultStoreFalseWarning(String toolName) {
  return ModelWarning(
    type: ModelWarningType.other,
    field: 'prompt.assistant.toolResult',
    message:
        'Results for OpenAI tool $toolName are not sent to the API when store is false',
  );
}
