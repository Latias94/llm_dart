// OpenAI reasoning params tests use ChatMessage-based chat flows to
// validate reasoning-related request shaping for backwards compatibility.
// ignore_for_file: deprecated_member_use

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;
import 'package:test/test.dart';
import 'openai_test_utils.dart';

void main() {
  group('OpenAI reasoning model parameter handling', () {
    test('Chat: reasoning models use max_completion_tokens and strip sampling',
        () async {
      final config = openai.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-5.1',
        maxTokens: 123,
        temperature: 0.3,
        topP: 0.9,
      );

      final client = CapturingOpenAIClient(config);
      final chat = openai.OpenAIChat(client, config);

      await chat.chat([ChatMessage.user('Hello')]);

      final body = client.lastBody;
      expect(body, isNotNull);
      expect(body!['model'], equals('gpt-5.1'));

      // Reasoning models: use max_completion_tokens instead of max_tokens.
      expect(body['max_completion_tokens'], equals(123));
      expect(body.containsKey('max_tokens'), isFalse);

      // Reasoning models: temperature / top_p are not sent.
      expect(body.containsKey('temperature'), isFalse);
      expect(body.containsKey('top_p'), isFalse);
    });

    test(
        'Chat: non-reasoning models use max_tokens and keep sampling parameters',
        () async {
      final config = openai.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        maxTokens: 256,
        temperature: 0.5,
        topP: 0.8,
      );

      final client = CapturingOpenAIClient(config);
      final chat = openai.OpenAIChat(client, config);

      await chat.chat([ChatMessage.user('Hello')]);

      final body = client.lastBody;
      expect(body, isNotNull);
      expect(body!['model'], equals('gpt-4o'));

      // Non-reasoning models: use max_tokens.
      expect(body['max_tokens'], equals(256));
      expect(body.containsKey('max_completion_tokens'), isFalse);

      // Non-reasoning models: keep temperature / top_p.
      expect(body['temperature'], equals(0.5));
      expect(body['top_p'], equals(0.8));
    });

    test(
        'Responses: reasoning models keep max_output_tokens and strip temperature/top_p',
        () async {
      final config = openai.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-5.1',
        maxTokens: 200,
        temperature: 0.4,
        topP: 0.7,
        reasoningEffort: ReasoningEffort.high,
        useResponsesAPI: true,
      );

      final client = CapturingOpenAIClient(config);
      final responses = openai.OpenAIResponses(client, config);

      await responses.chatWithTools([ChatMessage.user('Hello')], null);

      final body = client.lastBody;
      expect(body, isNotNull);
      expect(body!['model'], equals('gpt-5.1'));

      // Responses API: always uses max_output_tokens.
      expect(body['max_output_tokens'], equals(200));

      // Reasoning models: do not send temperature / top_p.
      expect(body.containsKey('temperature'), isFalse);
      expect(body.containsKey('top_p'), isFalse);

      // Reasoning config is attached.
      expect(body['reasoning'], isA<Map<String, dynamic>>());
      expect(
        (body['reasoning'] as Map<String, dynamic>)['effort'],
        equals(ReasoningEffort.high.value),
      );
    });

    test(
        'Responses: non-reasoning models keep temperature/top_p and skip reasoning',
        () async {
      final config = openai.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        maxTokens: 200,
        temperature: 0.4,
        topP: 0.7,
        reasoningEffort: ReasoningEffort.high,
        useResponsesAPI: true,
      );

      final client = CapturingOpenAIClient(config);
      final responses = openai.OpenAIResponses(client, config);

      await responses.chatWithTools([ChatMessage.user('Hello')], null);

      final body = client.lastBody;
      expect(body, isNotNull);
      expect(body!['model'], equals('gpt-4o'));

      // Responses API: always uses max_output_tokens.
      expect(body['max_output_tokens'], equals(200));

      // Non-reasoning models: keep temperature / top_p.
      expect(body['temperature'], equals(0.4));
      expect(body['top_p'], equals(0.7));

      // Non-reasoning models: reasoning config is not sent.
      expect(body.containsKey('reasoning'), isFalse);
    });
  });
}
