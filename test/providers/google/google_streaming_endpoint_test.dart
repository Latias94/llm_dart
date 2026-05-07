import 'package:llm_dart/core/cancellation.dart';
import 'package:llm_dart/core/config.dart';
import 'package:llm_dart/models/chat_models.dart';
import 'package:llm_dart/models/tool_models.dart';
import 'package:llm_dart/providers/google/chat.dart';
import 'package:llm_dart/providers/google/client.dart';
import 'package:llm_dart/providers/google/config.dart';
import 'package:llm_dart/src/compatibility/providers/google_config_adapter.dart';
import 'package:test/test.dart';

class RecordingGoogleClient extends GoogleClient {
  String? lastPostJsonEndpoint;
  String? lastPostStreamRawEndpoint;
  Map<String, dynamic>? lastPostJsonData;
  Map<String, dynamic>? lastPostStreamRawData;

  RecordingGoogleClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    TransportCancellation? cancelToken,
  }) async {
    lastPostJsonEndpoint = endpoint;
    lastPostJsonData = data;

    return {
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': 'ok'}
            ]
          }
        }
      ],
    };
  }

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    TransportCancellation? cancelToken,
  }) async* {
    lastPostStreamRawEndpoint = endpoint;
    lastPostStreamRawData = data;
    yield 'data: {"candidates":[{"content":{"parts":[{"text":"hi"}]}}]}\n\n';
  }
}

void main() {
  group('Google streaming endpoints', () {
    test('chat uses generateContent endpoint even when stream=true in config',
        () async {
      final config = const GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash',
        stream: true,
      );

      final client = RecordingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chat([ChatMessage.user('hello')]);

      expect(
        client.lastPostJsonEndpoint,
        equals('models/gemini-1.5-flash:generateContent'),
      );
    });

    test('chatStream uses streamGenerateContent endpoint', () async {
      final config = const GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash',
      );

      final client = RecordingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chatStream([ChatMessage.user('hello')]).first;

      expect(
        client.lastPostStreamRawEndpoint,
        equals('models/gemini-1.5-flash:streamGenerateContent'),
      );
    });
  });

  group('Google structured output requests', () {
    test(
        'chat includes responseSchema and responseMimeType when jsonSchema is configured',
        () async {
      const jsonSchema = StructuredOutputFormat(
        name: 'weather_response',
        schema: {
          'type': 'object',
          'properties': {
            'city': {'type': 'string'},
            'temperature': {'type': 'number'},
          },
          'required': ['city', 'temperature'],
          'additionalProperties': false,
        },
      );

      final config = createLegacyGoogleConfig(
        LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
          model: 'gemini-1.5-flash',
        ).withExtension('jsonSchema', jsonSchema),
      );

      final client = RecordingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chat([ChatMessage.user('hello')]);

      final generationConfig =
          client.lastPostJsonData?['generationConfig'] as Map<String, dynamic>?;

      expect(generationConfig, isNotNull);
      expect(
        generationConfig?['responseMimeType'],
        equals('application/json'),
      );
      expect(
        generationConfig?['responseSchema'],
        equals({
          'type': 'object',
          'properties': {
            'city': {'type': 'string'},
            'temperature': {'type': 'number'},
          },
          'required': ['city', 'temperature'],
        }),
      );
    });
  });
}
