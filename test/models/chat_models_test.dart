// Chat model tests cover the legacy ChatMessage factories alongside
// the newer ModelMessage and ChatContentPart abstractions.
// ignore_for_file: deprecated_member_use

import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart/legacy/chat.dart';
import 'dart:typed_data';

void main() {
  group('Chat Models Tests', () {
    group('ChatRole Enum', () {
      test('should have correct values', () {
        expect(ChatRole.values, hasLength(3));
        expect(ChatRole.values, contains(ChatRole.user));
        expect(ChatRole.values, contains(ChatRole.assistant));
        expect(ChatRole.values, contains(ChatRole.system));
      });
    });

    group('ImageMime Enum', () {
      test('should have correct MIME types', () {
        expect(ImageMime.jpeg.mimeType, equals('image/jpeg'));
        expect(ImageMime.png.mimeType, equals('image/png'));
        expect(ImageMime.gif.mimeType, equals('image/gif'));
        expect(ImageMime.webp.mimeType, equals('image/webp'));
      });
    });

    group('FileMime Class', () {
      test('should have correct MIME types', () {
        expect(FileMime.pdf.mimeType, equals('application/pdf'));
        expect(
            FileMime.docx.mimeType,
            equals(
                'application/vnd.openxmlformats-officedocument.wordprocessingml.document'));
        expect(FileMime.txt.mimeType, equals('text/plain'));
        expect(FileMime.csv.mimeType, equals('text/csv'));
        expect(FileMime.json.mimeType, equals('application/json'));
        expect(FileMime.xml.mimeType, equals('application/xml'));
        expect(FileMime.mp3.mimeType, equals('audio/mpeg'));
        expect(FileMime.wav.mimeType, equals('audio/wav'));
        expect(FileMime.mp4.mimeType, equals('video/mp4'));
        expect(FileMime.avi.mimeType, equals('video/x-msvideo'));
      });

      test('should support equality comparison', () {
        expect(FileMime.pdf, equals(FileMime.pdf));
        expect(FileMime.pdf == FileMime('application/pdf'), isTrue);
        expect(FileMime.pdf == FileMime.txt, isFalse);
      });

      test('should have correct string representation', () {
        expect(FileMime.pdf.toString(), equals('application/pdf'));
        expect(FileMime.json.toString(), equals('application/json'));
      });
    });

    group('MessageType Classes', () {
      test('TextMessage should be created correctly', () {
        const message = TextMessage();
        expect(message, isA<MessageType>());
      });

      test('ImageMessage should store data correctly', () {
        final data = Uint8List.fromList([1, 2, 3, 4]);
        final message = ImageMessage(ImageMime.png, data);

        expect(message.mime, equals(ImageMime.png));
        expect(message.data, equals(data));
      });

      test('FileMessage should store data correctly', () {
        final data = Uint8List.fromList([1, 2, 3, 4]);
        final message = FileMessage(FileMime.pdf, data);

        expect(message.mime, equals(FileMime.pdf));
        expect(message.data, equals(data));
      });

      test('ImageUrlMessage should store URL correctly', () {
        const url = 'https://example.com/image.jpg';
        const message = ImageUrlMessage(url);

        expect(message.url, equals(url));
      });

      test('ToolUseMessage should store tool calls correctly', () {
        final toolCalls = [
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(
              name: 'test_function',
              arguments: '{"param": "value"}',
            ),
          ),
        ];
        final message = ToolUseMessage(toolCalls);

        expect(message.toolCalls, equals(toolCalls));
      });
    });

    group('ChatMessage Factory Methods', () {
      test('should create user message correctly', () {
        final message = ChatMessage.user('Hello, world!');

        expect(message.role, equals(ChatRole.user));
        expect(message.content, equals('Hello, world!'));
        expect(message.messageType, isA<TextMessage>());
        expect(message.name, isNull);
      });

      test('should create assistant message correctly', () {
        final message = ChatMessage.assistant('Hello! How can I help?');

        expect(message.role, equals(ChatRole.assistant));
        expect(message.content, equals('Hello! How can I help?'));
        expect(message.messageType, isA<TextMessage>());
        expect(message.name, isNull);
      });

      test('should create system message correctly', () {
        final message = ChatMessage.system(
          'You are a helpful assistant',
          name: 'system',
        );

        expect(message.role, equals(ChatRole.system));
        expect(message.content, equals('You are a helpful assistant'));
        expect(message.messageType, isA<TextMessage>());
        expect(message.name, equals('system'));
      });

      test('should create image message correctly', () {
        final data = Uint8List.fromList([1, 2, 3, 4]);
        final message = ChatMessage.image(
          role: ChatRole.user,
          mime: ImageMime.png,
          data: data,
          content: 'Image description',
        );

        expect(message.role, equals(ChatRole.user));
        expect(message.content, equals('Image description'));
        expect(message.messageType, isA<ImageMessage>());

        final imageMessage = message.messageType as ImageMessage;
        expect(imageMessage.mime, equals(ImageMime.png));
        expect(imageMessage.data, equals(data));
      });

      test('should create image URL message correctly', () {
        const url = 'https://example.com/image.jpg';
        final message = ChatMessage.imageUrl(
          role: ChatRole.user,
          url: url,
          content: 'Image from URL',
        );

        expect(message.role, equals(ChatRole.user));
        expect(message.content, equals('Image from URL'));
        expect(message.messageType, isA<ImageUrlMessage>());

        final urlMessage = message.messageType as ImageUrlMessage;
        expect(urlMessage.url, equals(url));
      });

      test('should create file message correctly', () {
        final data = Uint8List.fromList([1, 2, 3, 4]);
        final message = ChatMessage.file(
          role: ChatRole.user,
          mime: FileMime.pdf,
          data: data,
          content: 'PDF document',
        );

        expect(message.role, equals(ChatRole.user));
        expect(message.content, equals('PDF document'));
        expect(message.messageType, isA<FileMessage>());

        final fileMessage = message.messageType as FileMessage;
        expect(fileMessage.mime, equals(FileMime.pdf));
        expect(fileMessage.data, equals(data));
      });

      test('should create PDF message correctly', () {
        final data = Uint8List.fromList([1, 2, 3, 4]);
        final message = ChatMessage.pdf(
          role: ChatRole.user,
          data: data,
          content: 'PDF document',
        );

        expect(message.role, equals(ChatRole.user));
        expect(message.content, equals('PDF document'));
        expect(message.messageType, isA<FileMessage>());

        final fileMessage = message.messageType as FileMessage;
        expect(fileMessage.mime, equals(FileMime.pdf));
        expect(fileMessage.data, equals(data));
      });

      test('should create tool use message correctly', () {
        final toolCalls = [
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(
              name: 'test_function',
              arguments: '{"param": "value"}',
            ),
          ),
        ];
        final message = ChatMessage.toolUse(
          toolCalls: toolCalls,
          content: 'Using tools',
        );

        expect(message.role, equals(ChatRole.assistant));
        expect(message.content, equals('Using tools'));
        expect(message.messageType, isA<ToolUseMessage>());

        final toolMessage = message.messageType as ToolUseMessage;
        expect(toolMessage.toolCalls, equals(toolCalls));
      });

      test('should create tool result message correctly', () {
        final results = [
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(
              name: 'test_function',
              arguments: '{"result": "success"}',
            ),
          ),
        ];
        final message = ChatMessage.toolResult(
          results: results,
          content: 'Tool results',
        );

        expect(message.role, equals(ChatRole.user));
        expect(message.content, equals('Tool results'));
        expect(message.messageType, isA<ToolResultMessage>());

        final resultMessage = message.messageType as ToolResultMessage;
        expect(resultMessage.results, equals(results));
      });
    });
  });
}
