import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_google/chat.dart';
import 'package:llm_dart_google/client.dart';
import 'package:test/test.dart';

class _CapturingGoogleClient extends GoogleClient {
  Map<String, dynamic>? lastBody;

  _CapturingGoogleClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    lastBody = data;

    return {
      'modelVersion': config.model,
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': '{"ok":true}'}
            ],
          },
          'finishReason': 'STOP',
        },
      ],
    };
  }
}

void main() {
  group('Google structured output request shaping', () {
    test(
        'adds responseMimeType and responseSchema and strips additionalProperties',
        () async {
      final schema = <String, dynamic>{
        'type': 'object',
        'properties': {
          'ok': {'type': 'boolean'},
        },
        'required': ['ok'],
        'additionalProperties': false,
      };

      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash',
        jsonSchema: StructuredOutputFormat(
          name: 'TestSchema',
          schema: schema,
        ),
      );

      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chatWithTools([ChatMessage.user('Return JSON')], null);

      final generationConfig = client.lastBody?['generationConfig'] as Map?;
      expect(generationConfig, isNotNull);
      expect(generationConfig!['responseMimeType'], equals('application/json'));

      final responseSchema = generationConfig['responseSchema'] as Map?;
      expect(responseSchema, isNotNull);
      expect(responseSchema!['type'], equals('object'));
      expect(responseSchema.containsKey('additionalProperties'), isFalse);

      expect(schema.containsKey('additionalProperties'), isTrue);
    });
  });
}
