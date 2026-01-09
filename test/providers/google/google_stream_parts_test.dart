import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

void main() {
  group('Google chatStreamParts (Gemini JSON array stream)', () {
    test('streams thinking/text/tool parts and finishes with toolCalls',
        () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash',
        stream: true,
      );

      final chunks = <String>[
        '[\n',
        jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': '思考中...', 'thought': true},
                  {'text': 'Hello '},
                ],
              },
            }
          ],
        }),
        ',\n',
        jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'world'},
                ],
              },
            }
          ],
        }),
        ',\n',
        jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'functionCall': {
                      'name': 'get_weather',
                      'args': {'location': 'London'},
                    },
                  },
                ],
              },
              'finishReason': 'STOP',
            }
          ],
          'usageMetadata': {
            'promptTokenCount': 10,
            'candidatesTokenCount': 5,
            'totalTokenCount': 15,
            'thoughtsTokenCount': 3,
          },
        }),
        '\n]\n',
      ];

      final client = FakeGoogleClient(config);
      client.streamResponse = Stream<String>.fromIterable(chunks);
      final chat = GoogleChat(client, config);

      final parts = await chat
          .chatStreamParts([ChatMessage.user('Hi')], tools: const []).toList();

      expect(parts.whereType<LLMReasoningStartPart>(), hasLength(1));
      expect(
        parts.whereType<LLMReasoningDeltaPart>().map((p) => p.delta).join(),
        equals('思考中...'),
      );
      expect(parts.whereType<LLMReasoningEndPart>().single.thinking,
          equals('思考中...'));

      expect(parts.whereType<LLMTextStartPart>(), hasLength(1));
      expect(parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join(),
          equals('Hello world'));
      expect(
          parts.whereType<LLMTextEndPart>().single.text, equals('Hello world'));

      final toolStart = parts.whereType<LLMToolCallStartPart>().single;
      expect(toolStart.toolCall.id, equals('call_get_weather'));
      expect(toolStart.toolCall.function.name, equals('get_weather'));
      expect(toolStart.toolCall.function.arguments,
          equals(jsonEncode({'location': 'London'})));

      expect(parts.whereType<LLMToolCallEndPart>().single.toolCallId,
          equals('call_get_weather'));

      final finish = parts.last as LLMFinishPart;
      expect(finish.response.text, equals('Hello world'));
      expect(finish.response.thinking, equals('思考中...'));

      final calls = finish.response.toolCalls;
      expect(calls, isNotNull);
      expect(calls!, hasLength(1));
      expect(calls.single.id, equals('call_get_weather'));
      expect(calls.single.function.name, equals('get_weather'));
      expect(calls.single.function.arguments,
          equals(jsonEncode({'location': 'London'})));

      final usage = finish.response.usage;
      expect(usage, isNotNull);
      expect(usage!.promptTokens, equals(10));
      expect(usage.completionTokens, equals(5));
      expect(usage.totalTokens, equals(15));
      expect(usage.reasoningTokens, equals(3));

      final metadata = finish.response.providerMetadata;
      expect(metadata, isNotNull);
      expect(metadata!['google']['model'], equals('gemini-1.5-flash'));
      expect(metadata['google']['finishReason'], equals('STOP'));
      expect(metadata['google']['usage']['promptTokens'], equals(10));
      expect(metadata['google']['usage']['completionTokens'], equals(5));
      expect(metadata['google']['usage']['totalTokens'], equals(15));
      expect(metadata['google']['usage']['reasoningTokens'], equals(3));
      expect(metadata.containsKey('google.chat'), isTrue);
      expect(metadata['google.chat'], equals(metadata['google']));
      expect(metadata.containsKey('google.generative-ai'), isTrue);
      expect(metadata['google.generative-ai'], equals(metadata['google']));
    });
  });
}
