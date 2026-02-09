import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/openai.dart';
import 'package:llm_dart_openai_compatible/responses.dart';
import 'package:test/test.dart';

import '../../utils/fakes/openai_fake_client.dart';

void main() {
  group('OpenAI Responses Prompt IR request body', () {
    test('groups multi-part user message into a single input entry', () async {
      final config = OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.com',
        model: 'gpt-4o-mini',
        useResponsesAPI: true,
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = {
          'id': 'resp_1',
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
      final responses = OpenAIResponses(client, config);

      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: ChatRole.user,
            parts: [
              const TextPart('Describe this image:'),
              ImagePart(
                mime: ImageMime.png,
                data: const [1, 2, 3],
                text: 'A small icon.',
              ),
            ],
          ),
        ],
      );

      await responses.chatPrompt(prompt);

      final input = client.lastJsonBody?['input'] as List?;
      expect(input, isNotNull);
      expect(input, hasLength(1));

      final user = input!.single as Map;
      expect(user['role'], equals('user'));

      final content = user['content'] as List;
      expect(content, hasLength(3));

      expect(
        content[0],
        equals({'type': 'input_text', 'text': 'Describe this image:'}),
      );
      expect(
          content[1], equals({'type': 'input_text', 'text': 'A small icon.'}));

      final expectedDataUrl =
          'data:image/png;base64,${base64Encode([1, 2, 3])}';
      expect(
        content[2],
        equals({'type': 'input_image', 'image_url': expectedDataUrl}),
      );
    });

    test('splits ToolResultPart into tool-role input messages', () async {
      final config = OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.com',
        model: 'gpt-4o-mini',
        useResponsesAPI: true,
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = {
          'id': 'resp_1',
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
      final responses = OpenAIResponses(client, config);

      final toolResult = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(
          name: 'get_weather',
          arguments: '{"temp":25}',
        ),
      );

      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: ChatRole.user,
            parts: [
              const TextPart('Before'),
              ToolResultPart(toolResult),
              const TextPart('After'),
            ],
          ),
        ],
      );

      await responses.chatPrompt(prompt);

      final input = client.lastJsonBody?['input'] as List?;
      expect(input, isNotNull);
      expect(input, hasLength(3));

      expect(input![0], equals({'role': 'user', 'content': 'Before'}));
      expect(
          input[1],
          equals({
            'role': 'tool',
            'tool_call_id': 'call_1',
            'content': '{"temp":25}'
          }));
      expect(input[2], equals({'role': 'user', 'content': 'After'}));
    });
  });
}
