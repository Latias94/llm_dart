import 'dart:async';
import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'ensure_single_finish.dart';
import 'ensure_block_ids.dart';
import 'ensure_stream_start.dart';
import 'prompt_input.dart';
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
      _promptMessageFromChatMessage(message),
    ],
  );
}

PromptMessage _promptMessageFromChatMessage(ChatMessage message) {
  final providerOptions = message.providerOptions;
  final parts = <PromptPart>[];

  void addTextIfPresent([String? text]) {
    final effective = text ?? '';
    if (effective.trim().isEmpty) return;
    parts.add(TextPart(effective));
  }

  // Protocol-internal: preserve Anthropic-compatible tool_use blocks that must
  // be persisted across requests for tool loop continuity.
  final anthropic = message.getProtocolPayload('anthropic');
  if (anthropic is Map) {
    final contentBlocks = anthropic['contentBlocks'];
    if (contentBlocks is List) {
      for (final raw in contentBlocks) {
        if (raw is! Map) continue;
        final type = raw['type'];
        if (type is! String) continue;

        final cacheControl = raw['cache_control'];
        final blockProviderOptions = cacheControl is Map<String, dynamic>
            ? {
                'anthropic': {'cacheControl': cacheControl},
              }
            : const <String, Map<String, dynamic>>{};

        switch (type) {
          case 'text':
            final text = raw['text']?.toString() ?? '';
            if (text.trim().isEmpty) continue;
            parts.add(TextPart(text, providerOptions: blockProviderOptions));
            break;

          case 'tool_use':
            if (message.role != ChatRole.assistant) {
              throw const InvalidRequestError(
                'Anthropic tool_use blocks must be emitted from an assistant message.',
              );
            }
            final id = raw['id']?.toString() ?? '';
            final name = raw['name']?.toString() ?? '';
            final input = raw['input'];
            parts.add(
              ToolCallPart(
                ToolCall(
                  id: id,
                  callType: 'function',
                  function: FunctionCall(
                    name: name,
                    arguments: jsonEncode(input ?? const <String, dynamic>{}),
                  ),
                ),
                providerOptions: blockProviderOptions,
              ),
            );
            break;

          case 'tool_result':
            if (message.role != ChatRole.user) {
              throw const InvalidRequestError(
                'Anthropic tool_result blocks must be emitted from a user message.',
              );
            }
            final toolUseId = raw['tool_use_id']?.toString() ?? '';
            final content = raw['content']?.toString() ?? '';
            final isError = raw['is_error'];
            final toolResultProviderOptions = <String, Map<String, dynamic>>{
              ...blockProviderOptions,
              if (isError == true) 'anthropic': {'isError': true},
            };
            parts.add(
              ToolResultPart(
                ToolCall(
                  id: toolUseId,
                  callType: 'function',
                  function: FunctionCall(
                    name: '',
                    arguments: content,
                  ),
                  providerOptions: toolResultProviderOptions,
                ),
                providerOptions: toolResultProviderOptions,
              ),
            );
            break;

          case 'thinking':
          case 'redacted_thinking':
            // Not part of the stable prompt surface; skip.
            break;

          case 'image':
            if (message.role == ChatRole.system) {
              throw const InvalidRequestError(
                'System messages cannot contain images.',
              );
            }
            final source = raw['source'];
            if (source is Map && source['type'] == 'base64') {
              final mediaType = source['media_type']?.toString() ?? '';
              final data = source['data']?.toString() ?? '';
              if (mediaType.isNotEmpty && data.isNotEmpty) {
                parts.add(
                  ImagePart(
                    mime: _imageMimeFromMediaType(mediaType),
                    data: base64Decode(data),
                    providerOptions: blockProviderOptions,
                  ),
                );
              }
            }
            break;

          case 'document':
            if (message.role == ChatRole.system) {
              throw const InvalidRequestError(
                'System messages cannot contain files.',
              );
            }
            final source = raw['source'];
            if (source is Map && source['type'] == 'base64') {
              final mediaType = source['media_type']?.toString() ?? '';
              final data = source['data']?.toString() ?? '';
              if (mediaType.isNotEmpty && data.isNotEmpty) {
                parts.add(
                  FilePart(
                    mime: FileMime(mediaType),
                    data: base64Decode(data),
                    providerOptions: blockProviderOptions,
                  ),
                );
              }
            }
            break;
        }
      }
    }
  }

  switch (message.messageType) {
    case TextMessage():
      if (parts.isEmpty) {
        addTextIfPresent(message.content);
      }

    case ImageMessage(mime: final mime, data: final data):
      if (message.role == ChatRole.system) {
        throw const InvalidRequestError(
          'System messages cannot contain images.',
        );
      }
      if (parts.isEmpty) {
        addTextIfPresent(message.content);
        parts.add(ImagePart(mime: mime, data: data));
      }

    case ImageUrlMessage(url: final url):
      if (message.role == ChatRole.system) {
        throw const InvalidRequestError(
          'System messages cannot contain image URLs.',
        );
      }
      if (parts.isEmpty) {
        addTextIfPresent(message.content);
        parts.add(ImageUrlPart(url: url));
      }

    case FileMessage(mime: final mime, data: final data):
      if (message.role == ChatRole.system) {
        throw const InvalidRequestError(
          'System messages cannot contain files.',
        );
      }
      if (parts.isEmpty) {
        addTextIfPresent(message.content);
        parts.add(FilePart(mime: mime, data: data));
      }

    case ToolUseMessage(toolCalls: final toolCalls):
      if (message.role != ChatRole.assistant) {
        throw const InvalidRequestError(
          'ToolUseMessage must be emitted from an assistant message.',
        );
      }
      if (parts.isEmpty) {
        addTextIfPresent(message.content);
        for (final toolCall in toolCalls) {
          parts.add(ToolCallPart(toolCall));
        }
      }

    case ToolResultMessage(results: final results):
      if (message.role != ChatRole.user) {
        throw const InvalidRequestError(
          'ToolResultMessage must be emitted from a user message.',
        );
      }
      if (parts.isEmpty) {
        addTextIfPresent(message.content);
        for (final toolResult in results) {
          parts.add(ToolResultPart(toolResult));
        }
      }
  }

  if (parts.isEmpty) {
    throw InvalidRequestError(
      'Cannot convert empty ChatMessage (${message.role.name}) to PromptMessage.',
    );
  }

  return PromptMessage(
    role: message.role,
    parts: List<PromptPart>.unmodifiable(parts),
    name: message.name,
    providerOptions: providerOptions,
    protocolPayloads: message.protocolPayloads,
  );
}

