import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_citation_projection.dart';
import 'anthropic_stream_state.dart';
import 'anthropic_stream_util.dart';

enum AnthropicProjectedStreamContentBlockKind {
  text,
  reasoning,
}

final class AnthropicProjectedStreamContentBlockStart {
  final AnthropicProjectedStreamContentBlockKind kind;
  final String id;
  final ProviderMetadata? providerMetadata;
  final LanguageModelStreamEvent event;

  const AnthropicProjectedStreamContentBlockStart({
    required this.kind,
    required this.id,
    required this.providerMetadata,
    required this.event,
  });
}

ProviderMetadata? anthropicStreamContentBlockMetadata({
  required int index,
  required String? blockType,
}) {
  return anthropicStreamProviderMetadata({
    'blockIndex': index,
    'blockType': blockType,
  });
}

AnthropicProjectedStreamContentBlockStart?
    projectAnthropicStreamContentBlockStart({
  required int index,
  required String? blockType,
  required Map<String, Object?> contentBlock,
}) {
  final id = '$index';
  final blockMetadata = anthropicStreamContentBlockMetadata(
    index: index,
    blockType: blockType,
  );

  if (blockType == 'text' || blockType == 'compaction') {
    final metadata = blockType == 'compaction'
        ? anthropicStreamProviderMetadata({
            'blockIndex': index,
            'blockType': blockType,
            'type': 'compaction',
          })
        : blockMetadata;
    return AnthropicProjectedStreamContentBlockStart(
      kind: AnthropicProjectedStreamContentBlockKind.text,
      id: id,
      providerMetadata: metadata,
      event: TextStartEvent(id: id, providerMetadata: metadata),
    );
  }

  if (blockType == 'thinking' || blockType == 'redacted_thinking') {
    final metadata = blockType == 'redacted_thinking'
        ? anthropicStreamProviderMetadata({
            'blockIndex': index,
            'blockType': blockType,
            'redactedData': contentBlock['data'],
          })
        : blockMetadata;
    return AnthropicProjectedStreamContentBlockStart(
      kind: AnthropicProjectedStreamContentBlockKind.reasoning,
      id: id,
      providerMetadata: metadata,
      event: ReasoningStartEvent(id: id, providerMetadata: metadata),
    );
  }

  return null;
}

LanguageModelStreamEvent? projectAnthropicStreamContentBlockDelta({
  required int index,
  required Map<String, Object?> delta,
  required AnthropicStreamContentBlockState? contentBlock,
}) {
  final deltaType = anthropicStreamAsString(delta['type']);

  if (deltaType == 'text_delta' || deltaType == 'compaction_delta') {
    if (contentBlock is! AnthropicStreamTextBlockState) {
      return null;
    }

    final value = deltaType == 'text_delta'
        ? anthropicStreamAsString(delta['text'])
        : anthropicStreamAsString(delta['content']);
    if (value == null || value.isEmpty) {
      return null;
    }

    return TextDeltaEvent(
      id: contentBlock.id,
      delta: value,
      providerMetadata: contentBlock.providerMetadata,
    );
  }

  if (deltaType == 'thinking_delta') {
    if (contentBlock is! AnthropicStreamReasoningBlockState) {
      return null;
    }

    final value = anthropicStreamAsString(delta['thinking']);
    if (value == null || value.isEmpty) {
      return null;
    }

    return ReasoningDeltaEvent(
      id: contentBlock.id,
      delta: value,
      providerMetadata: contentBlock.providerMetadata,
    );
  }

  if (deltaType == 'signature_delta') {
    if (contentBlock is! AnthropicStreamReasoningBlockState) {
      return null;
    }

    return ReasoningDeltaEvent(
      id: contentBlock.id,
      delta: '',
      providerMetadata: anthropicStreamProviderMetadata({
        'blockIndex': index,
        'blockType': 'thinking',
        'signature': anthropicStreamAsString(delta['signature']),
      }),
    );
  }

  if (deltaType == 'citations_delta') {
    final source = projectAnthropicCitationSource(
      anthropicStreamAsMap(delta['citation']),
    );
    if (source == null) {
      return null;
    }

    return SourceEvent(source);
  }

  return null;
}

LanguageModelStreamEvent? projectAnthropicStreamContentBlockStop(
  AnthropicStreamContentBlockState contentBlock,
) {
  if (contentBlock is AnthropicStreamTextBlockState) {
    return TextEndEvent(
      id: contentBlock.id,
      providerMetadata: contentBlock.providerMetadata,
    );
  }

  if (contentBlock is AnthropicStreamReasoningBlockState) {
    return ReasoningEndEvent(
      id: contentBlock.id,
      providerMetadata: contentBlock.providerMetadata,
    );
  }

  return null;
}

CustomEvent projectAnthropicStreamCustomContentBlockEvent({
  required String? blockType,
  required Map<String, Object?> contentBlock,
  required ProviderMetadata? providerMetadata,
}) {
  return CustomEvent(
    kind: 'anthropic.$blockType',
    data: contentBlock,
    providerMetadata: providerMetadata,
  );
}
