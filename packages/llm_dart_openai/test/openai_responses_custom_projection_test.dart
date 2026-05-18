import 'package:llm_dart_openai/src/openai_responses_custom_projection.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI Responses custom projection', () {
    test('projects compaction output items with replay metadata', () {
      final projection = projectOpenAIResponsesCustomOutputItem({
        'id': 'cmp_1',
        'type': 'compaction',
        'status': 'completed',
        'phase': 'final',
        'encrypted_content': 'enc_compaction',
      });

      expect(projection, isNotNull);
      expect(projection!.kind, 'openai.compaction');
      expect(projection.data, {
        'id': 'cmp_1',
        'type': 'compaction',
        'status': 'completed',
        'phase': 'final',
        'encrypted_content': 'enc_compaction',
      });
      expect(projection.providerMetadata?['openai'], {
        'itemId': 'cmp_1',
        'itemType': 'compaction',
        'status': 'completed',
        'phase': 'final',
        'encryptedContent': 'enc_compaction',
      });

      final contentPart = projection.toContentPart();
      expect(contentPart.kind, 'openai.compaction');
      expect(contentPart.providerMetadata, projection.providerMetadata);
    });

    test('skips reasoning output items as custom output', () {
      expect(openAIResponsesCustomOutputKind(null), isNull);
      expect(openAIResponsesCustomOutputKind('reasoning'), isNull);
      expect(
        projectOpenAIResponsesCustomOutputItem({
          'id': 'rs_1',
          'type': 'reasoning',
        }),
        isNull,
      );
    });

    test('projects partial image chunks into custom events', () {
      final projection = projectOpenAIResponsesPartialImageChunk(
        responseId: 'resp_1',
        serviceTier: 'default',
        chunk: {
          'item_id': 'img_1',
          'output_index': 2,
          'partial_image_b64': 'AQID',
        },
      );

      expect(projection.kind, openAIResponsesPartialImageCustomKind);
      expect(projection.data, {
        'item_id': 'img_1',
        'output_index': 2,
        'partial_image_b64': 'AQID',
      });
      expect(projection.providerMetadata?['openai'], {
        'responseId': 'resp_1',
        'itemId': 'img_1',
        'itemType': openAIResponsesPartialImageItemType,
        'outputIndex': 2,
        'serviceTier': 'default',
      });

      final event = projection.toEvent();
      expect(event.kind, openAIResponsesPartialImageCustomKind);
      expect(event.providerMetadata, projection.providerMetadata);
    });
  });
}
