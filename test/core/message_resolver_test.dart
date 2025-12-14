import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('resolvePromptMessagesForTextGeneration', () {
    test('prefers promptMessages over other inputs', () {
      final promptMessages = [
        ModelMessage(
          role: ChatRole.assistant,
          parts: const [],
        ),
        ModelMessage(
          role: ChatRole.user,
          parts: const [],
        ),
      ];

      final resolved = resolvePromptMessagesForTextGeneration(
        promptMessages: promptMessages,
        prompt: 'fallback prompt',
        structuredPrompt: ModelMessage(
          role: ChatRole.user,
          parts: const [],
        ),
      );

      expect(resolved, hasLength(2));
      expect(resolved.first.role, ChatRole.assistant);
      expect(resolved[1].role, ChatRole.user);
    });

    test('falls back to structuredPrompt when promptMessages is empty', () {
      final structured = ModelMessage(
        role: ChatRole.user,
        parts: const [],
      );

      final resolved = resolvePromptMessagesForTextGeneration(
        promptMessages: const [],
        structuredPrompt: structured,
      );

      expect(resolved, hasLength(1));
      expect(resolved.single.role, ChatRole.user);
    });

    test('falls back to plain prompt when no other inputs are provided', () {
      final resolved = resolvePromptMessagesForTextGeneration(
        prompt: 'Plain prompt',
      );

      expect(resolved, hasLength(1));
      final message = resolved.single;
      expect(message.role, ChatRole.user);
      expect(message.parts, hasLength(1));
      expect(message.parts.first, isA<TextContentPart>());
      expect((message.parts.first as TextContentPart).text,
          equals('Plain prompt'));
    });

    test('throws ArgumentError when no inputs are provided', () {
      expect(
        () => resolvePromptMessagesForTextGeneration(),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
