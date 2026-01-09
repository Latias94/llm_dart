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
  group('Google toolChoice request shaping (AI SDK parity)', () {
    test('auto maps to toolConfig.functionCallingConfig.mode=AUTO', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-2.5-flash',
        toolChoice: const AutoToolChoice(),
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chatStreamParts(
        [ChatMessage.user('hi')],
        tools: [
          Tool.function(
            name: 'testFunction',
            description: 'Test',
            parameters: const ParametersSchema(
              schemaType: 'object',
              properties: {},
              required: [],
            ),
          ),
        ],
      ).toList();

      expect(
        client.lastBody?['toolConfig'],
        equals({
          'functionCallingConfig': {'mode': 'AUTO'},
        }),
      );
    });

    test('any maps to toolConfig.functionCallingConfig.mode=ANY', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-2.5-flash',
        toolChoice: const AnyToolChoice(),
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chatStreamParts(
        [ChatMessage.user('hi')],
        tools: [
          Tool.function(
            name: 'testFunction',
            description: 'Test',
            parameters: const ParametersSchema(
              schemaType: 'object',
              properties: {},
              required: [],
            ),
          ),
        ],
      ).toList();

      expect(
        client.lastBody?['toolConfig'],
        equals({
          'functionCallingConfig': {'mode': 'ANY'},
        }),
      );
    });

    test('none maps to toolConfig.functionCallingConfig.mode=NONE', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-2.5-flash',
        toolChoice: const NoneToolChoice(),
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chatStreamParts(
        [ChatMessage.user('hi')],
        tools: [
          Tool.function(
            name: 'testFunction',
            description: 'Test',
            parameters: const ParametersSchema(
              schemaType: 'object',
              properties: {},
              required: [],
            ),
          ),
        ],
      ).toList();

      expect(
        client.lastBody?['toolConfig'],
        equals({
          'functionCallingConfig': {'mode': 'NONE'},
        }),
      );
    });

    test('specific tool uses allowedFunctionNames', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-2.5-flash',
        toolChoice: const SpecificToolChoice('testFunction'),
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chatStreamParts(
        [ChatMessage.user('hi')],
        tools: [
          Tool.function(
            name: 'testFunction',
            description: 'Test',
            parameters: const ParametersSchema(
              schemaType: 'object',
              properties: {},
              required: [],
            ),
          ),
        ],
      ).toList();

      expect(
        client.lastBody?['toolConfig'],
        equals({
          'functionCallingConfig': {
            'mode': 'ANY',
            'allowedFunctionNames': ['testFunction'],
          },
        }),
      );
    });

    test('ignores toolChoice when provider-native tools are enabled', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-2.5-flash',
        toolChoice: const AutoToolChoice(),
        providerOptions: const {
          'google': {
            'webSearchEnabled': true,
          },
        },
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chatStreamParts(
        [ChatMessage.user('hi')],
        tools: [
          Tool.function(
            name: 'testFunction',
            description: 'Test',
            parameters: const ParametersSchema(
              schemaType: 'object',
              properties: {},
              required: [],
            ),
          ),
        ],
      ).toList();

      expect(client.lastBody?.containsKey('toolConfig'), isFalse);
      final tools = client.lastBody?['tools'] as List?;
      expect(tools, isNotNull);
      expect(
          tools!.any((t) => t is Map && t.containsKey('googleSearch')), isTrue);
    });
  });
}
