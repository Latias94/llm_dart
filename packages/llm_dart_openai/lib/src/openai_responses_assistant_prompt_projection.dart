import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_request_encoding_util.dart';
import 'openai_responses_assistant_replay_projection.dart';
import 'openai_responses_native_tool_context.dart';
import 'openai_responses_prompt_limitations.dart';
import 'openai_responses_replay_policy.dart';

final class OpenAIResponsesAssistantPromptProjection {
  final OpenAIResponsesAssistantReasoningReplayProjection reasoningProjection;
  final OpenAIResponsesAssistantToolReplayProjection toolProjection;
  final OpenAIResponsesAssistantCompactionReplayProjection compactionProjection;

  const OpenAIResponsesAssistantPromptProjection({
    this.reasoningProjection =
        const OpenAIResponsesAssistantReasoningReplayProjection(),
    this.toolProjection = const OpenAIResponsesAssistantToolReplayProjection(),
    this.compactionProjection =
        const OpenAIResponsesAssistantCompactionReplayProjection(),
  });

  List<Object?> encode(
    AssistantPromptMessage message,
    List<ModelWarning> warnings, {
    required OpenAIResponsesReplayPolicy replayPolicy,
    OpenAIResponsesNativeToolContext nativeToolContext =
        OpenAIResponsesNativeToolContext.empty,
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

        reasoningProjection.encode(
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
        toolProjection.encodeToolCall(
          part,
          items,
          replayPolicy: replayPolicy,
          nativeToolContext: nativeToolContext,
        );
        continue;
      }

      if (part is ToolApprovalRequestPromptPart) {
        continue;
      }

      if (part is FilePromptPart ||
          part is ReasoningFilePromptPart ||
          part is CustomPromptPart) {
        if (part is CustomPromptPart && part.kind == 'openai.compaction') {
          final compactionItem = compactionProjection.encode(
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
        toolProjection.encodeToolResult(
          part,
          items,
          warnings,
          replayPolicy: replayPolicy,
          nativeToolContext: nativeToolContext,
        );
        continue;
      }

      throw unsupportedOpenAIResponsesPromptPart(
        role: 'assistant',
        part: part,
      );
    }

    flushTextContent();
    removeUnsupportedOpenAIResponsesReasoningWhenStoreIsFalse(
      items,
      warnings,
      store: replayPolicy.store,
    );
    return items;
  }
}
