// ignore_for_file: deprecated_member_use
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
      final events = await chat
          .chatStream([ChatMessage.user('hi')], tools: const [])
          .toList();

      final toolEvents = events.whereType<ToolCallDeltaEvent>().toList();
      expect(toolEvents, hasLength(2));

      expect(toolEvents[0].toolCall.id, equals('call_get_weather'));
      expect(toolEvents[1].toolCall.id, equals('call_get_weather_1'));

      expect(
        toolEvents.map((e) => e.toolCall.function.arguments).toList(),
        equals([
          jsonEncode({'location': 'London'}),
          jsonEncode({'location': 'Paris'}),
        ]),
      );

      expect(events.whereType<CompletionEvent>(), hasLength(1));
    });
  });
}
