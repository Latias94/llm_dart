// High-level agent helpers built on prompt-first ModelMessage conversations.

library;

import 'package:llm_dart_core/llm_dart_core.dart';

/// Run a text-only agent loop using structured prompt messages.
///
/// This variant accepts the initial conversation as a list of
/// [ModelMessage]s and delegates to the provided [agent] (defaults to
/// [ToolLoopAgent]).
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
