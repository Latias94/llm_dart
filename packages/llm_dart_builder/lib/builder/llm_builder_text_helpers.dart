part of 'llm_builder.dart';

/// High-level text generation helpers for [LLMBuilder].
///
/// These helpers provide a Vercel AI SDK-style experience on top of the
/// core [ChatCapability] interface, while remaining provider-agnostic.
extension LLMBuilderTextHelpers on LLMBuilder {
  /// Generate a single text response using the current builder configuration.
  ///
  /// This is a convenience wrapper around [ChatCapability.chat] that:
  /// - Resolves the input into a list of prompt-first [ModelMessage] instances.
  /// - Calls the provider's `chat(...)` method.
  /// - Returns a [GenerateTextResult] with text, thinking, tool calls,
  ///   usage, warnings, and call metadata.
  ///
  /// You must provide exactly one of:
  /// - [prompt]: simple single-turn user message
  /// - [promptMessages]: full conversation history
  /// - [structuredPrompt]: a structured [ModelMessage] built via
  ///   [ChatPromptBuilder].
  Future<GenerateTextResult> generateText({
    String? prompt,
    ModelMessage? structuredPrompt,
    List<ModelMessage>? promptMessages,
    CancellationToken? cancelToken,
    LanguageModelCallOptions? options,
  }) async {
    _ensureChatCapable('text generation');

    final provider = await buildWithMiddleware();
    final resolvedMessages = resolvePromptMessagesForTextGeneration(
      prompt: prompt,
      structuredPrompt: structuredPrompt,
      promptMessages: promptMessages,
    );

    final response = await provider.chat(
      resolvedMessages,
      tools: options?.resolveTools(),
      options: options,
      cancelToken: cancelToken,
    );

    return GenerateTextResult(
      rawResponse: response,
      text: response.text,
      thinking: response.thinking,
      toolCalls: response.toolCalls,
      usage: response.usage,
      warnings: response.warnings,
      metadata: response.callMetadata,
    );
  }

  /// Stream a text response using the current builder configuration.
  ///
  /// This is a convenience wrapper around [ChatCapability.chatStream] that:
  /// - Resolves the input into a list of prompt-first [ModelMessage] instances.
  /// - Builds the provider and forwards the stream of [ChatStreamEvent]
  ///   objects (thinking deltas, text deltas, tool call deltas, completion).
  ///
  /// The input resolution rules are the same as [generateText].
  Stream<ChatStreamEvent> streamText({
    String? prompt,
    ModelMessage? structuredPrompt,
    List<ModelMessage>? promptMessages,
    CancellationToken? cancelToken,
    LanguageModelCallOptions? options,
  }) async* {
    _ensureChatCapable('streaming text');

    final provider = await buildWithMiddleware();
    final resolvedMessages = resolvePromptMessagesForTextGeneration(
      prompt: prompt,
      structuredPrompt: structuredPrompt,
      promptMessages: promptMessages,
    );

    yield* provider.chatStream(
      resolvedMessages,
      tools: options?.resolveTools(),
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Stream high-level text parts using the current builder configuration.
  ///
  /// This is similar to [streamText] but adapts the low-level
  /// [ChatStreamEvent] stream into a provider-agnostic sequence of
  /// [StreamTextPart] values (text start/delta/end, thinking deltas,
  /// tool input lifecycle events, and a final completion part).
  Stream<StreamTextPart> streamTextParts({
    String? prompt,
    ModelMessage? structuredPrompt,
    List<ModelMessage>? promptMessages,
    CancellationToken? cancelToken,
    LanguageModelCallOptions? options,
  }) async* {
    _ensureChatCapable('streaming text parts');

    final rawStream = streamText(
      prompt: prompt,
      structuredPrompt: structuredPrompt,
      promptMessages: promptMessages,
      cancelToken: cancelToken,
      options: options,
    );

    yield* adaptStreamText(rawStream);
  }
}
