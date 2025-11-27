import 'package:test/test.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

void main() {
  group('ChatMessage.toPromptMessage', () {
    test('converts text message to TextContentPart', () {
      final message = ChatMessage.user('Hello');

      final prompt = message.toPromptMessage();

      expect(prompt.role, ChatRole.user);
      expect(prompt.parts.length, 1);
      expect(prompt.parts.first, isA<TextContentPart>());
      final textPart = prompt.parts.first as TextContentPart;
      expect(textPart.text, 'Hello');
    });

    test('converts image message to text + file parts when content present',
        () {
      final bytes = <int>[1, 2, 3];
      final message = ChatMessage.image(
        role: ChatRole.user,
        mime: ImageMime.png,
        data: bytes,
        content: 'An image description',
      );

      final prompt = message.toPromptMessage();

      expect(prompt.parts.length, 2);
      expect(prompt.parts[0], isA<TextContentPart>());
      expect(prompt.parts[1], isA<FileContentPart>());

      final textPart = prompt.parts[0] as TextContentPart;
      final filePart = prompt.parts[1] as FileContentPart;

      expect(textPart.text, 'An image description');
      expect(filePart.mime, FileMime.png);
      expect(filePart.data, bytes);
    });

    test('converts tool use message to ToolCallContentPart list', () {
      final toolCall = ToolCall(
        id: 'call-1',
        callType: 'function',
        function: const FunctionCall(
          name: 'get_weather',
          arguments: '{"location":"Paris"}',
        ),
      );

      final message = ChatMessage.toolUse(
        toolCalls: [toolCall],
        content: 'Using tool',
      );

      final prompt = message.toPromptMessage();

      expect(prompt.parts.length, 2);
      expect(prompt.parts[0], isA<TextContentPart>());
      expect(prompt.parts[1], isA<ToolCallContentPart>());

      final callPart = prompt.parts[1] as ToolCallContentPart;
      expect(callPart.toolName, 'get_weather');
      expect(callPart.argumentsJson, '{"location":"Paris"}');
      expect(callPart.toolCallId, 'call-1');
    });

    test('converts tool result message to ToolResultContentPart list', () {
      final toolResult = ToolCall(
        id: 'call-1',
        callType: 'function',
        function: const FunctionCall(
          name: 'get_weather',
          arguments: '{"temperature": "20C"}',
        ),
      );

      final message = ChatMessage.toolResult(
        results: [toolResult],
        content: 'Tool result',
      );

      final prompt = message.toPromptMessage();

      expect(prompt.parts.length, 2);
      expect(prompt.parts[0], isA<TextContentPart>());
      expect(prompt.parts[1], isA<ToolResultContentPart>());

      final resultPart = prompt.parts[1] as ToolResultContentPart;
      expect(resultPart.toolCallId, 'call-1');
      expect(resultPart.toolName, 'get_weather');
      expect(resultPart.payload, isA<ToolResultTextPayload>());
      final payload = resultPart.payload as ToolResultTextPayload;
      expect(payload.value, '{"temperature": "20C"}');
    });

    test('round-trips ModelMessage via ChatMessage.fromPromptMessage', () {
      final bytes = <int>[1, 2, 3, 4];

      final prompt = ModelMessage(
        role: ChatRole.user,
        parts: [
          const TextContentPart('Hello with file'),
          FileContentPart(
            FileMime.pdf,
            bytes,
            filename: 'doc.pdf',
          ),
        ],
        providerOptions: const {
          'anthropic': {'foo': 'bar'},
          'google': {'baz': 1},
        },
      );

      final message = ChatMessage.fromPromptMessage(prompt);
      final converted = message.toPromptMessage();

      expect(converted.role, ChatRole.user);
      expect(converted.providerOptions['anthropic'], {'foo': 'bar'});
      expect(converted.providerOptions['google'], {'baz': 1});
      expect(converted.parts.length, 2);
      expect(converted.parts[0], isA<TextContentPart>());
      expect(converted.parts[1], isA<FileContentPart>());

      final textPart = converted.parts[0] as TextContentPart;
      final filePart = converted.parts[1] as FileContentPart;

      expect(textPart.text, 'Hello with file');
      expect(filePart.mime, FileMime.pdf);
      expect(filePart.data, bytes);
      expect(filePart.filename, 'doc.pdf');
    });
  });
}
