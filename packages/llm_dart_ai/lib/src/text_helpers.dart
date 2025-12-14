// High-level prompt-first helpers that operate on LanguageModel instances.

library;

import 'package:llm_dart_core/llm_dart_core.dart';

/// Generate text using an existing [LanguageModel] instance.
///
/// This helper operates on a pre-configured [LanguageModel], which is useful
/// when you want to:
/// - Reuse the same model across multiple calls.
/// - Pass models through dependency injection.
/// - Decouple higher-level code from concrete providers.
Future<GenerateTextResult> generateTextWithModel(
  LanguageModel model, {
  String? prompt,
  ModelMessage? structuredPrompt,
  List<ModelMessage>? promptMessages,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
  void Function(GenerateTextResult result)? onFinish,
  void Function(List<CallWarning> warnings)? onWarnings,
}) async {
  // ElevenLabs is an audio-only provider and does not support chat/text
  // generation. Fail fast here instead of surfacing a lower-level error.
  if (model.providerId == 'elevenlabs') {
    throw const UnsupportedCapabilityError(
      'Provider "elevenlabs" does not support text generation. '
      'Use audio helpers such as generateSpeech(), transcribe(), or '
      'transcribeFile() instead.',
    );
  }

  final resolvedMessages = resolvePromptMessagesForTextGeneration(
    prompt: prompt,
    structuredPrompt: structuredPrompt,
    promptMessages: promptMessages,
  );

  final result = await model.generateTextWithOptions(
    resolvedMessages,
    options: options,
    cancelToken: cancelToken,
  );

  if (onFinish != null) {
    onFinish(result);
  }
  if (onWarnings != null && result.warnings.isNotEmpty) {
    onWarnings(result.warnings);
  }

  return result;
}

/// Prompt-first generateText helper using an existing [LanguageModel].
Future<GenerateTextResult> generateTextPromptWithModel(
  LanguageModel model, {
  required List<ModelMessage> messages,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
  void Function(GenerateTextResult result)? onFinish,
  void Function(List<CallWarning> warnings)? onWarnings,
}) {
  return generateTextWithModel(
    model,
    promptMessages: messages,
    cancelToken: cancelToken,
    options: options,
    onFinish: onFinish,
    onWarnings: onWarnings,
  );
}

/// Stream text using an existing [LanguageModel] instance.
Stream<ChatStreamEvent> streamTextWithModel(
  LanguageModel model, {
  String? prompt,
  ModelMessage? structuredPrompt,
  List<ModelMessage>? promptMessages,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
  void Function(GenerateTextResult result)? onFinish,
  void Function(List<CallWarning> warnings)? onWarnings,
}) async* {
  if (model.providerId == 'elevenlabs') {
    throw const UnsupportedCapabilityError(
      'Provider "elevenlabs" does not support streaming text. '
      'Use audio helpers such as generateSpeech(), transcribe(), or '
      'transcribeFile() instead.',
    );
  }

  final resolvedMessages = resolvePromptMessagesForTextGeneration(
    prompt: prompt,
    structuredPrompt: structuredPrompt,
    promptMessages: promptMessages,
  );

  final source = model.streamTextWithOptions(
    resolvedMessages,
    options: options,
    cancelToken: cancelToken,
  );

  await for (final event in source) {
    if (event is CompletionEvent && (onFinish != null || onWarnings != null)) {
      final response = event.response;
      final result = GenerateTextResult(
        rawResponse: response,
        text: response.text,
        thinking: response.thinking,
        toolCalls: response.toolCalls,
        usage: response.usage,
        warnings: response.warnings,
        metadata: response.callMetadata,
      );

      if (onFinish != null) {
        onFinish(result);
      }
      if (onWarnings != null && result.warnings.isNotEmpty) {
        onWarnings(result.warnings);
      }
    }

    yield event;
  }
}

/// Prompt-first streamText helper using an existing [LanguageModel].
Stream<ChatStreamEvent> streamTextPromptWithModel(
  LanguageModel model, {
  required List<ModelMessage> messages,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
  void Function(GenerateTextResult result)? onFinish,
  void Function(List<CallWarning> warnings)? onWarnings,
}) {
  return streamTextWithModel(
    model,
    promptMessages: messages,
    cancelToken: cancelToken,
    options: options,
    onFinish: onFinish,
    onWarnings: onWarnings,
  );
}

/// Stream high-level text parts using an existing [LanguageModel] instance.
Stream<StreamTextPart> streamTextPartsWithModel(
  LanguageModel model, {
  String? prompt,
  ModelMessage? structuredPrompt,
  List<ModelMessage>? promptMessages,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
}) async* {
  if (model.providerId == 'elevenlabs') {
    throw const UnsupportedCapabilityError(
      'Provider "elevenlabs" does not support streaming text parts. '
      'Use audio helpers such as generateSpeech(), transcribe(), or '
      'transcribeFile() instead.',
    );
  }

  final resolvedMessages = resolvePromptMessagesForTextGeneration(
    prompt: prompt,
    structuredPrompt: structuredPrompt,
    promptMessages: promptMessages,
  );

  yield* model.streamTextPartsWithOptions(
    resolvedMessages,
    options: options,
    cancelToken: cancelToken,
  );
}

/// Prompt-first helper that returns provider-agnostic stream parts.
Stream<StreamTextPart> streamTextPartsPromptWithModel(
  LanguageModel model, {
  required List<ModelMessage> messages,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
}) {
  return streamTextPartsWithModel(
    model,
    promptMessages: messages,
    cancelToken: cancelToken,
    options: options,
  );
}

/// Generate a structured object using an existing [LanguageModel].
///
/// This helper assumes the given [model] has already been configured to
/// produce structured JSON matching [output.format].
Future<GenerateObjectResult<T>> generateObjectWithModel<T>({
  required LanguageModel model,
  required OutputSpec<T> output,
  String? prompt,
  ModelMessage? structuredPrompt,
  List<ModelMessage>? promptMessages,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
}) async {
  final resolvedMessages = resolvePromptMessagesForTextGeneration(
    prompt: prompt,
    structuredPrompt: structuredPrompt,
    promptMessages: promptMessages,
  );

  return model.generateObjectWithOptions<T>(
    output,
    resolvedMessages,
    options: options,
    cancelToken: cancelToken,
  );
}
