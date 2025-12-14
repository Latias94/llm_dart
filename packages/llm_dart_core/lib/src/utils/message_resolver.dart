// Utilities for resolving various helper inputs into prompt-first ModelMessage
// conversations.

import '../core/capability.dart';
import '../models/chat_models.dart';

/// Resolve input into a list of prompt-first [ModelMessage]s for text generation.
///
/// This accepts:
/// - [promptMessages]: preferred structured prompt list;
/// - [structuredPrompt]: a single [ModelMessage];
/// - [prompt]: simple user text.
///
/// Optional [reasoning] / [toolCalls] pruning behavior removes reasoning/tool
/// parts from the prompt messages when requested.
List<ModelMessage> resolvePromptMessagesForTextGeneration({
  String? prompt,
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
      'You must provide either prompt, promptMessages, or structuredPrompt '
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
