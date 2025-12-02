// Agent implementation currently bridges between the legacy ChatMessage
// model and the newer ModelMessage prompt model. ChatMessage is used
// here intentionally as a compatibility layer for LanguageModel APIs.
// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:convert';

import '../models/chat_models.dart';
import '../models/tool_models.dart';
import '../utils/structured_output_utils.dart';
import 'capability.dart';
import 'cancellation.dart';
import 'llm_error.dart';

/// Input configuration for running an agent loop.
///
/// This combines a [LanguageModel], initial conversation [messages],
/// and a set of executable tools keyed by their function names.
class AgentInput {
  /// Language model used by the agent.
  final LanguageModel model;

  /// Initial conversation messages in the prompt-first [ModelMessage] format.
  ///
  /// Callers are expected to construct these using [ModelMessage] +
  /// [ChatContentPart] (or higher-level builders) rather than the
  /// legacy [ChatMessage] model.
  final List<ModelMessage> messages;

  /// Map of tool name to [ExecutableTool] implementation.
  final Map<String, ExecutableTool> tools;

  /// Configuration for the tool loop behavior.
  final ToolLoopConfig loopConfig;

  /// Optional cancellation token for the entire agent run.
  ///
  /// When provided, this token is forwarded to all underlying
  /// [LanguageModel] calls made during the agent loop. Tool
  /// execution itself is not automatically cancelled and should
  /// be handled by tool implementations if needed.
  final CancellationToken? cancelToken;

  /// Optional per-call language model options for this agent run.
  ///
  /// These options are forwarded to [LanguageModel] calls made during
  /// the agent loop via the `*WithOptions` methods when available.
  final LanguageModelCallOptions? callOptions;

  const AgentInput({
    required this.model,
    required this.messages,
    required this.tools,
    this.loopConfig = const ToolLoopConfig(),
    this.cancelToken,
    this.callOptions,
  });

  AgentInput copyWith({
    LanguageModel? model,
    List<ModelMessage>? messages,
    Map<String, ExecutableTool>? tools,
    ToolLoopConfig? loopConfig,
    CancellationToken? cancelToken,
    LanguageModelCallOptions? callOptions,
  }) {
    return AgentInput(
      model: model ?? this.model,
      messages: messages ?? this.messages,
      tools: tools ?? this.tools,
      loopConfig: loopConfig ?? this.loopConfig,
      cancelToken: cancelToken ?? this.cancelToken,
      callOptions: callOptions ?? this.callOptions,
    );
  }
}

/// Executable tool definition for agents.
///
/// This pairs a declarative [schema] (used when calling the model)
/// with an [execute] function that performs the actual work given
/// structured JSON arguments.
class ExecutableTool {
  /// Declarative tool schema exposed to the model.
  final Tool schema;

  /// Execute the tool with the given JSON arguments.
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> args)
      execute;

  const ExecutableTool({
    required this.schema,
    required this.execute,
  });
}

/// Configuration for tool loop behavior.
///
/// This controls how many iterations the agent may perform, whether
/// tools are executed sequentially or in parallel, and how many times
/// a failing tool execution should be retried.
class ToolLoopConfig {
  /// Maximum number of tool iterations before aborting.
  final int maxIterations;

  /// Whether to execute tools for a single model step in parallel.
  ///
  /// When `true`, all tool calls emitted by a single model response are
  /// executed concurrently. When `false`, they are executed sequentially.
  final bool runToolsInParallel;

  /// Number of retries for a failing tool execution.
  ///
  /// A value of `0` means no retries (single attempt). Retries are only
  /// applied to errors thrown by the tool's [ExecutableTool.execute]
  /// function; JSON parsing errors for tool arguments are not retried.
  final int maxToolRetries;

  const ToolLoopConfig({
    this.maxIterations = 8,
    this.runToolsInParallel = false,
    this.maxToolRetries = 0,
  });
}

/// Record of a single tool call execution within an agent step.
class AgentToolCallRecord {
  final ToolCall call;
  final Map<String, dynamic>? result;
  final Object? error;
  final StackTrace? stackTrace;

  const AgentToolCallRecord({
    required this.call,
    this.result,
    this.error,
    this.stackTrace,
  });

  bool get isSuccess => error == null;
}

/// Record of a single agent iteration step.
///
/// Each step consists of a model call (represented by [modelResult]) and
/// zero or more tool executions.
class AgentStepRecord {
  final int iteration;
  final GenerateTextResult modelResult;
  final List<AgentToolCallRecord> toolCalls;

