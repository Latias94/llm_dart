// This utility bridges between the new prompt-first model (ModelMessage) and
// the legacy ChatMessage-based chat interface used by providers.
// ChatMessage is intentionally used here as a compatibility layer.
// ignore_for_file: deprecated_member_use

import 'package:llm_dart_core/llm_dart_core.dart';

/// Resolve input into a list of [ChatMessage]s for text generation.
///
/// The preferred prompt-first representation is [promptMessages]
/// (a list of [ModelMessage]s). For backwards compatibility this
/// helper also accepts:
/// - [structuredPrompt] (single [ModelMessage])
/// - [messages] (legacy [ChatMessage] list)
/// - [prompt] (plain text)
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
/// This is the mirror of [resolveMessagesForTextGeneration] for the
/// prompt-first [LanguageModel] surface. It accepts:
/// - [promptMessages]: preferred structured prompt messages.
/// - [structuredPrompt]: a single [ModelMessage].
/// - [legacyMessages]: legacy [ChatMessage]s converted via
///   [ChatMessage.toPromptMessage].
/// - [prompt]: simple user text wrapped in a single [ModelMessage].
///
/// Optional [reasoning] and [toolCalls] pruning behaves like
/// [resolveMessagesForTextGeneration] but operates directly on the
/// returned [ModelMessage] list.
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
