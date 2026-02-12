import 'dart:async';
import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

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

List<ToolCall> _onlyLocalFunctionToolCalls(List<ToolCall>? toolCalls) {
  if (toolCalls == null || toolCalls.isEmpty) return const [];
  final filtered = toolCalls.where(_isExecutableFunctionToolCall).toList();
  return filtered.isEmpty ? const [] : List<ToolCall>.unmodifiable(filtered);
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
  CancelToken? cancelToken,
}) async {
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
      cancelToken: cancelToken,
    );
  }

  final standardizedMessages = (input as StandardizedChatMessages).messages;

  if (maxSteps < 1) {
    throw const InvalidRequestError('maxSteps must be >= 1');
  }

  final workingMessages = List<ChatMessage>.from(standardizedMessages);
  final steps = <ToolLoopStep>[];

  for (var stepIndex = 0; stepIndex < maxSteps; stepIndex++) {
    final startedAt = DateTime.now().toUtc();
    final response = await model.chatWithTools(
      workingMessages,
      tools,
      cancelToken: cancelToken,
    );

    final toolCalls = _onlyLocalFunctionToolCalls(response.toolCalls);

    final stepResult = GenerateTextResult(
      rawResponse: response,
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
      responseMetadata: response is ChatResponseWithResponseMetadata
          ? responseMetadataWithInclude(
              responseMetadataWithTimestampFallback(
                response.responseMetadata,
                startedAt,
              ),
              include,
            )
          : null,
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

      if (response is ChatResponseWithAssistantMessage) {
        workingMessages.add(response.assistantMessage);
      } else {
        workingMessages.add(ChatMessage.toolUse(toolCalls: toolCalls));
      }

      throw ToolApprovalRequiredError(
        state: ToolLoopBlockedState(
          stepIndex: stepIndex,
          stepResult: stepResult,
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
      toolCalls: toolCalls,
      tools: tools,
      toolHandlers: toolHandlers,
      repairToolCall: repairToolCall,
      continueOnToolError: continueOnToolError,
      cancelToken: cancelToken,
    );

    steps.add(
      ToolLoopStep(
        index: stepIndex,
        result: stepResult,
        toolCalls: List<ToolCall>.unmodifiable(toolCalls),
        toolResults: List<ToolResult>.unmodifiable(executed),
        responseMetadata: stepResult.responseMetadata,
        requestMetadata: stepResult.requestMetadata,
        responsePromptMessages: [
          ...stepResult.responsePromptMessages,
          buildToolResultPromptMessageBestEffort(
            toolCalls: toolCalls,
            toolResults: executed,
          ),
        ],
      ),
    );

    // Persist the tool call request and tool results in message history.
    if (response is ChatResponseWithAssistantMessage) {
      workingMessages.add(response.assistantMessage);
    } else {
      workingMessages.add(ChatMessage.toolUse(toolCalls: toolCalls));
    }
    workingMessages.add(
      ChatMessage.toolResult(
        results: _toToolResultCalls(toolCalls, executed),
      ),
    );
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
      cancelToken: cancelToken,
    );
  }

  if (maxSteps < 1) {
    throw const InvalidRequestError('maxSteps must be >= 1');
  }

  var workingPrompt = prompt;
  final workingMessages = List<ChatMessage>.from(
    _promptToLegacyChatMessagesBestEffort(prompt),
  );
  final steps = <ToolLoopStep>[];

  final promptCapable = model as PromptChatCapability;

  for (var stepIndex = 0; stepIndex < maxSteps; stepIndex++) {
    final startedAt = DateTime.now().toUtc();
    final response = await promptCapable.chatPrompt(
      workingPrompt,
      tools: tools,
      cancelToken: cancelToken,
    );

    final toolCalls = _onlyLocalFunctionToolCalls(response.toolCalls);

    final stepResult = GenerateTextResult(
      rawResponse: response,
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
      responseMetadata: response is ChatResponseWithResponseMetadata
          ? responseMetadataWithInclude(
              responseMetadataWithTimestampFallback(
                response.responseMetadata,
                startedAt,
              ),
              include,
            )
          : null,
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

      throw ToolApprovalRequiredError(
        state: ToolLoopBlockedState(
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
      toolCalls: toolCalls,
      tools: tools,
      toolHandlers: toolHandlers,
      repairToolCall: repairToolCall,
      continueOnToolError: continueOnToolError,
      cancelToken: cancelToken,
    );

    steps.add(
      ToolLoopStep(
        index: stepIndex,
        result: stepResult,
        toolCalls: List<ToolCall>.unmodifiable(toolCalls),
        toolResults: List<ToolResult>.unmodifiable(executed),
        responseMetadata: stepResult.responseMetadata,
        requestMetadata: stepResult.requestMetadata,
        responsePromptMessages: [
          ...stepResult.responsePromptMessages,
          buildToolResultPromptMessageBestEffort(
            toolCalls: toolCalls,
            toolResults: executed,
          ),
        ],
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

    final toolResultMessage = ChatMessage.toolResult(
      results: _toToolResultCalls(toolCalls, executed),
    );
    workingMessages.add(toolResultMessage);
    workingPrompt =
        _appendChatMessageToPrompt(workingPrompt, toolResultMessage);
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
  CancelToken? cancelToken,
}) async {
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
      cancelToken: cancelToken,
    );
  }

  final standardizedMessages = (input as StandardizedChatMessages).messages;

  if (maxSteps < 1) {
    throw const InvalidRequestError('maxSteps must be >= 1');
  }

  final workingMessages = List<ChatMessage>.from(standardizedMessages);
  final steps = <ToolLoopStep>[];

  for (var stepIndex = 0; stepIndex < maxSteps; stepIndex++) {
    final startedAt = DateTime.now().toUtc();
    final response = await model.chatWithTools(
      workingMessages,
      tools,
      cancelToken: cancelToken,
    );

    final toolCalls = _onlyLocalFunctionToolCalls(response.toolCalls);

    final stepResult = GenerateTextResult(
      rawResponse: response,
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
      responseMetadata: response is ChatResponseWithResponseMetadata
          ? responseMetadataWithInclude(
              responseMetadataWithTimestampFallback(
                response.responseMetadata,
                startedAt,
              ),
              include,
            )
          : null,
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

      if (response is ChatResponseWithAssistantMessage) {
        workingMessages.add(response.assistantMessage);
      } else {
        workingMessages.add(ChatMessage.toolUse(toolCalls: toolCalls));
      }

      return ToolLoopBlocked(
        ToolLoopBlockedState(
          stepIndex: stepIndex,
          stepResult: stepResult,
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
      toolCalls: toolCalls,
      tools: tools,
      toolHandlers: toolHandlers,
      repairToolCall: repairToolCall,
      continueOnToolError: continueOnToolError,
      cancelToken: cancelToken,
    );

    steps.add(
      ToolLoopStep(
        index: stepIndex,
        result: stepResult,
        toolCalls: List<ToolCall>.unmodifiable(toolCalls),
        toolResults: List<ToolResult>.unmodifiable(executed),
        responseMetadata: stepResult.responseMetadata,
        requestMetadata: stepResult.requestMetadata,
        responsePromptMessages: [
          ...stepResult.responsePromptMessages,
          buildToolResultPromptMessageBestEffort(
            toolCalls: toolCalls,
            toolResults: executed,
          ),
        ],
      ),
    );

    if (response is ChatResponseWithAssistantMessage) {
      workingMessages.add(response.assistantMessage);
    } else {
      workingMessages.add(ChatMessage.toolUse(toolCalls: toolCalls));
    }
    workingMessages.add(
      ChatMessage.toolResult(
        results: _toToolResultCalls(toolCalls, executed),
      ),
    );
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
      cancelToken: cancelToken,
    );
  }

  if (maxSteps < 1) {
    throw const InvalidRequestError('maxSteps must be >= 1');
  }

  var workingPrompt = prompt;
  final workingMessages = List<ChatMessage>.from(
    _promptToLegacyChatMessagesBestEffort(prompt),
  );
  final steps = <ToolLoopStep>[];

  final promptCapable = model as PromptChatCapability;

  for (var stepIndex = 0; stepIndex < maxSteps; stepIndex++) {
    final startedAt = DateTime.now().toUtc();
    final response = await promptCapable.chatPrompt(
      workingPrompt,
      tools: tools,
      cancelToken: cancelToken,
    );

    final toolCalls = _onlyLocalFunctionToolCalls(response.toolCalls);

    final stepResult = GenerateTextResult(
      rawResponse: response,
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
      responseMetadata: response is ChatResponseWithResponseMetadata
          ? responseMetadataWithInclude(
              responseMetadataWithTimestampFallback(
                response.responseMetadata,
                startedAt,
              ),
              include,
            )
          : null,
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
      toolCalls: toolCalls,
      tools: tools,
      toolHandlers: toolHandlers,
      repairToolCall: repairToolCall,
      continueOnToolError: continueOnToolError,
      cancelToken: cancelToken,
    );

    steps.add(
      ToolLoopStep(
        index: stepIndex,
        result: stepResult,
        toolCalls: List<ToolCall>.unmodifiable(toolCalls),
        toolResults: List<ToolResult>.unmodifiable(executed),
        responseMetadata: stepResult.responseMetadata,
        requestMetadata: stepResult.requestMetadata,
        responsePromptMessages: [
          ...stepResult.responsePromptMessages,
          buildToolResultPromptMessageBestEffort(
            toolCalls: toolCalls,
            toolResults: executed,
          ),
        ],
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

    final toolResultMessage = ChatMessage.toolResult(
      results: _toToolResultCalls(toolCalls, executed),
    );
    workingMessages.add(toolResultMessage);
    workingPrompt =
        _appendChatMessageToPrompt(workingPrompt, toolResultMessage);
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
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool continueOnToolError = true,
  IncludeOptions include = const IncludeOptions(),
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
    toolApprovalChecks: toolSet.approvalChecks,
    needsApproval: needsApproval,
    maxSteps: maxSteps,
    continueOnToolError: continueOnToolError,
    include: include,
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
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool continueOnToolError = true,
  IncludeOptions include = const IncludeOptions(),
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
    toolApprovalChecks: toolSet.approvalChecks,
    needsApproval: needsApproval,
    maxSteps: maxSteps,
    continueOnToolError: continueOnToolError,
    include: include,
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
  bool continueOnToolError = true,
  bool emitStepParts = false,
  IncludeOptions include = const IncludeOptions(),
  CancelToken? cancelToken,
}) async* {
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
        continueOnToolError: continueOnToolError,
        emitStepParts: emitStepParts,
        include: include,
        cancelToken: cancelToken,
      );
      return;
    }

    final standardizedMessages = (input as StandardizedChatMessages).messages;

    if (model is! ChatStreamPartsCapability) {
      yield const LLMErrorPart(
        InvalidRequestError(
          'streamToolLoopParts requires parts-first streaming. Implement '
          '`ChatStreamPartsCapability.chatStreamParts()` (or use a provider that does).',
        ),
      );
      return;
    }

    if (maxSteps < 1) {
      yield const LLMErrorPart(
        InvalidRequestError('maxSteps must be >= 1'),
      );
      return;
    }

    final workingMessages = List<ChatMessage>.from(standardizedMessages);

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

      final partsCapable = model as ChatStreamPartsCapability;

      await for (final part in partsCapable.chatStreamParts(
        workingMessages,
        tools: tools,
        cancelToken: cancelToken,
      )) {
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

        yield LLMFinishPart(
          mergedResponse,
          usage: mergedResponse.usage,
          finishReason: mergedResponse.finishReason,
        );
        return;
      }

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

        yield LLMErrorPart(
          ToolApprovalRequiredError(
            state: ToolLoopBlockedState(
              stepIndex: stepIndex,
              stepResult: GenerateTextResult(
                rawResponse: mergedResponse,
                text: mergedResponse.text,
                thinking: mergedResponse.thinking,
                toolCalls: completedToolCalls,
                usage: mergedResponse.usage,
                finishReason: mergedResponse.finishReason,
                responseMetadata: null,
                responseMessages:
                    buildResponseMessagesBestEffort(mergedResponse),
                responsePromptMessages:
                    buildResponsePromptMessagesBestEffort(mergedResponse),
              ),
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
        toolCalls: completedToolCalls,
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
      workingMessages.add(
        ChatMessage.toolResult(
          results: _toToolResultCalls(completedToolCalls, executed),
        ),
      );
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
  bool continueOnToolError = true,
  bool emitStepParts = false,
  IncludeOptions include = const IncludeOptions(),
  CancelToken? cancelToken,
}) async* {
  final hasPromptStreamParts = model is PromptChatStreamPartsCapability;

  if (!hasPromptStreamParts) {
    requirePromptCapabilityForFileReferenceParts(
      prompt: prompt,
      requiredCapabilityName: '`PromptChatStreamPartsCapability`',
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
      continueOnToolError: continueOnToolError,
      emitStepParts: emitStepParts,
      include: include,
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

    final partsCapable = model as PromptChatStreamPartsCapability;

    await for (final part in partsCapable.chatPromptStreamParts(
      workingPrompt,
      tools: tools,
      cancelToken: cancelToken,
    )) {
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

      yield LLMFinishPart(
        mergedResponse,
        usage: mergedResponse.usage,
        finishReason: mergedResponse.finishReason,
      );
      return;
    }

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

      yield LLMErrorPart(
        ToolApprovalRequiredError(
          state: ToolLoopBlockedState(
            stepIndex: stepIndex,
            stepResult: GenerateTextResult(
              rawResponse: mergedResponse,
              text: mergedResponse.text,
              thinking: mergedResponse.thinking,
              toolCalls: completedToolCalls,
              usage: mergedResponse.usage,
              finishReason: mergedResponse.finishReason,
              responseMetadata: null,
              responseMessages: buildResponseMessagesBestEffort(mergedResponse),
              responsePromptMessages:
                  buildResponsePromptMessagesBestEffort(mergedResponse),
            ),
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
      toolCalls: completedToolCalls,
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

    final toolResultMessage = ChatMessage.toolResult(
      results: _toToolResultCalls(completedToolCalls, executed),
    );
    workingMessages.add(toolResultMessage);
    workingPrompt =
        _appendChatMessageToPrompt(workingPrompt, toolResultMessage);
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
  CancelToken? cancelToken,
}) {
  return streamToolLoopParts(
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
    cancelToken: cancelToken,
  );
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
          errorMessage:
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
              errorMessage:
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
            errorMessage:
                '${parsed.error}: "${effectiveToolCall.function.name}"',
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
          errorMessage: 'No such tool: "${effectiveToolCall.function.name}"',
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
                  errorMessage:
                      'Parameter validation failed: ${errors.join('; ')}',
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
                errorMessage:
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
              errorMessage: 'Parameter validation failed: ${errors.join('; ')}',
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
          errorMessage:
              'No tool handler registered for "${effectiveToolCall.function.name}"',
        ),
      );
      if (!continueOnToolError) break;
      continue;
    }

    try {
      final output = await handler(effectiveToolCall, cancelToken: cancelToken);
      final content = _stringifyToolOutput(output);
      results.add(
        ToolResult.success(toolCallId: effectiveToolCall.id, content: content),
      );
    } catch (e) {
      results.add(
        ToolResult.error(
          toolCallId: effectiveToolCall.id,
          errorMessage: 'Tool execution failed: $e',
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

    final content = r.isError ? jsonEncode({'error': r.content}) : r.content;

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

String _stringifyToolOutput(Object? output) {
  if (output == null) return 'null';
  if (output is String) return output;
  if (output is num || output is bool) return output.toString();

  try {
    return jsonEncode(output);
  } catch (_) {
    return output.toString();
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
