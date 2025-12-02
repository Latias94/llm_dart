// Message resolver tests validate conversions between prompt-first
// ModelMessage inputs and legacy ChatMessage-based chat histories.
// ignore_for_file: deprecated_member_use

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart/legacy/chat.dart';
import 'package:llm_dart/utils/message_resolver.dart';
import 'package:test/test.dart';

void main() {
  group('resolveMessagesForTextGeneration', () {
    test('prefers promptMessages over other inputs and converts to ChatMessage',
        () {
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

      final resolved = resolveMessagesForTextGeneration(
        promptMessages: promptMessages,
        prompt: 'fallback prompt',
        messages: [ChatMessage.user('fallback message')],
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
      final structured = ModelMessage(role: ChatRole.user, parts: const []);

      final resolved = resolveMessagesForTextGeneration(
        promptMessages: const [],
        structuredPrompt: structured,
      );

      expect(resolved, hasLength(1));
      final message = resolved.single;
      expect(message.role, ChatRole.user);
    });

    test(
        'falls back to legacy messages when no promptMessages/structuredPrompt',
        () {
      final legacyMessages = [
        ChatMessage.user('Legacy user'),
        ChatMessage.assistant('Legacy assistant'),
      ];

      final resolved = resolveMessagesForTextGeneration(
        messages: legacyMessages,
      );

      expect(resolved, same(legacyMessages));
    });

    test('falls back to plain prompt when no other inputs are provided', () {
      final resolved = resolveMessagesForTextGeneration(
        prompt: 'Plain prompt',
      );

      expect(resolved, hasLength(1));
      final message = resolved.single;
      expect(message.role, ChatRole.user);
      expect(message.content, equals('Plain prompt'));
    });

    test('throws ArgumentError when no inputs are provided', () {
      expect(
        () => resolveMessagesForTextGeneration(),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