  const AgentStepRecord({
    required this.iteration,
    required this.modelResult,
    required this.toolCalls,
  });
}

/// Result of a text-only agent run with detailed steps.
class AgentTextRunWithSteps {
  final GenerateTextResult result;
  final List<AgentStepRecord> steps;

  const AgentTextRunWithSteps({
    required this.result,
    required this.steps,
  });
}

/// Result of a structured object agent run with detailed steps.
class AgentObjectRunWithSteps<T> {
  final GenerateObjectResult<T> result;
  final List<AgentStepRecord> steps;

  const AgentObjectRunWithSteps({
    required this.result,
    required this.steps,
  });
}

/// High-level agent interface.
///
/// Agents orchestrate calls between a [LanguageModel] and a set of
/// executable tools, optionally producing structured outputs via
/// [OutputSpec].
abstract class Agent {
  /// Specification version for the agent interface.
  ///
  /// This is intentionally aligned with the Vercel AI SDK's `"agent-v1"`
  /// version identifier to make cross-language concepts easier to map.
  String get version;

  /// Optional agent identifier for diagnostics and logging.
  ///
  /// Concrete implementations may override this to provide a stable
  /// identifier.
  String? get id;

  /// Run a text-only agent loop until the model returns a response
  /// without tool calls or the iteration limit is reached.
  Future<GenerateTextResult> runText(AgentInput input);

  /// Run an agent loop and parse the final response into a structured
  /// object using the given [output] specification.
  Future<GenerateObjectResult<T>> runObject<T>({
    required AgentInput input,
    required OutputSpec<T> output,
  });

  /// Run a text-only agent loop and return both the final result and
  /// the per-step trace.
  ///
  /// The default implementation delegates to [runText] and returns
  /// an empty steps list. Agent implementations that support detailed
  /// tracing should override this method.
  Future<AgentTextRunWithSteps> runTextWithSteps(AgentInput input) async {
    final result = await runText(input);
    return AgentTextRunWithSteps(result: result, steps: const []);
  }

  /// Run an agent loop for structured output and return both the final
  /// object result and the per-step trace.
  ///
  /// The default implementation delegates to [runObject] and returns
  /// an empty steps list. Agent implementations that support detailed
  /// tracing should override this method.
  Future<AgentObjectRunWithSteps<T>> runObjectWithSteps<T>({
    required AgentInput input,
    required OutputSpec<T> output,
  }) async {
    final result = await runObject<T>(input: input, output: output);
    return AgentObjectRunWithSteps<T>(result: result, steps: const []);
  }
}

/// Minimal tool-loop agent implementation.
///
/// This agent performs the following loop:
/// - Call [LanguageModel.generateText] with the current messages.
/// - If the model emits tool calls, execute matching [ExecutableTool]s
///   and append tool result messages to the conversation.
/// - Repeat until no tool calls are present or [AgentInput.maxIterations]
///   is reached.
class ToolLoopAgent implements Agent {
  @override
  final String version;

  @override
  final String? id;

  const ToolLoopAgent({
    this.id,
    this.version = 'agent-v1',
  });

  @override
  Future<GenerateTextResult> runText(AgentInput input) async {
    final trace = await runTextWithSteps(input);
    return trace.result;
  }