ImageMime _imageMimeFromMediaType(String mediaType) {
  switch (mediaType) {
    case 'image/jpeg':
      return ImageMime.jpeg;
    case 'image/png':
      return ImageMime.png;
    case 'image/gif':
      return ImageMime.gif;
    case 'image/webp':
      return ImageMime.webp;
    default:
      return ImageMime.jpeg;
  }
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
        ),
      );

      return ToolLoopResult(
        finalResult: stepResult,
        steps: steps,
        messages: List<ChatMessage>.unmodifiable(workingMessages),
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
        ),
      );

      return ToolLoopResult(
        finalResult: stepResult,
        steps: steps,
        messages: List<ChatMessage>.unmodifiable(workingMessages),
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
        ),
      );

      return ToolLoopCompleted(
        ToolLoopResult(
          finalResult: stepResult,
          steps: steps,
          messages: List<ChatMessage>.unmodifiable(workingMessages),
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
        ),
      );

      return ToolLoopCompleted(
        ToolLoopResult(
          finalResult: stepResult,
          steps: steps,
          messages: List<ChatMessage>.unmodifiable(workingMessages),
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
              ),
              toolCalls: List<ToolCall>.unmodifiable(completedToolCalls),
              toolCallsNeedingApproval:
                  List<ToolCall>.unmodifiable(needingApproval),
              steps: const [],
              messages: List<ChatMessage>.unmodifiable(workingMessages),
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
    ensureBlockIdsPart(
      ensureSingleFinishPart(upstream()),
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
            ),
            toolCalls: List<ToolCall>.unmodifiable(completedToolCalls),
            toolCallsNeedingApproval:
                List<ToolCall>.unmodifiable(needingApproval),
            steps: const [],
            messages: List<ChatMessage>.unmodifiable(workingMessages),
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
