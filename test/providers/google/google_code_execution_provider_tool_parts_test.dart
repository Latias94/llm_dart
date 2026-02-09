import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

void main() {
  group('Google chatStreamParts provider tool parts', () {
    test('emits provider tool call/result parts for code execution', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-flash',
        stream: true,
      );

      final client = FakeGoogleClient(config);
      client.streamResponse = Stream<String>.fromIterable(const [
        'data: {"candidates":[{"content":{"parts":[{"executableCode":{"language":"python","code":"print(1)"}}]}}]}\n\n',
        'data: {"candidates":[{"content":{"parts":[{"codeExecutionResult":{"outcome":"OUTCOME_OK","output":"1\\n"}}]},"finishReason":"STOP"}]}\n\n',
      ]);

      final chat = GoogleChat(client, config);
      final parts = await chat.chatStreamParts([ChatMessage.user('hello')],
          tools: const []).toList();

      final calls = parts.whereType<LLMProviderToolCallPart>().toList();
      expect(calls, hasLength(1));
      expect(calls.single.toolCallId, equals('code_execution_0'));
      expect(calls.single.toolName, equals('code_execution'));
      expect(calls.single.input, isA<Map>());
      expect((calls.single.input as Map)['code'], equals('print(1)'));

      final results = parts.whereType<LLMProviderToolResultPart>().toList();
      expect(results, hasLength(1));
      expect(results.single.toolCallId, equals('code_execution_0'));
      expect(results.single.toolName, equals('code_execution'));
      expect(results.single.result, isA<Map>());
      expect((results.single.result as Map)['outcome'], equals('OUTCOME_OK'));
      expect((results.single.result as Map)['output'], equals('1\n'));

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.toolCalls, anyOf(isNull, isEmpty));
    });
  });
}
