import 'package:llm_dart/core/web_search.dart';
import 'package:llm_dart/models/chat_models.dart';
import 'package:llm_dart/models/tool_models.dart';
import 'package:llm_dart/providers/google/config.dart';
import 'package:llm_dart/src/compatibility/providers/google/client.dart';
import 'package:llm_dart/src/compatibility/providers/google/google_chat_request_builder.dart';
import 'package:test/test.dart';

void main() {
  group('Google chat request config support', () {
    test('builds generation config and body decorations together', () {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.0-flash',
        candidateCount: 2,
        stopSequences: const ['END'],
        maxTokens: 64,
        temperature: 0.25,
        topP: 0.8,
        topK: 40,
        jsonSchema: const StructuredOutputFormat(
          name: 'answer_schema',
          schema: {
            'type': 'object',
            'properties': {
              'answer': {'type': 'string'},
            },
            'required': ['answer'],
            'additionalProperties': false,
          },
        ),
        thinkingBudgetTokens: 128,
        webSearchConfig: const WebSearchConfig(),
        safetySettings: const [
          SafetySetting(
            category: HarmCategory.harmCategoryHarassment,
            threshold: HarmBlockThreshold.blockNone,
          ),
        ],
        tools: [_weatherTool()],
        toolChoice: const SpecificToolChoice('get_weather'),
      );

      final body = _buildRequest(config, stream: true);

      expect(body['generationConfig'], {
        'candidateCount': 2,
        'stopSequences': ['END'],
        'maxOutputTokens': 64,
        'temperature': 0.25,
        'topP': 0.8,
        'topK': 40,
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'object',
          'properties': {
            'answer': {'type': 'string'},
          },
          'required': ['answer'],
        },
        'thinkingConfig': {
          'includeThoughts': true,
          'thinkingBudget': 128,
        },
      });
      expect(body['safetySettings'], [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_NONE',
        },
      ]);
      expect(body['tools'], [
        {
          'functionDeclarations': [
            {
              'name': 'get_weather',
              'description': 'Get weather information.',
              'parameters': {
                'type': 'object',
                'properties': {
                  'city': {
                    'type': 'string',
                    'description': 'City name.',
                  },
                },
                'required': ['city'],
              },
            },
          ],
        },
        {'google_search': <String, Object?>{}},
      ]);
      expect(body['tool_config'], {
        'function_calling_config': {
          'mode': 'ANY',
          'allowed_function_names': ['get_weather'],
        },
      });
    });

    test('uses default image response modalities for image generation', () {
      final body = _buildRequest(
        const GoogleConfig(
          apiKey: 'test-key',
          model: 'gemini-2.0-flash',
          enableImageGeneration: true,
        ),
        stream: false,
      );

      expect(body['generationConfig'], {
        'responseModalities': ['TEXT', 'IMAGE'],
        'responseMimeType': 'text/plain',
      });
      expect(
        body['safetySettings'],
        hasLength(GoogleConfig.defaultSafetySettings.length),
      );
    });
  });
}

Map<String, dynamic> _buildRequest(
  GoogleConfig config, {
  required bool stream,
}) {
  final builder = GoogleChatRequestBuilder(
    client: GoogleClient(config),
    config: config,
  );

  return builder.buildRequestBody(
    [ChatMessage.user('hello')],
    null,
    stream,
  );
}

Tool _weatherTool() {
  return Tool.function(
    name: 'get_weather',
    description: 'Get weather information.',
    parameters: const ParametersSchema(
      schemaType: 'object',
      properties: {
        'city': ParameterProperty(
          propertyType: 'string',
          description: 'City name.',
        ),
      },
      required: ['city'],
    ),
  );
}
