import 'package:llm_dart_provider/llm_dart_provider.dart';

UnsupportedError unsupportedOpenAIChatCompletionsPromptPart({
  required String role,
  required PromptPart part,
}) {
  return UnsupportedError(
    'OpenAI-family chat-completions $role prompt messages do not support '
    '${part.runtimeType} parts.',
  );
}

UnsupportedError unsupportedOpenAIChatCompletionsUserFileMediaType(
  String mediaType,
) {
  return UnsupportedError(
    'OpenAI-family chat-completions user file prompt parts do not support '
    'media type $mediaType.',
  );
}

UnsupportedError unsupportedOpenAIChatCompletionsAudioFileUri() {
  return UnsupportedError(
    'OpenAI-family chat-completions audio file prompt parts do not support '
    'URIs. Provide bytes or an OpenAI provider reference instead.',
  );
}

UnsupportedError missingOpenAIChatCompletionsAudioFileData() {
  return UnsupportedError(
    'OpenAI-family chat-completions audio file prompt parts require bytes '
    'or an OpenAI provider reference.',
  );
}

UnsupportedError unsupportedOpenAIChatCompletionsPdfFileUri() {
  return UnsupportedError(
    'OpenAI-family chat-completions PDF file prompt parts do not support '
    'URIs. Provide bytes or an OpenAI provider reference instead.',
  );
}

UnsupportedError missingOpenAIChatCompletionsPdfFileData() {
  return UnsupportedError(
    'OpenAI-family chat-completions PDF file prompt parts require bytes '
    'or an OpenAI provider reference.',
  );
}

UnsupportedError unsupportedOpenAIChatCompletionsAudioMediaType(
  String mediaType,
) {
  return UnsupportedError(
    'OpenAI-family chat-completions audio file prompt parts do not support '
    'media type $mediaType.',
  );
}

ModelWarning unsupportedOpenAIChatCompletionsAssistantPartWarning(
  PromptPart part,
) {
  return ModelWarning(
    type: ModelWarningType.unsupported,
    field: 'prompt.assistant.parts',
    message:
        'Chat-completions replay dropped unsupported assistant prompt part: '
        '${part.runtimeType}.',
  );
}

ModelWarning unsupportedOpenAIChatCompletionsToolPartWarning(
  PromptPart part,
) {
  return ModelWarning(
    type: ModelWarningType.unsupported,
    field: 'prompt.tool.parts',
    message: 'Chat-completions replay dropped unsupported tool prompt part: '
        '${part.runtimeType}.',
  );
}
