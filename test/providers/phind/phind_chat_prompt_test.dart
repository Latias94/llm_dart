// Phind chat prompt mapping tests validate prompt-first ModelMessage inputs.

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';
import 'phind_test_utils.dart';

void main() {
  group('PhindChat prompt mapping', () {
    test('builds message_history from ModelMessage', () async {
      final config = PhindConfig(
        apiKey: 'test-key',
        model: 'phind-code-1',
        systemPrompt: 'You are a coding assistant.',
      );

      final client = CapturingPhindClient(config);
      final chat = PhindChat(client, config);

      final messages = <ModelMessage>[
        ModelMessage.userText('Explain this code'),
        ModelMessage.assistantText('Sure, here is an explanation.'),
      ];

      await chat.chat(messages);

      final body = client.lastRequestBody;
      expect(body, isNotNull);

      final history = body!['message_history'] as List<dynamic>;
      expect(history.length, equals(3));

      final systemMsg = history[0] as Map<String, dynamic>;
      expect(systemMsg['role'], equals('system'));
      expect(systemMsg['content'], equals(config.systemPrompt));

      final userMsg = history[1] as Map<String, dynamic>;
      expect(userMsg['role'], equals('user'));
      expect(userMsg['content'], contains('Explain this code'));

      final assistantMsg = history[2] as Map<String, dynamic>;
      expect(assistantMsg['role'], equals('assistant'));
      expect(
        assistantMsg['content'],
        contains('Sure, here is an explanation.'),
      );

      expect(body['user_input'], equals('Explain this code'));
    });
  });
}
