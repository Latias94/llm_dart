import 'package:llm_dart_core/llm_dart_core.dart';

import 'generate_text.dart' as low_level;
import 'prompt_input.dart';
import 'prompt_message_converters.dart';
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
    ToolCallRepair? repairToolCall,
    ToolApprovalCheck? needsApproval,
    int? maxSteps,
    bool? continueOnToolError,
    LLMCallOptions callOptions = const LLMCallOptions(),
    CancelToken? cancelToken,
  }) async {
    final effectiveToolSet = toolSet ?? this.toolSet;
    final effectiveRepair = repairToolCall ?? this.repairToolCall;
    final effectiveNeedsApproval = needsApproval ?? this.needsApproval;
    final effectiveMaxSteps = maxSteps ?? this.maxSteps;
    final effectiveContinueOnToolError =
        continueOnToolError ?? this.continueOnToolError;

    if (effectiveToolSet != null) {
      return runToolLoopWithToolSet(
        model: model,
        system: system,
        prompt: prompt,
        messages: messages,
        promptIr: promptIr,
        toolSet: effectiveToolSet,
        repairToolCall: effectiveRepair,
        needsApproval: effectiveNeedsApproval,
        maxSteps: effectiveMaxSteps,
        continueOnToolError: effectiveContinueOnToolError,
        include: include,
        defaultCallOptions: defaultCallOptions,
        callOptions: callOptions,
        cancelToken: cancelToken,
      );
    }

    final result = await low_level.generateText(
      model: model,
      system: system,
      prompt: prompt,
      messages: messages,
      promptIr: promptIr,
      toolSet: null,
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
    ToolCallRepair? repairToolCall,
    ToolApprovalCheck? needsApproval,
    ProviderToolApprovalHandler? onProviderToolApprovalRequests,
    bool stopOnProviderToolApprovalRequests = false,
    int providerToolApprovalMaxSteps = 10,
    int? maxSteps,
    bool? continueOnToolError,
    bool includeRawChunks = false,
    streaming.StreamTextOnStepFinishCallback? onStepFinish,
    streaming.StreamTextOnFinishCallback? onFinish,
    LLMCallOptions callOptions = const LLMCallOptions(),
    CancelToken? cancelToken,
  }) {
    return streaming.streamText(
      model: model,
      system: system,
      prompt: prompt,
      messages: messages,
      promptIr: promptIr,
      toolSet: toolSet ?? this.toolSet,
      tools: tools,
      repairToolCall: repairToolCall ?? this.repairToolCall,
      needsApproval: needsApproval ?? this.needsApproval,
      onProviderToolApprovalRequests: onProviderToolApprovalRequests,
      stopOnProviderToolApprovalRequests: stopOnProviderToolApprovalRequests,
      providerToolApprovalMaxSteps: providerToolApprovalMaxSteps,
      maxSteps: maxSteps ?? this.maxSteps,
      continueOnToolError: continueOnToolError ?? this.continueOnToolError,
      includeRawChunks: includeRawChunks,
      onStepFinish: onStepFinish,
      onFinish: onFinish,
      include: include,
      defaultCallOptions: defaultCallOptions,
      callOptions: callOptions,
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
