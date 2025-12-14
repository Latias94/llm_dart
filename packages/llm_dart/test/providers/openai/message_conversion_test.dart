import 'dart:typed_data';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_core/llm_dart_core.dart' show ToolResultTextPayload;
import 'package:llm_dart_openai/testing.dart' as openai;
import 'package:test/test.dart';

void main() {
  group('OpenAI prompt message mapping', () {
    late openai.OpenAIClient chatClient;
    late openai.OpenAIClient responsesClient;

    setUp(() {
      chatClient = openai.OpenAIClient(
        const openai.OpenAIConfig(
          apiKey: 'test-key',
          model: 'gpt-4o',
          useResponsesAPI: false,
        ),
      );

      responsesClient = openai.OpenAIClient(
        const openai.OpenAIConfig(
          apiKey: 'test-key',
          model: 'gpt-4o',
          useResponsesAPI: true,
        ),
      );
    });

    test('maps pure user text to string content (chat completions)', () {
      final message = ModelMessage.userText('Hello, world!');
      final apiMessages = chatClient.buildApiMessagesFromPrompt([message]);
      expect(apiMessages, hasLength(1));

      final mapped = apiMessages.single;
      expect(mapped['role'], equals('user'));
      expect(mapped['content'], equals('Hello, world!'));
    });

    test('maps user image bytes to image_url part (chat completions)', () {
      final imageData = Uint8List.fromList([137, 80, 78, 71]); // PNG header
      final message = ChatPromptBuilder.user()
          .imageBytes(imageData, mime: ImageMime.png)
          .build();

      final apiMessages = chatClient.buildApiMessagesFromPrompt([message]);
      final mapped = apiMessages.single;

      expect(mapped['role'], equals('user'));
      expect(mapped['content'], isA<List>());

      final content = mapped['content'] as List;
      expect(content, hasLength(1));
      expect(content.first['type'], equals('image_url'));
      expect(content.first['image_url']['url'],
          startsWith('data:image/png;base64,'));
    });

    test('maps user text + image bytes to mixed parts (chat completions)', () {
      final imageData = Uint8List.fromList([137, 80, 78, 71]);
      final message = ChatPromptBuilder.user()
          .text('What is in this image?')
          .imageBytes(imageData, mime: ImageMime.png)
          .build();

      final mapped = chatClient.buildApiMessagesFromPrompt([message]).single;
      final content = mapped['content'] as List;

      expect(content, hasLength(2));
      expect(content[0]['type'], equals('text'));
      expect(content[0]['text'], equals('What is in this image?'));
      expect(content[1]['type'], equals('image_url'));
      expect(
          content[1]['image_url']['url'], startsWith('data:image/png;base64,'));
    });

    test('maps user image url part (responses api)', () {
      const imageUrl = 'https://example.com/image.jpg';
      final message = ModelMessage(
        role: ChatRole.user,
        parts: const [
          UrlFileContentPart(imageUrl),
        ],
      );

      final mapped =
          responsesClient.buildApiMessagesFromPrompt([message]).single;
      final content = mapped['content'] as List;

      expect(mapped['role'], equals('user'));
      expect(content, hasLength(1));
      expect(content[0]['type'], equals('input_image'));
      expect(content[0]['image_url'], equals(imageUrl));
    });

    test('maps user file bytes to file part (chat completions)', () {
      final fileData = Uint8List.fromList([37, 80, 68, 70]); // PDF header
      final message = ModelMessage(
        role: ChatRole.user,
        parts: [
          FileContentPart(FileMime.pdf, fileData),
        ],
      );

      final mapped = chatClient.buildApiMessagesFromPrompt([message]).single;
      final content = mapped['content'] as List;

      expect(mapped['role'], equals('user'));
      expect(content, hasLength(1));
      expect(content[0]['type'], equals('file'));
      expect(content[0]['file']['file_data'], isA<String>());
    });

    test('maps assistant tool calls to tool_calls (chat completions)', () {
      final message = ModelMessage(
        role: ChatRole.assistant,
        parts: const [
          TextContentPart('Using weather tool'),
          ToolCallContentPart(
            toolName: 'get_weather',
            argumentsJson: '{"location":"San Francisco"}',
            toolCallId: 'call_123',
          ),
        ],
      );

      final mapped = chatClient.buildApiMessagesFromPrompt([message]).single;
      expect(mapped['role'], equals('assistant'));
      expect(mapped['content'], equals('Using weather tool'));
      expect(mapped['tool_calls'], isA<List>());
      expect(mapped['tool_calls'], hasLength(1));
      expect(mapped['tool_calls'][0]['id'], equals('call_123'));
      expect(
          mapped['tool_calls'][0]['function']['name'], equals('get_weather'));
    });

    test('maps tool results to role=tool messages', () {
      final message = ModelMessage(
        role: ChatRole.user,
        parts: const [
          ToolResultContentPart(
            toolCallId: 'call_123',
            toolName: 'get_weather',
            payload: ToolResultTextPayload('Sunny'),
          ),
        ],
      );

      final mapped = chatClient.buildApiMessagesFromPrompt([message]);
      expect(mapped, hasLength(1));
      expect(mapped.single['role'], equals('tool'));
      expect(mapped.single['tool_call_id'], equals('call_123'));
      expect(mapped.single['content'], equals('Sunny'));
    });
  });
}
