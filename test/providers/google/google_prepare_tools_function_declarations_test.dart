import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_google/client.dart';
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';

void main() {
  group('Google functionDeclarations request shaping (AI SDK parity)', () {
    test('omits parameters for empty object schema', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-2.5-flash',
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = FakeGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chatStreamParts(
        [ChatMessage.user('hi')],
        tools: [
          Tool.function(
            name: 'testFunction',
            description: 'A test function',
            parameters: const ParametersSchema(
              schemaType: 'object',
              properties: {},
              required: [],
            ),
          ),
        ],
      ).toList();

      final tools = client.lastBody?['tools'] as List?;
      expect(tools, isNotNull);
      final functionDeclarations = tools!
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .where((m) => m['functionDeclarations'] is List)
          .expand((m) => (m['functionDeclarations'] as List))
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

      expect(functionDeclarations, hasLength(1));
      expect(functionDeclarations.single['name'], 'testFunction');
      expect(functionDeclarations.single['description'], 'A test function');
      expect(functionDeclarations.single.containsKey('parameters'), isFalse);
    });

    test('keeps parameters for non-empty object schema', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-2.5-flash',
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = FakeGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chatStreamParts(
        [ChatMessage.user('hi')],
        tools: [
          Tool.function(
            name: 'testFunction',
            description: 'Test',
            parameters: const ParametersSchema(
              schemaType: 'object',
              properties: {
                'q': ParameterProperty(
                  propertyType: 'string',
                  description: 'Query',
                ),
              },
              required: ['q'],
            ),
          ),
        ],
      ).toList();

      final tools = client.lastBody?['tools'] as List?;
      expect(tools, isNotNull);
      final functionDeclarations = tools!
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .where((m) => m['functionDeclarations'] is List)
          .expand((m) => (m['functionDeclarations'] as List))
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

      expect(functionDeclarations, hasLength(1));
      expect(functionDeclarations.single.containsKey('parameters'), isTrue);
    });
  });
}
