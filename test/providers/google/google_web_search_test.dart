// Google web search tests validate prompt-first ModelMessage inputs and
// request shaping for web search configuration.

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';
import 'google_test_utils.dart';

void main() {
  group('Google web search (Gemini)', () {
    test('uses googleSearch tool for Gemini 2.x models', () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.0-pro',
        webSearchEnabled: true,
      );

      final client = CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      final messages = [ModelMessage.userText('hello')];
      await chat.chat(messages);

      final body = client.lastRequestBody;
      expect(body, isNotNull);

      final tools = (body!['tools'] as List).cast<Map<String, dynamic>>();
      expect(tools.length, equals(1));
      expect(tools.first, equals({'googleSearch': <String, dynamic>{}}));
    });

    test(
        'uses googleSearchRetrieval with dynamicRetrievalConfig for Gemini 1.5 Flash',
        () async {
      final webConfig = WebSearchConfig(
        mode: 'auto',
      );

      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash',
        webSearchEnabled: true,
        webSearchConfig: webConfig,
      );

      final client = CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      final messages = [ModelMessage.userText('hello')];
      await chat.chat(messages);

      final body = client.lastRequestBody;
      expect(body, isNotNull);

      final tools = (body!['tools'] as List).cast<Map<String, dynamic>>();
      expect(tools.length, equals(1));

      final retrieval =
          tools.first['googleSearchRetrieval'] as Map<String, dynamic>?;
      expect(retrieval, isNotNull);

      final dynamicConfig =
          retrieval!['dynamicRetrievalConfig'] as Map<String, dynamic>?;
      expect(dynamicConfig, isNotNull);
      expect(dynamicConfig!['mode'], equals('MODE_DYNAMIC'));
    });

    test(
        'propagates dynamicThreshold from WebSearchConfig for Gemini 1.5 Flash',
        () async {
      final webConfig = WebSearchConfig(
        mode: 'MODE_DYNAMIC',
        dynamicThreshold: 1.5,
      );

      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash',
        webSearchEnabled: true,
        webSearchConfig: webConfig,
      );

      final client = CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      final messages = [ModelMessage.userText('hello')];
      await chat.chat(messages);

      final body = client.lastRequestBody;
      expect(body, isNotNull);

      final tools = (body!['tools'] as List).cast<Map<String, dynamic>>();
      expect(tools.length, equals(1));

      final retrieval =
          tools.first['googleSearchRetrieval'] as Map<String, dynamic>?;
      expect(retrieval, isNotNull);

      final dynamicConfig =
          retrieval!['dynamicRetrievalConfig'] as Map<String, dynamic>?;
      expect(dynamicConfig, isNotNull);
      expect(dynamicConfig!['mode'], equals('MODE_DYNAMIC'));
      expect(dynamicConfig['dynamicThreshold'], equals(1.5));
    });

    test('falls back to basic googleSearchRetrieval for non-dynamic models',
        () async {
      final webConfig = WebSearchConfig(
        mode: 'auto',
      );

      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash-8b',
        webSearchEnabled: true,
        webSearchConfig: webConfig,
      );

      final client = CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      final messages = [ModelMessage.userText('hello')];
      await chat.chat(messages);

      final body = client.lastRequestBody;
      expect(body, isNotNull);

      final tools = (body!['tools'] as List).cast<Map<String, dynamic>>();
      expect(tools.length, equals(1));
      expect(
        tools.first,
        equals({'googleSearchRetrieval': <String, dynamic>{}}),
      );
    });
  });
}
