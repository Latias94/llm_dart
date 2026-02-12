import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('v3 stream part codec: raw envelopes', () {
    test('encodes provider metadata snapshot without kind', () {
      final objects = encodeV3StreamParts([
        const LLMProviderMetadataPart({
          'openai': {'id': 'resp_1'}
        }),
      ]);

      expect(
        objects,
        [
          {
            'type': 'raw',
            'rawValue': {
              'providerMetadata': {
                'openai': {'id': 'resp_1'}
              },
            },
          }
        ],
      );
    });

    test('decodes provider metadata snapshot without kind', () {
      final parts = decodeV3StreamParts([
        {
          'type': 'raw',
          'rawValue': {
            'providerMetadata': {
              'openai': {'id': 'resp_1'}
            },
          },
        }
      ]);

      expect(parts.single, isA<LLMProviderMetadataPart>());
    });

    test('encodes provider tool delta without kind', () {
      final objects = encodeV3StreamParts([
        const LLMProviderToolDeltaPart(
          toolCallId: 'id-0',
          toolName: 'tool',
          status: 'in_progress',
          data: {'n': 1},
          providerMetadata: {
            'xai': {'foo': 'bar'}
          },
        ),
      ]);

      expect(
        objects,
        [
          {
            'type': 'raw',
            'rawValue': {
              'toolCallId': 'id-0',
              'toolName': 'tool',
              'status': 'in_progress',
              'data': {'n': 1},
              'providerMetadata': {
                'xai': {'foo': 'bar'}
              },
            },
          }
        ],
      );
    });

    test('decodes provider tool delta without kind', () {
      final parts = decodeV3StreamParts([
        {
          'type': 'raw',
          'rawValue': {
            'toolCallId': 'id-0',
            'toolName': 'tool',
            'status': 'in_progress',
            'data': {'n': 1},
          },
        }
      ]);

      expect(parts.single, isA<LLMProviderToolDeltaPart>());
    });

    test('decodes legacy kind envelopes', () {
      final parts = decodeV3StreamParts([
        {
          'type': 'raw',
          'rawValue': {
            'kind': 'provider-metadata',
            'providerMetadata': {
              'openai': {'id': 'resp_1'}
            },
          },
        },
        {
          'type': 'raw',
          'rawValue': {
            'kind': 'provider-tool-delta',
            'toolCallId': 'id-0',
            'toolName': 'tool',
            'status': 'in_progress',
          },
        },
      ]);

      expect(parts.first, isA<LLMProviderMetadataPart>());
      expect(parts.last, isA<LLMProviderToolDeltaPart>());
    });
  });
}
