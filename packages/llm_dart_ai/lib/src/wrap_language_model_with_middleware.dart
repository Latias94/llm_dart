import 'package:llm_dart_core/llm_dart_core.dart';

import 'call_options_dispatch.dart';
import 'middleware.dart';
import 'prompt_input.dart';
import 'simulate_streaming_middleware.dart';
import 'simulated_stream_parts.dart';

/// Wraps a chat model with a middleware chain (AI SDK-inspired).
///
/// Middlewares can:
/// - Inject defaults (e.g. headers/body) per call
/// - Observe/transform streamed parts
ChatCapability wrapLanguageModelWithMiddleware(
  ChatCapability model, {
  required List<LanguageModelMiddleware> middlewares,
}) {
  if (middlewares.isEmpty) return model;
  final list = List<LanguageModelMiddleware>.unmodifiable(middlewares);
  if (model is ModelIdentityCapability) {
    return _MiddlewareLanguageModelWithIdentity(
      inner: model,
      middlewares: list,
    );
  }
  return _MiddlewareLanguageModel(
    inner: model,
    middlewares: list,
  );
}

class _MiddlewareLanguageModel extends ChatCapability
    implements
        ChatCallOptionsCapability,
        PromptChatCapability,
        PromptChatCallOptionsCapability,
        ChatStreamPartsCapability,
        ChatStreamPartsCallOptionsCapability,
        PromptChatStreamPartsCapability,
        PromptChatStreamPartsCallOptionsCapability {
  final ChatCapability inner;
  final List<LanguageModelMiddleware> middlewares;
  final bool _simulateStreaming;

  _MiddlewareLanguageModel({
    required this.inner,
    required this.middlewares,
  }) : _simulateStreaming =
            middlewares.any((m) => m is SimulateStreamingMiddleware);

  Future<ChatResponse> _chatViaMiddleware({
    required StandardizedPromptInput input,
    required List<Tool>? tools,
    required List<ProviderTool>? providerTools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    Future<ChatResponse> dispatch(ChatMiddlewareContext c) {
      return chatWithToolsBestEffort(
        model: inner,
        input: c.input,
        tools: c.tools,
        callOptions: c.callOptions,
        cancelToken: c.cancelToken,
      );
    }

    ChatMiddlewareNext next = dispatch;
    for (final middleware in middlewares.reversed) {
      final prev = next;
      next = (c) => middleware.chat(c, prev);
    }

    return next(
      ChatMiddlewareContext(
        input: input,
        tools: tools,
        providerTools: providerTools,
        callOptions: callOptions,
        cancelToken: cancelToken,
      ),
    );
  }

  Stream<LLMStreamPart> _streamViaMiddleware({
    required StandardizedPromptInput input,
    required List<Tool>? tools,
    required List<ProviderTool>? providerTools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    Stream<LLMStreamPart> dispatch(ChatStreamMiddlewareContext c) {
      if (!_simulateStreaming) {
        return chatStreamPartsBestEffort(
          model: inner,
          input: c.input,
          tools: c.tools,
          providerTools: c.providerTools,
          callOptions: c.callOptions,
          cancelToken: c.cancelToken,
        );
      }

      try {
        return chatStreamPartsBestEffort(
          model: inner,
          input: c.input,
          tools: c.tools,
          providerTools: c.providerTools,
          callOptions: c.callOptions,
          cancelToken: c.cancelToken,
        );
      } catch (e) {
        if (e is! UnsupportedError && e is! InvalidRequestError) rethrow;

        return _simulateStreamParts(
          input: c.input,
          tools: c.tools,
          callOptions: c.callOptions,
          cancelToken: c.cancelToken,
        );
      }
    }

    ChatStreamMiddlewareNext next = dispatch;
    for (final middleware in middlewares.reversed) {
      final prev = next;
      next = (c) => middleware.stream(c, prev);
    }

    return next(
      ChatStreamMiddlewareContext(
        input: input,
        tools: tools,
        providerTools: providerTools,
        callOptions: callOptions,
        cancelToken: cancelToken,
      ),
    );
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) {
    return _chatViaMiddleware(
      input: StandardizedChatMessages(messages),
      tools: tools,
      providerTools: providerTools,
      callOptions: const LLMCallOptions(),
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatWithToolsWithCallOptions(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    return _chatViaMiddleware(
      input: StandardizedChatMessages(messages),
      tools: tools,
      providerTools: providerTools,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatPrompt(
    Prompt prompt, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    return _chatViaMiddleware(
      input: StandardizedPromptIr(prompt),
      tools: tools,
      providerTools: providerTools,
      callOptions: const LLMCallOptions(),
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatPromptWithCallOptions(
    Prompt prompt, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    return _chatViaMiddleware(
      input: StandardizedPromptIr(prompt),
      tools: tools,
      providerTools: providerTools,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) {
    return _streamViaMiddleware(
      input: StandardizedChatMessages(messages),
      tools: tools,
      providerTools: providerTools,
      callOptions: const LLMCallOptions(),
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatStreamPartsWithCallOptions(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    List<ProviderTool>? providerTools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    return _streamViaMiddleware(
      input: StandardizedChatMessages(messages),
      tools: tools,
      providerTools: providerTools,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamParts(
    Prompt prompt, {
    List<Tool>? tools,
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) {
    return _streamViaMiddleware(
      input: StandardizedPromptIr(prompt),
      tools: tools,
      providerTools: providerTools,
      callOptions: const LLMCallOptions(),
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamPartsWithCallOptions(
    Prompt prompt, {
    List<Tool>? tools,
    List<ProviderTool>? providerTools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    return _streamViaMiddleware(
      input: StandardizedPromptIr(prompt),
      tools: tools,
      providerTools: providerTools,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  Stream<LLMStreamPart> _simulateStreamParts({
    required StandardizedPromptInput input,
    required List<Tool>? tools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async* {
    final startedAt = DateTime.now().toUtc();
    final defaultModelId = inner is ModelIdentityCapability
        ? (inner as ModelIdentityCapability).modelId
        : null;

    final response = await chatWithToolsBestEffort(
      model: inner,
      input: input,
      tools: tools,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );

    yield* simulatedStreamPartsFromChatResponse(
      response,
      startedAtUtc: startedAt,
      defaultModelId: defaultModelId,
    );
  }
}

class _MiddlewareLanguageModelWithIdentity extends _MiddlewareLanguageModel
    implements ModelIdentityCapability {
  _MiddlewareLanguageModelWithIdentity({
    required ChatCapability inner,
    required List<LanguageModelMiddleware> middlewares,
  }) : super(inner: inner, middlewares: middlewares);

  ModelIdentityCapability get _identity => inner as ModelIdentityCapability;

  @override
  String get providerId => _identity.providerId;

  @override
  String get modelId => _identity.modelId;
}
