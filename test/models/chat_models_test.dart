import 'dart:typed_data';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_core/llm_dart_core.dart' show ToolResultTextPayload;
import 'package:test/test.dart';

void main() {
  group('Chat Models', () {
    group('ChatRole', () {
      test('has expected values', () {
        expect(ChatRole.values, hasLength(3));
        expect(ChatRole.values, contains(ChatRole.user));
        expect(ChatRole.values, contains(ChatRole.assistant));
        expect(ChatRole.values, contains(ChatRole.system));
      });
    });

    group('ImageMime', () {
      test('has expected MIME types', () {
        expect(ImageMime.jpeg.mimeType, equals('image/jpeg'));
        expect(ImageMime.png.mimeType, equals('image/png'));
        expect(ImageMime.gif.mimeType, equals('image/gif'));
        expect(ImageMime.webp.mimeType, equals('image/webp'));
      });
    });

    group('FileMime', () {
      test('has expected MIME types', () {
        expect(FileMime.pdf.mimeType, equals('application/pdf'));
        expect(
          FileMime.docx.mimeType,
          equals(
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          ),
        );
        expect(FileMime.txt.mimeType, equals('text/plain'));
        expect(FileMime.csv.mimeType, equals('text/csv'));
        expect(FileMime.json.mimeType, equals('application/json'));
        expect(FileMime.xml.mimeType, equals('application/xml'));
        expect(FileMime.mp3.mimeType, equals('audio/mpeg'));
        expect(FileMime.wav.mimeType, equals('audio/wav'));
        expect(FileMime.mp4.mimeType, equals('video/mp4'));
        expect(FileMime.avi.mimeType, equals('video/x-msvideo'));
      });

      test('supports equality', () {
        expect(FileMime.pdf, equals(FileMime.pdf));
        expect(FileMime.pdf == const FileMime('application/pdf'), isTrue);
        expect(FileMime.pdf == FileMime.txt, isFalse);
      });

      test('has expected string representation', () {
        expect(FileMime.pdf.toString(), equals('application/pdf'));
        expect(FileMime.json.toString(), equals('application/json'));
      });
    });

    group('ChatContentPart', () {
      test('TextContentPart stores text', () {
        const part = TextContentPart('Hello');
        expect(part.text, equals('Hello'));
      });

      test('ReasoningContentPart stores text', () {
        const part = ReasoningContentPart('Think step by step');
        expect(part.text, equals('Think step by step'));
      });

      test('FileContentPart stores file fields', () {
        final data = Uint8List.fromList([1, 2, 3, 4]);
        final part = FileContentPart(
          FileMime.pdf,
          data,
          filename: 'test.pdf',
          uri: 'https://example.com/test.pdf',
        );

        expect(part.mime, equals(FileMime.pdf));
        expect(part.data, equals(data));
        expect(part.filename, equals('test.pdf'));
        expect(part.uri, equals('https://example.com/test.pdf'));
      });

      test('UrlFileContentPart stores url and mime', () {
        const part = UrlFileContentPart('https://example.com/image.jpg');
        expect(part.url, equals('https://example.com/image.jpg'));
        expect(part.mime, equals(const FileMime('image/*')));
        expect(part.filename, isNull);
      });

      test('ToolCallContentPart stores tool call fields', () {
        const part = ToolCallContentPart(
          toolName: 'get_weather',
          argumentsJson: '{"location":"Boston"}',
          toolCallId: 'call_1',
        );

        expect(part.toolName, equals('get_weather'));
        expect(part.argumentsJson, equals('{"location":"Boston"}'));
        expect(part.toolCallId, equals('call_1'));
      });

      test('ToolResultContentPart stores tool result fields', () {
        const part = ToolResultContentPart(
          toolCallId: 'call_1',
          toolName: 'get_weather',
          payload: ToolResultTextPayload('Sunny'),
        );

        expect(part.toolCallId, equals('call_1'));
        expect(part.toolName, equals('get_weather'));
        expect(part.payload, isA<ToolResultTextPayload>());
      });
    });

    group('ModelMessage', () {
      test('userText builds a user text message', () {
        final message = ModelMessage.userText('Hi');
        expect(message.role, equals(ChatRole.user));
        expect(message.parts, hasLength(1));
        expect(message.parts.first, isA<TextContentPart>());
        expect((message.parts.first as TextContentPart).text, equals('Hi'));
      });

      test('systemText builds a system text message', () {
        final message = ModelMessage.systemText('System');
        expect(message.role, equals(ChatRole.system));
        expect(message.parts, hasLength(1));
        expect((message.parts.first as TextContentPart).text, equals('System'));
      });

      test('assistantText builds an assistant text message', () {
        final message = ModelMessage.assistantText('Hello');
        expect(message.role, equals(ChatRole.assistant));
        expect(message.parts, hasLength(1));
        expect((message.parts.first as TextContentPart).text, equals('Hello'));
      });

      test('supports providerOptions', () {
        final message = ModelMessage.userText(
          'Hi',
          providerOptions: const {'custom': true},
        );

        expect(message.providerOptions, containsPair('custom', true));
      });
    });
  });
}
