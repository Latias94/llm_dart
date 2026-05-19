import 'package:llm_dart_anthropic/src/anthropic_citation_projection.dart';
import 'package:llm_dart_anthropic/src/anthropic_stream_content_projection.dart';
import 'package:llm_dart_anthropic/src/anthropic_stream_state.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic stream content projection', () {
    test('projects text, compaction, and redacted reasoning starts', () {
      final text = projectAnthropicStreamContentBlockStart(
        index: 0,
        blockType: 'text',
        contentBlock: {
          'type': 'text',
        },
      );
      final compaction = projectAnthropicStreamContentBlockStart(
        index: 1,
        blockType: 'compaction',
        contentBlock: {
          'type': 'compaction',
        },
      );
      final redacted = projectAnthropicStreamContentBlockStart(
        index: 2,
        blockType: 'redacted_thinking',
        contentBlock: {
          'type': 'redacted_thinking',
          'data': 'encrypted-thinking',
        },
      );

      expect(text?.kind, AnthropicProjectedStreamContentBlockKind.text);
      expect(text?.event, isA<TextStartEvent>());
      expect(text?.providerMetadata?.values['anthropic'], {
        'blockIndex': 0,
        'blockType': 'text',
      });

      expect(compaction?.kind, AnthropicProjectedStreamContentBlockKind.text);
      expect(compaction?.event, isA<TextStartEvent>());
      expect(compaction?.providerMetadata?.values['anthropic'], {
        'blockIndex': 1,
        'blockType': 'compaction',
        'type': 'compaction',
      });

      expect(
        redacted?.kind,
        AnthropicProjectedStreamContentBlockKind.reasoning,
      );
      expect(redacted?.event, isA<ReasoningStartEvent>());
      expect(redacted?.providerMetadata?.values['anthropic'], {
        'blockIndex': 2,
        'blockType': 'redacted_thinking',
        'redactedData': 'encrypted-thinking',
      });
    });

    test('projects text, reasoning, signature, and citation deltas', () {
      final textState = AnthropicStreamTextBlockState(
        id: '0',
        providerMetadata: ProviderMetadata.forNamespace('anthropic', {
          'blockIndex': 0,
          'blockType': 'text',
        }),
      );
      final reasoningState = AnthropicStreamReasoningBlockState(
        id: '1',
        providerMetadata: ProviderMetadata.forNamespace('anthropic', {
          'blockIndex': 1,
          'blockType': 'thinking',
        }),
      );

      final textEvent = projectAnthropicStreamContentBlockDelta(
        index: 0,
        delta: {
          'type': 'text_delta',
          'text': 'Hello',
        },
        contentBlock: textState,
      );
      final reasoningEvent = projectAnthropicStreamContentBlockDelta(
        index: 1,
        delta: {
          'type': 'thinking_delta',
          'thinking': 'Plan',
        },
        contentBlock: reasoningState,
      );
      final signatureEvent = projectAnthropicStreamContentBlockDelta(
        index: 1,
        delta: {
          'type': 'signature_delta',
          'signature': 'sig_1',
        },
        contentBlock: reasoningState,
      );
      final sourceEvent = projectAnthropicStreamContentBlockDelta(
        index: 0,
        delta: {
          'type': 'citations_delta',
          'citation': {
            'type': 'web_search_result_location',
            'url': 'https://dart.dev',
            'title': 'Dart',
            'cited_text': 'Dart',
            'encrypted_index': 'enc_1',
          },
        },
        contentBlock: null,
      );

      expect(textEvent, isA<TextDeltaEvent>());
      expect((textEvent as TextDeltaEvent).delta, 'Hello');
      expect(textEvent.providerMetadata, textState.providerMetadata);

      expect(reasoningEvent, isA<ReasoningDeltaEvent>());
      expect((reasoningEvent as ReasoningDeltaEvent).delta, 'Plan');
      expect(reasoningEvent.providerMetadata, reasoningState.providerMetadata);

      expect(signatureEvent, isA<ReasoningDeltaEvent>());
      expect((signatureEvent as ReasoningDeltaEvent).delta, isEmpty);
      expect(signatureEvent.providerMetadata?.values['anthropic'], {
        'blockIndex': 1,
        'blockType': 'thinking',
        'signature': 'sig_1',
      });

      expect(sourceEvent, isA<SourceEvent>());
      final source = (sourceEvent as SourceEvent).source;
      expect(source.kind, SourceReferenceKind.url);
      expect(source.sourceId, 'https://dart.dev');
      expect(source.title, 'Dart');
      expect(source.providerMetadata?.values['anthropic'], {
        'citationType': 'web_search_result_location',
        'citedText': 'Dart',
        'encryptedIndex': 'enc_1',
      });
    });

    test('projects document citation source metadata', () {
      final source = projectAnthropicCitationSource({
        'type': 'page_location',
        'document_index': 3,
        'document_title': 'Manual',
        'cited_text': 'Step 1',
        'start_page_number': 4,
        'end_page_number': 5,
      });

      expect(source?.kind, SourceReferenceKind.document);
      expect(source?.sourceId, 'document-3');
      expect(source?.title, 'Manual');
      expect(source?.providerMetadata?.values['anthropic'], {
        'citationType': 'page_location',
        'citedText': 'Step 1',
        'documentIndex': 3,
        'startPageNumber': 4,
        'endPageNumber': 5,
      });
    });

    test('projects text and reasoning stop events', () {
      final textEvent = projectAnthropicStreamContentBlockStop(
        AnthropicStreamTextBlockState(id: '0'),
      );
      final reasoningEvent = projectAnthropicStreamContentBlockStop(
        AnthropicStreamReasoningBlockState(id: '1'),
      );

      expect(textEvent, isA<TextEndEvent>());
      expect((textEvent as TextEndEvent).id, '0');
      expect(reasoningEvent, isA<ReasoningEndEvent>());
      expect((reasoningEvent as ReasoningEndEvent).id, '1');
    });
  });
}
