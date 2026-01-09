import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_google/client.dart';
import 'package:test/test.dart';

class _CapturingGoogleClient extends GoogleClient {
  Map<String, dynamic>? lastBody;

  _CapturingGoogleClient(super.config);

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) {
    lastBody = data;
    return Stream<String>.empty();
  }
}

void main() {
  group('Google systemInstruction', () {
    test('uses config.systemPrompt as systemInstruction', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash',
        systemPrompt: 'SYS',
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat
          .chatStreamParts([ChatMessage.user('hi')], tools: const []).toList();

      final systemInstruction = client.lastBody?['systemInstruction'];
      expect(systemInstruction, isA<Map>());
      expect(
        (systemInstruction as Map)['parts'],
        equals([
          {'text': 'SYS'},
        ]),
      );

      final contents = client.lastBody?['contents'];
      expect(contents, isA<List>());
      expect((contents as List).length, 1);
      expect((contents.first as Map)['role'], 'user');
      expect(
        (contents.first as Map)['parts'],
        equals([
          {'text': 'hi'},
        ]),
      );
    });

    test('collects leading ChatRole.system messages into systemInstruction',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash',
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chatStreamParts(
        [
          ChatMessage.system('SYS1'),
          ChatMessage.system('SYS2'),
          ChatMessage.user('hi'),
        ],
        tools: const [],
      ).toList();

      final systemInstruction = client.lastBody?['systemInstruction'];
      expect(systemInstruction, isA<Map>());
      expect(
        (systemInstruction as Map)['parts'],
        equals([
          {'text': 'SYS1'},
          {'text': 'SYS2'},
        ]),
      );
    });

    test('prefers system messages over config.systemPrompt', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash',
        systemPrompt: 'CONFIG_SYS',
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chatStreamParts(
        [
          ChatMessage.system('MSG_SYS'),
          ChatMessage.user('hi'),
        ],
        tools: const [],
      ).toList();

      final systemInstruction = client.lastBody?['systemInstruction'];
      expect(systemInstruction, isA<Map>());
      expect(
        (systemInstruction as Map)['parts'],
        equals([
          {'text': 'MSG_SYS'},
        ]),
      );
    });

    test('throws if a system message appears after the conversation started',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash',
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await expectLater(
        chat.chatStreamParts(
          [
            ChatMessage.user('hi'),
            ChatMessage.system('too late'),
          ],
          tools: const [],
        ).toList(),
        throwsA(isA<InvalidRequestError>()),
      );
    });

    test('does not send systemInstruction for Gemma models', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemma-3-12b-it',
        systemPrompt: 'SYS',
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat
          .chatStreamParts([ChatMessage.user('hi')], tools: const []).toList();

      expect(client.lastBody?.containsKey('systemInstruction'), isFalse);

      final contents = client.lastBody?['contents'] as List?;
      expect(contents, isNotNull);
      expect(contents, isNotEmpty);
      final first = contents!.first as Map;
      expect(first['role'], 'user');
      final parts = first['parts'] as List;
      expect((parts.first as Map)['text'], 'SYS\n\n');
    });

    test('prepends system messages for Gemma models (AI SDK parity)', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemma-3-12b-it',
        systemPrompt: 'CONFIG_SYS',
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chatStreamParts(
        [
          ChatMessage.system('MSG_SYS1'),
          ChatMessage.system('MSG_SYS2'),
          ChatMessage.user('hi'),
        ],
        tools: const [],
      ).toList();

      expect(client.lastBody?.containsKey('systemInstruction'), isFalse);

      final contents = client.lastBody?['contents'] as List?;
      expect(contents, isNotNull);
      expect(contents, isNotEmpty);
      final first = contents!.first as Map;
      expect(first['role'], 'user');
      final parts = first['parts'] as List;
      expect((parts.first as Map)['text'], 'MSG_SYS1\n\nMSG_SYS2\n\n');
    });

    test('omits systemInstruction when no system prompt is provided', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash',
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat
          .chatStreamParts([ChatMessage.user('hi')], tools: const []).toList();

      expect(client.lastBody?.containsKey('systemInstruction'), isFalse);
    });
  });
}
