import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_chat/llm_dart_chat.dart';
import 'package:test/test.dart';

void main() {
  group('ChatInput', () {
    test('text creates user-facing model messages', () {
      final input = ChatInput.text('Hello');

      final UserModelMessage message = input.message;
      expect(message.role, ModelMessageRole.user);
      expect(message.parts, hasLength(1));
      expect((message.parts.single as TextModelPart).text, 'Hello');
    });

    test('parts preserves model parts and provider options', () {
      const providerOptions = _TestPromptPartOptions('input');
      final fileData = FileTextData('notes');
      final input = ChatInput.parts(
        [
          const TextModelPart('Read this'),
          FileModelPart(
            mediaType: 'text/plain',
            filename: 'notes.txt',
            data: fileData,
          ),
        ],
        providerOptions: providerOptions,
      );

      final UserModelMessage message = input.message;
      expect(message.providerOptions, same(providerOptions));
      expect(message.parts, hasLength(2));
      expect((message.parts[0] as TextModelPart).text, 'Read this');
      final filePart = message.parts[1] as FileModelPart;
      expect(filePart.mediaType, 'text/plain');
      expect(filePart.filename, 'notes.txt');
      expect(filePart.data, same(fileData));
    });
  });
}

final class _TestPromptPartOptions implements ProviderPromptPartOptions {
  final String value;

  const _TestPromptPartOptions(this.value);
}
