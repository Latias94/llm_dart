import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';
import 'ollama_test_utils.dart';

void main() {
  group('OllamaChat prompt mapping', () {
    test('builds messages from ModelMessage with tools and jsonSchema',
        () async {
      final tool = Tool.function(
        name: 'get_weather',
        description: 'Get current weather',
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

      final schema = StructuredOutputFormat(
        name: 'Weather',
        schema: {
          'type': 'object',
          'properties': {
            'temp': {'type': 'number'},
          },
          'required': ['temp'],
        },
      );

      final config = OllamaConfig(
        model: 'llama3.2',
        tools: [tool],
        jsonSchema: schema,
      );

      final client = CapturingOllamaClient(config);
      final chat = OllamaChat(client, config);

      final messages = <ChatMessage>[
        ChatMessage.user('Hello'),
        ChatMessage.toolResult(
          results: [
            ToolCall(
              id: 'call_1',
              callType: 'function',
              function: const FunctionCall(
                name: 'get_weather',
                arguments: '{"location":"Tokyo"}',
              ),
            ),
          ],
        ),
      ];

      await chat.chatWithTools(messages, null);

      final body = client.lastRequestBody;
      expect(body, isNotNull);
      expect(client.lastEndpoint, equals('/api/chat'));

      final apiMessages = body!['messages'] as List<dynamic>;
      expect(apiMessages.length, equals(2));

      final userMessage = apiMessages[0] as Map<String, dynamic>;
      expect(userMessage['role'], equals('user'));
      expect(userMessage['content'], contains('Hello'));

      final toolMessage = apiMessages[1] as Map<String, dynamic>;
      expect(toolMessage['role'], equals('tool'));
      expect(toolMessage['tool_name'], equals('get_weather'));
      expect(
        toolMessage['content'],
        equals('{"location":"Tokyo"}'),
      );

      final toolsJson = body['tools'] as List<dynamic>;
      expect(toolsJson.length, equals(1));

      // Structured output should use native Ollama `format` parameter
      // with the JSON schema.
      final format = body['format'] as Map<String, dynamic>?;
      expect(format, isNotNull);
      expect(format!['type'], equals('object'));
      expect(format['properties'], contains('temp'));
    });
  });

  group('OllamaChat multimodal', () {
    test('encodes inline image bytes into images array', () async {
      final config = const OllamaConfig(
        model: 'llava:latest',
      );

      final client = CapturingOllamaClient(config);
      final chat = OllamaChat(client, config);

      final imageBytes = <int>[1, 2, 3, 4];

      final messages = <ChatMessage>[
        ChatMessage.image(
          role: ChatRole.user,
          mime: ImageMime.png,
          data: imageBytes,
          content: 'Describe this image',
        ),
      ];

      await chat.chat(messages);

      final body = client.lastRequestBody;
      expect(body, isNotNull);
      expect(client.lastEndpoint, equals('/api/chat'));

      final apiMessages = body!['messages'] as List<dynamic>;
      expect(apiMessages.length, equals(1));

      final userMessage = apiMessages.first as Map<String, dynamic>;
      expect(userMessage['role'], equals('user'));
      expect(userMessage['content'], contains('Describe this image'));

      final images = userMessage['images'] as List<dynamic>?;
      expect(images, isNotNull);
      expect(images!.length, equals(1));

      final encoded = images.first as String;
      expect(encoded, equals(base64Encode(imageBytes)));
    });
  });
}
