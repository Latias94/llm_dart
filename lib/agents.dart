// High-level agent helpers. These still accept ChatMessage as a
// compatibility entry point, but using the ModelMessage-based APIs
// is recommended.
// ignore_for_file: deprecated_member_use

library;

import 'package:llm_dart_core/llm_dart_core.dart';

/// Run a text-only agent loop using the given [model] and [tools].
///
/// This helper constructs an [AgentInput] and delegates to the provided
/// [agent] (defaults to [ToolLoopAgent]). The loop will:
/// - Call the language model with the current messages.
/// - Execute any requested tools and append their results.
/// - Repeat until no tool calls remain or [ToolLoopConfig.maxIterations]
///   is reached.
@Deprecated(
  'runAgentText() uses the legacy ChatMessage model. '
  'Use runAgentPromptText() with ModelMessage instead. '
  'This helper will be removed in a future breaking release.',
)
Future<GenerateTextResult> runAgentText({
  required LanguageModel model,
  required List<ChatMessage> messages,
  required Map<String, ExecutableTool> tools,
  ToolLoopConfig loopConfig = const ToolLoopConfig(),
  CancellationToken? cancelToken,
  Agent? agent,
  LanguageModelCallOptions? options,
}) async {
  final promptMessages = messages
      .map((message) => message.toPromptMessage())
      .toList(growable: false);

  final input = AgentInput(
    model: model,
    messages: promptMessages,
    tools: tools,
    loopConfig: loopConfig,
    cancelToken: cancelToken,
    callOptions: options,
  );

  final effectiveAgent = agent ?? const ToolLoopAgent();
  return effectiveAgent.runText(input);
}

/// Run a text-only agent loop using structured prompt messages.
///
/// This variant accepts the initial conversation as a list of
/// [ModelMessage]s and bridges them to [ChatMessage] internally so
/// that providers can still recover the full structured content model.
Future<GenerateTextResult> runAgentPromptText({
  required LanguageModel model,
  required List<ModelMessage> promptMessages,
  required Map<String, ExecutableTool> tools,
  ToolLoopConfig loopConfig = const ToolLoopConfig(),
  CancellationToken? cancelToken,
  Agent? agent,
  LanguageModelCallOptions? options,
}) async {
  final input = AgentInput(
    model: model,
    messages: promptMessages,
    tools: tools,
    loopConfig: loopConfig,
    cancelToken: cancelToken,
    callOptions: options,
  );

  final effectiveAgent = agent ?? const ToolLoopAgent();
  return effectiveAgent.runText(input);
}

/// Run a text-only agent loop and return both the final result and steps.
@Deprecated(
  'runAgentTextWithSteps() uses the legacy ChatMessage model. '
  'Use runAgentPromptTextWithSteps() with ModelMessage instead. '
  'This helper will be removed in a future breaking release.',
)
Future<AgentTextRunWithSteps> runAgentTextWithSteps({
  required LanguageModel model,
  required List<ChatMessage> messages,
  required Map<String, ExecutableTool> tools,
  ToolLoopConfig loopConfig = const ToolLoopConfig(),
  CancellationToken? cancelToken,
  Agent? agent,
  LanguageModelCallOptions? options,
}) {
  final promptMessages = messages
      .map((message) => message.toPromptMessage())
      .toList(growable: false);

  final input = AgentInput(
    model: model,
    messages: promptMessages,
    tools: tools,
    loopConfig: loopConfig,
    cancelToken: cancelToken,
    callOptions: options,
  );

  final effectiveAgent = agent ?? const ToolLoopAgent();
  return effectiveAgent.runTextWithSteps(input);
}

