import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'dart:typed_data';

void main() {
  group('OpenAI Message Conversion Tests', () {
    late OpenAIClient client;
    late OpenAIClient responsesClient;

    setUp(() {
      // Client for Chat Completions API (default)
      final config = OpenAIConfig(
        apiKey: 'test-key',
        model: 'gpt-4o',
        useResponsesAPI: false,
      );
      client = OpenAIClient(config);

      // Client for Responses API
      final responsesConfig = OpenAIConfig(
        apiKey: 'test-key',
        model: 'gpt-4o',
        useResponsesAPI: true,
      );
      responsesClient = OpenAIClient(responsesConfig);
    });

    group('TextMessage Conversion', () {
      test('should convert text message correctly', () {
        final message = ChatMessage.user('Hello, world!');
        final result = client.convertMessage(message);

        expect(result['role'], equals('user'));
        expect(result['content'], equals('Hello, world!'));
      });

      test('should convert text message with name', () {
        final message = ChatMessage.system('You are helpful', name: 'system');
        final result = client.convertMessage(message);

        expect(result['role'], equals('system'));
        expect(result['content'], equals('You are helpful'));
        expect(result['name'], equals('system'));
      });
    });

    group('ImageMessage Conversion - Chat Completions API', () {
      test('should convert image message without text content', () {
        final imageData = Uint8List.fromList([137, 80, 78, 71]); // PNG header
        final message = ChatMessage.image(
          role: ChatRole.user,
          mime: ImageMime.png,
          data: imageData,
        );

        final result = client.convertMessage(message);

        expect(result['role'], equals('user'));
        expect(result['content'], isA<List>());

        final content = result['content'] as List;
        expect(content, hasLength(1));
        expect(content[0]['type'], equals('image_url'));
        expect(content[0]['image_url'], isA<Map>());
        expect(content[0]['image_url']['url'],
            startsWith('data:image/png;base64,'));
      });

      test('should convert image message with text content', () {
        final imageData = Uint8List.fromList([137, 80, 78, 71]);
        final message = ChatMessage.image(
          role: ChatRole.user,
          mime: ImageMime.png,
          data: imageData,
          content: 'What is in this image?',
        );

        final result = client.convertMessage(message);

        expect(result['role'], equals('user'));
        expect(result['content'], isA<List>());

        final content = result['content'] as List;
        expect(content, hasLength(2));

        // First element should be text
        expect(content[0]['type'], equals('text'));
        expect(content[0]['text'], equals('What is in this image?'));

        // Second element should be image
        expect(content[1]['type'], equals('image_url'));
        expect(content[1]['image_url'], isA<Map>());
        expect(content[1]['image_url']['url'],
            startsWith('data:image/png;base64,'));
      });

      test('should handle different image MIME types', () {
        final testCases = [
          (ImageMime.jpeg, 'image/jpeg'),
          (ImageMime.png, 'image/png'),
          (ImageMime.gif, 'image/gif'),
          (ImageMime.webp, 'image/webp'),
        ];

        for (final (mime, mimeType) in testCases) {
          final imageData = Uint8List.fromList([1, 2, 3, 4]);
          final message = ChatMessage.image(
            role: ChatRole.user,
            mime: mime,
            data: imageData,
          );

          final result = client.convertMessage(message);
          final content = result['content'] as List;
          final imageUrl = content[0]['image_url']['url'] as String;

          expect(imageUrl, startsWith('data:$mimeType;base64,'));
        }
      });
    });

    group('ImageMessage Conversion - Responses API', () {
      test('should convert image message without text content', () {
        final imageData = Uint8List.fromList([137, 80, 78, 71]);
        final message = ChatMessage.image(
          role: ChatRole.user,
          mime: ImageMime.png,
          data: imageData,
        );

        final result = responsesClient.convertMessage(message);

        expect(result['role'], equals('user'));
        expect(result['content'], isA<List>());

        final content = result['content'] as List;
        expect(content, hasLength(1));
        expect(content[0]['type'], equals('input_image'));
        expect(content[0]['image_url'], isA<String>());
        expect(content[0]['image_url'], startsWith('data:image/png;base64,'));
      });

      test('should convert image message with text content', () {
        final imageData = Uint8List.fromList([137, 80, 78, 71]);
        final message = ChatMessage.image(
          role: ChatRole.user,
          mime: ImageMime.png,
          data: imageData,
          content: 'Describe this image',
        );

        final result = responsesClient.convertMessage(message);

        expect(result['role'], equals('user'));
        expect(result['content'], isA<List>());

        final content = result['content'] as List;
        expect(content, hasLength(2));

        // First element should be text with input_text type
        expect(content[0]['type'], equals('input_text'));
        expect(content[0]['text'], equals('Describe this image'));

        // Second element should be image with input_image type
        expect(content[1]['type'], equals('input_image'));
        expect(content[1]['image_url'], isA<String>());
        expect(content[1]['image_url'], startsWith('data:image/png;base64,'));
      });
    });

    group('ImageUrlMessage Conversion - Chat Completions API', () {
      test('should convert image URL message without text content', () {
        const imageUrl = 'https://example.com/image.jpg';
        final message = ChatMessage.imageUrl(
          role: ChatRole.user,
          url: imageUrl,
        );

        final result = client.convertMessage(message);

        expect(result['role'], equals('user'));
        expect(result['content'], isA<List>());

        final content = result['content'] as List;
        expect(content, hasLength(1));
        expect(content[0]['type'], equals('image_url'));
        expect(content[0]['image_url'], isA<Map>());
        expect(content[0]['image_url']['url'], equals(imageUrl));
      });

      test('should convert image URL message with text content', () {
        const imageUrl = 'https://example.com/image.jpg';
        final message = ChatMessage.imageUrl(
          role: ChatRole.user,
          url: imageUrl,
          content: 'Analyze this image',
        );

        final result = client.convertMessage(message);

        expect(result['role'], equals('user'));
        expect(result['content'], isA<List>());

        final content = result['content'] as List;
        expect(content, hasLength(2));

        // First element should be text
        expect(content[0]['type'], equals('text'));
        expect(content[0]['text'], equals('Analyze this image'));

        // Second element should be image URL
        expect(content[1]['type'], equals('image_url'));
        expect(content[1]['image_url']['url'], equals(imageUrl));
      });
    });

    group('ImageUrlMessage Conversion - Responses API', () {
      test('should convert image URL message without text content', () {
        const imageUrl = 'https://example.com/image.jpg';
        final message = ChatMessage.imageUrl(
          role: ChatRole.user,
          url: imageUrl,
        );

        final result = responsesClient.convertMessage(message);

        expect(result['role'], equals('user'));
        expect(result['content'], isA<List>());

        final content = result['content'] as List;
        expect(content, hasLength(1));
        expect(content[0]['type'], equals('input_image'));
        expect(content[0]['image_url'], equals(imageUrl));
      });

      test('should convert image URL message with text content', () {
        const imageUrl = 'https://example.com/image.jpg';
        final message = ChatMessage.imageUrl(
          role: ChatRole.user,
          url: imageUrl,
          content: 'What do you see?',
        );

        final result = responsesClient.convertMessage(message);

        expect(result['role'], equals('user'));
        expect(result['content'], isA<List>());

        final content = result['content'] as List;
        expect(content, hasLength(2));

        // First element should be text with input_text type
        expect(content[0]['type'], equals('input_text'));
        expect(content[0]['text'], equals('What do you see?'));

        // Second element should be image with input_image type
        expect(content[1]['type'], equals('input_image'));
        expect(content[1]['image_url'], equals(imageUrl));
      });
    });

    group('FileMessage Conversion - Chat Completions API', () {
      test('should convert file message without text content', () {
        final fileData = Uint8List.fromList([37, 80, 68, 70]); // PDF header
        final message = ChatMessage.file(
          role: ChatRole.user,
          mime: FileMime.pdf,
          data: fileData,
        );

        final result = client.convertMessage(message);

        expect(result['role'], equals('user'));
        expect(result['content'], isA<List>());

        final content = result['content'] as List;
        expect(content, hasLength(1));
        expect(content[0]['type'], equals('file'));
        expect(content[0]['file'], isA<Map>());
        expect(content[0]['file']['file_data'], isA<String>());
      });

      test('should convert file message with text content', () {
        final fileData = Uint8List.fromList([37, 80, 68, 70]);
        final message = ChatMessage.file(
          role: ChatRole.user,
          mime: FileMime.pdf,
          data: fileData,
          content: 'Analyze this PDF document',
        );

        final result = client.convertMessage(message);

        expect(result['role'], equals('user'));
        expect(result['content'], isA<List>());

        final content = result['content'] as List;
        expect(content, hasLength(2));

        // First element should be text
        expect(content[0]['type'], equals('text'));
        expect(content[0]['text'], equals('Analyze this PDF document'));

        // Second element should be file
        expect(content[1]['type'], equals('file'));
        expect(content[1]['file']['file_data'], isA<String>());
      });

      test('should convert PDF message using convenience method', () {
        final fileData = Uint8List.fromList([37, 80, 68, 70]);
        final message = ChatMessage.pdf(
          role: ChatRole.user,
          data: fileData,
          content: 'Review this PDF',
        );

        final result = client.convertMessage(message);

        expect(result['role'], equals('user'));
        expect(result['content'], isA<List>());

        final content = result['content'] as List;
        expect(content, hasLength(2));
        expect(content[0]['type'], equals('text'));
        expect(content[1]['type'], equals('file'));
      });
    });

    group('FileMessage Conversion - Responses API', () {
      test('should convert file message without text content', () {
        final fileData = Uint8List.fromList([37, 80, 68, 70]);
        final message = ChatMessage.file(
          role: ChatRole.user,
          mime: FileMime.pdf,
          data: fileData,
        );

        final result = responsesClient.convertMessage(message);

        expect(result['role'], equals('user'));
        expect(result['content'], isA<List>());

        final content = result['content'] as List;
        expect(content, hasLength(1));
        expect(content[0]['type'], equals('input_file'));
        expect(content[0]['file_data'], isA<String>());
      });

      test('should convert file message with text content', () {
        final fileData = Uint8List.fromList([37, 80, 68, 70]);
        final message = ChatMessage.file(
          role: ChatRole.user,
          mime: FileMime.pdf,
          data: fileData,
          content: 'Summarize this document',
        );

        final result = responsesClient.convertMessage(message);

        expect(result['role'], equals('user'));
        expect(result['content'], isA<List>());

        final content = result['content'] as List;
        expect(content, hasLength(2));

        // First element should be text with input_text type
        expect(content[0]['type'], equals('input_text'));
        expect(content[0]['text'], equals('Summarize this document'));

        // Second element should be file with input_file type
        expect(content[1]['type'], equals('input_file'));
        expect(content[1]['file_data'], isA<String>());
      });
    });

    group('ToolUseMessage Conversion', () {
      test('should convert tool use message correctly', () {
        final toolCalls = [
          ToolCall(
            id: 'call_123',
            callType: 'function',
            function: FunctionCall(
              name: 'get_weather',
              arguments: '{"location": "San Francisco"}',
            ),
          ),
        ];
        final message = ChatMessage.toolUse(
          toolCalls: toolCalls,
          content: 'Using weather tool',
        );

        final result = client.convertMessage(message);

        expect(result['role'], equals('assistant'));
        expect(result['tool_calls'], isA<List>());
        expect(result['tool_calls'], hasLength(1));
        expect(result['tool_calls'][0]['id'], equals('call_123'));
      });
    });
  });
}
