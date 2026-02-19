import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

String _sseData(Map<String, dynamic> json) => 'data: ${jsonEncode(json)}\n\n';

void main() {
  group('Google toolWarnings providerMetadata (AI SDK parity)', () {
    test('emits warning when mixing function and provider-defined tools',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-2.5-flash',
        providerTools: const [
          ProviderTool(id: 'google.google_search'),
        ],
      );

      final config = GoogleConfig.fromLLMConfig(llmConfig);
      final endpoint = 'models/${config.model}:generateContent';
      final client = FakeGoogleClient(
        config,
        responsesByEndpoint: {
          endpoint: {
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'ok'}
                  ],
                },
              },
            ],
          },
        },
      );
      final chat = GoogleChat(client, config);

      final response = await chat.chatWithTools(
        [ChatMessage.user('hi')],
        [
          Tool.function(
            name: 'testFunction',
            description: 'Test',
            inputSchema: Schema.params(properties: const {}),
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
      final endpoint = 'models/${config.model}:generateContent';
      final client = FakeGoogleClient(
        config,
        responsesByEndpoint: {
          endpoint: {
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'ok'}
                  ],
                },
              },
            ],
          },
        },
      );
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

    test('emits warning as stream-start warnings when streaming', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-2.5-flash',
        providerTools: const [
          ProviderTool(id: 'google.google_search'),
        ],
      );

      final config = GoogleConfig.fromLLMConfig(llmConfig);
      final client = FakeGoogleClient(config)
        ..streamResponse = Stream<String>.fromIterable([
          _sseData({
            'modelVersion': config.model,
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'ok'}
                  ],
                },
              },
            ],
          }),
          _sseData({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': ''}
                  ],
                },
                'finishReason': 'STOP',
              },
            ],
          }),
        ]);
      final chat = GoogleChat(client, config);

      final parts = await chat.chatStreamParts(
        [ChatMessage.user('hi')],
        tools: [
          Tool.function(
            name: 'testFunction',
            description: 'Test',
            inputSchema: Schema.params(properties: const {}),
          ),
        ],
      ).toList();

      expect(parts.first, isA<LLMStreamStartPart>());
      final start = parts.first as LLMStreamStartPart;
      expect(start.warnings, hasLength(1));
      expect(start.warnings.single, isA<LLMUnsupportedWarning>());
      expect(
        (start.warnings.single as LLMUnsupportedWarning).feature,
        equals('combination of function and provider-defined tools'),
      );
    });
  });
}
