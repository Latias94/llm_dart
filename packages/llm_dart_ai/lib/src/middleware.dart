import 'package:llm_dart_core/llm_dart_core.dart';

import 'prompt_input.dart';

typedef ChatMiddlewareNext = Future<ChatResponse> Function(
  ChatMiddlewareContext context,
);

typedef ChatStreamMiddlewareNext = Stream<LLMStreamPart> Function(
  ChatStreamMiddlewareContext context,
);

class ChatMiddlewareContext {
  final StandardizedPromptInput input;
  final List<Tool>? tools;
  final List<ProviderTool>? providerTools;
  final LLMCallOptions callOptions;
  final CancelToken? cancelToken;

  const ChatMiddlewareContext({
    required this.input,
    required this.tools,
    required this.providerTools,
    required this.callOptions,
    required this.cancelToken,
  });

  ChatMiddlewareContext copyWith({
    StandardizedPromptInput? input,
    List<Tool>? tools,
    List<ProviderTool>? providerTools,
    LLMCallOptions? callOptions,
    CancelToken? cancelToken,
  }) {
    return ChatMiddlewareContext(
      input: input ?? this.input,
      tools: tools ?? this.tools,
      providerTools: providerTools ?? this.providerTools,
      callOptions: callOptions ?? this.callOptions,
      cancelToken: cancelToken ?? this.cancelToken,
    );
  }
}

class ChatStreamMiddlewareContext {
  final StandardizedPromptInput input;
  final List<Tool>? tools;
  final List<ProviderTool>? providerTools;
  final LLMCallOptions callOptions;
  final CancelToken? cancelToken;

  const ChatStreamMiddlewareContext({
    required this.input,
    required this.tools,
    required this.providerTools,
    required this.callOptions,
    required this.cancelToken,
  });

  ChatStreamMiddlewareContext copyWith({
    StandardizedPromptInput? input,
    List<Tool>? tools,
    List<ProviderTool>? providerTools,
    LLMCallOptions? callOptions,
    CancelToken? cancelToken,
  }) {
    return ChatStreamMiddlewareContext(
      input: input ?? this.input,
      tools: tools ?? this.tools,
      providerTools: providerTools ?? this.providerTools,
      callOptions: callOptions ?? this.callOptions,
      cancelToken: cancelToken ?? this.cancelToken,
    );
  }
}

/// Middleware hook points for wrapping a chat model.
///
/// This mirrors the Vercel AI SDK idea of middlewares that can:
/// - Modify request options (headers/body) per call
/// - Observe/transform streamed parts
abstract class LanguageModelMiddleware {
  const LanguageModelMiddleware();

  Future<ChatResponse> chat(
    ChatMiddlewareContext context,
    ChatMiddlewareNext next,
  ) {
    return next(context);
  }

  Stream<LLMStreamPart> stream(
    ChatStreamMiddlewareContext context,
    ChatStreamMiddlewareNext next,
  ) {
    return next(context);
  }
}

class DefaultCallOptionsMiddleware extends LanguageModelMiddleware {
  final LLMCallOptions defaultCallOptions;

  const DefaultCallOptionsMiddleware(this.defaultCallOptions);

  @override
  Future<ChatResponse> chat(
    ChatMiddlewareContext context,
    ChatMiddlewareNext next,
  ) {
    if (defaultCallOptions.isEmpty) return next(context);
    return next(
      context.copyWith(
        callOptions: defaultCallOptions.mergedWith(context.callOptions),
      ),
    );
  }

  @override
  Stream<LLMStreamPart> stream(
    ChatStreamMiddlewareContext context,
    ChatStreamMiddlewareNext next,
  ) {
    if (defaultCallOptions.isEmpty) return next(context);
    return next(
      context.copyWith(
        callOptions: defaultCallOptions.mergedWith(context.callOptions),
      ),
    );
  }
}