/// Run a text-only agent loop using structured prompt messages and
/// return both the final result and per-step trace.
Future<AgentTextRunWithSteps> runAgentPromptTextWithSteps({
  required LanguageModel model,
  required List<ModelMessage> promptMessages,
  required Map<String, ExecutableTool> tools,
  ToolLoopConfig loopConfig = const ToolLoopConfig(),
  CancellationToken? cancelToken,
  Agent? agent,
  LanguageModelCallOptions? options,
}) {
  final input = AgentInput(
    model: model,
    messages: promptMessages,
    tools: tools,
    loopConfig: loopConfig,
    cancelToken: cancelToken,
    callOptions: options,
  );

  final effectiveAgent = agent ?? const ToolLoopAgent();
  return effectiveAgent.runTextWithSteps(input);
}

/// Run an agent loop that produces a structured object result.
Future<GenerateObjectResult<T>> runAgentObject<T>({
  required LanguageModel model,
  required List<ModelMessage> messages,
  required Map<String, ExecutableTool> tools,
  required OutputSpec<T> output,
  ToolLoopConfig loopConfig = const ToolLoopConfig(),
  CancellationToken? cancelToken,
  Agent? agent,
  LanguageModelCallOptions? options,
}) async {
  final input = AgentInput(
    model: model,
    messages: messages,
    tools: tools,
    loopConfig: loopConfig,
    cancelToken: cancelToken,
    callOptions: options,
  );

  final effectiveAgent = agent ?? const ToolLoopAgent();
  return effectiveAgent.runObject<T>(
    input: input,
    output: output,
  );
}

/// Run an agent loop using structured prompt messages that produces a
/// structured object result.
Future<GenerateObjectResult<T>> runAgentPromptObject<T>({
  required LanguageModel model,
  required List<ModelMessage> promptMessages,
  required Map<String, ExecutableTool> tools,
  required OutputSpec<T> output,
  ToolLoopConfig loopConfig = const ToolLoopConfig(),
  CancellationToken? cancelToken,
  Agent? agent,
  LanguageModelCallOptions? options,
}) async {
  final input = AgentInput(
    model: model,
    messages: promptMessages,
    tools: tools,
    loopConfig: loopConfig,
    cancelToken: cancelToken,
    callOptions: options,
  );

  final effectiveAgent = agent ?? const ToolLoopAgent();
  return effectiveAgent.runObject<T>(
    input: input,
    output: output,
  );
}

/// Run an agent loop that produces a structured object result and step trace.
Future<AgentObjectRunWithSteps<T>> runAgentObjectWithSteps<T>({
  required LanguageModel model,
  required List<ModelMessage> messages,
  required Map<String, ExecutableTool> tools,
  required OutputSpec<T> output,
  ToolLoopConfig loopConfig = const ToolLoopConfig(),
  CancellationToken? cancelToken,
  Agent? agent,
  LanguageModelCallOptions? options,
}) {
  final input = AgentInput(
    model: model,
    messages: messages,
    tools: tools,
    loopConfig: loopConfig,
    cancelToken: cancelToken,
    callOptions: options,
  );

  final effectiveAgent = agent ?? const ToolLoopAgent();
  return effectiveAgent.runObjectWithSteps<T>(
    input: input,
    output: output,
  );
}

/// Run an agent loop using structured prompt messages that produces a
/// structured object result and step trace.
Future<AgentObjectRunWithSteps<T>> runAgentPromptObjectWithSteps<T>({
  required LanguageModel model,
  required List<ModelMessage> promptMessages,
  required Map<String, ExecutableTool> tools,
  required OutputSpec<T> output,
  ToolLoopConfig loopConfig = const ToolLoopConfig(),
  CancellationToken? cancelToken,
  Agent? agent,
  LanguageModelCallOptions? options,
}) {
  final input = AgentInput(
    model: model,
    messages: promptMessages,
    tools: tools,
    loopConfig: loopConfig,
    cancelToken: cancelToken,
    callOptions: options,
  );

  final effectiveAgent = agent ?? const ToolLoopAgent();
  return effectiveAgent.runObjectWithSteps<T>(
    input: input,
    output: output,
  );
}
