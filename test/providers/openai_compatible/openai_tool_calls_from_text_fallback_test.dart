import 'dart:convert';

import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIChatResponse.toolCalls text fallback', () {
    test('parses a tool call from text when enabled and tools were requested',
        () {
      final response = OpenAIChatResponse(
        {
          'choices': [
            {
              'message': {
                'role': 'assistant',
                'content': jsonEncode({
                  'name': 'weather\$weather#get_weather',
                  'arguments': {'addr': '广州市', 'date': '2026-01-09'},
                }),
              },
            }
          ],
        },
        providerId: 'siliconcloud',
        parseToolCallsFromText: true,
        didRequestTools: true,
      );

      final calls = response.toolCalls;
      expect(calls, isNotNull);
      expect(calls, hasLength(1));
      expect(
          calls!.first.function.name, equals('weather\$weather#get_weather'));

      final args = jsonDecode(calls.first.function.arguments);
      expect(args, isA<Map>());
      expect(args['addr'], equals('广州市'));
      expect(args['date'], equals('2026-01-09'));
    });

    test('does not parse a tool call when tools were not requested', () {
      final response = OpenAIChatResponse(
        {
          'choices': [
            {
              'message': {
                'role': 'assistant',
                'content': '{"name":"x","arguments":{"a":1}}',
              },
            }
          ],
        },
        providerId: 'siliconcloud',
        parseToolCallsFromText: true,
        didRequestTools: false,
      );

      expect(response.toolCalls, isNull);
    });
  });
}
