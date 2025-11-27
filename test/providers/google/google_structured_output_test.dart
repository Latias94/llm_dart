import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import 'google_test_utils.dart';

void main() {
  group('Google structured output jsonSchema', () {
    test(
        'attaches responseSchema and responseMimeType when jsonSchema is set and image generation is disabled',
        () async {
      final schema = {
        'type': 'object',
        'properties': {
          'content': {'type': 'string'},
        },
        'required': ['content'],
      };

      final format = StructuredOutputFormat(
        name: 'TestObject',
        description: 'Test object schema',
        schema: schema,
      );

      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash',
        jsonSchema: format,
      );

      final client = CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chat([ChatMessage.user('Hello')]);

      final body = client.lastRequestBody;
      expect(body, isNotNull);

      final generationConfig =
          (body!['generationConfig'] as Map).cast<String, dynamic>();

      expect(
        generationConfig['responseMimeType'],
        equals('application/json'),
      );
      expect(
        (generationConfig['responseSchema'] as Map).cast<String, dynamic>(),
        equals(schema),
      );
    });

    test(
        'does not attach responseSchema when image generation is enabled even if jsonSchema is set',
        () async {
      final schema = {
        'type': 'object',
        'properties': {
          'imageCaption': {'type': 'string'},
        },
        'required': ['imageCaption'],
      };

      final format = StructuredOutputFormat(
        name: 'ImageCaption',
        schema: schema,
      );

      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash',
        jsonSchema: format,
        enableImageGeneration: true,
      );

      final client = CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chat([ChatMessage.user('Describe the image')]);

      final body = client.lastRequestBody;
      expect(body, isNotNull);

      final generationConfig =
          (body!['generationConfig'] as Map).cast<String, dynamic>();

      // When image generation is enabled, the provider configures
      // responseModalities / responseMimeType for images, and skips
      // structured responseSchema configuration.
      expect(generationConfig['responseModalities'], equals(['TEXT', 'IMAGE']));
      expect(generationConfig['responseMimeType'], equals('text/plain'));
      expect(generationConfig.containsKey('responseSchema'), isFalse);
    });

    test(
        'ignores jsonSchema without inline schema and does not set responseSchema',
        () async {
      final format = StructuredOutputFormat(
        name: 'NoSchema',
        description: 'No inline schema',
      );

      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash',
        jsonSchema: format,
      );

      final client = CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chat([ChatMessage.user('Hello')]);

      final body = client.lastRequestBody;
      expect(body, isNotNull);

      final rawGenerationConfig = body!['generationConfig'];
      if (rawGenerationConfig == null) {
        // No generationConfig at all means no responseSchema and no
        // forced responseMimeType have been configured, which is the
        // expected behavior for a jsonSchema without inline schema.
        return;
      }

      final generationConfig =
          (rawGenerationConfig as Map).cast<String, dynamic>();

      expect(generationConfig.containsKey('responseSchema'), isFalse);
      // No schema, so we do not force a JSON responseMimeType here.
      expect(generationConfig['responseMimeType'], isNull);
    });
  });
}