  @override
  Future<AgentTextRunWithSteps> runTextWithSteps(AgentInput input) async {
    // Agent operates purely on prompt-first ModelMessage conversations.
    // We clone the initial messages so that each run can evolve its own
    // conversation history without mutating the caller's list.
    var messages = List<ModelMessage>.from(input.messages);
    final steps = <AgentStepRecord>[];

    for (var i = 0; i < input.loopConfig.maxIterations; i++) {
      final result = await input.model.generateTextWithOptions(
        messages,
        options: input.callOptions,
        cancelToken: input.cancelToken,
      );
      final calls = result.toolCalls ?? const [];

      if (calls.isEmpty) {
        steps.add(
          AgentStepRecord(
            iteration: i + 1,
            modelResult: result,
            toolCalls: const [],
          ),
        );
        return AgentTextRunWithSteps(result: result, steps: steps);
      }

      final toolResults = <ModelMessage>[];
      final toolCallRecords = <AgentToolCallRecord>[];

      Future<AgentToolCallRecord> runSingleToolCall(ToolCall call) async {
        final handler = input.tools[call.function.name];
        if (handler == null) {
          return AgentToolCallRecord(call: call, result: null);
        }

        Map<String, dynamic> args;
        try {
          final decoded = jsonDecode(call.function.arguments);
          if (decoded is Map<String, dynamic>) {
            args = decoded;
          } else if (decoded is Map) {
            args = Map<String, dynamic>.from(decoded);
          } else {
            throw const FormatException(
              'Tool arguments must be a JSON object',
            );
          }
        } catch (e) {
          throw ResponseFormatError(
            'Failed to parse tool arguments for "${call.function.name}": $e',
            call.function.arguments,
          );
        }

        int attempt = 0;
        while (true) {
          try {
            final output = await handler.execute(args);
            final outputJson = jsonEncode(output);

            toolResults.add(
              ModelMessage(
                role: ChatRole.user,
                parts: <ChatContentPart>[
                  ToolResultContentPart(
                    toolCallId: call.id,
                    toolName: call.function.name,
                    payload: ToolResultTextPayload(outputJson),
                  ),
                ],
              ),
            );

            return AgentToolCallRecord(
              call: call,
              result: output,
            );
          } catch (e) {
            if (attempt >= input.loopConfig.maxToolRetries) {
              throw GenericError(
                'Tool execution failed for "${call.function.name}"',
              );
            }
            attempt++;
          }
        }
      }

      if (input.loopConfig.runToolsInParallel) {
        toolCallRecords.addAll(
          await Future.wait(calls.map(runSingleToolCall)),
        );
      } else {
        for (final call in calls) {
          toolCallRecords.add(await runSingleToolCall(call));
        }
      }

      if (toolResults.isEmpty) {
        steps.add(
          AgentStepRecord(
            iteration: i + 1,
            modelResult: result,
            toolCalls: toolCallRecords,
          ),
        );
        return AgentTextRunWithSteps(result: result, steps: steps);
      }

      // Append the assistant tool-use message and tool results to history.
      //
      // This mirrors the typical OpenAI pattern where the assistant
      // message contains tool_calls, followed by one or more tool
      // messages with results. We store the textual part (if any) in
      // the assistant message and encode tool calls via
      // ToolCallContentPart / ToolResultContentPart.
      final toolCallParts = <ChatContentPart>[];
      if (result.text != null && result.text!.isNotEmpty) {
        toolCallParts.add(TextContentPart(result.text!));
      }
      for (final call in calls) {
        toolCallParts.add(
          ToolCallContentPart(
            toolName: call.function.name,
            argumentsJson: call.function.arguments,
            toolCallId: call.id,
          ),
        );
      }

      messages = [
        ...messages,
        if (toolCallParts.isNotEmpty)
          ModelMessage(
            role: ChatRole.assistant,
            parts: toolCallParts,
          ),
        ...toolResults,
      ];

      steps.add(
        AgentStepRecord(
          iteration: i + 1,
          modelResult: result,
          toolCalls: toolCallRecords,
        ),
      );
    }

    // Fallback after reaching iteration limit.
    final finalResult = await input.model.generateTextWithOptions(
      messages,
      options: input.callOptions,
      cancelToken: input.cancelToken,
    );
    steps.add(
      AgentStepRecord(
        iteration: steps.length + 1,
        modelResult: finalResult,
        toolCalls: const [],
      ),
    );

    return AgentTextRunWithSteps(result: finalResult, steps: steps);
  }

  @override
  Future<GenerateObjectResult<T>> runObject<T>({
    required AgentInput input,
    required OutputSpec<T> output,
  }) async {
    final traced = await runObjectWithSteps<T>(
      input: input,
      output: output,
    );
    return traced.result;
  }

  @override
  Future<AgentObjectRunWithSteps<T>> runObjectWithSteps<T>({
    required AgentInput input,
    required OutputSpec<T> output,
  }) async {
    final textRun = await runTextWithSteps(input);
    final textResult = textRun.result;

    final rawText = textResult.text;
    if (rawText == null || rawText.trim().isEmpty) {
      throw const ResponseFormatError(
        'Structured output is empty or missing JSON content',
        '',
      );
    }

    final json = parseStructuredObjectJson(rawText, output.format);
    final object = output.fromJson(json);

    final objectResult = GenerateObjectResult<T>(
      object: object,
      textResult: textResult,
    );

    return AgentObjectRunWithSteps<T>(
      result: objectResult,
      steps: textRun.steps,
    );
  }
}
