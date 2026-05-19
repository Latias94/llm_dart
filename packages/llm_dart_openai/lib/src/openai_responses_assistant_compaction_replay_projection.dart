import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_request_encoding_util.dart';
import 'openai_responses_replay_policy.dart';

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
