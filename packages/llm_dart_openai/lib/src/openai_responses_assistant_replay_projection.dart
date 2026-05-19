import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_request_encoding_util.dart';
import 'openai_responses_prompt_limitations.dart';
import 'openai_responses_replay_policy.dart';
import 'openai_responses_tool_search_replay_projection.dart';

final class OpenAIResponsesAssistantReasoningReplayProjection {
  const OpenAIResponsesAssistantReasoningReplayProjection();

  void encode(
    ReasoningPromptPart part, {
    required List<Object?> items,
    required Map<String, Map<String, Object?>> reasoningItemsById,
    required Set<String> referencedReasoningIds,
    required List<ModelWarning> warnings,
    required OpenAIResponsesReplayPolicy replayPolicy,
  }) {
    final metadata = openAIPromptPartProviderMetadata(part)?.namespace(
      'openai',
    );
    final reasoningId = openAIRequestAsString(metadata?['itemId']);
    final encryptedContent =
        openAIRequestAsString(metadata?['reasoningEncryptedContent']) ??
            openAIRequestAsString(metadata?['encryptedContent']);
    final summaryPart = part.text.isEmpty
        ? null
        : <String, Object?>{
            'type': 'summary_text',
            'text': part.text,
          };

    if (replayPolicy.shouldSkipStoredItem(reasoningId)) {
      return;
    }

    if (replayPolicy.shouldReferenceStoredItem(reasoningId)) {
      if (referencedReasoningIds.add(reasoningId!)) {
        items.add(replayPolicy.itemReference(reasoningId));
      }
      return;
    }

    if (reasoningId != null) {
      final existingItem = reasoningItemsById[reasoningId];
      if (existingItem == null) {
        final reasoningItem = <String, Object?>{
          'type': 'reasoning',
          'id': reasoningId,
          if (encryptedContent != null) 'encrypted_content': encryptedContent,
          'summary': <Object?>[
            if (summaryPart != null) summaryPart,
          ],
        };
        reasoningItemsById[reasoningId] = reasoningItem;
        items.add(reasoningItem);
      } else {
        final summary = existingItem['summary'];
        if (summaryPart != null && summary is List<Object?>) {
          summary.add(summaryPart);
        } else if (summaryPart == null) {
          warnings.add(emptyOpenAIResponsesReasoningPartWarning(reasoningId));
        }
        if (encryptedContent != null) {
          existingItem['encrypted_content'] = encryptedContent;
        }
      }
      return;
    }

    if (encryptedContent == null) {
      warnings.add(nonOpenAIResponsesReasoningPartWarning);
      return;
    }

    items.add({
      'type': 'reasoning',
      'encrypted_content': encryptedContent,
      'summary': <Object?>[
        if (summaryPart != null) summaryPart,
      ],
    });
  }
}

final class OpenAIResponsesAssistantToolReplayProjection {
  const OpenAIResponsesAssistantToolReplayProjection();

  void encodeToolCall(
    ToolCallPromptPart part,
    List<Object?> items, {
    required OpenAIResponsesReplayPolicy replayPolicy,
  }) {
    final metadata = openAIPromptPartProviderMetadata(part)?.namespace(
      'openai',
    );
    final itemId = openAIRequestAsString(metadata?['itemId']);

    if (replayPolicy.shouldSkipStoredItem(itemId)) {
      return;
    }

    if (replayPolicy.shouldReferenceStoredItem(itemId)) {
      items.add(replayPolicy.itemReference(itemId!));
      return;
    }

    final toolSearchCall = projectOpenAIResponsesToolSearchReplayCall(
      part,
      metadata: metadata,
    );
    if (toolSearchCall != null) {
      items.add(toolSearchCall.toInputItem());
      return;
    }

    if (part.providerExecuted) {
      return;
    }

    items.add({
      'type': 'function_call',
      'call_id': part.toolCallId,
      if (itemId != null) 'id': itemId,
      'name': part.toolName,
      'arguments': encodeOpenAIJsonString(part.input),
    });
  }

  void encodeToolResult(
    ToolResultPromptPart part,
    List<Object?> items,
    List<ModelWarning> warnings, {
    required OpenAIResponsesReplayPolicy replayPolicy,
  }) {
    if (replayPolicy.hasConversation) {
      return;
    }

    final metadata = openAIPromptPartProviderMetadata(part)?.namespace(
      'openai',
    );
    final itemId =
        openAIRequestAsString(metadata?['itemId']) ?? part.toolCallId;

    if (replayPolicy.store) {
      items.add(replayPolicy.itemReference(itemId));
      return;
    }

    final toolSearchOutput = projectOpenAIResponsesToolSearchReplayOutput(
      part,
      metadata: metadata,
    );
    if (toolSearchOutput != null) {
      items.add(toolSearchOutput.toInputItem());
      return;
    }

    warnings.add(openAIResponsesToolResultStoreFalseWarning(part.toolName));
  }
}

final class OpenAIResponsesAssistantCompactionReplayProjection {
  const OpenAIResponsesAssistantCompactionReplayProjection();

  Map<String, Object?>? encode(
    CustomPromptPart part, {
    required OpenAIResponsesReplayPolicy replayPolicy,
  }) {
    final data = part.data is Map
        ? Map<String, Object?>.from(part.data as Map)
        : const <String, Object?>{};
    final metadata = openAIPromptPartProviderMetadata(part)?.namespace(
      'openai',
    );
    final id = openAIRequestAsString(metadata?['itemId']) ??
        openAIRequestAsString(data['id']);
    final encryptedContent =
        openAIRequestAsString(metadata?['encryptedContent']) ??
            openAIRequestAsString(data['encrypted_content']) ??
            openAIRequestAsString(data['encryptedContent']);

    if (replayPolicy.shouldSkipStoredItem(id)) {
      return null;
    }

    if (replayPolicy.shouldReferenceStoredItem(id)) {
      return replayPolicy.itemReference(id!);
    }

    if (id == null || encryptedContent == null) {
      return null;
    }

    final item = <String, Object?>{
      'type': 'compaction',
      'id': id,
      'encrypted_content': encryptedContent,
    };

    for (final entry in data.entries) {
      if (entry.key == 'type' ||
          entry.key == 'id' ||
          entry.key == 'encrypted_content' ||
          entry.key == 'encryptedContent') {
        continue;
      }
      item[entry.key] = entry.value;
    }

    return item;
  }
}

void removeUnsupportedOpenAIResponsesReasoningWhenStoreIsFalse(
  List<Object?> items,
  List<ModelWarning> warnings, {
  required bool store,
}) {
  if (store) {
    return;
  }

  var removedUnsupportedReasoning = false;
  items.removeWhere((item) {
    final map = openAIRequestAsMap(item);
    final shouldRemove = map != null &&
        openAIRequestAsString(map['type']) == 'reasoning' &&
        !map.containsKey('encrypted_content');
    if (shouldRemove) {
      removedUnsupportedReasoning = true;
    }
    return shouldRemove;
  });

  if (removedUnsupportedReasoning) {
    warnings.add(openAIResponsesReasoningStoreFalseWarning);
  }
}
