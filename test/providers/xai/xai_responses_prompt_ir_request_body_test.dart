import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_xai/responses.dart';
import 'package:test/test.dart';

import '../../utils/fakes/openai_fake_client.dart';

void main() {
  group('xAI Responses Prompt IR request body', () {
    test('combines text parts and emits tool input items', () async {
      final config = OpenAICompatibleConfig(
        providerId: 'xai.responses',
        providerName: 'xAI (Responses)',
        apiKey: 'test-key',
        baseUrl: 'https://example.com/v1/',
        model: 'grok-4-fast',
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = {
          'id': 'resp_1',
          'model': config.model,
          'status': 'completed',
          'output': [
            {
              'type': 'message',
              'role': 'assistant',
              'content': [
                {'type': 'output_text', 'text': 'ok'}
              ],
            }
          ],
        };

      final responses = XAIResponses(client, config);

      final call = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(
          name: 'get_weather',
          arguments: '{"city":"Tokyo"}',
        ),
      );

      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: ChatRole.user,
            parts: [
              const TextPart('A'),
              const TextPart('B'),
              ToolCallPart(call, overrideRole: ChatRole.assistant),
            ],
          ),
        ],
      );

      await responses.chatPrompt(prompt);

      final body = client.lastJsonBody;
      expect(body, isNotNull);
      expect(body!['model'], equals('grok-4-fast'));

      final input = body['input'] as List;
      expect(input, hasLength(2));

      expect(input[0], equals({'role': 'user', 'content': 'A\n\nB'}));
      expect(
        input[1],
        equals({
          'type': 'function_call',
          'id': 'call_1',
          'call_id': 'call_1',
          'name': 'get_weather',
          'arguments': '{"city":"Tokyo"}',
          'status': 'completed',
        }),
      );
    });
  });
}
