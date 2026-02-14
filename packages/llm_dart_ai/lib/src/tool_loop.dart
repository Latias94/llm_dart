import 'dart:async';
import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'content_part.dart';
import 'content_part_builders.dart';
import 'ensure_single_finish.dart';
import 'ensure_block_ids.dart';
import 'ensure_block_ends.dart';
import 'ensure_provider_metadata.dart';
import 'ensure_response_metadata.dart';
import 'ensure_stream_start.dart';
import 'metadata_fallbacks.dart';
import 'prompt_input.dart';
import 'prompt_message_converters.dart';
import 'response_messages.dart';
import 'tool_set.dart';
import 'tool_types.dart';
import 'types.dart';

class _ToolCallAccum {
  String? name;
  String callType = 'function';
  final StringBuffer arguments = StringBuffer();

  ToolCall toToolCall(String id) {
    return ToolCall(
      id: id,
      callType: callType,
      function: FunctionCall(
        name: name ?? '',
        arguments: arguments.toString(),
      ),
    );
  }
}

Prompt _appendChatMessageToPrompt(Prompt prompt, ChatMessage message) {
  return Prompt(
    messages: [
      ...prompt.messages,
      promptMessageFromChatMessage(message),
    ],
  );
}

bool _isFunctionToolCall(ToolCall toolCall) {
  return toolCall.callType.trim().toLowerCase() == 'function';
}

bool _isExecutableFunctionToolCall(ToolCall toolCall) {
  if (!_isFunctionToolCall(toolCall)) return false;
  return toolCall.function.name.trim().isNotEmpty;
}

GenerateTextResult _attachToolResultsToStepResult(
  GenerateTextResult base, {
  required List<ToolCall> toolCalls,
  required List<ToolResult> toolResults,
  required List<PromptMessage> responsePromptMessages,
}) {
  return GenerateTextResult(
    rawResponse: base.rawResponse,
    content: buildContentPartsBestEffort(
      text: base.text,
      thinking: base.thinking,
      sources: base.sources,
      files: base.files,
      toolCalls: toolCalls,
      toolResults: toolResults,
    ),
    text: base.text,
    thinking: base.thinking,
    toolCalls: toolCalls,
    toolResults: toolResults,
    usage: base.usage,
    totalUsage: base.totalUsage,
    finishReason: base.finishReason,
    requestMetadata: base.requestMetadata,
    responseMetadata: base.responseMetadata,
    responseMessages: base.responseMessages,
    responsePromptMessages: responsePromptMessages,
    steps: base.steps,
    sources: base.sources,
    files: base.files,
  );
}

Object? _decodeJsonIfPossible(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return const <String, dynamic>{};
  try {
    return jsonDecode(trimmed);
  } catch (_) {
    return raw;
  }
}

GenerateTextResult _attachToolApprovalRequestsToStepResult(
  GenerateTextResult base, {
  required List<ToolCall> toolCallsNeedingApproval,
}) {
  if (toolCallsNeedingApproval.isEmpty) return base;

  final existing = base.content;
  final out = <ContentPart>[];

  bool hasApprovalFor(String toolCallId) {
    for (final p in existing) {
      if (p is ToolApprovalRequestContentPart && p.toolCall.id == toolCallId) {
        return true;
      }
      if (p is ProviderToolApprovalRequestContentPart &&
          p.toolCallId == toolCallId) {
        return true;
      }
    }
    for (final p in out) {
      if (p is ToolApprovalRequestContentPart && p.toolCall.id == toolCallId) {
        return true;
      }
      if (p is ProviderToolApprovalRequestContentPart &&
          p.toolCallId == toolCallId) {
        return true;
      }
    }
    return false;
  }

  for (final part in existing) {
    out.add(part);
    if (part is! ToolCallContentPart) continue;
    final id = part.toolCall.id;
    final needing = toolCallsNeedingApproval.where((c) => c.id == id);
    for (final call in needing) {
      if (hasApprovalFor(call.id)) continue;
      out.add(
        ToolApprovalRequestContentPart(
          approvalId: call.id,
          toolCall: call,
        ),
      );
    }
  }

  // If any approval requests couldn't be attached to a tool-call part, append them.
  for (final call in toolCallsNeedingApproval) {
    if (hasApprovalFor(call.id)) continue;
    out.add(
      ToolApprovalRequestContentPart(
        approvalId: call.id,
        toolCall: call,
      ),
    );
  }

  return GenerateTextResult(
    rawResponse: base.rawResponse,
    content: List<ContentPart>.unmodifiable(out),
    text: base.text,
    thinking: base.thinking,
    toolCalls: base.toolCalls,
    toolResults: base.toolResults,
    usage: base.usage,
    totalUsage: base.totalUsage,
    finishReason: base.finishReason,
    requestMetadata: base.requestMetadata,
    responseMetadata: base.responseMetadata,
    responseMessages: base.responseMessages,
    responsePromptMessages: base.responsePromptMessages,
    steps: base.steps,
    sources: base.sources,
    files: base.files,
  );
}

List<ToolCall> _onlyLocalFunctionToolCalls(List<ToolCall>? toolCalls) {
  if (toolCalls == null || toolCalls.isEmpty) return const [];
  final filtered = toolCalls.where(_isExecutableFunctionToolCall).toList();
  return filtered.isEmpty ? const [] : List<ToolCall>.unmodifiable(filtered);
}

({List<ToolCall> executable, List<ToolCall> unexecutable})
    _partitionToolCallsByLocalHandler({
  required List<ToolCall> toolCalls,
  required Map<String, ToolCallHandler> toolHandlers,
}) {
  if (toolCalls.isEmpty) {
    return (executable: const <ToolCall>[], unexecutable: const <ToolCall>[]);
  }

  final executable = <ToolCall>[];
  final unexecutable = <ToolCall>[];

  for (final call in toolCalls) {
    if (toolHandlers.containsKey(call.function.name)) {
      executable.add(call);
    } else {
      unexecutable.add(call);
    }
  }

  return (
    executable: List<ToolCall>.unmodifiable(executable),
    unexecutable: List<ToolCall>.unmodifiable(unexecutable),
  );
}

Future<ChatResponse> _chatWithToolsBestEffort(
  ChatCapability model,
  List<ChatMessage> messages,
  List<Tool>? tools, {
  required LLMCallOptions callOptions,
  CancelToken? cancelToken,
}) {
  if (callOptions.isEmpty) {
    return model.chatWithTools(
      messages,
      tools,
      cancelToken: cancelToken,
    );
  }

  if (model is! ChatCallOptionsCapability) {
    throw const InvalidRequestError(
      'This model does not support call-level overrides (headers/body). '
      'Implement `ChatCallOptionsCapability` (or use a provider that does).',
    );
  }

  return (model as ChatCallOptionsCapability).chatWithToolsWithCallOptions(
    messages,
    tools,
    callOptions: callOptions,
    cancelToken: cancelToken,
  );
}

