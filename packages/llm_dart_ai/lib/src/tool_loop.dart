import 'dart:async';
import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

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

    final stepResult = GenerateTextResult(
      rawResponse: response,
      text: response.text,
      thinking: response.thinking,
      toolCalls: response.toolCalls,
      usage: response.usage,
    );

    final toolCalls = response.toolCalls ?? const <ToolCall>[];
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
      toolHandlers: toolHandlers,
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

Future<ToolLoopResult> _runToolLoopPromptIr({
  required ChatCapability model,
  required Prompt prompt,
  List<Tool>? tools,
  required Map<String, ToolCallHandler> toolHandlers,
  Map<String, ToolApprovalCheck>? toolApprovalChecks,
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool continueOnToolError = true,
  CancelToken? cancelToken,
}) async {
  if (model is! PromptChatCapability) {
    return runToolLoop(
      model: model,
      messages: prompt.toChatMessages(),
      tools: tools,
      toolHandlers: toolHandlers,
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
  final workingMessages = List<ChatMessage>.from(prompt.toChatMessages());
  final steps = <ToolLoopStep>[];

  final promptCapable = model as PromptChatCapability;

  for (var stepIndex = 0; stepIndex < maxSteps; stepIndex++) {
    final response = await promptCapable.chatPrompt(
      workingPrompt,
      tools: tools,
      cancelToken: cancelToken,
    );

    final stepResult = GenerateTextResult(
      rawResponse: response,
      text: response.text,
      thinking: response.thinking,
      toolCalls: response.toolCalls,
      usage: response.usage,
    );

    final toolCalls = response.toolCalls ?? const <ToolCall>[];
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
      toolHandlers: toolHandlers,
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

/// Run a non-streaming tool loop starting from a `Prompt` IR (Vercel-style).
@Deprecated('Use runToolLoop(model: ..., promptIr: ...) instead.')
Future<ToolLoopResult> runToolLoopFromPromptIr({
  required ChatCapability model,
  required Prompt prompt,
  List<Tool>? tools,
  required Map<String, ToolCallHandler> toolHandlers,
  Map<String, ToolApprovalCheck>? toolApprovalChecks,
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool continueOnToolError = true,
  CancelToken? cancelToken,
}) {
  return runToolLoop(
    model: model,
    promptIr: prompt,
    tools: tools,
    toolHandlers: toolHandlers,
    toolApprovalChecks: toolApprovalChecks,
    needsApproval: needsApproval,
    maxSteps: maxSteps,
    continueOnToolError: continueOnToolError,
    cancelToken: cancelToken,
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

    final stepResult = GenerateTextResult(
      rawResponse: response,
      text: response.text,
      thinking: response.thinking,
      toolCalls: response.toolCalls,
      usage: response.usage,
    );

    final toolCalls = response.toolCalls ?? const <ToolCall>[];
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
      toolHandlers: toolHandlers,
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
  Map<String, ToolApprovalCheck>? toolApprovalChecks,
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool continueOnToolError = true,
  CancelToken? cancelToken,
}) async {
  if (model is! PromptChatCapability) {
    return runToolLoopUntilBlocked(
      model: model,
      messages: prompt.toChatMessages(),
      tools: tools,
      toolHandlers: toolHandlers,
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
  final workingMessages = List<ChatMessage>.from(prompt.toChatMessages());
  final steps = <ToolLoopStep>[];

  final promptCapable = model as PromptChatCapability;

  for (var stepIndex = 0; stepIndex < maxSteps; stepIndex++) {
    final response = await promptCapable.chatPrompt(
      workingPrompt,
      tools: tools,
      cancelToken: cancelToken,
    );

    final stepResult = GenerateTextResult(
      rawResponse: response,
      text: response.text,
      thinking: response.thinking,
      toolCalls: response.toolCalls,
      usage: response.usage,
    );

    final toolCalls = response.toolCalls ?? const <ToolCall>[];
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
      toolHandlers: toolHandlers,
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

/// Run a tool loop until blocked starting from a `Prompt` IR (Vercel-style).
@Deprecated('Use runToolLoopUntilBlocked(model: ..., promptIr: ...) instead.')
Future<ToolLoopRunOutcome> runToolLoopUntilBlockedFromPromptIr({
  required ChatCapability model,
  required Prompt prompt,
  List<Tool>? tools,
  required Map<String, ToolCallHandler> toolHandlers,
  Map<String, ToolApprovalCheck>? toolApprovalChecks,
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool continueOnToolError = true,
  CancelToken? cancelToken,
}) {
  return runToolLoopUntilBlocked(
    model: model,
    promptIr: prompt,
    tools: tools,
    toolHandlers: toolHandlers,
    toolApprovalChecks: toolApprovalChecks,
    needsApproval: needsApproval,
    maxSteps: maxSteps,
    continueOnToolError: continueOnToolError,
    cancelToken: cancelToken,
  );
}

/// Stream a tool loop as provider-agnostic stream parts.
///
/// This behaves like [streamText], but automatically runs a non-streaming tool
/// loop under the hood:
/// - For each step, stream model output parts.
/// - If the step results in tool calls, execute them locally and continue with a
///   next step by appending tool messages.
/// - Once a step completes without tool calls, emit a final [FinishPart].
Stream<TextStreamPart> streamToolLoop({
  required ChatCapability model,
  String? system,
  String? prompt,
  List<ChatMessage>? messages,
  Prompt? promptIr,
  List<Tool>? tools,
  required Map<String, ToolCallHandler> toolHandlers,
  Map<String, ToolApprovalCheck>? toolApprovalChecks,
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool continueOnToolError = true,
  CancelToken? cancelToken,
}) {
  final input = standardizePromptInput(
    system: system,
    prompt: prompt,
    messages: messages,
    promptIr: promptIr,
  );

  if (input is StandardizedPromptIr) {
    return _mapPartsToLegacyTextStreamParts(
      streamToolLoopParts(
        model: model,
        promptIr: input.prompt,
        tools: tools,
        toolHandlers: toolHandlers,
        toolApprovalChecks: toolApprovalChecks,
        needsApproval: needsApproval,
        maxSteps: maxSteps,
        continueOnToolError: continueOnToolError,
        cancelToken: cancelToken,
      ),
    );
  }

  final standardizedMessages = (input as StandardizedChatMessages).messages;

  return _mapPartsToLegacyTextStreamParts(
    streamToolLoopParts(
      model: model,
      messages: standardizedMessages,
      tools: tools,
      toolHandlers: toolHandlers,
      toolApprovalChecks: toolApprovalChecks,
      needsApproval: needsApproval,
      maxSteps: maxSteps,
      continueOnToolError: continueOnToolError,
      cancelToken: cancelToken,
    ),
  );
}

/// Stream a tool loop (legacy `TextStreamPart`) starting from a `Prompt` IR.
///
/// This is a compatibility wrapper over [streamToolLoopPartsFromPromptIr].
/// Prefer [streamToolLoopPartsFromPromptIr] for Vercel-style structured parts.
@Deprecated(
  'Use streamToolLoop(model: ..., promptIr: ...) or '
  'streamToolLoopParts(model: ..., promptIr: ...) instead.',
)
Stream<TextStreamPart> streamToolLoopFromPromptIr({
  required ChatCapability model,
  required Prompt prompt,
  List<Tool>? tools,
  required Map<String, ToolCallHandler> toolHandlers,
  Map<String, ToolApprovalCheck>? toolApprovalChecks,
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool continueOnToolError = true,
  CancelToken? cancelToken,
}) {
  return streamToolLoop(
    model: model,
    promptIr: prompt,
    tools: tools,
    toolHandlers: toolHandlers,
    toolApprovalChecks: toolApprovalChecks,
    needsApproval: needsApproval,
    maxSteps: maxSteps,
    continueOnToolError: continueOnToolError,
    cancelToken: cancelToken,
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

/// ToolSet variant of [streamToolLoop].
Stream<TextStreamPart> streamToolLoopWithToolSet({
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
  return streamToolLoop(
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

/// ToolSet variant of [streamToolLoopFromPromptIr].
@Deprecated('Use streamToolLoopWithToolSet(model: ..., promptIr: ...) instead.')
Stream<TextStreamPart> streamToolLoopWithToolSetFromPromptIr({
  required ChatCapability model,
  required Prompt prompt,
  required ToolSet toolSet,
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool continueOnToolError = true,
  CancelToken? cancelToken,
}) {
  return streamToolLoopWithToolSet(
    model: model,
    promptIr: prompt,
    toolSet: toolSet,
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

/// ToolSet variant of [streamToolLoop] that can stop when approval is required.
Stream<TextStreamPart> streamToolLoopUntilBlockedWithToolSet({
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
  return streamToolLoop(
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

class _MergedChatResponseForStreaming implements ChatResponse {
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
  Map<String, dynamic>? get providerMetadata => raw.providerMetadata;
}

/// Stream a tool loop as Vercel-style stream parts.
///
/// Differences vs [streamToolLoop]:
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
  Map<String, ToolApprovalCheck>? toolApprovalChecks,
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool continueOnToolError = true,
  CancelToken? cancelToken,
}) async* {
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
      toolApprovalChecks: toolApprovalChecks,
      needsApproval: needsApproval,
      maxSteps: maxSteps,
      continueOnToolError: continueOnToolError,
      cancelToken: cancelToken,
    );
    return;
  }

  final standardizedMessages = (input as StandardizedChatMessages).messages;

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

    final usesNativeParts = model is ChatStreamPartsCapability;
    var didEmitProviderMetadataPart = false;

    if (usesNativeParts) {
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
    } else {
      var inText = false;
      var inThinking = false;

      await for (final event in model.chatStream(
        workingMessages,
        tools: tools,
        cancelToken: cancelToken,
      )) {
        switch (event) {
          case TextDeltaEvent(:final delta):
            if (!inText) {
              inText = true;
              yield const LLMTextStartPart();
            }
            fullText.write(delta);
            yield LLMTextDeltaPart(delta);

          case ThinkingDeltaEvent(:final delta):
            if (!inThinking) {
              inThinking = true;
              yield const LLMReasoningStartPart();
            }
            fullThinking.write(delta);
            yield LLMReasoningDeltaPart(delta);

          case ToolCallDeltaEvent(:final toolCall):
            final accum =
                toolAccums.putIfAbsent(toolCall.id, () => _ToolCallAccum());
            accum.callType = toolCall.callType;
            if (toolCall.function.name.isNotEmpty) {
              accum.name = toolCall.function.name;
            }
            if (toolCall.function.arguments.isNotEmpty) {
              accum.arguments.write(toolCall.function.arguments);
            }

            if (startedToolCalls.add(toolCall.id)) {
              yield LLMToolCallStartPart(toolCall);
            } else {
              yield LLMToolCallDeltaPart(toolCall);
            }

          case CompletionEvent(:final response):
            completedResponse = response;
            usage = response.usage;

          case ErrorEvent(:final error):
            yield LLMErrorPart(error);
            return;
        }
      }

      if (inText) {
        yield LLMTextEndPart(fullText.toString());
      }
      if (inThinking) {
        yield LLMReasoningEndPart(fullThinking.toString());
      }
      for (final toolCallId in startedToolCalls) {
        yield LLMToolCallEndPart(toolCallId);
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
        .toList(growable: false);

    if (usesNativeParts && !didEmitProviderMetadataPart) {
      final providerMetadata = mergedResponse.providerMetadata;
      if (providerMetadata != null && providerMetadata.isNotEmpty) {
        yield LLMProviderMetadataPart(providerMetadata);
      }
    } else if (!usesNativeParts) {
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

      yield LLMFinishPart(mergedResponse);
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
        workingMessages.add(ChatMessage.toolUse(toolCalls: completedToolCalls));
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
      toolHandlers: toolHandlers,
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

Stream<LLMStreamPart> _streamToolLoopPartsPromptIr({
  required ChatCapability model,
  required Prompt prompt,
  List<Tool>? tools,
  required Map<String, ToolCallHandler> toolHandlers,
  Map<String, ToolApprovalCheck>? toolApprovalChecks,
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool continueOnToolError = true,
  CancelToken? cancelToken,
}) async* {
  final hasPromptStreamParts = model is PromptChatStreamPartsCapability;
  final hasPromptStream = model is PromptChatCapability;

  if (!hasPromptStreamParts && !hasPromptStream) {
    yield* streamToolLoopParts(
      model: model,
      messages: prompt.toChatMessages(),
      tools: tools,
      toolHandlers: toolHandlers,
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
  final workingMessages = List<ChatMessage>.from(prompt.toChatMessages());

  for (var stepIndex = 0; stepIndex < maxSteps; stepIndex++) {
    final toolAccums = <String, _ToolCallAccum>{};
    final fullText = StringBuffer();
    final fullThinking = StringBuffer();
    UsageInfo? usage;
    ChatResponse? completedResponse;

    final startedToolCalls = <String>{};

    var didEmitProviderMetadataPart = false;

    if (hasPromptStreamParts) {
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
    } else {
      final promptCapable = model as PromptChatCapability;

      var inText = false;
      var inThinking = false;

      await for (final event in promptCapable.chatPromptStream(
        workingPrompt,
        tools: tools,
        cancelToken: cancelToken,
      )) {
        switch (event) {
          case TextDeltaEvent(:final delta):
            if (!inText) {
              inText = true;
              yield const LLMTextStartPart();
            }
            fullText.write(delta);
            yield LLMTextDeltaPart(delta);

          case ThinkingDeltaEvent(:final delta):
            if (!inThinking) {
              inThinking = true;
              yield const LLMReasoningStartPart();
            }
            fullThinking.write(delta);
            yield LLMReasoningDeltaPart(delta);

          case ToolCallDeltaEvent(:final toolCall):
            final accum =
                toolAccums.putIfAbsent(toolCall.id, () => _ToolCallAccum());
            accum.callType = toolCall.callType;
            if (toolCall.function.name.isNotEmpty) {
              accum.name = toolCall.function.name;
            }
            if (toolCall.function.arguments.isNotEmpty) {
              accum.arguments.write(toolCall.function.arguments);
            }

            if (startedToolCalls.add(toolCall.id)) {
              yield LLMToolCallStartPart(toolCall);
            } else {
              yield LLMToolCallDeltaPart(toolCall);
            }

          case CompletionEvent(:final response):
            completedResponse = response;
            usage = response.usage;

          case ErrorEvent(:final error):
            yield LLMErrorPart(error);
            return;
        }
      }

      if (inText) {
        yield LLMTextEndPart(fullText.toString());
      }
      if (inThinking) {
        yield LLMReasoningEndPart(fullThinking.toString());
      }
      for (final toolCallId in startedToolCalls) {
        yield LLMToolCallEndPart(toolCallId);
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
        .toList(growable: false);

    if (hasPromptStreamParts && !didEmitProviderMetadataPart) {
      final providerMetadata = mergedResponse.providerMetadata;
      if (providerMetadata != null && providerMetadata.isNotEmpty) {
        yield LLMProviderMetadataPart(providerMetadata);
      }
    } else if (!hasPromptStreamParts) {
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

      yield LLMFinishPart(mergedResponse);
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
      toolHandlers: toolHandlers,
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

/// Stream a tool loop as Vercel-style stream parts from a `Prompt` IR.
@Deprecated('Use streamToolLoopParts(model: ..., promptIr: ...) instead.')
Stream<LLMStreamPart> streamToolLoopPartsFromPromptIr({
  required ChatCapability model,
  required Prompt prompt,
  List<Tool>? tools,
  required Map<String, ToolCallHandler> toolHandlers,
  Map<String, ToolApprovalCheck>? toolApprovalChecks,
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool continueOnToolError = true,
  CancelToken? cancelToken,
}) {
  return streamToolLoopParts(
    model: model,
    promptIr: prompt,
    tools: tools,
    toolHandlers: toolHandlers,
    toolApprovalChecks: toolApprovalChecks,
    needsApproval: needsApproval,
    maxSteps: maxSteps,
    continueOnToolError: continueOnToolError,
    cancelToken: cancelToken,
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
    toolApprovalChecks: toolSet.approvalChecks,
    needsApproval: needsApproval,
    maxSteps: maxSteps,
    continueOnToolError: continueOnToolError,
    cancelToken: cancelToken,
  );
}

/// ToolSet variant of [streamToolLoopPartsFromPromptIr].
@Deprecated(
    'Use streamToolLoopPartsWithToolSet(model: ..., promptIr: ...) instead.')
Stream<LLMStreamPart> streamToolLoopPartsWithToolSetFromPromptIr({
  required ChatCapability model,
  required Prompt prompt,
  required ToolSet toolSet,
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool continueOnToolError = true,
  CancelToken? cancelToken,
}) {
  return streamToolLoopPartsWithToolSet(
    model: model,
    promptIr: prompt,
    toolSet: toolSet,
    needsApproval: needsApproval,
    maxSteps: maxSteps,
    continueOnToolError: continueOnToolError,
    cancelToken: cancelToken,
  );
}

/// Execute tool calls locally and return a list of tool results.
Future<List<ToolResult>> executeToolCalls({
  required List<ToolCall> toolCalls,
  required Map<String, ToolCallHandler> toolHandlers,
  bool continueOnToolError = true,
  CancelToken? cancelToken,
}) {
  return _executeToolCalls(
    toolCalls: toolCalls,
    toolHandlers: toolHandlers,
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
  required Map<String, ToolCallHandler> toolHandlers,
  required bool continueOnToolError,
  CancelToken? cancelToken,
}) async {
  final results = <ToolResult>[];

  for (final toolCall in toolCalls) {
    final handler = toolHandlers[toolCall.function.name];
    if (handler == null) {
      results.add(
        ToolResult.error(
          toolCallId: toolCall.id,
          errorMessage:
              'No tool handler registered for "${toolCall.function.name}"',
        ),
      );
      if (!continueOnToolError) break;
      continue;
    }

    try {
      final output = await handler(toolCall, cancelToken: cancelToken);
      final content = _stringifyToolOutput(output);
      results
          .add(ToolResult.success(toolCallId: toolCall.id, content: content));
    } catch (e) {
      results.add(
        ToolResult.error(
          toolCallId: toolCall.id,
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

Stream<TextStreamPart> _mapPartsToLegacyTextStreamParts(
  Stream<LLMStreamPart> parts,
) async* {
  await for (final part in parts) {
    switch (part) {
      case LLMTextDeltaPart(:final delta):
        yield TextDeltaPart(delta);

      case LLMReasoningDeltaPart(:final delta):
        yield ThinkingDeltaPart(delta);

      case LLMToolCallStartPart(:final toolCall):
        yield ToolCallDeltaPart(toolCall);

      case LLMToolCallDeltaPart(:final toolCall):
        yield ToolCallDeltaPart(toolCall);

      case LLMFinishPart(:final response):
        yield FinishPart(
          GenerateTextResult(
            rawResponse: response,
            text: response.text,
            thinking: response.thinking,
            toolCalls: response.toolCalls,
            usage: response.usage,
          ),
        );

      case LLMErrorPart(:final error):
        yield ErrorPart(error);

      case LLMTextStartPart():
      case LLMTextEndPart():
      case LLMReasoningStartPart():
      case LLMReasoningEndPart():
      case LLMToolCallEndPart():
      case LLMProviderMetadataPart():
      case LLMToolResultPart():
        // Not represented in legacy TextStreamPart.
        break;
    }
  }
}
