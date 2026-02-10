import 'dart:typed_data';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _FakeChatResponse implements ChatResponse, ChatResponseWithFinishReason {
  @override
  final String? text;

  @override
  final String? thinking;

  @override
  final UsageInfo? usage;

  @override
  final Map<String, dynamic>? providerMetadata;

  @override
  final LLMFinishReason? finishReason;

  const _FakeChatResponse({
    this.text,
    this.thinking,
    this.usage,
    this.providerMetadata,
    this.finishReason,
  });

  @override
  List<ToolCall>? get toolCalls => null;
}

void main() {
  group('encodeV3StreamParts', () {
    test('injects missing block ids and encodes text parts', () {
      final parts = <LLMStreamPart>[
        const LLMStreamStartPart(),
        const LLMTextStartPart(),
        const LLMTextDeltaPart('Hello'),
        const LLMTextEndPart('Hello'),
      ];

      final json = encodeV3StreamParts(parts);

      expect(json.map((e) => e['type']), [
        'stream-start',
        'text-start',
        'text-delta',
        'text-end',
      ]);

      expect(json[1]['id'], isA<String>());
      expect((json[1]['id'] as String).isNotEmpty, isTrue);
      expect(json[2]['id'], equals(json[1]['id']));
      expect(json[3]['id'], equals(json[1]['id']));
      expect(json[2]['delta'], equals('Hello'));
    });

    test('encodes stream-start warnings and response metadata', () {
      final parts = <LLMStreamPart>[
        const LLMStreamStartPart(
          warnings: [
            {'type': 'unsupported', 'feature': 'some-feature'},
          ],
        ),
        LLMResponseMetadataPart(
          id: 'resp_123',
          timestamp: DateTime.parse('2026-02-10T00:00:00Z'),
          model: 'gpt-test',
        ),
      ];

      final json = encodeV3StreamParts(parts);

      expect(json.map((e) => e['type']), ['stream-start', 'response-metadata']);
      expect(json.first['warnings'], isA<List>());
      expect((json.first['warnings'] as List).length, 1);
      expect((json.first['warnings'] as List).first, {
        'type': 'unsupported',
        'feature': 'some-feature',
      });

      final meta = json.last;
      expect(meta['id'], equals('resp_123'));
      expect(meta['timestamp'], equals('2026-02-10T00:00:00.000Z'));
      expect(meta['modelId'], equals('gpt-test'));
    });

    test('encodes tool input lifecycle and emits tool-call on end', () {
      final parts = <LLMStreamPart>[
        const LLMStreamStartPart(),
        LLMToolCallStartPart(
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: const FunctionCall(name: 'do_it', arguments: ''),
          ),
        ),
        LLMToolCallDeltaPart(
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: const FunctionCall(name: 'do_it', arguments: '{"a":1'),
          ),
        ),
        LLMToolCallDeltaPart(
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: const FunctionCall(name: 'do_it', arguments: '}'),
          ),
        ),
        const LLMToolCallEndPart('call_1'),
      ];

      final json = encodeV3StreamParts(parts);

      expect(
        json.map((e) => e['type']),
        [
          'stream-start',
          'tool-input-start',
          'tool-input-delta',
          'tool-input-delta',
          'tool-input-end',
          'tool-call',
        ],
      );

      final toolCall = json.last;
      expect(toolCall['toolCallId'], equals('call_1'));
      expect(toolCall['toolName'], equals('do_it'));
      expect(toolCall['input'], equals('{"a":1}'));
    });

    test('encodes raw parts', () {
      final parts = <LLMStreamPart>[
        const LLMStreamStartPart(),
        const LLMRawPart({
          'hello': [1, 2, 3],
        }),
      ];

      final json = encodeV3StreamParts(parts);
      expect(json.map((e) => e['type']), ['stream-start', 'raw']);
      expect(
          json.last['rawValue'],
          equals({
            'hello': [1, 2, 3]
          }));
    });

    test('encodes file parts', () {
      final parts = <LLMStreamPart>[
        const LLMStreamStartPart(),
        LLMFilePart(
          mediaType: 'image/png',
          data: Uint8List.fromList([1, 2, 3]),
        ),
      ];

      final json = encodeV3StreamParts(parts);
      expect(json.map((e) => e['type']), ['stream-start', 'file']);
      expect(
        json.last,
        {
          'type': 'file',
          'mediaType': 'image/png',
          'data': 'AQID',
        },
      );
    });

    test('encodes finish usage and finish reason', () {
      final parts = <LLMStreamPart>[
        const LLMStreamStartPart(),
        LLMFinishPart(
          const _FakeChatResponse(
            providerMetadata: {
              'openai': {'id': 'resp_1'},
            },
          ),
          usage: const UsageInfo(
            promptTokens: 3,
            completionTokens: 5,
            reasoningTokens: 2,
          ),
          finishReason: const LLMFinishReason(
            unified: LLMUnifiedFinishReason.stop,
            raw: 'stop',
          ),
        ),
      ];

      final json = encodeV3StreamParts(parts);
      expect(json.map((e) => e['type']), ['stream-start', 'finish']);

      final finish = json.last;
      expect(finish['usage'], isA<Map>());
      expect(
        ((finish['finishReason'] as Map)['unified'] as String),
        equals('stop'),
      );
      expect(
          ((finish['finishReason'] as Map)['raw'] as String?), equals('stop'));
      expect(finish['providerMetadata'], isNotNull);
    });
  });
}
