import 'package:llm_dart_core/llm_dart_core.dart';

import 'openai_custom_part.dart';
import 'openai_custom_part_summary.dart';

final class OpenAIMappedMessage {
  final ChatUiMessage message;
  final List<OpenAICustomPart> customParts;
  final List<OpenAICustomPartSummary> customPartSummaries;
  final Map<String, Object?>? responseMetadata;
  final Map<String, Object?>? finishMetadata;

  const OpenAIMappedMessage({
    required this.message,
    required this.customParts,
    required this.customPartSummaries,
    required this.responseMetadata,
    required this.finishMetadata,
  });

  bool get hasOpenAIMetadata =>
      responseMetadata != null ||
      finishMetadata != null ||
      customParts.isNotEmpty;
}

final class OpenAIMessageMapper {
  const OpenAIMessageMapper();

  OpenAIMappedMessage map(ChatUiMessage message) {
    final customParts = <OpenAICustomPart>[];
    final customPartSummaries = <OpenAICustomPartSummary>[];

    for (final part in message.parts) {
      final customPart = OpenAICustomPart.tryParseUiPart(part);
      if (customPart == null) {
        continue;
      }

      customParts.add(customPart);
      customPartSummaries.add(OpenAICustomPartSummary.fromPart(customPart));
    }

    return OpenAIMappedMessage(
      message: message,
      customParts: List<OpenAICustomPart>.unmodifiable(customParts),
      customPartSummaries:
          List<OpenAICustomPartSummary>.unmodifiable(customPartSummaries),
      responseMetadata: _openaiMessageMetadata(
        message.metadata[ChatUiMetadataKeys.responseProviderMetadata],
      ),
      finishMetadata: _openaiMessageMetadata(
        message.metadata[ChatUiMetadataKeys.finishProviderMetadata],
      ),
    );
  }

  List<OpenAIMappedMessage> mapMessages(Iterable<ChatUiMessage> messages) {
    return messages.map(map).toList(growable: false);
  }
}

Map<String, Object?>? _openaiMessageMetadata(Object? metadata) {
  return switch (metadata) {
    ProviderMetadata() => metadata.namespace('openai'),
    _ => null,
  };
}
