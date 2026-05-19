import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_request_encoding_util.dart';
import 'openai_responses_prompt_limitations.dart';
import 'openai_responses_replay_policy.dart';

final class OpenAIResponsesAssistantPromptProjection {
  const OpenAIResponsesAssistantPromptProjection();

  List<Object?> encode(
    AssistantPromptMessage message,
    List<ModelWarning> warnings, {
    required OpenAIResponsesReplayPolicy replayPolicy,
  }) {
    final items = <Object?>[];
    final textContent = <Object?>[];
    final reasoningItemsById = <String, Map<String, Object?>>{};
    final referencedReasoningIds = <String>{};
    String? textItemId;
    String? textPhase;

    void flushTextContent() {
      if (textContent.isEmpty) {
        return;
      }

      items.add({
        'role': 'assistant',
        'content': List<Object?>.from(textContent),
        if (textItemId != null) 'id': textItemId,
        if (textPhase != null) 'phase': textPhase,
      });
      textContent.clear();
      textItemId = null;
      textPhase = null;
    }

    for (final part in message.parts) {
      if (part is TextPromptPart) {
        final metadata = openAIPromptPartProviderMetadata(part)?.namespace(
          'openai',
        );
        final partItemId = openAIRequestAsString(metadata?['itemId']);
        final partPhase = openAIRequestAsString(metadata?['phase']);

        if (replayPolicy.shouldSkipStoredItem(partItemId)) {
          flushTextContent();
          continue;
        }

        if (replayPolicy.shouldReferenceStoredItem(partItemId)) {
          flushTextContent();
          items.add(replayPolicy.itemReference(partItemId!));
          continue;
        }

        if (textContent.isNotEmpty &&
            (partItemId != textItemId || partPhase != textPhase)) {
          flushTextContent();
        }

        if (textContent.isEmpty) {
          textItemId = partItemId;
          textPhase = partPhase;
        }

        textContent.add({
          'type': 'output_text',
          'text': part.text,
        });
        continue;
      }

      if (part is ReasoningPromptPart) {
        flushTextContent();

        _encodeReasoningPart(
          part,
          items: items,
          reasoningItemsById: reasoningItemsById,
          referencedReasoningIds: referencedReasoningIds,
          warnings: warnings,
          replayPolicy: replayPolicy,
        );
        continue;
      }

      flushTextContent();

      if (part is ToolCallPromptPart) {
        _encodeToolCallPart(part, items, replayPolicy: replayPolicy);
        continue;
      }

      if (part is ToolApprovalRequestPromptPart) {
        continue;
      }

      if (part is FilePromptPart ||
          part is ReasoningFilePromptPart ||
          part is CustomPromptPart) {
        if (part is CustomPromptPart && part.kind == 'openai.compaction') {
          final compactionItem = _encodeOpenAICompactionItem(
            part,
            replayPolicy: replayPolicy,
          );
          if (compactionItem != null) {
            items.add(compactionItem);
          }
        }
        continue;
      }

      if (part is ToolResultPromptPart) {
        _encodeToolResultPart(
          part,
          items,
          warnings,
          replayPolicy: replayPolicy,
        );
        continue;
      }

      throw unsupportedOpenAIResponsesPromptPart(
        role: 'assistant',
        part: part,
      );
    }

    flushTextContent();
    _removeUnsupportedReasoningWhenStoreIsFalse(
      items,
      warnings,
      store: replayPolicy.store,
    );
    return items;
  }

  void _encodeReasoningPart(
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
          warnings.add(
            ModelWarning(
              type: ModelWarningType.other,
              field: 'prompt.assistant.reasoning',
              message:
                  'Cannot append empty reasoning part to existing reasoning sequence. Skipping reasoning part with itemId "$reasoningId".',
            ),
          );
        }
        if (encryptedContent != null) {
          existingItem['encrypted_content'] = encryptedContent;
        }
      }
      return;
    }

    if (encryptedContent == null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.other,
          field: 'prompt.assistant.reasoning',
          message:
              'Non-OpenAI reasoning parts without itemId or encryptedContent are not sent to the OpenAI Responses API',
        ),
      );
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

  void _encodeToolCallPart(
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

  void _encodeToolResultPart(
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

    warnings.add(
      ModelWarning(
        type: ModelWarningType.other,
        field: 'prompt.assistant.toolResult',
        message:
            'Results for OpenAI tool ${part.toolName} are not sent to the API when store is false',
      ),
    );
  }

  Map<String, Object?>? _encodeOpenAICompactionItem(
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

  void _removeUnsupportedReasoningWhenStoreIsFalse(
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
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.other,
          field: 'prompt.assistant.reasoning',
          message:
              'Reasoning parts without encrypted content are not supported when store is false. Skipping reasoning parts.',
        ),
      );
    }
  }
}
