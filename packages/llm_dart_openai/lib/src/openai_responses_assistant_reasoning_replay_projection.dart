import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_request_encoding_util.dart';
import 'openai_responses_prompt_limitations.dart';
import 'openai_responses_replay_policy.dart';

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
