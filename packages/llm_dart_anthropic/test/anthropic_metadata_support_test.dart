import 'package:llm_dart_anthropic/src/anthropic_metadata_support.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic metadata support', () {
    test('maps stop reasons for result and stream finish events', () {
      expect(mapAnthropicStopReason('end_turn'), FinishReason.stop);
      expect(mapAnthropicStopReason('stop_sequence'), FinishReason.stop);
      expect(mapAnthropicStopReason('tool_use'), FinishReason.toolCalls);
      expect(mapAnthropicStopReason('max_tokens'), FinishReason.maxTokens);
      expect(
        mapAnthropicStopReason('model_context_window_exceeded'),
        FinishReason.maxTokens,
      );
      expect(mapAnthropicStopReason('refusal'), FinishReason.contentFilter);
      expect(mapAnthropicStopReason('unknown'), FinishReason.other);
    });

    test('decodes Anthropic token usage', () {
      final usage = decodeAnthropicUsage(
        {
          'input_tokens': 12,
          'output_tokens': 34.8,
        },
      );

      expect(usage?.inputTokens, 12);
      expect(usage?.outputTokens, 34);
      expect(usage?.totalTokens, 46);
    });

    test('decodes container metadata fields', () {
      expect(
        decodeAnthropicContainerMetadata(
          {
            'id': 'container_123',
            'expires_at': '2026-03-27T12:00:00Z',
            'skills': [
              {
                'type': 'web_search',
              },
            ],
          },
        ),
        {
          'id': 'container_123',
          'expiresAt': '2026-03-27T12:00:00Z',
          'skills': [
            {
              'type': 'web_search',
            },
          ],
        },
      );
    });

    test('filters nullable provider metadata values', () {
      final metadata = anthropicProviderMetadata(
        {
          'usage': {
            'input_tokens': 1,
          },
          'stopSequence': null,
        },
      );

      expect(
        anthropicProviderMetadataValues(metadata),
        {
          'usage': {
            'input_tokens': 1,
          },
        },
      );
    });
  });
}
