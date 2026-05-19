import 'package:llm_dart_anthropic/src/anthropic_stream_state.dart';
import 'package:llm_dart_anthropic/src/anthropic_stream_tool_codec.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('AnthropicStreamToolCodec', () {
    test('owns streamed tool input delta accumulation', () {
      final metadata = ProviderMetadata.forNamespace('anthropic', {
        'blockIndex': 0,
        'blockType': 'tool_use',
      });
      final block = AnthropicStreamToolBlockState(
        toolCallId: 'toolu_1',
        toolName: 'weather',
        providerExecuted: false,
        isDynamic: false,
        title: null,
        providerMetadata: metadata,
      );

      final events = const AnthropicStreamToolCodec().decodeToolInputDelta(
        block,
        {
          'type': 'input_json_delta',
          'partial_json': '{"city":"Hong Kong"}',
        },
      ).toList();

      expect(block.inputBuffer.toString(), '{"city":"Hong Kong"}');
      expect(events, hasLength(1));
      expect(events.single, isA<ToolInputDeltaEvent>());

      final deltaEvent = events.single as ToolInputDeltaEvent;
      expect(deltaEvent.toolCallId, 'toolu_1');
      expect(deltaEvent.delta, '{"city":"Hong Kong"}');
      expect(deltaEvent.providerMetadata, metadata);
    });

    test('ignores empty and non-tool input deltas', () {
      final block = AnthropicStreamToolBlockState(
        toolCallId: 'toolu_2',
        toolName: 'weather',
        providerExecuted: false,
        isDynamic: false,
        title: null,
        providerMetadata: null,
      );
      final codec = const AnthropicStreamToolCodec();

      expect(
        codec.decodeToolInputDelta(block, {
          'type': 'input_json_delta',
          'partial_json': '',
        }).toList(),
        isEmpty,
      );
      expect(block.inputBuffer.toString(), isEmpty);

      expect(
        codec.decodeToolInputDelta(
          AnthropicStreamTextBlockState(id: '0'),
          {
            'type': 'input_json_delta',
            'partial_json': '{"city":"Hong Kong"}',
          },
        ).toList(),
        isEmpty,
      );
    });
  });
}
