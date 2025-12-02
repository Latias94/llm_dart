// OpenAI-compatible structured output tests use ChatMessage-based
// prompts to validate structured JSON responses via the compatibility
// layer.
// ignore_for_file: deprecated_member_use

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart/legacy/chat.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:test/test.dart';

import 'openai_compatible_test_utils.dart';

void main() {
  group('OpenAICompatible structured output jsonSchema', () {
    test(
        'attaches response_format.json_schema with schema and strict flag when jsonSchema is set',
        () async {
      final schema = {
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
        },
        'required': ['name'],
      };

      final format = StructuredOutputFormat(
        name: 'User',
        description: 'User schema',
        schema: schema,
        strict: true,
      );

      final config = OpenAICompatibleConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.test/v1',
        providerId: 'test-provider',
        model: 'gpt-4.1-mini',
        jsonSchema: format,
      );

      final client = CapturingOpenAICompatibleClient(config);
      final chat = OpenAICompatibleChat(client, config);

      await chat.chat([ChatMessage.user('Return a user object')]);

      final body = client.lastRequestBody;
      expect(body, isNotNull);

      final responseFormat =
          (body!['response_format'] as Map).cast<String, dynamic>();
      expect(responseFormat['type'], equals('json_schema'));

      final jsonSchema =
          (responseFormat['json_schema'] as Map).cast<String, dynamic>();
      expect(jsonSchema['name'], equals('User'));
      expect(jsonSchema['description'], equals('User schema'));
      expect(jsonSchema['strict'], isTrue);

      final embeddedSchema =
          (jsonSchema['schema'] as Map).cast<String, dynamic>();
      expect(embeddedSchema['type'], equals('object'));
      expect(embeddedSchema['properties'], contains('name'));
      expect(embeddedSchema['required'], contains('name'));
      expect(embeddedSchema['additionalProperties'], isFalse);
    });

    test(
        'preserves explicit additionalProperties in jsonSchema.schema for OpenAI-compatible providers',
        () async {
      final schema = {
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
        },
        'required': ['name'],
        'additionalProperties': true,
      };

      final format = StructuredOutputFormat(
        name: 'FlexibleUser',
        schema: schema,
      );

      final config = OpenAICompatibleConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.test/v1',
        providerId: 'test-provider',
        model: 'gpt-4.1-mini',
        jsonSchema: format,
      );

      final client = CapturingOpenAICompatibleClient(config);
      final chat = OpenAICompatibleChat(client, config);

      await chat.chat([ChatMessage.user('Return a flexible user object')]);

      final body = client.lastRequestBody;
      expect(body, isNotNull);

      final responseFormat =
          (body!['response_format'] as Map).cast<String, dynamic>();

      final jsonSchema =
          (responseFormat['json_schema'] as Map).cast<String, dynamic>();
      final embeddedSchema =
          (jsonSchema['schema'] as Map).cast<String, dynamic>();

      expect(embeddedSchema['additionalProperties'], isTrue);
    });
  });
}
