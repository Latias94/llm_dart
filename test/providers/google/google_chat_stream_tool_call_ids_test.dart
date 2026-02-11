import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

void main() {
  group('GoogleChat chatStream tool call ids', () {
    test('assigns unique ids for repeated tool names', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-flash',
        stream: true,
      );

      final payload = {
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
                {
                  'functionCall': {
                    'name': 'get_weather',
                    'args': {'location': 'Paris'},
                  },
                },
              ],
            },
            'finishReason': 'STOP',
          },
        ],
        'usageMetadata': {
          'promptTokenCount': 1,
          'candidatesTokenCount': 1,
          'totalTokenCount': 2,
        },
      };

      final client = FakeGoogleClient(config);
      client.streamResponse = Stream<String>.fromIterable([
        'data: ${jsonEncode(payload)}\n\n',
      ]);

      final chat = GoogleChat(client, config);
      final parts = await chat
          .chatStreamParts([ChatMessage.user('hi')], tools: const []).toList();

      final toolCalls = parts
          .whereType<LLMToolCallStartPart>()
          .map((p) => p.toolCall)
          .toList();
      expect(toolCalls, hasLength(2));

      expect(toolCalls[0].id, equals('call_get_weather'));
      expect(toolCalls[1].id, equals('call_get_weather_1'));

      expect(
        toolCalls.map((c) => c.function.arguments).toList(),
        equals([
          jsonEncode({'location': 'London'}),
          jsonEncode({'location': 'Paris'}),
        ]),
      );

      expect(parts.whereType<LLMFinishPart>(), hasLength(1));
    });
  });
}
