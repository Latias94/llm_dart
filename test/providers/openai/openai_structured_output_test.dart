// OpenAI structured output tests ensure jsonSchema request shaping.

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;
import 'package:test/test.dart';

import 'openai_test_utils.dart';

void main() {
  group('OpenAI structured output jsonSchema', () {
    test(
        'Chat attaches response_format with json_schema including schema and strict flag',
        () async {
      final format = StructuredOutputFormat(
        name: 'TestObject',
        description: 'Test object schema',
        schema: const {
          'type': 'object',
          'properties': {
            'content': {'type': 'string'},
          },
          'required': ['content'],
        },
        strict: true,
      );

      final config = openai.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        jsonSchema: format,
      );

      final client = CapturingOpenAIClient(config);
      final chat = openai.OpenAIChat(client, config);

      await chat.chat([ModelMessage.userText('Hello')]);

      final body = client.lastBody;
      expect(body, isNotNull);

      final responseFormat = body!['response_format'] as Map<String, dynamic>?;
      expect(responseFormat, isNotNull);
      expect(responseFormat!['type'], equals('json_schema'));

      final jsonSchema = responseFormat['json_schema'] as Map<String, dynamic>;
      expect(jsonSchema['name'], equals('TestObject'));
      expect(jsonSchema['description'], equals('Test object schema'));
      expect(jsonSchema['strict'], isTrue);

      final schema = jsonSchema['schema'] as Map<String, dynamic>;
      expect(schema['type'], equals('object'));
      expect(schema['properties'], isA<Map>());
      expect(schema['required'], contains('content'));

      // additionalProperties should default to false when it is not provided.
      expect(schema['additionalProperties'], isFalse);
    });

    test('Chat preserves explicit additionalProperties in schema', () async {
      final format = StructuredOutputFormat(
        name: 'FlexibleObject',
        schema: const {
          'type': 'object',
          'properties': {
            'content': {'type': 'string'},
          },
          'required': ['content'],
          'additionalProperties': true,
        },
      );

      final config = openai.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        jsonSchema: format,
      );

      final client = CapturingOpenAIClient(config);
      final chat = openai.OpenAIChat(client, config);

      await chat.chat([ModelMessage.userText('Hello')]);

      final body = client.lastBody;
      expect(body, isNotNull);

      final responseFormat = body!['response_format'] as Map<String, dynamic>?;
      expect(responseFormat, isNotNull);

      final jsonSchema = responseFormat!['json_schema'] as Map<String, dynamic>;
      final schema = jsonSchema['schema'] as Map<String, dynamic>;
      expect(schema['additionalProperties'], isTrue);
    });

    test('Responses API uses jsonSchema.toJson when schema is null', () async {
      final format = StructuredOutputFormat(
        name: 'NoSchema',
        description: 'No inline JSON schema',
      );

      final config = openai.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        jsonSchema: format,
        useResponsesAPI: true,
      );

      final client = CapturingOpenAIClient(config);
      final responses = openai.OpenAIResponses(client, config);

      await responses.chatWithTools([ModelMessage.userText('Hello')], null);

      final body = client.lastBody;
      expect(body, isNotNull);

      final responseFormat = body!['response_format'] as Map<String, dynamic>?;
      expect(responseFormat, isNotNull);

      final jsonSchema = responseFormat!['json_schema'] as Map<String, dynamic>;
      expect(jsonSchema['name'], equals('NoSchema'));
      expect(jsonSchema['description'], equals('No inline JSON schema'));
      expect(jsonSchema.containsKey('schema'), isFalse);
    });
  });
}
