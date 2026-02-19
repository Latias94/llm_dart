import 'package:llm_dart_core/llm_dart_core.dart';

import 'generate_text.dart' as low_level;
import 'openai_tool_control.dart';
import 'prompt_input.dart';
import 'prompt_message_converters.dart';
import 'stream_object.dart' as object_streaming;
import 'stream_text.dart' as streaming;
import 'tool_loop.dart';
import 'tool_set.dart';
import 'tool_types.dart';
import 'types.dart';

/// High-level orchestration wrapper inspired by Vercel AI SDK agents.
///
/// This stays intentionally Dart-flavored:
/// - uses `Future`/`Stream` APIs,
/// - exposes strongly typed results,
/// - composes existing low-level primitives (generateText/streamText/tool loops).
class Agent {
  final ChatCapability model;
  final ToolSet? toolSet;

  final ToolCallRepair? repairToolCall;
  final ToolApprovalCheck? needsApproval;

  final int maxSteps;
  final bool continueOnToolError;

  final IncludeOptions include;
  final LLMCallOptions defaultCallOptions;

  const Agent({
    required this.model,
    this.toolSet,
    this.repairToolCall,
    this.needsApproval,
    this.maxSteps = 10,
    this.continueOnToolError = true,
    this.include = const IncludeOptions(),
    this.defaultCallOptions = const LLMCallOptions(),
  });

  /// Generate text, executing local tools when a [ToolSet] is available.
  ///
  /// When no [ToolSet] is configured (and none is provided), this falls back to
  /// a single non-streaming model call and returns a single-step [ToolLoopResult]
  /// for AI SDK parity.
  Future<ToolLoopResult> generateText({
    String? system,
    String? prompt,
    List<ChatMessage>? messages,
    Prompt? promptIr,
    ToolSet? toolSet,
    List<ProviderTool>? providerTools,
    ToolChoice? toolChoice,
    bool? parallelToolCalls,
    ToolCallRepair? repairToolCall,
    ToolApprovalCheck? needsApproval,
    int? maxSteps,
    bool? continueOnToolError,
    LLMCallOptions callOptions = const LLMCallOptions(),
    CancelToken? cancelToken,
    IdGenerator? generateId,
  }) async {
    final effectiveToolSet = toolSet ?? this.toolSet;
    final effectiveRepair = repairToolCall ?? this.repairToolCall;
    final effectiveNeedsApproval = needsApproval ?? this.needsApproval;
    final effectiveMaxSteps = maxSteps ?? this.maxSteps;
    final effectiveContinueOnToolError =
        continueOnToolError ?? this.continueOnToolError;

    if (effectiveToolSet != null) {
      final effectiveCallOptions = applyOpenAIToolControlsToCallOptions(
        defaultCallOptions.mergedWith(callOptions),
        toolChoice: toolChoice,
        parallelToolCalls: parallelToolCalls,
      );
      return runToolLoopWithToolSet(
        model: model,
        system: system,
        prompt: prompt,
        messages: messages,
        promptIr: promptIr,
        toolSet: effectiveToolSet,
        providerTools: providerTools,
        repairToolCall: effectiveRepair,
        needsApproval: effectiveNeedsApproval,
        maxSteps: effectiveMaxSteps,
        continueOnToolError: effectiveContinueOnToolError,
        include: include,
        defaultCallOptions: const LLMCallOptions(),
        callOptions: effectiveCallOptions,
        cancelToken: cancelToken,
        generateId: generateId,
      );
    }

    final result = await low_level.generateText(
      model: model,
      system: system,
      prompt: prompt,
      messages: messages,
      promptIr: promptIr,
      toolSet: null,
      toolChoice: toolChoice,
      parallelToolCalls: parallelToolCalls,
      providerTools: providerTools,
      tools: null,
      include: include,
      defaultCallOptions: defaultCallOptions,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );

    final input = standardizePromptInput(
      system: system,
      prompt: prompt,
      messages: messages,
      promptIr: promptIr,
    );

    Prompt? promptHistory;
    List<ChatMessage> messageHistory = const <ChatMessage>[];

    if (input case StandardizedChatMessages(:final messages)) {
      final history = <ChatMessage>[
        ...messages,
        ...result.responseMessages,
      ];
      messageHistory = List<ChatMessage>.unmodifiable(history);
      promptHistory = promptFromChatMessages(history);
    } else if (input case StandardizedPromptIr(:final prompt)) {
      promptHistory = Prompt(
        messages: [
          ...prompt.messages,
          ...result.responsePromptMessages,
        ],
      );

      try {
        messageHistory = List<ChatMessage>.unmodifiable(
          promptHistory.toChatMessages(),
        );
      } catch (_) {
        messageHistory = const <ChatMessage>[];
      }
    }

    return ToolLoopResult(
      finalResult: result,
      steps: result.steps,
      messages: messageHistory,
      prompt: promptHistory,
    );
  }