Future<ChatResponse> _chatPromptBestEffort(
  ChatCapability model,
  Prompt prompt, {
  required List<Tool>? tools,
  required LLMCallOptions callOptions,
  CancelToken? cancelToken,
}) {
  if (model is PromptChatCapability) {
    if (callOptions.isEmpty) {
      return (model as PromptChatCapability).chatPrompt(
        prompt,
        tools: tools,
        cancelToken: cancelToken,
      );
    }

    if (model is! PromptChatCallOptionsCapability) {
      throw const InvalidRequestError(
        'This model does not support call-level overrides for Prompt IR. '
        'Implement `PromptChatCallOptionsCapability` (or use a provider that does).',
      );
    }

    return (model as PromptChatCallOptionsCapability).chatPromptWithCallOptions(
      prompt,
      tools: tools,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  requirePromptCapabilityForFileReferenceParts(
    prompt: prompt,
    requiredCapabilityName: '`PromptChatCapability`',
  );

  return _chatWithToolsBestEffort(
    model,
    prompt.toChatMessages(),
    tools,
    callOptions: callOptions,
    cancelToken: cancelToken,
  );
}

/// Run a non-streaming tool loop:
/// - Call the model
/// - If tool calls are returned, execute them locally and send tool results back
/// - Repeat until no tool calls are returned, or [maxSteps] is exceeded
Future<ToolLoopResult> runToolLoop({
  required ChatCapability model,
  String? system,
  String? prompt,
  List<ChatMessage>? messages,
  Prompt? promptIr,
  List<Tool>? tools,
  required Map<String, ToolCallHandler> toolHandlers,
  ToolCallRepair? repairToolCall,
  Map<String, ToolApprovalCheck>? toolApprovalChecks,
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool continueOnToolError = true,
  IncludeOptions include = const IncludeOptions(),
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async {
  final effectiveCallOptions = defaultCallOptions.mergedWith(callOptions);
  final input = standardizePromptInput(
    system: system,
    prompt: prompt,
    messages: messages,
    promptIr: promptIr,
  );

  if (input is StandardizedPromptIr) {
    return _runToolLoopPromptIr(
      model: model,
      prompt: input.prompt,
      tools: tools,
      toolHandlers: toolHandlers,
      repairToolCall: repairToolCall,
      toolApprovalChecks: toolApprovalChecks,
      needsApproval: needsApproval,
      maxSteps: maxSteps,
      continueOnToolError: continueOnToolError,
      include: include,
      callOptions: effectiveCallOptions,
      cancelToken: cancelToken,
    );
  }

  final standardizedMessages = (input as StandardizedChatMessages).messages;

  if (maxSteps < 1) {
    throw const InvalidRequestError('maxSteps must be >= 1');
  }

  final defaultModelId = model is ModelIdentityCapability
      ? (model as ModelIdentityCapability).modelId
      : null;

  final workingMessages = List<ChatMessage>.from(standardizedMessages);
  final steps = <ToolLoopStep>[];

  for (var stepIndex = 0; stepIndex < maxSteps; stepIndex++) {
    final startedAt = DateTime.now().toUtc();
    final response = await _chatWithToolsBestEffort(
      model,
      workingMessages,
      tools,
      callOptions: effectiveCallOptions,
      cancelToken: cancelToken,
    );

    final toolCalls = _onlyLocalFunctionToolCalls(response.toolCalls);

    final stepResult = GenerateTextResult(
      rawResponse: response,
      content: buildContentPartsBestEffort(
        text: response.text,
        thinking: response.thinking,
        toolCalls: toolCalls,
        toolResults: const <ToolResult>[],
      ),
      text: response.text,
      thinking: response.thinking,
      toolCalls: toolCalls,
      usage: response.usage,
      finishReason: response is ChatResponseWithFinishReason
          ? response.finishReason
          : null,
      requestMetadata: requestMetadataWithInclude(
        response is ChatResponseWithRequestMetadata
            ? response.requestMetadata
            : null,
        include,
      ),
      responseMetadata: responseMetadataWithInclude(
        responseMetadataWithDefaults(
          response is ChatResponseWithResponseMetadata
              ? response.responseMetadata
              : null,
          startedAt,
          defaultModelId: defaultModelId,
        ),
        include,
      ),
      responseMessages: buildResponseMessagesBestEffort(response),
      responsePromptMessages: buildResponsePromptMessagesBestEffort(response),
    );

    if (toolCalls.isEmpty) {
      if (response.text != null) {
        workingMessages.add(ChatMessage.assistant(response.text!));
      }

      steps.add(
        ToolLoopStep(
          index: stepIndex,
          result: stepResult,
          toolCalls: const [],
          toolResults: const [],
          responseMetadata: stepResult.responseMetadata,
          requestMetadata: stepResult.requestMetadata,
          responsePromptMessages: stepResult.responsePromptMessages,
        ),
      );

      return ToolLoopResult(
        finalResult: stepResult,
        steps: steps,
        messages: List<ChatMessage>.unmodifiable(workingMessages),
        prompt: promptFromChatMessages(workingMessages),
      );
    }

    final partition = _partitionToolCallsByLocalHandler(
      toolCalls: toolCalls,
      toolHandlers: toolHandlers,
    );
    final executableToolCalls = partition.executable;
    final hasUnexecutableToolCalls = partition.unexecutable.isNotEmpty;

    final needingApproval = await _findToolCallsNeedingApproval(
      toolCalls: toolCalls,
      toolApprovalChecks: toolApprovalChecks,
      needsApproval: needsApproval,
      messages: workingMessages,
      stepIndex: stepIndex,
      cancelToken: cancelToken,
    );
    if (needingApproval.isNotEmpty) {
      final stepResultWithApprovals = _attachToolApprovalRequestsToStepResult(
        stepResult,
        toolCallsNeedingApproval: needingApproval,
      );
      steps.add(
        ToolLoopStep(
          index: stepIndex,
          result: stepResultWithApprovals,
          toolCalls: List<ToolCall>.unmodifiable(toolCalls),
          toolResults: const [],
          responseMetadata: stepResultWithApprovals.responseMetadata,
          requestMetadata: stepResultWithApprovals.requestMetadata,
          responsePromptMessages:
              stepResultWithApprovals.responsePromptMessages,
        ),
      );

      if (response is ChatResponseWithAssistantMessage) {
        workingMessages.add(response.assistantMessage);
      } else {
        workingMessages.add(ChatMessage.toolUse(toolCalls: toolCalls));
      }

      throw ToolApprovalRequiredError(
        state: ToolLoopBlockedState(
          stepIndex: stepIndex,
          stepResult: stepResultWithApprovals,
          toolCalls: List<ToolCall>.unmodifiable(toolCalls),
          toolCallsNeedingApproval:
              List<ToolCall>.unmodifiable(needingApproval),
          steps: List<ToolLoopStep>.unmodifiable(steps),
          messages: List<ChatMessage>.unmodifiable(workingMessages),
          prompt: promptFromChatMessages(workingMessages),
        ),
      );
    }

    final executed = await _executeToolCalls(
      toolCalls: executableToolCalls,
      tools: tools,
      toolHandlers: toolHandlers,
      repairToolCall: repairToolCall,
      continueOnToolError: continueOnToolError,
      cancelToken: cancelToken,
    );

    final stepResponsePromptMessages = executed.isEmpty
        ? stepResult.responsePromptMessages
        : [
            ...stepResult.responsePromptMessages,
            buildToolResultPromptMessageBestEffort(
              toolCalls: toolCalls,
              toolResults: executed,
            ),
          ];

    final stepResultWithTools = executed.isEmpty
        ? stepResult
        : _attachToolResultsToStepResult(
            stepResult,
            toolCalls: toolCalls,
            toolResults: executed,
            responsePromptMessages: stepResponsePromptMessages,
          );

    steps.add(
      ToolLoopStep(
        index: stepIndex,
        result: stepResultWithTools,
        toolCalls: List<ToolCall>.unmodifiable(toolCalls),
        toolResults: List<ToolResult>.unmodifiable(executed),
        responseMetadata: stepResult.responseMetadata,
        requestMetadata: stepResult.requestMetadata,
        responsePromptMessages: stepResponsePromptMessages,
      ),
    );

    // Persist the tool call request and tool results in message history.
    if (response is ChatResponseWithAssistantMessage) {
      workingMessages.add(response.assistantMessage);
    } else {
      workingMessages.add(ChatMessage.toolUse(toolCalls: toolCalls));
    }
    if (executed.isNotEmpty) {
      workingMessages.add(
        ChatMessage.toolResult(
          results: _toToolResultCalls(toolCalls, executed),
        ),
      );
    }

    // AI SDK parity: only continue the loop if all tool calls can be executed
    // locally. If any tool calls lack a handler, return the current step.
    if (hasUnexecutableToolCalls) {
      return ToolLoopResult(
        finalResult: stepResultWithTools,
        steps: steps,
        messages: List<ChatMessage>.unmodifiable(workingMessages),
        prompt: promptFromChatMessages(workingMessages),
      );
    }
  }

  throw InvalidRequestError(
    'Tool loop exceeded maxSteps ($maxSteps). '
    'The model kept requesting tools and did not produce a final response.',
  );
}

Prompt _sanitizePromptForLegacyChat(Prompt prompt) {
  PromptMessage sanitizeMessage(PromptMessage message) {
    if (message.parts.isEmpty) return message;

    final sanitizedParts = <PromptPart>[];
    for (final part in message.parts) {
      switch (part) {
        case FileUrlPart(:final mime, :final text):
          final trimmedText = text?.trim() ?? '';
          sanitizedParts.add(
            TextPart(
              trimmedText.isNotEmpty
                  ? trimmedText
                  : '[FileUrlPart ${mime.mimeType}]',
              providerOptions: part.providerOptions,
            ),
          );
          break;

        case FileIdPart(:final mime, :final text):
          final trimmedText = text?.trim() ?? '';
          sanitizedParts.add(
            TextPart(
              trimmedText.isNotEmpty
                  ? trimmedText
                  : '[FileIdPart ${mime.mimeType}]',
              providerOptions: part.providerOptions,
            ),
          );
          break;

        default:
          sanitizedParts.add(part);
          break;
      }
    }

    return PromptMessage(
      role: message.role,
      parts: sanitizedParts,
      name: message.name,
      providerOptions: message.providerOptions,
      protocolPayloads: message.protocolPayloads,
    );
  }

  return Prompt(
    messages: prompt.messages.map(sanitizeMessage).toList(growable: false),
  );
}

List<ChatMessage> _promptToLegacyChatMessagesBestEffort(Prompt prompt) {
  return _sanitizePromptForLegacyChat(prompt).toChatMessages();
}

Future<ToolLoopResult> _runToolLoopPromptIr({
  required ChatCapability model,
  required Prompt prompt,
  List<Tool>? tools,
  required Map<String, ToolCallHandler> toolHandlers,
  ToolCallRepair? repairToolCall,
  Map<String, ToolApprovalCheck>? toolApprovalChecks,
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool continueOnToolError = true,
  IncludeOptions include = const IncludeOptions(),
  required LLMCallOptions callOptions,
  CancelToken? cancelToken,
}) async {
  if (model is! PromptChatCapability) {
    requirePromptCapabilityForFileReferenceParts(
      prompt: prompt,
      requiredCapabilityName: '`PromptChatCapability`',
    );
    return runToolLoop(
      model: model,
      messages: prompt.toChatMessages(),
      tools: tools,
      toolHandlers: toolHandlers,
      repairToolCall: repairToolCall,
      toolApprovalChecks: toolApprovalChecks,
      needsApproval: needsApproval,
      maxSteps: maxSteps,
      continueOnToolError: continueOnToolError,
      include: include,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  if (maxSteps < 1) {
    throw const InvalidRequestError('maxSteps must be >= 1');
  }

  final defaultModelId = model is ModelIdentityCapability
      ? (model as ModelIdentityCapability).modelId
      : null;

  var workingPrompt = prompt;
  final workingMessages = List<ChatMessage>.from(
    _promptToLegacyChatMessagesBestEffort(prompt),
  );
  final steps = <ToolLoopStep>[];

  for (var stepIndex = 0; stepIndex < maxSteps; stepIndex++) {
    final startedAt = DateTime.now().toUtc();
    final response = await _chatPromptBestEffort(
      model,
      workingPrompt,
      tools: tools,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );

    final toolCalls = _onlyLocalFunctionToolCalls(response.toolCalls);

    final stepResult = GenerateTextResult(
      rawResponse: response,
      content: buildContentPartsBestEffort(
        text: response.text,
        thinking: response.thinking,
        toolCalls: toolCalls,
        toolResults: const <ToolResult>[],
      ),
      text: response.text,
      thinking: response.thinking,
      toolCalls: toolCalls,
      usage: response.usage,
      finishReason: response is ChatResponseWithFinishReason
          ? response.finishReason
          : null,
      requestMetadata: requestMetadataWithInclude(
        response is ChatResponseWithRequestMetadata
            ? response.requestMetadata
            : null,
        include,
      ),
      responseMetadata: responseMetadataWithInclude(
        responseMetadataWithDefaults(
          response is ChatResponseWithResponseMetadata
              ? response.responseMetadata
              : null,
          startedAt,
          defaultModelId: defaultModelId,
        ),
        include,
      ),
      responseMessages: buildResponseMessagesBestEffort(response),
      responsePromptMessages: buildResponsePromptMessagesBestEffort(response),
    );

    if (toolCalls.isEmpty) {
      if (response is ChatResponseWithAssistantMessage) {
        workingMessages.add(response.assistantMessage);
        workingPrompt = _appendChatMessageToPrompt(
            workingPrompt, response.assistantMessage);
      } else if (response.text != null && response.text!.isNotEmpty) {
        final assistant = ChatMessage.assistant(response.text!);
        workingMessages.add(assistant);
        workingPrompt = _appendChatMessageToPrompt(workingPrompt, assistant);
      }

      steps.add(
        ToolLoopStep(
          index: stepIndex,
          result: stepResult,
          toolCalls: const [],
          toolResults: const [],
          responseMetadata: stepResult.responseMetadata,
          requestMetadata: stepResult.requestMetadata,
          responsePromptMessages: stepResult.responsePromptMessages,
        ),
      );

      return ToolLoopResult(
        finalResult: stepResult,
        steps: steps,
        messages: List<ChatMessage>.unmodifiable(workingMessages),
        prompt: workingPrompt,
      );
    }

    final partition = _partitionToolCallsByLocalHandler(
      toolCalls: toolCalls,
      toolHandlers: toolHandlers,
    );
    final executableToolCalls = partition.executable;
    final hasUnexecutableToolCalls = partition.unexecutable.isNotEmpty;

    final needingApproval = await _findToolCallsNeedingApproval(
      toolCalls: toolCalls,
      toolApprovalChecks: toolApprovalChecks,
      needsApproval: needsApproval,
      messages: workingMessages,
      stepIndex: stepIndex,
      cancelToken: cancelToken,
    );
    if (needingApproval.isNotEmpty) {
      final stepResultWithApprovals = _attachToolApprovalRequestsToStepResult(
        stepResult,
        toolCallsNeedingApproval: needingApproval,
      );
      steps.add(
        ToolLoopStep(
          index: stepIndex,
          result: stepResultWithApprovals,
          toolCalls: List<ToolCall>.unmodifiable(toolCalls),
          toolResults: const [],
          responseMetadata: stepResultWithApprovals.responseMetadata,
          requestMetadata: stepResultWithApprovals.requestMetadata,
          responsePromptMessages:
              stepResultWithApprovals.responsePromptMessages,
        ),
      );

      final assistantMessage = response is ChatResponseWithAssistantMessage
          ? response.assistantMessage
          : ChatMessage.toolUse(
              toolCalls: toolCalls,
              content: response.text ?? '',
            );

      workingMessages.add(assistantMessage);
      workingPrompt =
          _appendChatMessageToPrompt(workingPrompt, assistantMessage);

      throw ToolApprovalRequiredError(
        state: ToolLoopBlockedState(
          stepIndex: stepIndex,
          stepResult: stepResultWithApprovals,
          toolCalls: List<ToolCall>.unmodifiable(toolCalls),
          toolCallsNeedingApproval:
              List<ToolCall>.unmodifiable(needingApproval),
          steps: List<ToolLoopStep>.unmodifiable(steps),
          messages: List<ChatMessage>.unmodifiable(workingMessages),
          prompt: workingPrompt,
        ),
      );
    }

    final executed = await _executeToolCalls(
      toolCalls: executableToolCalls,
      tools: tools,
      toolHandlers: toolHandlers,
      repairToolCall: repairToolCall,
      continueOnToolError: continueOnToolError,
      cancelToken: cancelToken,
    );

    final stepResponsePromptMessages = executed.isEmpty
        ? stepResult.responsePromptMessages
        : [
            ...stepResult.responsePromptMessages,
            buildToolResultPromptMessageBestEffort(
              toolCalls: toolCalls,
              toolResults: executed,
            ),
          ];

    final stepResultWithTools = executed.isEmpty
        ? stepResult
        : _attachToolResultsToStepResult(
            stepResult,
            toolCalls: toolCalls,
            toolResults: executed,
            responsePromptMessages: stepResponsePromptMessages,
          );

    steps.add(
      ToolLoopStep(
        index: stepIndex,
        result: stepResultWithTools,
        toolCalls: List<ToolCall>.unmodifiable(toolCalls),
        toolResults: List<ToolResult>.unmodifiable(executed),
        responseMetadata: stepResult.responseMetadata,
        requestMetadata: stepResult.requestMetadata,
        responsePromptMessages: stepResponsePromptMessages,
      ),
    );

    final assistantMessage = response is ChatResponseWithAssistantMessage
        ? response.assistantMessage
        : ChatMessage.toolUse(
            toolCalls: toolCalls,
            content: response.text ?? '',
          );
    workingMessages.add(assistantMessage);
    workingPrompt = _appendChatMessageToPrompt(workingPrompt, assistantMessage);

    if (executed.isNotEmpty) {
      final toolResultMessage = ChatMessage.toolResult(
        results: _toToolResultCalls(toolCalls, executed),
      );
      workingMessages.add(toolResultMessage);
      workingPrompt =
          _appendChatMessageToPrompt(workingPrompt, toolResultMessage);
    }

    // AI SDK parity: only continue the loop if all tool calls can be executed
    // locally. If any tool calls lack a handler, return the current step.
    if (hasUnexecutableToolCalls) {
      return ToolLoopResult(
        finalResult: stepResultWithTools,
        steps: steps,
        messages: List<ChatMessage>.unmodifiable(workingMessages),
        prompt: workingPrompt,
      );
    }
  }

  throw InvalidRequestError(
    'Tool loop exceeded maxSteps ($maxSteps). '
    'The model kept requesting tools and did not produce a final response.',
  );
}

/// Run a non-streaming tool loop, but stop and return state when approval is required.
Future<ToolLoopRunOutcome> runToolLoopUntilBlocked({
  required ChatCapability model,
  String? system,
  String? prompt,
  List<ChatMessage>? messages,
  Prompt? promptIr,
  List<Tool>? tools,
  required Map<String, ToolCallHandler> toolHandlers,
  ToolCallRepair? repairToolCall,
  Map<String, ToolApprovalCheck>? toolApprovalChecks,
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool continueOnToolError = true,
  IncludeOptions include = const IncludeOptions(),
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async {
  final effectiveCallOptions = defaultCallOptions.mergedWith(callOptions);
  final input = standardizePromptInput(
    system: system,
    prompt: prompt,
    messages: messages,
    promptIr: promptIr,
  );

  if (input is StandardizedPromptIr) {
    return _runToolLoopUntilBlockedPromptIr(
      model: model,
      prompt: input.prompt,
      tools: tools,
      toolHandlers: toolHandlers,
      repairToolCall: repairToolCall,
      toolApprovalChecks: toolApprovalChecks,
      needsApproval: needsApproval,
      maxSteps: maxSteps,
      continueOnToolError: continueOnToolError,
      include: include,
      callOptions: effectiveCallOptions,
      cancelToken: cancelToken,
    );
  }

  final standardizedMessages = (input as StandardizedChatMessages).messages;

  if (maxSteps < 1) {
    throw const InvalidRequestError('maxSteps must be >= 1');
  }

  final defaultModelId = model is ModelIdentityCapability
      ? (model as ModelIdentityCapability).modelId
      : null;

  final workingMessages = List<ChatMessage>.from(standardizedMessages);
  final steps = <ToolLoopStep>[];

  for (var stepIndex = 0; stepIndex < maxSteps; stepIndex++) {
    final startedAt = DateTime.now().toUtc();
    final response = await _chatWithToolsBestEffort(
      model,
      workingMessages,
      tools,
      callOptions: effectiveCallOptions,
      cancelToken: cancelToken,
    );

    final toolCalls = _onlyLocalFunctionToolCalls(response.toolCalls);

    final stepResult = GenerateTextResult(
      rawResponse: response,
      content: buildContentPartsBestEffort(
        text: response.text,
        thinking: response.thinking,
        toolCalls: toolCalls,
        toolResults: const <ToolResult>[],
      ),
      text: response.text,
      thinking: response.thinking,
      toolCalls: toolCalls,
      usage: response.usage,
      finishReason: response is ChatResponseWithFinishReason
          ? response.finishReason
          : null,
      requestMetadata: requestMetadataWithInclude(
        response is ChatResponseWithRequestMetadata
            ? response.requestMetadata
            : null,
        include,
      ),
      responseMetadata: responseMetadataWithInclude(
        responseMetadataWithDefaults(
          response is ChatResponseWithResponseMetadata
              ? response.responseMetadata
              : null,
          startedAt,
          defaultModelId: defaultModelId,
        ),
        include,
      ),
      responseMessages: buildResponseMessagesBestEffort(response),
      responsePromptMessages: buildResponsePromptMessagesBestEffort(response),
    );

    if (toolCalls.isEmpty) {
      if (response.text != null) {
        workingMessages.add(ChatMessage.assistant(response.text!));
      }

      steps.add(
        ToolLoopStep(
          index: stepIndex,
          result: stepResult,
          toolCalls: const [],
          toolResults: const [],
          responseMetadata: stepResult.responseMetadata,
          requestMetadata: stepResult.requestMetadata,
          responsePromptMessages: stepResult.responsePromptMessages,
        ),
      );

      return ToolLoopCompleted(
        ToolLoopResult(
          finalResult: stepResult,
          steps: steps,
          messages: List<ChatMessage>.unmodifiable(workingMessages),
          prompt: promptFromChatMessages(workingMessages),
        ),
      );
    }

    final partition = _partitionToolCallsByLocalHandler(
      toolCalls: toolCalls,
      toolHandlers: toolHandlers,
    );
    final executableToolCalls = partition.executable;
    final hasUnexecutableToolCalls = partition.unexecutable.isNotEmpty;

    final needingApproval = await _findToolCallsNeedingApproval(
      toolCalls: toolCalls,
      toolApprovalChecks: toolApprovalChecks,
      needsApproval: needsApproval,
      messages: workingMessages,
      stepIndex: stepIndex,
      cancelToken: cancelToken,
    );
    if (needingApproval.isNotEmpty) {
      final stepResultWithApprovals = _attachToolApprovalRequestsToStepResult(
        stepResult,
        toolCallsNeedingApproval: needingApproval,
      );
      steps.add(
        ToolLoopStep(
          index: stepIndex,
          result: stepResultWithApprovals,
          toolCalls: List<ToolCall>.unmodifiable(toolCalls),
          toolResults: const [],
          responseMetadata: stepResultWithApprovals.responseMetadata,
          requestMetadata: stepResultWithApprovals.requestMetadata,
          responsePromptMessages:
              stepResultWithApprovals.responsePromptMessages,
        ),
      );

      if (response is ChatResponseWithAssistantMessage) {
        workingMessages.add(response.assistantMessage);
      } else {
        workingMessages.add(ChatMessage.toolUse(toolCalls: toolCalls));
      }

      return ToolLoopBlocked(
        ToolLoopBlockedState(
          stepIndex: stepIndex,
          stepResult: stepResultWithApprovals,
          toolCalls: List<ToolCall>.unmodifiable(toolCalls),
          toolCallsNeedingApproval:
              List<ToolCall>.unmodifiable(needingApproval),
          steps: List<ToolLoopStep>.unmodifiable(steps),
          messages: List<ChatMessage>.unmodifiable(workingMessages),
          prompt: promptFromChatMessages(workingMessages),
        ),
      );
    }

    final executed = await _executeToolCalls(
      toolCalls: executableToolCalls,
      tools: tools,
      toolHandlers: toolHandlers,
      repairToolCall: repairToolCall,
      continueOnToolError: continueOnToolError,
      cancelToken: cancelToken,
    );

    final stepResponsePromptMessages = executed.isEmpty
        ? stepResult.responsePromptMessages
        : [
            ...stepResult.responsePromptMessages,
            buildToolResultPromptMessageBestEffort(
              toolCalls: toolCalls,
              toolResults: executed,
            ),
          ];

    final stepResultWithTools = executed.isEmpty
        ? stepResult
        : _attachToolResultsToStepResult(
            stepResult,
            toolCalls: toolCalls,
            toolResults: executed,
            responsePromptMessages: stepResponsePromptMessages,
          );

    steps.add(
      ToolLoopStep(
        index: stepIndex,
        result: stepResultWithTools,
        toolCalls: List<ToolCall>.unmodifiable(toolCalls),
        toolResults: List<ToolResult>.unmodifiable(executed),
        responseMetadata: stepResult.responseMetadata,
        requestMetadata: stepResult.requestMetadata,
        responsePromptMessages: stepResponsePromptMessages,
      ),
    );

    if (response is ChatResponseWithAssistantMessage) {
      workingMessages.add(response.assistantMessage);
    } else {
      workingMessages.add(ChatMessage.toolUse(toolCalls: toolCalls));
    }
    if (executed.isNotEmpty) {
      workingMessages.add(
        ChatMessage.toolResult(
          results: _toToolResultCalls(toolCalls, executed),
        ),
      );
    }

    // AI SDK parity: only continue the loop if all tool calls can be executed
    // locally. If any tool calls lack a handler, return the current step.
    if (hasUnexecutableToolCalls) {
      return ToolLoopCompleted(
        ToolLoopResult(
          finalResult: stepResultWithTools,
          steps: steps,
          messages: List<ChatMessage>.unmodifiable(workingMessages),
          prompt: promptFromChatMessages(workingMessages),
        ),
      );
    }
  }

  throw InvalidRequestError(
    'Tool loop exceeded maxSteps ($maxSteps). '
    'The model kept requesting tools and did not produce a final response.',
  );
}

/// Resume a previously blocked tool loop by applying tool approval decisions.
///
/// This is intended to close the "tool approval" loop in an AI SDK-compatible
/// way:
/// 1) Run [runToolLoopUntilBlocked] until it returns [ToolLoopBlocked].
/// 2) Ask the user to approve/deny [ToolLoopBlockedState.toolCallsNeedingApproval].
/// 3) Call this function with the collected [ToolApprovalDecision]s to execute
///    tools (or emit execution-denied tool outputs) and continue the loop.
Future<ToolLoopRunOutcome> resumeToolLoopUntilBlocked({
  required ChatCapability model,
  required ToolLoopBlockedState blockedState,
  required List<ToolApprovalDecision> approvals,
  List<Tool>? tools,
  required Map<String, ToolCallHandler> toolHandlers,
  ToolCallRepair? repairToolCall,
  Map<String, ToolApprovalCheck>? toolApprovalChecks,
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool continueOnToolError = true,
  IncludeOptions include = const IncludeOptions(),
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async {
  final effectiveCallOptions = defaultCallOptions.mergedWith(callOptions);
  if (maxSteps < 1) {
    throw const InvalidRequestError('maxSteps must be >= 1');
  }

  final startStepIndex = blockedState.stepIndex + 1;
  if (startStepIndex >= maxSteps) {
    throw InvalidRequestError(
      'Cannot resume blocked tool loop at stepIndex=${blockedState.stepIndex} '
      'with maxSteps=$maxSteps. Increase maxSteps to allow at least one more model call.',
    );
  }

  final decisionsByApprovalId = <String, ToolApprovalDecision>{};
  for (final decision in approvals) {
    final approvalId = decision.approvalId.trim();
    if (approvalId.isEmpty) {
      throw const InvalidRequestError(
          'ToolApprovalDecision.approvalId must be non-empty.');
    }
    final existing = decisionsByApprovalId[approvalId];
    if (existing != null) {
      throw InvalidRequestError(
          'Duplicate ToolApprovalDecision for approvalId "$approvalId".');
    }
    decisionsByApprovalId[approvalId] = decision;
  }

  final needingApprovalIds = <String>{
    for (final call in blockedState.toolCallsNeedingApproval) call.id,
  };

  for (final approvalId in needingApprovalIds) {
    if (!decisionsByApprovalId.containsKey(approvalId)) {
      throw InvalidRequestError(
        'Missing ToolApprovalDecision for approvalId "$approvalId".',
      );
    }
  }

  final toolResults = await _executeToolCallsWithApprovals(
    toolCalls: blockedState.toolCalls,
    tools: tools,
    toolHandlers: toolHandlers,
    repairToolCall: repairToolCall,
    continueOnToolError: continueOnToolError,
    needingApprovalIds: needingApprovalIds,
    decisionsByApprovalId: decisionsByApprovalId,
    cancelToken: cancelToken,
  );

  final toolMessage = _buildToolApprovalAndResultPromptMessageBestEffort(
    toolCalls: blockedState.toolCalls,
    toolResults: toolResults,
    needingApprovalIds: needingApprovalIds,
    decisionsByApprovalId: decisionsByApprovalId,
  );

  final updatedSteps = _patchBlockedStepWithToolResults(
    blockedState: blockedState,
    toolResults: toolResults,
    toolMessage: toolMessage,
  );

  final resumedMessages = <ChatMessage>[
    ...blockedState.messages,
    ChatMessage.toolResult(
      results: encodeToolResultsAsToolCalls(
        toolCalls: blockedState.toolCalls,
        toolResults: toolResults,
      ),
    ),
  ];

  final resumedPrompt = blockedState.prompt == null
      ? null
      : Prompt(
          messages: [
            ...blockedState.prompt!.messages,
            toolMessage,
          ],
        );

  if (resumedPrompt != null && model is PromptChatCapability) {
    return _continueToolLoopUntilBlockedPromptIrFromState(
      model: model,
      prompt: resumedPrompt,
      initialMessages: resumedMessages,
      initialSteps: updatedSteps,
      startStepIndex: startStepIndex,
      tools: tools,
      toolHandlers: toolHandlers,
      repairToolCall: repairToolCall,
      toolApprovalChecks: toolApprovalChecks,
      needsApproval: needsApproval,
      maxSteps: maxSteps,
      continueOnToolError: continueOnToolError,
      include: include,
      callOptions: effectiveCallOptions,
      cancelToken: cancelToken,
    );
  }

  return _continueToolLoopUntilBlockedFromState(
    model: model,
    initialMessages: resumedMessages,
    initialSteps: updatedSteps,
    startStepIndex: startStepIndex,
    tools: tools,
    toolHandlers: toolHandlers,
    repairToolCall: repairToolCall,
    toolApprovalChecks: toolApprovalChecks,
    needsApproval: needsApproval,
    maxSteps: maxSteps,
    continueOnToolError: continueOnToolError,
    include: include,
    callOptions: effectiveCallOptions,
    cancelToken: cancelToken,
  );
}

/// Resume variant of [runToolLoop] that throws [ToolApprovalRequiredError] again
/// if the loop becomes blocked after resuming.
Future<ToolLoopResult> resumeToolLoop({
  required ChatCapability model,
  required ToolLoopBlockedState blockedState,
  required List<ToolApprovalDecision> approvals,
  List<Tool>? tools,
  required Map<String, ToolCallHandler> toolHandlers,
  ToolCallRepair? repairToolCall,
  Map<String, ToolApprovalCheck>? toolApprovalChecks,
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool continueOnToolError = true,
  IncludeOptions include = const IncludeOptions(),
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async {
  final outcome = await resumeToolLoopUntilBlocked(
    model: model,
    blockedState: blockedState,
    approvals: approvals,
    tools: tools,
    toolHandlers: toolHandlers,
    repairToolCall: repairToolCall,
    toolApprovalChecks: toolApprovalChecks,
    needsApproval: needsApproval,
    maxSteps: maxSteps,
    continueOnToolError: continueOnToolError,
    include: include,
    defaultCallOptions: defaultCallOptions,
    callOptions: callOptions,
    cancelToken: cancelToken,
  );

  switch (outcome) {
    case ToolLoopCompleted(:final result):
      return result;
    case ToolLoopBlocked(:final state):
      throw ToolApprovalRequiredError(state: state);
  }
}

ToolLoopStep _withToolResultsOnStep({
  required ToolLoopStep step,
  required List<ToolResult> toolResults,
  required PromptMessage toolMessage,
}) {
  return ToolLoopStep(
    index: step.index,
    result: step.result,
    toolCalls: step.toolCalls,
    toolResults: List<ToolResult>.unmodifiable(toolResults),
    responseMetadata: step.responseMetadata,
    requestMetadata: step.requestMetadata,
    responsePromptMessages: [
      ...step.responsePromptMessages,
      toolMessage,
    ],
  );
}

List<ToolLoopStep> _patchBlockedStepWithToolResults({
  required ToolLoopBlockedState blockedState,
  required List<ToolResult> toolResults,
  required PromptMessage toolMessage,
}) {
  final existingSteps = blockedState.steps;
  final updated = <ToolLoopStep>[];
  var patched = false;

  for (final step in existingSteps) {
    if (step.index == blockedState.stepIndex) {
      updated.add(
        _withToolResultsOnStep(
          step: step,
          toolResults: toolResults,
          toolMessage: toolMessage,
        ),
      );
      patched = true;
    } else {
      updated.add(step);
    }
  }

  if (!patched) {
    updated.add(
      ToolLoopStep(
        index: blockedState.stepIndex,
        result: blockedState.stepResult,
        toolCalls: List<ToolCall>.unmodifiable(blockedState.toolCalls),
        toolResults: List<ToolResult>.unmodifiable(toolResults),
        responseMetadata: blockedState.stepResult.responseMetadata,
        requestMetadata: blockedState.stepResult.requestMetadata,
        responsePromptMessages: [
          ...blockedState.stepResult.responsePromptMessages,
          toolMessage,
        ],
      ),
    );
  }

  return List<ToolLoopStep>.unmodifiable(updated);
}

PromptMessage _buildToolApprovalAndResultPromptMessageBestEffort({
  required List<ToolCall> toolCalls,
  required List<ToolResult> toolResults,
  required Set<String> needingApprovalIds,
  required Map<String, ToolApprovalDecision> decisionsByApprovalId,
}) {
  final resultsById = <String>{for (final r in toolResults) r.toolCallId};

  final approvalParts = <PromptPart>[];
  for (final call in toolCalls) {
    if (!needingApprovalIds.contains(call.id)) continue;
    if (!resultsById.contains(call.id)) continue;
    final decision = decisionsByApprovalId[call.id];
    if (decision == null) continue;
    approvalParts.add(
      ToolApprovalResponsePart(
        approvalId: decision.approvalId,
        approved: decision.approved,
        reason: decision.reason,
      ),
    );
  }

  final toolResultMessage = buildToolResultPromptMessageBestEffort(
    toolCalls: toolCalls,
    toolResults: toolResults,
  );

  if (approvalParts.isEmpty) return toolResultMessage;

  return PromptMessage.tool(
    parts: [
      ...approvalParts,
      ...toolResultMessage.parts,
    ],
  );
}

Future<List<ToolResult>> _executeToolCallsWithApprovals({
  required List<ToolCall> toolCalls,
  required List<Tool>? tools,
  required Map<String, ToolCallHandler> toolHandlers,
  required ToolCallRepair? repairToolCall,
  required bool continueOnToolError,
  required Set<String> needingApprovalIds,
  required Map<String, ToolApprovalDecision> decisionsByApprovalId,
  CancelToken? cancelToken,
}) async {
  final results = <ToolResult>[];

  ToolResult deniedResult(
    ToolCall toolCall, {
    String? reason,
  }) {
    final payload = <String, dynamic>{
      'type': 'execution-denied',
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    };
    return ToolResult.success(
      toolCallId: toolCall.id,
      result: payload,
    );
  }

  for (final toolCall in toolCalls) {
    if (needingApprovalIds.contains(toolCall.id)) {
      final decision = decisionsByApprovalId[toolCall.id];
      if (decision == null) {
        throw InvalidRequestError(
          'Missing ToolApprovalDecision for approvalId "${toolCall.id}".',
        );
      }
      if (!decision.approved) {
        results.add(deniedResult(toolCall, reason: decision.reason));
        continue;
      }
    }

    final executed = await _executeToolCalls(
      toolCalls: [toolCall],
      tools: tools,
      toolHandlers: toolHandlers,
      repairToolCall: repairToolCall,
      continueOnToolError: continueOnToolError,
      cancelToken: cancelToken,
    );

    if (executed.isEmpty) {
      continue;
    }

    final result = executed.first;
    results.add(result);

    if (result.isError && !continueOnToolError) {
      break;
    }
  }

  return results;
}

Future<ToolLoopRunOutcome> _continueToolLoopUntilBlockedFromState({
  required ChatCapability model,
  required List<ChatMessage> initialMessages,
  required List<ToolLoopStep> initialSteps,
  required int startStepIndex,
  List<Tool>? tools,
  required Map<String, ToolCallHandler> toolHandlers,
  ToolCallRepair? repairToolCall,
  Map<String, ToolApprovalCheck>? toolApprovalChecks,
  ToolApprovalCheck? needsApproval,
  required int maxSteps,
  required bool continueOnToolError,
  required IncludeOptions include,
  required LLMCallOptions callOptions,
  CancelToken? cancelToken,
}) async {
  final defaultModelId = model is ModelIdentityCapability
      ? (model as ModelIdentityCapability).modelId
      : null;

  final workingMessages = List<ChatMessage>.from(initialMessages);
  final steps = <ToolLoopStep>[...initialSteps];

  for (var stepIndex = startStepIndex; stepIndex < maxSteps; stepIndex++) {
    final startedAt = DateTime.now().toUtc();
    final response = await _chatWithToolsBestEffort(
      model,
      workingMessages,
      tools,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );

    final toolCalls = _onlyLocalFunctionToolCalls(response.toolCalls);

    final stepResult = GenerateTextResult(
      rawResponse: response,
      content: buildContentPartsBestEffort(
        text: response.text,
        thinking: response.thinking,
        toolCalls: toolCalls,
        toolResults: const <ToolResult>[],
      ),
      text: response.text,
      thinking: response.thinking,
      toolCalls: toolCalls,
      usage: response.usage,
      finishReason: response is ChatResponseWithFinishReason
          ? response.finishReason
          : null,
      requestMetadata: requestMetadataWithInclude(
        response is ChatResponseWithRequestMetadata
            ? response.requestMetadata
            : null,
        include,
      ),
      responseMetadata: responseMetadataWithInclude(
        responseMetadataWithDefaults(
          response is ChatResponseWithResponseMetadata
              ? response.responseMetadata
              : null,
          startedAt,
          defaultModelId: defaultModelId,
        ),
        include,
      ),
      responseMessages: buildResponseMessagesBestEffort(response),
      responsePromptMessages: buildResponsePromptMessagesBestEffort(response),
    );

    if (toolCalls.isEmpty) {
      if (response.text != null) {
        workingMessages.add(ChatMessage.assistant(response.text!));
      }

      steps.add(
        ToolLoopStep(
          index: stepIndex,
          result: stepResult,
          toolCalls: const [],
          toolResults: const [],
          responseMetadata: stepResult.responseMetadata,
          requestMetadata: stepResult.requestMetadata,
          responsePromptMessages: stepResult.responsePromptMessages,
        ),
      );

      return ToolLoopCompleted(
        ToolLoopResult(
          finalResult: stepResult,
          steps: steps,
          messages: List<ChatMessage>.unmodifiable(workingMessages),
          prompt: promptFromChatMessages(workingMessages),
        ),
      );
    }

    final partition = _partitionToolCallsByLocalHandler(
      toolCalls: toolCalls,
      toolHandlers: toolHandlers,
    );
    final executableToolCalls = partition.executable;
    final hasUnexecutableToolCalls = partition.unexecutable.isNotEmpty;

    final needingApproval = await _findToolCallsNeedingApproval(
      toolCalls: toolCalls,
      toolApprovalChecks: toolApprovalChecks,
      needsApproval: needsApproval,
      messages: workingMessages,
      stepIndex: stepIndex,
      cancelToken: cancelToken,
    );
    if (needingApproval.isNotEmpty) {
      final stepResultWithApprovals = _attachToolApprovalRequestsToStepResult(
        stepResult,
        toolCallsNeedingApproval: needingApproval,
      );
      steps.add(
        ToolLoopStep(
          index: stepIndex,
          result: stepResultWithApprovals,
          toolCalls: List<ToolCall>.unmodifiable(toolCalls),
          toolResults: const [],
          responseMetadata: stepResultWithApprovals.responseMetadata,
          requestMetadata: stepResultWithApprovals.requestMetadata,
          responsePromptMessages:
              stepResultWithApprovals.responsePromptMessages,
        ),
      );

      if (response is ChatResponseWithAssistantMessage) {
        workingMessages.add(response.assistantMessage);
      } else {
        workingMessages.add(ChatMessage.toolUse(toolCalls: toolCalls));
      }

      return ToolLoopBlocked(
        ToolLoopBlockedState(
          stepIndex: stepIndex,
          stepResult: stepResultWithApprovals,
          toolCalls: List<ToolCall>.unmodifiable(toolCalls),
          toolCallsNeedingApproval:
              List<ToolCall>.unmodifiable(needingApproval),
          steps: List<ToolLoopStep>.unmodifiable(steps),
          messages: List<ChatMessage>.unmodifiable(workingMessages),
          prompt: promptFromChatMessages(workingMessages),
        ),
      );
    }

    final executed = await _executeToolCalls(
      toolCalls: executableToolCalls,
      tools: tools,
      toolHandlers: toolHandlers,
      repairToolCall: repairToolCall,
      continueOnToolError: continueOnToolError,
      cancelToken: cancelToken,
    );

    final stepResponsePromptMessages = executed.isEmpty
        ? stepResult.responsePromptMessages
        : [
            ...stepResult.responsePromptMessages,
            buildToolResultPromptMessageBestEffort(
              toolCalls: toolCalls,
              toolResults: executed,
            ),
          ];

    final stepResultWithTools = executed.isEmpty
        ? stepResult
        : _attachToolResultsToStepResult(
            stepResult,
            toolCalls: toolCalls,
            toolResults: executed,
            responsePromptMessages: stepResponsePromptMessages,
          );

    steps.add(
      ToolLoopStep(
        index: stepIndex,
        result: stepResultWithTools,
        toolCalls: List<ToolCall>.unmodifiable(toolCalls),
        toolResults: List<ToolResult>.unmodifiable(executed),
        responseMetadata: stepResult.responseMetadata,
        requestMetadata: stepResult.requestMetadata,
        responsePromptMessages: stepResponsePromptMessages,
      ),
    );

    if (response is ChatResponseWithAssistantMessage) {
      workingMessages.add(response.assistantMessage);
    } else {
      workingMessages.add(ChatMessage.toolUse(toolCalls: toolCalls));
    }
    if (executed.isNotEmpty) {
      workingMessages.add(
        ChatMessage.toolResult(
          results: _toToolResultCalls(toolCalls, executed),
        ),
      );
    }

    // AI SDK parity: only continue the loop if all tool calls can be executed
    // locally. If any tool calls lack a handler, return the current step.
    if (hasUnexecutableToolCalls) {
      return ToolLoopCompleted(
        ToolLoopResult(
          finalResult: stepResultWithTools,
          steps: steps,
          messages: List<ChatMessage>.unmodifiable(workingMessages),
          prompt: promptFromChatMessages(workingMessages),
        ),
      );
    }
  }

  throw InvalidRequestError(
    'Tool loop exceeded maxSteps ($maxSteps). '
    'The model kept requesting tools and did not produce a final response.',
  );
}

Future<ToolLoopRunOutcome> _continueToolLoopUntilBlockedPromptIrFromState({
  required ChatCapability model,
  required Prompt prompt,
  required List<ChatMessage> initialMessages,
  required List<ToolLoopStep> initialSteps,
  required int startStepIndex,
  List<Tool>? tools,
  required Map<String, ToolCallHandler> toolHandlers,
  ToolCallRepair? repairToolCall,
  Map<String, ToolApprovalCheck>? toolApprovalChecks,
  ToolApprovalCheck? needsApproval,
  required int maxSteps,
  required bool continueOnToolError,
  required IncludeOptions include,
  required LLMCallOptions callOptions,
  CancelToken? cancelToken,
}) async {
  if (model is! PromptChatCapability) {
    requirePromptCapabilityForFileReferenceParts(
      prompt: prompt,
      requiredCapabilityName: '`PromptChatCapability`',
    );
    return _continueToolLoopUntilBlockedFromState(
      model: model,
      initialMessages: initialMessages,
      initialSteps: initialSteps,
      startStepIndex: startStepIndex,
      tools: tools,
      toolHandlers: toolHandlers,
      repairToolCall: repairToolCall,
      toolApprovalChecks: toolApprovalChecks,
      needsApproval: needsApproval,
      maxSteps: maxSteps,
      continueOnToolError: continueOnToolError,
      include: include,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  final defaultModelId = model is ModelIdentityCapability
      ? (model as ModelIdentityCapability).modelId
      : null;

  var workingPrompt = prompt;
  final workingMessages = List<ChatMessage>.from(initialMessages);
  final steps = <ToolLoopStep>[...initialSteps];

  for (var stepIndex = startStepIndex; stepIndex < maxSteps; stepIndex++) {
    final startedAt = DateTime.now().toUtc();
    final response = await _chatPromptBestEffort(
      model,
      workingPrompt,
      tools: tools,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );

    final toolCalls = _onlyLocalFunctionToolCalls(response.toolCalls);

    final stepResult = GenerateTextResult(
      rawResponse: response,
      content: buildContentPartsBestEffort(
        text: response.text,
        thinking: response.thinking,
        toolCalls: toolCalls,
        toolResults: const <ToolResult>[],
      ),
      text: response.text,
      thinking: response.thinking,
      toolCalls: toolCalls,
      usage: response.usage,
      finishReason: response is ChatResponseWithFinishReason
          ? response.finishReason
          : null,
      requestMetadata: requestMetadataWithInclude(
        response is ChatResponseWithRequestMetadata
            ? response.requestMetadata
            : null,
        include,
      ),
      responseMetadata: responseMetadataWithInclude(
        responseMetadataWithDefaults(
          response is ChatResponseWithResponseMetadata
              ? response.responseMetadata
              : null,
          startedAt,
          defaultModelId: defaultModelId,
        ),
        include,
      ),
      responseMessages: buildResponseMessagesBestEffort(response),
      responsePromptMessages: buildResponsePromptMessagesBestEffort(response),
    );

    if (toolCalls.isEmpty) {
      if (response is ChatResponseWithAssistantMessage) {
        workingMessages.add(response.assistantMessage);
        workingPrompt = _appendChatMessageToPrompt(
            workingPrompt, response.assistantMessage);
      } else if (response.text != null && response.text!.isNotEmpty) {
        final assistant = ChatMessage.assistant(response.text!);
        workingMessages.add(assistant);
        workingPrompt = _appendChatMessageToPrompt(workingPrompt, assistant);
      }

      steps.add(
        ToolLoopStep(
          index: stepIndex,
          result: stepResult,
          toolCalls: const [],
          toolResults: const [],
          responseMetadata: stepResult.responseMetadata,
          requestMetadata: stepResult.requestMetadata,
          responsePromptMessages: stepResult.responsePromptMessages,
        ),
      );

      return ToolLoopCompleted(
        ToolLoopResult(
          finalResult: stepResult,
          steps: steps,
          messages: List<ChatMessage>.unmodifiable(workingMessages),
          prompt: workingPrompt,
        ),
      );
    }

    final partition = _partitionToolCallsByLocalHandler(
      toolCalls: toolCalls,
      toolHandlers: toolHandlers,
    );
    final executableToolCalls = partition.executable;
    final hasUnexecutableToolCalls = partition.unexecutable.isNotEmpty;

    final needingApproval = await _findToolCallsNeedingApproval(
      toolCalls: toolCalls,
      toolApprovalChecks: toolApprovalChecks,
      needsApproval: needsApproval,
      messages: workingMessages,
      stepIndex: stepIndex,
      cancelToken: cancelToken,
    );
    if (needingApproval.isNotEmpty) {
      final stepResultWithApprovals = _attachToolApprovalRequestsToStepResult(
        stepResult,
        toolCallsNeedingApproval: needingApproval,
      );
      steps.add(
        ToolLoopStep(
          index: stepIndex,
          result: stepResultWithApprovals,
          toolCalls: List<ToolCall>.unmodifiable(toolCalls),
          toolResults: const [],
          responseMetadata: stepResultWithApprovals.responseMetadata,
          requestMetadata: stepResultWithApprovals.requestMetadata,
          responsePromptMessages:
              stepResultWithApprovals.responsePromptMessages,
        ),
      );

      final assistantMessage = response is ChatResponseWithAssistantMessage
          ? response.assistantMessage
          : ChatMessage.toolUse(
              toolCalls: toolCalls,
              content: response.text ?? '',
            );

      workingMessages.add(assistantMessage);
      workingPrompt =
          _appendChatMessageToPrompt(workingPrompt, assistantMessage);

      return ToolLoopBlocked(
        ToolLoopBlockedState(
          stepIndex: stepIndex,
          stepResult: stepResultWithApprovals,
          toolCalls: List<ToolCall>.unmodifiable(toolCalls),
          toolCallsNeedingApproval:
              List<ToolCall>.unmodifiable(needingApproval),
          steps: List<ToolLoopStep>.unmodifiable(steps),
          messages: List<ChatMessage>.unmodifiable(workingMessages),
          prompt: workingPrompt,
        ),
      );
    }

    final executed = await _executeToolCalls(
      toolCalls: executableToolCalls,
      tools: tools,
      toolHandlers: toolHandlers,
      repairToolCall: repairToolCall,
      continueOnToolError: continueOnToolError,
      cancelToken: cancelToken,
    );

    final stepResponsePromptMessages = executed.isEmpty
        ? stepResult.responsePromptMessages
        : [
            ...stepResult.responsePromptMessages,
            buildToolResultPromptMessageBestEffort(
              toolCalls: toolCalls,
              toolResults: executed,
            ),
          ];

    final stepResultWithTools = executed.isEmpty
        ? stepResult
        : _attachToolResultsToStepResult(
            stepResult,
            toolCalls: toolCalls,
            toolResults: executed,
            responsePromptMessages: stepResponsePromptMessages,
          );

    steps.add(
      ToolLoopStep(
        index: stepIndex,
        result: stepResultWithTools,
        toolCalls: List<ToolCall>.unmodifiable(toolCalls),
        toolResults: List<ToolResult>.unmodifiable(executed),
        responseMetadata: stepResult.responseMetadata,
        requestMetadata: stepResult.requestMetadata,
        responsePromptMessages: stepResponsePromptMessages,
      ),
    );

    final assistantMessage = response is ChatResponseWithAssistantMessage
        ? response.assistantMessage
        : ChatMessage.toolUse(
            toolCalls: toolCalls,
            content: response.text ?? '',
          );
    workingMessages.add(assistantMessage);
    workingPrompt = _appendChatMessageToPrompt(workingPrompt, assistantMessage);

    if (executed.isNotEmpty) {
      final toolResultMessage = ChatMessage.toolResult(
        results: _toToolResultCalls(toolCalls, executed),
      );
      workingMessages.add(toolResultMessage);
      workingPrompt =
          _appendChatMessageToPrompt(workingPrompt, toolResultMessage);
    }

    // AI SDK parity: only continue the loop if all tool calls can be executed
    // locally. If any tool calls lack a handler, return the current step.
    if (hasUnexecutableToolCalls) {
      return ToolLoopCompleted(
        ToolLoopResult(
          finalResult: stepResultWithTools,
          steps: steps,
          messages: List<ChatMessage>.unmodifiable(workingMessages),
          prompt: workingPrompt,
        ),
      );
    }
  }

  throw InvalidRequestError(
    'Tool loop exceeded maxSteps ($maxSteps). '
    'The model kept requesting tools and did not produce a final response.',
  );
}

Future<ToolLoopRunOutcome> _runToolLoopUntilBlockedPromptIr({
  required ChatCapability model,
  required Prompt prompt,
  List<Tool>? tools,
  required Map<String, ToolCallHandler> toolHandlers,
  ToolCallRepair? repairToolCall,
  Map<String, ToolApprovalCheck>? toolApprovalChecks,
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool continueOnToolError = true,
  IncludeOptions include = const IncludeOptions(),
  required LLMCallOptions callOptions,
  CancelToken? cancelToken,
}) async {
  if (model is! PromptChatCapability) {
    requirePromptCapabilityForFileReferenceParts(
      prompt: prompt,
      requiredCapabilityName: '`PromptChatCapability`',
    );
    return runToolLoopUntilBlocked(
      model: model,
      messages: prompt.toChatMessages(),
      tools: tools,
      toolHandlers: toolHandlers,
      repairToolCall: repairToolCall,
      toolApprovalChecks: toolApprovalChecks,
      needsApproval: needsApproval,
      maxSteps: maxSteps,
      continueOnToolError: continueOnToolError,
      include: include,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  if (maxSteps < 1) {
    throw const InvalidRequestError('maxSteps must be >= 1');
  }

  final defaultModelId = model is ModelIdentityCapability
      ? (model as ModelIdentityCapability).modelId
      : null;

  var workingPrompt = prompt;
  final workingMessages = List<ChatMessage>.from(
    _promptToLegacyChatMessagesBestEffort(prompt),
  );
  final steps = <ToolLoopStep>[];

  for (var stepIndex = 0; stepIndex < maxSteps; stepIndex++) {
    final startedAt = DateTime.now().toUtc();
    final response = await _chatPromptBestEffort(
      model,
      workingPrompt,
      tools: tools,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );

    final toolCalls = _onlyLocalFunctionToolCalls(response.toolCalls);

    final stepResult = GenerateTextResult(
      rawResponse: response,
      content: buildContentPartsBestEffort(
        text: response.text,
        thinking: response.thinking,
        toolCalls: toolCalls,
        toolResults: const <ToolResult>[],
      ),
      text: response.text,
      thinking: response.thinking,
      toolCalls: toolCalls,
      usage: response.usage,
      finishReason: response is ChatResponseWithFinishReason
          ? response.finishReason
          : null,
      requestMetadata: requestMetadataWithInclude(
        response is ChatResponseWithRequestMetadata
            ? response.requestMetadata
            : null,
        include,
      ),
      responseMetadata: responseMetadataWithInclude(
        responseMetadataWithDefaults(
          response is ChatResponseWithResponseMetadata
              ? response.responseMetadata
              : null,
          startedAt,
          defaultModelId: defaultModelId,
        ),
        include,
      ),
      responseMessages: buildResponseMessagesBestEffort(response),
      responsePromptMessages: buildResponsePromptMessagesBestEffort(response),
    );

    if (toolCalls.isEmpty) {
      if (response is ChatResponseWithAssistantMessage) {
        workingMessages.add(response.assistantMessage);
        workingPrompt = _appendChatMessageToPrompt(
            workingPrompt, response.assistantMessage);
      } else if (response.text != null && response.text!.isNotEmpty) {
        final assistant = ChatMessage.assistant(response.text!);
        workingMessages.add(assistant);
        workingPrompt = _appendChatMessageToPrompt(workingPrompt, assistant);
      }

      steps.add(
        ToolLoopStep(
          index: stepIndex,
          result: stepResult,
          toolCalls: const [],
          toolResults: const [],
          responseMetadata: stepResult.responseMetadata,
          requestMetadata: stepResult.requestMetadata,
          responsePromptMessages: stepResult.responsePromptMessages,
        ),
      );

      return ToolLoopCompleted(
        ToolLoopResult(
          finalResult: stepResult,
          steps: steps,
          messages: List<ChatMessage>.unmodifiable(workingMessages),
          prompt: workingPrompt,
        ),
      );
    }

    final partition = _partitionToolCallsByLocalHandler(
      toolCalls: toolCalls,
      toolHandlers: toolHandlers,
    );
    final executableToolCalls = partition.executable;
    final hasUnexecutableToolCalls = partition.unexecutable.isNotEmpty;

    final needingApproval = await _findToolCallsNeedingApproval(
      toolCalls: toolCalls,
      toolApprovalChecks: toolApprovalChecks,
      needsApproval: needsApproval,
      messages: workingMessages,
      stepIndex: stepIndex,
      cancelToken: cancelToken,
    );
    if (needingApproval.isNotEmpty) {
      steps.add(
        ToolLoopStep(
          index: stepIndex,
          result: stepResult,
          toolCalls: List<ToolCall>.unmodifiable(toolCalls),
          toolResults: const [],
          responseMetadata: stepResult.responseMetadata,
          requestMetadata: stepResult.requestMetadata,
          responsePromptMessages: stepResult.responsePromptMessages,
        ),
      );

      final assistantMessage = response is ChatResponseWithAssistantMessage
          ? response.assistantMessage
          : ChatMessage.toolUse(
              toolCalls: toolCalls,
              content: response.text ?? '',
            );
      workingMessages.add(assistantMessage);
      workingPrompt =
          _appendChatMessageToPrompt(workingPrompt, assistantMessage);

      return ToolLoopBlocked(
        ToolLoopBlockedState(
          stepIndex: stepIndex,
          stepResult: stepResult,
          toolCalls: List<ToolCall>.unmodifiable(toolCalls),
          toolCallsNeedingApproval:
              List<ToolCall>.unmodifiable(needingApproval),
          steps: List<ToolLoopStep>.unmodifiable(steps),
          messages: List<ChatMessage>.unmodifiable(workingMessages),
          prompt: workingPrompt,
        ),
      );
    }

    final executed = await _executeToolCalls(
      toolCalls: executableToolCalls,
      tools: tools,
      toolHandlers: toolHandlers,
      repairToolCall: repairToolCall,
      continueOnToolError: continueOnToolError,
      cancelToken: cancelToken,
    );

    final stepResponsePromptMessages = executed.isEmpty
        ? stepResult.responsePromptMessages
        : [
            ...stepResult.responsePromptMessages,
            buildToolResultPromptMessageBestEffort(
              toolCalls: toolCalls,
              toolResults: executed,
            ),
          ];

    final stepResultWithTools = executed.isEmpty
        ? stepResult
        : _attachToolResultsToStepResult(
            stepResult,
            toolCalls: toolCalls,
            toolResults: executed,
            responsePromptMessages: stepResponsePromptMessages,
          );

    steps.add(
      ToolLoopStep(
        index: stepIndex,
        result: stepResultWithTools,
        toolCalls: List<ToolCall>.unmodifiable(toolCalls),
        toolResults: List<ToolResult>.unmodifiable(executed),
        responseMetadata: stepResult.responseMetadata,
        requestMetadata: stepResult.requestMetadata,
        responsePromptMessages: stepResponsePromptMessages,
      ),
    );

    final assistantMessage = response is ChatResponseWithAssistantMessage
        ? response.assistantMessage
        : ChatMessage.toolUse(
            toolCalls: toolCalls,
            content: response.text ?? '',
          );
    workingMessages.add(assistantMessage);
    workingPrompt = _appendChatMessageToPrompt(workingPrompt, assistantMessage);

    if (executed.isNotEmpty) {
      final toolResultMessage = ChatMessage.toolResult(
        results: _toToolResultCalls(toolCalls, executed),
      );
      workingMessages.add(toolResultMessage);
      workingPrompt =
          _appendChatMessageToPrompt(workingPrompt, toolResultMessage);
    }

    // AI SDK parity: only continue the loop if all tool calls can be executed
    // locally. If any tool calls lack a handler, return the current step.
    if (hasUnexecutableToolCalls) {
      return ToolLoopCompleted(
        ToolLoopResult(
          finalResult: stepResultWithTools,
          steps: steps,
          messages: List<ChatMessage>.unmodifiable(workingMessages),
          prompt: workingPrompt,
        ),
      );
    }
  }

  throw InvalidRequestError(
    'Tool loop exceeded maxSteps ($maxSteps). '
    'The model kept requesting tools and did not produce a final response.',
  );
}

/// ToolSet variant of [runToolLoop].
Future<ToolLoopResult> runToolLoopWithToolSet({
  required ChatCapability model,
  String? system,
  String? prompt,
  List<ChatMessage>? messages,
  Prompt? promptIr,
  required ToolSet toolSet,
  ToolCallRepair? repairToolCall,
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool continueOnToolError = true,
  IncludeOptions include = const IncludeOptions(),
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) {
  return runToolLoop(
    model: model,
    system: system,
    prompt: prompt,
    messages: messages,
    promptIr: promptIr,
    tools: toolSet.tools,
    toolHandlers: toolSet.handlers,
    repairToolCall: repairToolCall,
    toolApprovalChecks: toolSet.approvalChecks,
    needsApproval: needsApproval,
    maxSteps: maxSteps,
    continueOnToolError: continueOnToolError,
    include: include,
    defaultCallOptions: defaultCallOptions,
    callOptions: callOptions,
    cancelToken: cancelToken,
  );
}

/// ToolSet variant of [runToolLoopUntilBlocked].
Future<ToolLoopRunOutcome> runToolLoopUntilBlockedWithToolSet({
  required ChatCapability model,
  String? system,
  String? prompt,
  List<ChatMessage>? messages,
  Prompt? promptIr,
  required ToolSet toolSet,
  ToolCallRepair? repairToolCall,
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool continueOnToolError = true,
  IncludeOptions include = const IncludeOptions(),
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) {
  return runToolLoopUntilBlocked(
    model: model,
    system: system,
    prompt: prompt,
    messages: messages,
    promptIr: promptIr,
    tools: toolSet.tools,
    toolHandlers: toolSet.handlers,
    repairToolCall: repairToolCall,
    toolApprovalChecks: toolSet.approvalChecks,
    needsApproval: needsApproval,
    maxSteps: maxSteps,
    continueOnToolError: continueOnToolError,
    include: include,
    defaultCallOptions: defaultCallOptions,
    callOptions: callOptions,
    cancelToken: cancelToken,
  );
}

class _MergedChatResponseForStreaming implements ChatResponseWithFinishReason {
  final ChatResponse raw;
  final String? textOverride;
  final String? thinkingOverride;
  final UsageInfo? usageOverride;

  const _MergedChatResponseForStreaming({
    required this.raw,
    this.textOverride,
    this.thinkingOverride,
    this.usageOverride,
  });

  @override
  String? get text => textOverride ?? raw.text;

  @override
  String? get thinking => thinkingOverride ?? raw.thinking;

  @override
  List<ToolCall>? get toolCalls => raw.toolCalls;

  @override
  UsageInfo? get usage => usageOverride ?? raw.usage;

  @override
  LLMFinishReason? get finishReason {
    final r = raw;
    if (r is ChatResponseWithFinishReason) return r.finishReason;
    return null;
  }

  @override
  Map<String, dynamic>? get providerMetadata => raw.providerMetadata;
}

/// Stream a tool loop as Vercel-style stream parts.
///
/// Differences vs [runToolLoop]:
/// - Uses `LLMStreamPart` with block boundaries.
/// - Emits `LLMToolResultPart` for locally executed tools.
/// - Emits a single `LLMFinishPart` only when the loop completes.
Stream<LLMStreamPart> streamToolLoopParts({
  required ChatCapability model,
  String? system,
  String? prompt,
  List<ChatMessage>? messages,
  Prompt? promptIr,
  List<Tool>? tools,
  required Map<String, ToolCallHandler> toolHandlers,
  ToolCallRepair? repairToolCall,
  Map<String, ToolApprovalCheck>? toolApprovalChecks,
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool waitForDeferredProviderToolResults = true,
  int maxAdditionalProviderToolResultSteps = 1,
  bool continueOnToolError = true,
  bool emitStepParts = false,
  IncludeOptions include = const IncludeOptions(),
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async* {
  final effectiveCallOptions = defaultCallOptions.mergedWith(callOptions);
  Stream<LLMStreamPart> upstream() async* {
    final input = standardizePromptInput(
      system: system,
      prompt: prompt,
      messages: messages,
      promptIr: promptIr,
    );

    if (input is StandardizedPromptIr) {
      yield* _streamToolLoopPartsPromptIr(
        model: model,
        prompt: input.prompt,
        tools: tools,
        toolHandlers: toolHandlers,
        repairToolCall: repairToolCall,
        toolApprovalChecks: toolApprovalChecks,
        needsApproval: needsApproval,
        maxSteps: maxSteps,
        waitForDeferredProviderToolResults: waitForDeferredProviderToolResults,
        maxAdditionalProviderToolResultSteps:
            maxAdditionalProviderToolResultSteps,
        continueOnToolError: continueOnToolError,
        emitStepParts: emitStepParts,
        include: include,
        callOptions: effectiveCallOptions,
        cancelToken: cancelToken,
      );
      return;
    }

    final standardizedMessages = (input as StandardizedChatMessages).messages;

    if (effectiveCallOptions.isEmpty) {
      if (model is! ChatStreamPartsCapability) {
        yield const LLMErrorPart(
          InvalidRequestError(
            'streamToolLoopParts requires parts-first streaming. Implement '
            '`ChatStreamPartsCapability.chatStreamParts()` (or use a provider that does).',
          ),
        );
        return;
      }
    } else {
      if (model is! ChatStreamPartsCallOptionsCapability) {
        yield const LLMErrorPart(
          InvalidRequestError(
            'streamToolLoopParts requires parts-first streaming with call-level overrides. '
            'Implement `ChatStreamPartsCallOptionsCapability` (or use a provider that does).',
          ),
        );
        return;
      }
    }

    if (maxSteps < 1) {
      yield const LLMErrorPart(
        InvalidRequestError('maxSteps must be >= 1'),
      );
      return;
    }

    final workingMessages = List<ChatMessage>.from(standardizedMessages);
    final pendingProviderToolCallFirstStep = <String, int>{};

    for (var stepIndex = 0; stepIndex < maxSteps; stepIndex++) {
      if (emitStepParts) {
        yield LLMStepStartPart(stepIndex);
      }

      final toolAccums = <String, _ToolCallAccum>{};
      final fullText = StringBuffer();
      final fullThinking = StringBuffer();
      UsageInfo? usage;
      ChatResponse? completedResponse;

      final startedToolCalls = <String>{};

      final usesNativeParts = true;
      var didEmitProviderMetadataPart = false;

      final Stream<LLMStreamPart> partsStream;
      if (effectiveCallOptions.isEmpty) {
        partsStream = (model as ChatStreamPartsCapability).chatStreamParts(
          workingMessages,
          tools: tools,
          cancelToken: cancelToken,
        );
      } else {
        partsStream = (model as ChatStreamPartsCallOptionsCapability)
            .chatStreamPartsWithCallOptions(
          workingMessages,
          tools: tools,
          callOptions: effectiveCallOptions,
          cancelToken: cancelToken,
        );
      }

      await for (final part in partsStream) {
        switch (part) {
          case LLMTextDeltaPart(:final delta):
            fullText.write(delta);
            yield part;

          case LLMTextEndPart(:final text):
            if (fullText.isEmpty && text.isNotEmpty) {
              fullText.write(text);
            }
            yield part;

          case LLMReasoningDeltaPart(:final delta):
            fullThinking.write(delta);
            yield part;

          case LLMReasoningEndPart(:final thinking):
            if (fullThinking.isEmpty && thinking.isNotEmpty) {
              fullThinking.write(thinking);
            }
            yield part;

          case LLMToolCallStartPart(:final toolCall):
          case LLMToolCallDeltaPart(:final toolCall):
            if (!_isFunctionToolCall(toolCall)) {
              // Tool loop only executes local function tools.
              yield part;
              break;
            }
            final accum =
                toolAccums.putIfAbsent(toolCall.id, () => _ToolCallAccum());
            accum.callType = toolCall.callType;
            if (toolCall.function.name.isNotEmpty) {
              accum.name = toolCall.function.name;
            }
            if (toolCall.function.arguments.isNotEmpty) {
              accum.arguments.write(toolCall.function.arguments);
            }
            startedToolCalls.add(toolCall.id);
            yield part;

          case LLMProviderToolCallPart(
              :final toolCallId,
              :final providerExecuted,
            ):
            if (waitForDeferredProviderToolResults &&
                toolCallId.trim().isNotEmpty &&
                providerExecuted != false) {
              pendingProviderToolCallFirstStep.putIfAbsent(
                toolCallId,
                () => stepIndex,
              );
            }
            yield part;

          case LLMProviderToolResultPart(:final toolCallId, :final preliminary):
            if (toolCallId.trim().isNotEmpty && preliminary != true) {
              pendingProviderToolCallFirstStep.remove(toolCallId);
            }
            yield part;

          case LLMProviderMetadataPart():
            didEmitProviderMetadataPart = true;
            yield part;

          case LLMFinishPart(:final response):
            completedResponse = response;
            usage = response.usage;
            break;

          case LLMErrorPart():
            yield part;
            return;

          default:
            yield part;
        }

        if (part is LLMFinishPart) {
          break;
        }
      }

      final baseResponse = completedResponse ??
          _FakeChatResponseForStreaming(
            text: fullText.isNotEmpty ? fullText.toString() : null,
            thinking: fullThinking.isNotEmpty ? fullThinking.toString() : null,
            usage: usage,
          );

      final mergedResponse = _MergedChatResponseForStreaming(
        raw: baseResponse,
        textOverride:
            fullText.isNotEmpty ? fullText.toString() : baseResponse.text,
        thinkingOverride: fullThinking.isNotEmpty
            ? fullThinking.toString()
            : baseResponse.thinking,
        usageOverride: usage ?? baseResponse.usage,
      );

      final completedToolCalls = toolAccums.entries
          .map((e) => e.value.toToolCall(e.key))
          .where(_isExecutableFunctionToolCall)
          .toList(growable: false);

      if (usesNativeParts && !didEmitProviderMetadataPart) {
        final providerMetadata = mergedResponse.providerMetadata;
        if (providerMetadata != null && providerMetadata.isNotEmpty) {
          yield LLMProviderMetadataPart(providerMetadata);
        }
      }

      // If no tool calls, we're done.
      if (completedToolCalls.isEmpty) {
        if (completedResponse is ChatResponseWithAssistantMessage) {
          workingMessages.add(completedResponse.assistantMessage);
        } else {
          final finalText = mergedResponse.text;
          if (finalText != null && finalText.isNotEmpty) {
            workingMessages.add(ChatMessage.assistant(finalText));
          }
        }

        if (emitStepParts) {
          yield LLMStepFinishPart(
            stepIndex: stepIndex,
            response: mergedResponse,
            usage: mergedResponse.usage,
            finishReason: mergedResponse.finishReason,
            toolCalls: const [],
            toolResults: const [],
          );
        }

        if (waitForDeferredProviderToolResults &&
            pendingProviderToolCallFirstStep.isNotEmpty &&
            maxAdditionalProviderToolResultSteps > 0) {
          pendingProviderToolCallFirstStep.removeWhere(
            (_, firstStep) =>
                (stepIndex - firstStep) >= maxAdditionalProviderToolResultSteps,
          );
          if (pendingProviderToolCallFirstStep.isNotEmpty) {
            // Provider-native tools may defer their results to a subsequent step.
            // Continue until all pending provider tool calls have a non-preliminary
            // result, or the wait budget is exhausted.
            continue;
          }
        }

        yield LLMFinishPart(
          mergedResponse,
          usage: mergedResponse.usage,
          finishReason: mergedResponse.finishReason,
        );
        return;
      }

      final partition = _partitionToolCallsByLocalHandler(
        toolCalls: completedToolCalls,
        toolHandlers: toolHandlers,
      );
      final executableToolCalls = partition.executable;
      final hasUnexecutableToolCalls = partition.unexecutable.isNotEmpty;

      final needingApproval = await _findToolCallsNeedingApproval(
        toolCalls: completedToolCalls,
        toolApprovalChecks: toolApprovalChecks,
        needsApproval: needsApproval,
        messages: workingMessages,
        stepIndex: stepIndex,
        cancelToken: cancelToken,
      );
      if (needingApproval.isNotEmpty) {
        if (completedResponse is ChatResponseWithAssistantMessage) {
          workingMessages.add(completedResponse.assistantMessage);
        } else {
          workingMessages
              .add(ChatMessage.toolUse(toolCalls: completedToolCalls));
        }

        for (final call in needingApproval) {
          yield LLMProviderToolApprovalRequestPart(
            approvalId: call.id,
            toolCallId: call.id,
            toolName: call.function.name,
            input: _decodeJsonIfPossible(call.function.arguments),
          );
        }

        final stepResultBase = GenerateTextResult(
          rawResponse: mergedResponse,
          content: buildContentPartsBestEffort(
            text: mergedResponse.text,
            thinking: mergedResponse.thinking,
            toolCalls: completedToolCalls,
            toolResults: const <ToolResult>[],
          ),
          text: mergedResponse.text,
          thinking: mergedResponse.thinking,
          toolCalls: completedToolCalls,
          usage: mergedResponse.usage,
          finishReason: mergedResponse.finishReason,
          responseMetadata: null,
          responseMessages: buildResponseMessagesBestEffort(mergedResponse),
          responsePromptMessages: buildResponsePromptMessagesBestEffort(
            mergedResponse,
          ),
        );
        final stepResultWithApprovals = _attachToolApprovalRequestsToStepResult(
          stepResultBase,
          toolCallsNeedingApproval: needingApproval,
        );

        yield LLMErrorPart(
          ToolApprovalRequiredError(
            state: ToolLoopBlockedState(
              stepIndex: stepIndex,
              stepResult: stepResultWithApprovals,
              toolCalls: List<ToolCall>.unmodifiable(completedToolCalls),
              toolCallsNeedingApproval:
                  List<ToolCall>.unmodifiable(needingApproval),
              steps: const [],
              messages: List<ChatMessage>.unmodifiable(workingMessages),
              prompt: promptFromChatMessages(workingMessages),
            ),
          ),
        );
        return;
      }

      final executed = await _executeToolCalls(
        toolCalls: executableToolCalls,
        tools: tools,
        toolHandlers: toolHandlers,
        repairToolCall: repairToolCall,
        continueOnToolError: continueOnToolError,
        cancelToken: cancelToken,
      );

      for (final result in executed) {
        yield LLMToolResultPart(result);
      }

      if (emitStepParts) {
        yield LLMStepFinishPart(
          stepIndex: stepIndex,
          response: mergedResponse,
          usage: mergedResponse.usage,
          finishReason: mergedResponse.finishReason,
          toolCalls: List<ToolCall>.unmodifiable(completedToolCalls),
          toolResults: List<ToolResult>.unmodifiable(executed),
        );
      }

      if (completedResponse is ChatResponseWithAssistantMessage) {
        workingMessages.add(completedResponse.assistantMessage);
      } else {
        workingMessages.add(ChatMessage.toolUse(toolCalls: completedToolCalls));
      }
      if (executed.isNotEmpty) {
        workingMessages.add(
          ChatMessage.toolResult(
            results: _toToolResultCalls(completedToolCalls, executed),
          ),
        );
      }

      // AI SDK parity: only continue the loop if all tool calls can be executed
      // locally. If any tool calls lack a handler, emit finish and stop.
      if (hasUnexecutableToolCalls) {
        yield LLMFinishPart(
          mergedResponse,
          usage: mergedResponse.usage,
          finishReason: mergedResponse.finishReason,
        );
        return;
      }
    }

    yield LLMErrorPart(
      InvalidRequestError(
        'Tool loop exceeded maxSteps ($maxSteps). '
        'The model kept requesting tools and did not produce a final response.',
      ),
    );
  }

  yield* ensureStreamStartPart(
    ensureBlockEndsPart(
      ensureBlockIdsPart(
        ensureSingleFinishPart(
          ensureProviderMetadataPart(
            streamPartsWithInclude(
              ensureResponseMetadataPart(upstream()),
              include,
            ),
          ),
        ),
      ),
    ),
  );
}

Stream<LLMStreamPart> _streamToolLoopPartsPromptIr({
  required ChatCapability model,
  required Prompt prompt,
  List<Tool>? tools,
  required Map<String, ToolCallHandler> toolHandlers,
  ToolCallRepair? repairToolCall,
  Map<String, ToolApprovalCheck>? toolApprovalChecks,
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool waitForDeferredProviderToolResults = true,
  int maxAdditionalProviderToolResultSteps = 1,
  bool continueOnToolError = true,
  bool emitStepParts = false,
  IncludeOptions include = const IncludeOptions(),
  required LLMCallOptions callOptions,
  CancelToken? cancelToken,
}) async* {
  final hasPromptStreamParts = callOptions.isEmpty
      ? model is PromptChatStreamPartsCapability
      : model is PromptChatStreamPartsCallOptionsCapability;

  if (!hasPromptStreamParts) {
    requirePromptCapabilityForFileReferenceParts(
      prompt: prompt,
      requiredCapabilityName: callOptions.isEmpty
          ? '`PromptChatStreamPartsCapability`'
          : '`PromptChatStreamPartsCallOptionsCapability`',
    );
    yield* streamToolLoopParts(
      model: model,
      messages: prompt.toChatMessages(),
      tools: tools,
      toolHandlers: toolHandlers,
      repairToolCall: repairToolCall,
      toolApprovalChecks: toolApprovalChecks,
      needsApproval: needsApproval,
      maxSteps: maxSteps,
      waitForDeferredProviderToolResults: waitForDeferredProviderToolResults,
      maxAdditionalProviderToolResultSteps:
          maxAdditionalProviderToolResultSteps,
      continueOnToolError: continueOnToolError,
      emitStepParts: emitStepParts,
      include: include,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
    return;
  }

  if (maxSteps < 1) {
    yield const LLMErrorPart(
      InvalidRequestError('maxSteps must be >= 1'),
    );
    return;
  }

  var workingPrompt = prompt;
  final workingMessages = List<ChatMessage>.from(
    _promptToLegacyChatMessagesBestEffort(prompt),
  );
  final pendingProviderToolCallFirstStep = <String, int>{};

  for (var stepIndex = 0; stepIndex < maxSteps; stepIndex++) {
    if (emitStepParts) {
      yield LLMStepStartPart(stepIndex);
    }

    final toolAccums = <String, _ToolCallAccum>{};
    final fullText = StringBuffer();
    final fullThinking = StringBuffer();
    UsageInfo? usage;
    ChatResponse? completedResponse;

    final startedToolCalls = <String>{};

    var didEmitProviderMetadataPart = false;

    final Stream<LLMStreamPart> partsStream;
    if (callOptions.isEmpty) {
      partsStream =
          (model as PromptChatStreamPartsCapability).chatPromptStreamParts(
        workingPrompt,
        tools: tools,
        cancelToken: cancelToken,
      );
    } else {
      partsStream = (model as PromptChatStreamPartsCallOptionsCapability)
          .chatPromptStreamPartsWithCallOptions(
        workingPrompt,
        tools: tools,
        callOptions: callOptions,
        cancelToken: cancelToken,
      );
    }

    await for (final part in partsStream) {
      switch (part) {
        case LLMTextDeltaPart(:final delta):
          fullText.write(delta);
          yield part;

        case LLMTextEndPart(:final text):
          if (fullText.isEmpty && text.isNotEmpty) {
            fullText.write(text);
          }
          yield part;

        case LLMReasoningDeltaPart(:final delta):
          fullThinking.write(delta);
          yield part;

        case LLMReasoningEndPart(:final thinking):
          if (fullThinking.isEmpty && thinking.isNotEmpty) {
            fullThinking.write(thinking);
          }
          yield part;

        case LLMToolCallStartPart(:final toolCall):
        case LLMToolCallDeltaPart(:final toolCall):
          if (!_isFunctionToolCall(toolCall)) {
            // Tool loop only executes local function tools.
            yield part;
            break;
          }
          final accum =
              toolAccums.putIfAbsent(toolCall.id, () => _ToolCallAccum());
          accum.callType = toolCall.callType;
          if (toolCall.function.name.isNotEmpty) {
            accum.name = toolCall.function.name;
          }
          if (toolCall.function.arguments.isNotEmpty) {
            accum.arguments.write(toolCall.function.arguments);
          }
          startedToolCalls.add(toolCall.id);
          yield part;

        case LLMProviderToolCallPart(
            :final toolCallId,
            :final providerExecuted,
          ):
          if (waitForDeferredProviderToolResults &&
              toolCallId.trim().isNotEmpty &&
              providerExecuted != false) {
            pendingProviderToolCallFirstStep.putIfAbsent(
              toolCallId,
              () => stepIndex,
            );
          }
          yield part;

        case LLMProviderToolResultPart(:final toolCallId, :final preliminary):
          if (toolCallId.trim().isNotEmpty && preliminary != true) {
            pendingProviderToolCallFirstStep.remove(toolCallId);
          }
          yield part;

        case LLMProviderMetadataPart():
          didEmitProviderMetadataPart = true;
          yield part;

        case LLMFinishPart(:final response):
          completedResponse = response;
          usage = response.usage;
          break;

        case LLMErrorPart():
          yield part;
          return;

        default:
          yield part;
      }

      if (part is LLMFinishPart) {
        break;
      }
    }

    final baseResponse = completedResponse ??
        _FakeChatResponseForStreaming(
          text: fullText.isNotEmpty ? fullText.toString() : null,
          thinking: fullThinking.isNotEmpty ? fullThinking.toString() : null,
          usage: usage,
        );

    final mergedResponse = _MergedChatResponseForStreaming(
      raw: baseResponse,
      textOverride:
          fullText.isNotEmpty ? fullText.toString() : baseResponse.text,
      thinkingOverride: fullThinking.isNotEmpty
          ? fullThinking.toString()
          : baseResponse.thinking,
      usageOverride: usage ?? baseResponse.usage,
    );

    final completedToolCalls = toolAccums.entries
        .map((e) => e.value.toToolCall(e.key))
        .where(_isExecutableFunctionToolCall)
        .toList(growable: false);

    if (!didEmitProviderMetadataPart) {
      final providerMetadata = mergedResponse.providerMetadata;
      if (providerMetadata != null && providerMetadata.isNotEmpty) {
        yield LLMProviderMetadataPart(providerMetadata);
      }
    }

    // If no tool calls, we're done.
    if (completedToolCalls.isEmpty) {
      if (completedResponse is ChatResponseWithAssistantMessage) {
        workingMessages.add(completedResponse.assistantMessage);
        workingPrompt = _appendChatMessageToPrompt(
          workingPrompt,
          completedResponse.assistantMessage,
        );
      } else {
        final finalText = mergedResponse.text;
        if (finalText != null && finalText.isNotEmpty) {
          final assistant = ChatMessage.assistant(finalText);
          workingMessages.add(assistant);
          workingPrompt = _appendChatMessageToPrompt(workingPrompt, assistant);
        }
      }

      if (emitStepParts) {
        yield LLMStepFinishPart(
          stepIndex: stepIndex,
          response: mergedResponse,
          usage: mergedResponse.usage,
          finishReason: mergedResponse.finishReason,
          toolCalls: const [],
          toolResults: const [],
        );
      }

      if (waitForDeferredProviderToolResults &&
          pendingProviderToolCallFirstStep.isNotEmpty &&
          maxAdditionalProviderToolResultSteps > 0) {
        pendingProviderToolCallFirstStep.removeWhere(
          (_, firstStep) =>
              (stepIndex - firstStep) >= maxAdditionalProviderToolResultSteps,
        );
        if (pendingProviderToolCallFirstStep.isNotEmpty) {
          // Provider-native tools may defer their results to a subsequent step.
          // Continue until all pending provider tool calls have a non-preliminary
          // result, or the wait budget is exhausted.
          continue;
        }
      }

      yield LLMFinishPart(
        mergedResponse,
        usage: mergedResponse.usage,
        finishReason: mergedResponse.finishReason,
      );
      return;
    }

    final partition = _partitionToolCallsByLocalHandler(
      toolCalls: completedToolCalls,
      toolHandlers: toolHandlers,
    );
    final executableToolCalls = partition.executable;
    final hasUnexecutableToolCalls = partition.unexecutable.isNotEmpty;

    final needingApproval = await _findToolCallsNeedingApproval(
      toolCalls: completedToolCalls,
      toolApprovalChecks: toolApprovalChecks,
      needsApproval: needsApproval,
      messages: workingMessages,
      stepIndex: stepIndex,
      cancelToken: cancelToken,
    );
    if (needingApproval.isNotEmpty) {
      final assistantMessage =
          completedResponse is ChatResponseWithAssistantMessage
              ? completedResponse.assistantMessage
              : ChatMessage.toolUse(toolCalls: completedToolCalls);

      workingMessages.add(assistantMessage);
      workingPrompt =
          _appendChatMessageToPrompt(workingPrompt, assistantMessage);

      for (final call in needingApproval) {
        yield LLMProviderToolApprovalRequestPart(
          approvalId: call.id,
          toolCallId: call.id,
          toolName: call.function.name,
          input: _decodeJsonIfPossible(call.function.arguments),
        );
      }

      final stepResultBase = GenerateTextResult(
        rawResponse: mergedResponse,
        content: buildContentPartsBestEffort(
          text: mergedResponse.text,
          thinking: mergedResponse.thinking,
          toolCalls: completedToolCalls,
          toolResults: const <ToolResult>[],
        ),
        text: mergedResponse.text,
        thinking: mergedResponse.thinking,
        toolCalls: completedToolCalls,
        usage: mergedResponse.usage,
        finishReason: mergedResponse.finishReason,
        responseMetadata: null,
        responseMessages: buildResponseMessagesBestEffort(mergedResponse),
        responsePromptMessages: buildResponsePromptMessagesBestEffort(
          mergedResponse,
        ),
      );
      final stepResultWithApprovals = _attachToolApprovalRequestsToStepResult(
        stepResultBase,
        toolCallsNeedingApproval: needingApproval,
      );

      yield LLMErrorPart(
        ToolApprovalRequiredError(
          state: ToolLoopBlockedState(
            stepIndex: stepIndex,
            stepResult: stepResultWithApprovals,
            toolCalls: List<ToolCall>.unmodifiable(completedToolCalls),
            toolCallsNeedingApproval:
                List<ToolCall>.unmodifiable(needingApproval),
            steps: const [],
            messages: List<ChatMessage>.unmodifiable(workingMessages),
            prompt: workingPrompt,
          ),
        ),
      );
      return;
    }

    final executed = await _executeToolCalls(
      toolCalls: executableToolCalls,
      tools: tools,
      toolHandlers: toolHandlers,
      repairToolCall: repairToolCall,
      continueOnToolError: continueOnToolError,
      cancelToken: cancelToken,
    );

    for (final result in executed) {
      yield LLMToolResultPart(result);
    }

    if (emitStepParts) {
      yield LLMStepFinishPart(
        stepIndex: stepIndex,
        response: mergedResponse,
        usage: mergedResponse.usage,
        finishReason: mergedResponse.finishReason,
        toolCalls: List<ToolCall>.unmodifiable(completedToolCalls),
        toolResults: List<ToolResult>.unmodifiable(executed),
      );
    }

    final assistantMessage =
        completedResponse is ChatResponseWithAssistantMessage
            ? completedResponse.assistantMessage
            : ChatMessage.toolUse(
                toolCalls: completedToolCalls,
                content: mergedResponse.text ?? '',
              );
    workingMessages.add(assistantMessage);
    workingPrompt = _appendChatMessageToPrompt(workingPrompt, assistantMessage);

    if (executed.isNotEmpty) {
      final toolResultMessage = ChatMessage.toolResult(
        results: _toToolResultCalls(completedToolCalls, executed),
      );
      workingMessages.add(toolResultMessage);
      workingPrompt =
          _appendChatMessageToPrompt(workingPrompt, toolResultMessage);
    }

    // AI SDK parity: only continue the loop if all tool calls can be executed
    // locally. If any tool calls lack a handler, emit finish and stop.
    if (hasUnexecutableToolCalls) {
      yield LLMFinishPart(
        mergedResponse,
        usage: mergedResponse.usage,
        finishReason: mergedResponse.finishReason,
      );
      return;
    }
  }

  yield LLMErrorPart(
    InvalidRequestError(
      'Tool loop exceeded maxSteps ($maxSteps). '
      'The model kept requesting tools and did not produce a final response.',
    ),
  );
}

/// ToolSet variant of [streamToolLoopParts].
Stream<LLMStreamPart> streamToolLoopPartsWithToolSet({
  required ChatCapability model,
  String? system,
  String? prompt,
  List<ChatMessage>? messages,
  Prompt? promptIr,
  required ToolSet toolSet,
  ToolCallRepair? repairToolCall,
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool continueOnToolError = true,
  bool emitStepParts = false,
  IncludeOptions include = const IncludeOptions(),
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async* {
  final upstream = streamToolLoopParts(
    model: model,
    system: system,
    prompt: prompt,
    messages: messages,
    promptIr: promptIr,
    tools: toolSet.tools,
    toolHandlers: toolSet.handlers,
    repairToolCall: repairToolCall,
    toolApprovalChecks: toolSet.approvalChecks,
    needsApproval: needsApproval,
    maxSteps: maxSteps,
    continueOnToolError: continueOnToolError,
    emitStepParts: emitStepParts,
    include: include,
    defaultCallOptions: defaultCallOptions,
    callOptions: callOptions,
    cancelToken: cancelToken,
  );

  final toolNameByCallId = <String, String>{};
  final toolInputTextByCallId = <String, StringBuffer>{};

  ({Object value, String? error}) tryDecodeJsonLike(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return (value: const <String, dynamic>{}, error: null);
    }

    final looksJsonLike = trimmed.startsWith('{') ||
        trimmed.startsWith('[') ||
        trimmed == 'null' ||
        trimmed == 'true' ||
        trimmed == 'false' ||
        num.tryParse(trimmed) != null;

    if (!looksJsonLike) return (value: content, error: null);

    try {
      return (value: jsonDecode(trimmed), error: null);
    } catch (e) {
      return (value: content, error: 'Invalid JSON: $e');
    }
  }

  Future<void> safeCall(FutureOr<void> Function() fn) async {
    try {
      await Future.value(fn());
    } catch (_) {
      // Best-effort: tool input hooks must not break streaming.
    }
  }

  await for (final part in upstream) {
    switch (part) {
      case LLMToolInputStartPart(:final id, :final toolName):
        toolNameByCallId[id] = toolName;
        toolInputTextByCallId[id] = StringBuffer();
        final tool = toolSet.toolByName(toolName);
        final onStart = tool?.onInputStart;
        if (onStart != null) {
          await safeCall(() => onStart(id));
        }
        break;

      case LLMToolInputDeltaPart(:final id, :final delta):
        (toolInputTextByCallId[id] ??= StringBuffer()).write(delta);
        final toolName = toolNameByCallId[id];
        if (toolName != null && toolName.isNotEmpty) {
          final tool = toolSet.toolByName(toolName);
          final onDelta = tool?.onInputDelta;
          if (onDelta != null) {
            await safeCall(() => onDelta(id, delta));
          }
        }
        break;

      case LLMToolInputEndPart(:final id):
        final toolName = toolNameByCallId[id];
        if (toolName != null && toolName.isNotEmpty) {
          final tool = toolSet.toolByName(toolName);
          final onAvailable = tool?.onInputAvailable;
          final onError = tool?.onInputError;
          if (onAvailable != null || onError != null) {
            final raw = toolInputTextByCallId[id]?.toString() ?? '';
            final parsed = tryDecodeJsonLike(raw);
            if (parsed.error != null) {
              if (onError != null) {
                await safeCall(() => onError(id, raw, parsed.error!));
              }
            } else {
              if (onAvailable != null) {
                await safeCall(() => onAvailable(id, parsed.value));
              }
            }
          }
        }
        toolInputTextByCallId.remove(id);
        toolNameByCallId.remove(id);
        break;

      default:
        break;
    }

    yield part;
  }
}

/// Execute tool calls locally and return a list of tool results.
Future<List<ToolResult>> executeToolCalls({
  required List<ToolCall> toolCalls,
  List<Tool>? tools,
  required Map<String, ToolCallHandler> toolHandlers,
  ToolCallRepair? repairToolCall,
  bool continueOnToolError = true,
  CancelToken? cancelToken,
}) {
  return _executeToolCalls(
    toolCalls: toolCalls,
    tools: tools,
    toolHandlers: toolHandlers,
    repairToolCall: repairToolCall,
    continueOnToolError: continueOnToolError,
    cancelToken: cancelToken,
  );
}

/// Encode tool results into the `ToolCall` shape used by [ChatMessage.toolResult].
List<ToolCall> encodeToolResultsAsToolCalls({
  required List<ToolCall> toolCalls,
  required List<ToolResult> toolResults,
}) {
  return _toToolResultCalls(toolCalls, toolResults);
}

Future<List<ToolCall>> _findToolCallsNeedingApproval({
  required List<ToolCall> toolCalls,
  required Map<String, ToolApprovalCheck>? toolApprovalChecks,
  required ToolApprovalCheck? needsApproval,
  required List<ChatMessage> messages,
  required int stepIndex,
  CancelToken? cancelToken,
}) async {
  if (toolApprovalChecks == null && needsApproval == null) {
    return const [];
  }

  final needing = <ToolCall>[];
  for (final toolCall in toolCalls) {
    if (!_isExecutableFunctionToolCall(toolCall)) continue;
    final checker =
        toolApprovalChecks?[toolCall.function.name] ?? needsApproval;
    if (checker == null) continue;
    final requiredApproval = await Future.value(
      checker(
        toolCall,
        messages: messages,
        stepIndex: stepIndex,
        cancelToken: cancelToken,
      ),
    );
    if (requiredApproval) {
      needing.add(toolCall);
    }
  }
  return needing;
}

Future<List<ToolResult>> _executeToolCalls({
  required List<ToolCall> toolCalls,
  required List<Tool>? tools,
  required Map<String, ToolCallHandler> toolHandlers,
  ToolCallRepair? repairToolCall,
  required bool continueOnToolError,
  CancelToken? cancelToken,
}) async {
  final results = <ToolResult>[];

  final toolByName = tools == null
      ? null
      : <String, Tool>{
          for (final t in tools)
            if (t.function.name.trim().isNotEmpty) t.function.name: t,
        };

  ({Map<String, dynamic>? parsed, String? error}) parseToolInput(
    String raw,
  ) {
    final trimmed = raw.trim();
    final toParse = trimmed.isEmpty ? '{}' : trimmed;

    dynamic decoded;
    try {
      decoded = jsonDecode(toParse);
    } catch (_) {
      return (parsed: null, error: 'Invalid JSON in tool arguments');
    }

    if (decoded is! Map) {
      return (parsed: null, error: 'Tool arguments must be a JSON object');
    }

    return (parsed: Map<String, dynamic>.from(decoded), error: null);
  }

  Future<String?> tryRepairToolCall(
    ToolCall toolCall, {
    required String reason,
    String? errorMessage,
    List<String>? validationErrors,
  }) async {
    final repair = repairToolCall;
    if (repair == null) return null;

    final repaired = await Future.value(
      repair(
        toolCall,
        reason: reason,
        errorMessage: errorMessage,
        validationErrors: validationErrors,
      ),
    );
    final trimmed = repaired?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  for (final toolCall in toolCalls) {
    var effectiveToolCall = toolCall;

    if (!_isExecutableFunctionToolCall(toolCall)) {
      results.add(
        ToolResult.error(
          toolCallId: toolCall.id,
          error:
              'Only "function" ToolCall can be executed locally (got: ${toolCall.callType})',
        ),
      );
      if (!continueOnToolError) break;
      continue;
    }

    // Best-effort AI SDK parity: tool call input is expected to be a JSON object.
    // If it is malformed, emit an error result and skip execution.
    var parsed = parseToolInput(effectiveToolCall.function.arguments);
    if (parsed.error != null) {
      final reason = parsed.error == 'Tool arguments must be a JSON object'
          ? 'arguments_not_object'
          : 'invalid_json';

      final repaired = await tryRepairToolCall(
        effectiveToolCall,
        reason: reason,
        errorMessage: parsed.error,
      );

      if (repaired != null) {
        final repairedCall = ToolCall(
          id: effectiveToolCall.id,
          callType: effectiveToolCall.callType,
          function: FunctionCall(
            name: effectiveToolCall.function.name,
            arguments: repaired,
          ),
          providerOptions: effectiveToolCall.providerOptions,
        );
        final repairedParsed = parseToolInput(repairedCall.function.arguments);
        if (repairedParsed.error == null) {
          effectiveToolCall = repairedCall;
          parsed = repairedParsed;
        } else {
          results.add(
            ToolResult.error(
              toolCallId: effectiveToolCall.id,
              error:
                  '${repairedParsed.error}: "${effectiveToolCall.function.name}"',
              metadata: {
                'kind': 'invalid_tool_call',
                'reason': reason,
                'toolName': effectiveToolCall.function.name,
                'input': toolCall.function.arguments,
                'repairAttempted': true,
                'repairedInput': repaired,
                'repairError': repairedParsed.error,
              },
            ),
          );
          if (!continueOnToolError) break;
          continue;
        }
      } else {
        results.add(
          ToolResult.error(
            toolCallId: effectiveToolCall.id,
            error: '${parsed.error}: "${effectiveToolCall.function.name}"',
            metadata: {
              'kind': 'invalid_tool_call',
              'reason': reason,
              'toolName': effectiveToolCall.function.name,
              'input': effectiveToolCall.function.arguments,
            },
          ),
        );
        if (!continueOnToolError) break;
        continue;
      }
    }

    final toolDef = toolByName?[effectiveToolCall.function.name];
    if (toolByName != null && toolDef == null) {
      results.add(
        ToolResult.error(
          toolCallId: effectiveToolCall.id,
          error: 'No such tool: "${effectiveToolCall.function.name}"',
          metadata: {
            'kind': 'invalid_tool_call',
            'reason': 'no_such_tool',
            'toolName': effectiveToolCall.function.name,
            'availableTools': toolByName.keys.toList()..sort(),
            'input': effectiveToolCall.function.arguments,
          },
        ),
      );
      if (!continueOnToolError) break;
      continue;
    }

    if (toolDef != null) {
      final errors = ToolValidator.validateParameters(
        parsed.parsed!,
        toolDef.function.parameters,
      );
      if (errors.isNotEmpty) {
        final repaired = await tryRepairToolCall(
          effectiveToolCall,
          reason: 'schema_validation_failed',
          validationErrors: errors,
        );

        if (repaired != null) {
          final repairedCall = ToolCall(
            id: effectiveToolCall.id,
            callType: effectiveToolCall.callType,
            function: FunctionCall(
              name: effectiveToolCall.function.name,
              arguments: repaired,
            ),
            providerOptions: effectiveToolCall.providerOptions,
          );

          final repairedParsed =
              parseToolInput(repairedCall.function.arguments);
          if (repairedParsed.error == null) {
            final repairedErrors = ToolValidator.validateParameters(
              repairedParsed.parsed!,
              toolDef.function.parameters,
            );
            if (repairedErrors.isEmpty) {
              effectiveToolCall = repairedCall;
              parsed = repairedParsed;
            } else {
              results.add(
                ToolResult.error(
                  toolCallId: effectiveToolCall.id,
                  error: 'Parameter validation failed: ${errors.join('; ')}',
                  metadata: {
                    'kind': 'invalid_tool_call',
                    'reason': 'schema_validation_failed',
                    'toolName': effectiveToolCall.function.name,
                    'errors': errors,
                    'input': toolCall.function.arguments,
                    'repairAttempted': true,
                    'repairedInput': repaired,
                    'repairErrors': repairedErrors,
                  },
                ),
              );
              if (!continueOnToolError) break;
              continue;
            }
          } else {
            results.add(
              ToolResult.error(
                toolCallId: effectiveToolCall.id,
                error:
                    '${repairedParsed.error}: "${effectiveToolCall.function.name}"',
                metadata: {
                  'kind': 'invalid_tool_call',
                  'reason': 'schema_validation_failed',
                  'toolName': effectiveToolCall.function.name,
                  'errors': errors,
                  'input': toolCall.function.arguments,
                  'repairAttempted': true,
                  'repairedInput': repaired,
                  'repairError': repairedParsed.error,
                },
              ),
            );
            if (!continueOnToolError) break;
            continue;
          }
        } else {
          results.add(
            ToolResult.error(
              toolCallId: effectiveToolCall.id,
              error: 'Parameter validation failed: ${errors.join('; ')}',
              metadata: {
                'kind': 'invalid_tool_call',
                'reason': 'schema_validation_failed',
                'toolName': effectiveToolCall.function.name,
                'errors': errors,
                'input': effectiveToolCall.function.arguments,
              },
            ),
          );
          if (!continueOnToolError) break;
          continue;
        }
      }
    }

    final handler = toolHandlers[effectiveToolCall.function.name];
    if (handler == null) {
      results.add(
        ToolResult.error(
          toolCallId: effectiveToolCall.id,
          error:
              'No tool handler registered for "${effectiveToolCall.function.name}"',
        ),
      );
      if (!continueOnToolError) break;
      continue;
    }

    try {
      final output = await handler(effectiveToolCall, cancelToken: cancelToken);
      results.add(
        ToolResult.success(
          toolCallId: effectiveToolCall.id,
          result: _normalizeToolOutput(output),
        ),
      );
    } catch (e) {
      results.add(
        ToolResult.error(
          toolCallId: effectiveToolCall.id,
          error: 'Tool execution failed: $e',
        ),
      );
      if (!continueOnToolError) break;
    }
  }

  return results;
}

List<ToolCall> _toToolResultCalls(
  List<ToolCall> toolCalls,
  List<ToolResult> toolResults,
) {
  final byId = <String, ToolCall>{
    for (final c in toolCalls) c.id: c,
  };

  return toolResults.map((r) {
    final original = byId[r.toolCallId];
    final toolName = original?.function.name ?? 'tool';
    final callType = original?.callType ?? 'function';

    final content = _toolCallArgumentsForToolResult(r);

    return ToolCall(
      id: r.toolCallId,
      callType: callType,
      function: FunctionCall(
        name: toolName,
        arguments: content,
      ),
    );
  }).toList();
}

Object? _normalizeToolOutput(Object? output) {
  // AI SDK v3 `tool-result.result` is non-null. Preserve "no output" as empty
  // string rather than JSON null.
  if (output == null) return '';
  if (output is String || output is num || output is bool) return output;

  if (output is Map) {
    final out = <String, Object?>{};
    output.forEach((k, v) {
      out[k.toString()] = _normalizeToolOutput(v);
    });
    return out;
  }

  if (output is List) {
    return output.map(_normalizeToolOutput).toList(growable: false);
  }

  // Best-effort fallback: preserve something JSON-safe.
  return output.toString();
}

String _toolCallArgumentsForToolResult(ToolResult result) {
  if (result.isError) {
    return jsonEncode({'error': result.result});
  }

  final value = result.result;
  if (value == null) return 'null';
  if (value is String) return value;

  try {
    return jsonEncode(value);
  } catch (_) {
    return value.toString();
  }
}

class _FakeChatResponseForStreaming implements ChatResponse {
  @override
  final String? text;

  @override
  final List<ToolCall>? toolCalls;

  @override
  final String? thinking;

  @override
  final UsageInfo? usage;

  @override
  Map<String, dynamic>? get providerMetadata => null;

  const _FakeChatResponseForStreaming({
    this.text,
    this.thinking,
    this.usage,
  }) : toolCalls = null;
}
