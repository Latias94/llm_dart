// This utility bridges between the new prompt-first model (ModelMessage) and
// the legacy ChatMessage-based chat interface used by providers.
// ChatMessage is intentionally used here as a compatibility layer.
// ignore_for_file: deprecated_member_use_from_same_package

import '../core/capability.dart';
import '../models/chat_models.dart';

/// Resolve input into a list of [ChatMessage]s for text generation.
///
/// 优先使用 prompt-first 的 [promptMessages]（`List<ModelMessage>`），
/// 为了兼容还支持：
/// - [structuredPrompt]：单个 [ModelMessage]
/// - [messages]：旧的 [ChatMessage] 列表
/// - [prompt]：纯文本用户输入
List<ChatMessage> resolveMessagesForTextGeneration({
  String? prompt,
  List<ChatMessage>? messages,
  ModelMessage? structuredPrompt,
  List<ModelMessage>? promptMessages,
  ReasoningPruneMode reasoning = ReasoningPruneMode.none,
  ToolCallPruneMode toolCalls = ToolCallPruneMode.none,
  List<String>? toolNames,
  bool removeEmptyMessages = true,
}) {
  if (promptMessages != null && promptMessages.isNotEmpty) {
    final effectivePrompts = (reasoning != ReasoningPruneMode.none ||
            toolCalls != ToolCallPruneMode.none)
        ? pruneModelMessages(
            messages: promptMessages,
            reasoning: reasoning,
            toolCalls: toolCalls,
            toolNames: toolNames,
            removeEmptyMessages: removeEmptyMessages,
          )
        : promptMessages;

    return effectivePrompts
        .map(ChatMessage.fromPromptMessage)
        .toList(growable: false);
  }

  if (structuredPrompt != null) {
    return [ChatMessage.fromPromptMessage(structuredPrompt)];
  }

  if (messages != null && messages.isNotEmpty) {
    return messages;
  }

  if (prompt != null && prompt.isNotEmpty) {
    return [ChatMessage.user(prompt)];
  }

  throw ArgumentError(
    'You must provide either prompt, messages, or structuredPrompt for text generation.',
  );
}

/// Resolve input into a list of prompt-first [ModelMessage]s for text generation.
///
/// 与 [resolveMessagesForTextGeneration] 相反，这里返回的是 prompt-first
/// 的 [ModelMessage] 列表，接受：
/// - [promptMessages]：首选的 structured prompt；
/// - [structuredPrompt]：单个 [ModelMessage]；
/// - [legacyMessages]：旧的 [ChatMessage]，通过 `toPromptMessage()` 转换；
/// - [prompt]：简单的用户文本。
///
/// [reasoning] / [toolCalls] 可选裁剪行为与
/// [resolveMessagesForTextGeneration] 一致。
List<ModelMessage> resolvePromptMessagesForTextGeneration({
  String? prompt,
  List<ChatMessage>? legacyMessages,
  ModelMessage? structuredPrompt,
  List<ModelMessage>? promptMessages,
  ReasoningPruneMode reasoning = ReasoningPruneMode.none,
  ToolCallPruneMode toolCalls = ToolCallPruneMode.none,
  List<String>? toolNames,
  bool removeEmptyMessages = true,
}) {
  List<ModelMessage>? resolved;

  if (promptMessages != null && promptMessages.isNotEmpty) {
    resolved = promptMessages;
  } else if (structuredPrompt != null) {
    resolved = [structuredPrompt];
  } else if (legacyMessages != null && legacyMessages.isNotEmpty) {
    resolved = legacyMessages
        .map((message) => message.toPromptMessage())
        .toList(growable: false);
  } else if (prompt != null && prompt.isNotEmpty) {
    resolved = <ModelMessage>[
      ModelMessage(
        role: ChatRole.user,
        parts: <ChatContentPart>[
          TextContentPart(prompt),
        ],
      ),
    ];
  } else {
    throw ArgumentError(
      'You must provide either prompt, legacyMessages, or structuredPrompt '
      'for text generation.',
    );
  }

  final shouldPrune = reasoning != ReasoningPruneMode.none ||
      toolCalls != ToolCallPruneMode.none;

  if (!shouldPrune) {
    return resolved;
  }

  return pruneModelMessages(
    messages: resolved,
    reasoning: reasoning,
    toolCalls: toolCalls,
    toolNames: toolNames,
    removeEmptyMessages: removeEmptyMessages,
  );
}
