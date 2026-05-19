import 'package:llm_dart_provider/llm_dart_provider.dart';

UnsupportedError unsupportedAnthropicPromptPart({
  required String role,
  required PromptPart part,
}) {
  return UnsupportedError(
    'Anthropic $role prompt messages do not support ${part.runtimeType} parts.',
  );
}

UnsupportedError unsupportedAnthropicDocumentMediaType(String mediaType) {
  return UnsupportedError(
    'Anthropic user document prompt parts do not support media type $mediaType.',
  );
}

UnsupportedError missingAnthropicUserBinarySource(String path) {
  return UnsupportedError(
    'Anthropic $path requires in-memory bytes, an HTTP/HTTPS URI, or an Anthropic provider reference.',
  );
}

UnsupportedError missingAnthropicUserTextDocumentSource() {
  return UnsupportedError(
    'Anthropic text document prompt parts require text, UTF-8 bytes, an HTTP/HTTPS URI, or an Anthropic provider reference.',
  );
}

UnsupportedError unsupportedAnthropicToolOutputFileMediaType(
  String mediaType,
) {
  return UnsupportedError(
    'Anthropic tool output file parts do not support media type $mediaType.',
  );
}

UnsupportedError missingAnthropicToolOutputImageData() {
  return UnsupportedError(
    'Anthropic tool output image parts require in-memory bytes, a URI, or an Anthropic provider reference.',
  );
}

UnsupportedError missingAnthropicToolOutputFileData() {
  return UnsupportedError(
    'Anthropic tool output file parts require in-memory bytes, text, a URI, or an Anthropic provider reference.',
  );
}

ModelWarning unsupportedAnthropicAssistantReplayPartWarning(
  PromptPart part,
) {
  return ModelWarning(
    type: ModelWarningType.unsupported,
    field: switch (part) {
      ReasoningPromptPart() => 'assistant.reasoning',
      FilePromptPart() => 'assistant.file',
      ReasoningFilePromptPart() => 'assistant.reasoningFile',
      CustomPromptPart() => 'assistant.custom',
      _ => 'assistant.part',
    },
    message: switch (part) {
      ReasoningPromptPart() =>
        'Anthropic assistant replay does not support reasoning parts yet. The part has been dropped.',
      FilePromptPart() =>
        'Anthropic assistant replay does not support assistant file parts yet. The part has been dropped.',
      ReasoningFilePromptPart() =>
        'Anthropic assistant replay does not support reasoning file parts yet. The part has been dropped.',
      CustomPromptPart(:final kind) =>
        'Anthropic assistant replay does not support custom part "$kind" yet. The part has been dropped.',
      _ =>
        'Anthropic assistant replay does not support this part yet. The part has been dropped.',
    },
  );
}