  /// Stream text, executing local tools when a [ToolSet] is available.
  streaming.StreamTextResult streamText({
    String? system,
    String? prompt,
    List<ChatMessage>? messages,
    Prompt? promptIr,
    ToolSet? toolSet,
    List<Tool>? tools,
    List<ProviderTool>? providerTools,
    ToolChoice? toolChoice,
    bool? parallelToolCalls,
    ToolCallRepair? repairToolCall,
    ToolApprovalCheck? needsApproval,
    ProviderToolApprovalHandler? onProviderToolApprovalRequests,
    bool stopOnProviderToolApprovalRequests = false,
    int providerToolApprovalMaxSteps = 10,
    bool waitForDeferredProviderToolResults = true,
    int maxAdditionalProviderToolResultSteps = 1,
    int? maxSteps,
    bool? continueOnToolError,
    bool includeRawChunks = false,
    streaming.StreamTextOnStepFinishCallback? onStepFinish,
    streaming.StreamTextOnFinishCallback? onFinish,
    LLMCallOptions callOptions = const LLMCallOptions(),
    CancelToken? cancelToken,
    IdGenerator? generateId,
  }) {
    return streaming.streamText(
      model: model,
      system: system,
      prompt: prompt,
      messages: messages,
      promptIr: promptIr,
      toolSet: toolSet ?? this.toolSet,
      tools: tools,
      providerTools: providerTools,
      toolChoice: toolChoice,
      parallelToolCalls: parallelToolCalls,
      repairToolCall: repairToolCall ?? this.repairToolCall,
      needsApproval: needsApproval ?? this.needsApproval,
      onProviderToolApprovalRequests: onProviderToolApprovalRequests,
      stopOnProviderToolApprovalRequests: stopOnProviderToolApprovalRequests,
      providerToolApprovalMaxSteps: providerToolApprovalMaxSteps,
      waitForDeferredProviderToolResults: waitForDeferredProviderToolResults,
      maxAdditionalProviderToolResultSteps:
          maxAdditionalProviderToolResultSteps,
      maxSteps: maxSteps ?? this.maxSteps,
      continueOnToolError: continueOnToolError ?? this.continueOnToolError,
      includeRawChunks: includeRawChunks,
      onStepFinish: onStepFinish,
      onFinish: onFinish,
      include: include,
      defaultCallOptions: defaultCallOptions,
      callOptions: callOptions,
      cancelToken: cancelToken,
      generateId: generateId,
    );
  }

  /// Stream a JSON object using a tool-call schema (AI SDK-inspired).
  object_streaming.StreamObjectResult streamObject({
    String? system,
    String? prompt,
    List<ChatMessage>? messages,
    Prompt? promptIr,
    required Object schema,
    object_streaming.StreamObjectOutput output =
        object_streaming.StreamObjectOutput.object,
    String toolName = 'return_object',
    String toolDescription =
        'Return the result as a JSON object that matches the schema.',
    List<ProviderTool>? providerTools,
    ToolChoice? toolChoice,
    bool? parallelToolCalls,
    ProviderToolApprovalHandler? onProviderToolApprovalRequests,
    bool stopOnProviderToolApprovalRequests = false,
    int providerToolApprovalMaxSteps = 10,
    bool waitForDeferredProviderToolResults = true,
    int maxAdditionalProviderToolResultSteps = 1,
    IncludeOptions? include,
    LLMCallOptions callOptions = const LLMCallOptions(),
    CancelToken? cancelToken,
  }) {
    final effectiveCallOptions = defaultCallOptions.mergedWith(callOptions);

    return object_streaming.streamObject(
      model: model,
      system: system,
      prompt: prompt,
      messages: messages,
      promptIr: promptIr,
      schema: schema,
      output: output,
      toolName: toolName,
      toolDescription: toolDescription,
      providerTools: providerTools,
      toolChoice: toolChoice,
      parallelToolCalls: parallelToolCalls,
      onProviderToolApprovalRequests: onProviderToolApprovalRequests,
      stopOnProviderToolApprovalRequests: stopOnProviderToolApprovalRequests,
      providerToolApprovalMaxSteps: providerToolApprovalMaxSteps,
      waitForDeferredProviderToolResults: waitForDeferredProviderToolResults,
      maxAdditionalProviderToolResultSteps:
          maxAdditionalProviderToolResultSteps,
      include: include ?? this.include,
      callOptions: effectiveCallOptions,
      cancelToken: cancelToken,
    );
  }
}

/// Alias class for closer naming parity with Vercel AI SDK (`ToolLoopAgent`).
///
/// This is a thin wrapper around [Agent] and intentionally keeps the Dart
/// API shape (e.g. [ToolSet]) instead of TypeScript record-based tools.
class ToolLoopAgent extends Agent {
  const ToolLoopAgent({
    required super.model,
    ToolSet? tools,
    super.repairToolCall,
    super.needsApproval,
    super.maxSteps = 10,
    super.continueOnToolError = true,
    super.include = const IncludeOptions(),
    super.defaultCallOptions = const LLMCallOptions(),
  }) : super(toolSet: tools);
}
