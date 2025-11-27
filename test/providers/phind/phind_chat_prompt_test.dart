import 'package:dio/dio.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

class FakePhindClient extends PhindClient {
  Map<String, dynamic>? lastRequestBody;
  String? lastEndpoint;

  FakePhindClient(PhindConfig config) : super(config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastRequestBody = data;

    return {
      'choices': [
        {
          'message': {
            'role': 'assistant',
            'content': 'ok',
          },
        },
      ],
    };
  }
}

void main() {
  group('PhindChat prompt mapping', () {
    test('builds message_history from ModelMessage', () async {
      final config = PhindConfig(
        apiKey: 'test-key',
        model: 'phind-code-1',
        systemPrompt: 'You are a coding assistant.',
      );

      final client = FakePhindClient(config);
      final chat = PhindChat(client, config);

      final messages = <ChatMessage>[
        ChatMessage.user('Explain this code'),
        ChatMessage.assistant('Sure, here is an explanation.'),
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
