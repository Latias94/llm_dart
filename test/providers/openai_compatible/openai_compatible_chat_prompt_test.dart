// OpenAI-compatible chat prompt tests exercise ChatMessage-based
// prompts and verify mapping into the generic OpenAI-compatible
// request model.
// ignore_for_file: deprecated_member_use

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:test/test.dart';
import 'openai_compatible_test_utils.dart';

void main() {
  group('OpenAICompatibleChat prompt mapping', () {
    test('builds messages from ModelMessage with multimodal + tools', () async {
      final tool = Tool.function(
        name: 'get_weather',
        description: 'Get the weather',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'location': ParameterProperty(
              propertyType: 'string',
              description: 'City name',
            ),
          },
          required: const ['location'],
        ),
      );

      final config = OpenAICompatibleConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.test/v1',
        providerId: 'test-provider',
        model: 'gpt-4.1-mini',
        tools: [tool],
      );

      final client = CapturingOpenAICompatibleClient(config);
      final chat = OpenAICompatibleChat(client, config);

      final messages = <ChatMessage>[
        ChatMessage.user('Hello'),
        ChatMessage.imageUrl(
          role: ChatRole.user,
          url: 'https://example.com/image.png',
          content: 'Look at this image',
        ),
        ChatMessage.toolUse(
          toolCalls: [
            ToolCall(
              id: 'call_1',
              callType: 'function',
              function: const FunctionCall(
                name: 'get_weather',
                arguments: '{"location":"Paris"}',
              ),
            ),
          ],
        ),
      ];

      await chat.chatWithTools(messages, null);

      final body = client.lastRequestBody;
      expect(body, isNotNull);

      final apiMessages = body!['messages'] as List<dynamic>;
      expect(apiMessages.length, equals(3));

      final firstUser = apiMessages[0] as Map<String, dynamic>;
      expect(firstUser['role'], equals('user'));
      expect(firstUser['content'], equals('Hello'));

      final secondUser = apiMessages[1] as Map<String, dynamic>;
      expect(secondUser['role'], equals('user'));
      final contentArray = secondUser['content'] as List<dynamic>;
      final hasTextPart = contentArray.any((part) {
        final map = part as Map<String, dynamic>;
        return map['type'] == 'text' && map['text'] == 'Look at this image';
      });
      final hasImagePart = contentArray.any((part) {
        final map = part as Map<String, dynamic>;
        if (map['type'] != 'image_url') return false;
        final image = map['image_url'] as Map<String, dynamic>;
        return image['url'] == 'https://example.com/image.png';
      });
      expect(hasTextPart, isTrue);
      expect(hasImagePart, isTrue);

      final assistantMsg = apiMessages[2] as Map<String, dynamic>;
      expect(assistantMsg['role'], equals('assistant'));
      final toolCalls = assistantMsg['tool_calls'] as List<dynamic>;
      expect(toolCalls.length, equals(1));
      final firstCall = toolCalls.first as Map<String, dynamic>;
      expect(firstCall['type'], equals('function'));
      final function = firstCall['function'] as Map<String, dynamic>;
      expect(function['name'], equals('get_weather'));
      expect(function['arguments'], equals('{"location":"Paris"}'));
    });
  });
}
