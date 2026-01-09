import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_google/client.dart';
import 'package:test/test.dart';

class _FakeGoogleClient extends GoogleClient {
  _FakeGoogleClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    return {
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': 'ok'}
            ],
          },
        },
      ],
    };
  }
}

void main() {
  group('Google toolWarnings providerMetadata (AI SDK parity)', () {
    test('emits warning when mixing function and provider-defined tools',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-2.5-flash',
        providerOptions: const {
          'google': {
            'webSearchEnabled': true,
          },
        },
      );

      final config = GoogleConfig.fromLLMConfig(llmConfig);
      final client = _FakeGoogleClient(config);
      final chat = GoogleChat(client, config);

      final response = await chat.chatWithTools(
        [ChatMessage.user('hi')],
        [
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
      );

      final google = response.providerMetadata?['google'] as Map?;
      expect(google, isNotNull);

      final warnings = google!['toolWarnings'] as List?;
      expect(warnings, isNotNull);
      expect(
        warnings,
        equals([
          {
            'type': 'unsupported',
            'feature': 'combination of function and provider-defined tools',
          },
        ]),
      );
    });

    test('emits warning when provider tool is unsupported on model', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash',
        providerTools: const [
          ProviderTool(id: 'google.google_maps'),
        ],
      );

      final config = GoogleConfig.fromLLMConfig(llmConfig);
      final client = _FakeGoogleClient(config);
      final chat = GoogleChat(client, config);

      final response = await chat.chatWithTools(
        [ChatMessage.user('hi')],
        const [],
      );

      final google = response.providerMetadata?['google'] as Map?;
      expect(google, isNotNull);

      final warnings = google!['toolWarnings'] as List?;
      expect(warnings, isNotNull);
      expect(
        warnings,
        equals([
          {
            'type': 'unsupported',
            'feature': 'provider-defined tool google.google_maps',
            'details':
                'The Google Maps grounding tool is not supported with Gemini models other than Gemini 2 or newer.',
          },
        ]),
      );
    });
  });
}
