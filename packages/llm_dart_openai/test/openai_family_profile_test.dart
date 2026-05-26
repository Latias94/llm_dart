import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_openai/src/provider/openai_family_route_policy.dart';
import 'package:llm_dart_openai/src/provider/resolved_openai_chat_settings.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIFamilyProfile', () {
    test('OpenAI profile supports Responses API by default', () {
      const profile = OpenAIProfile();

      expect(profile.providerId, 'openai');
      expect(profile.defaultBaseUrl, 'https://api.openai.com/v1');
      expect(
        profile.routePolicy.resolveLanguageModelRoute(
          const ResolvedOpenAIChatModelSettings(),
        ),
        OpenAIRequestRoute.responses,
      );
      expect(
        profile.buildHeaders(
          apiKey: 'test-key',
          extraHeaders: {'x-test': '1'},
        ),
        {
          'authorization': 'Bearer test-key',
          'x-test': '1',
        },
      );
    });

    test(
        'OpenAI-compatible profiles expose provider defaults and disable Responses API',
        () {
      const cases = <({
        OpenAIFamilyProfile profile,
        String providerId,
        String defaultBaseUrl,
      })>[
        (
          profile: OpenAICompatibleProfile(
            providerId: 'together-ai',
            defaultBaseUrl: 'https://api.together.xyz/v1',
          ),
          providerId: 'together-ai',
          defaultBaseUrl: 'https://api.together.xyz/v1',
        ),
        (
          profile: OpenRouterProfile(),
          providerId: 'openrouter',
          defaultBaseUrl: 'https://openrouter.ai/api/v1',
        ),
        (
          profile: DeepSeekProfile(),
          providerId: 'deepseek',
          defaultBaseUrl: 'https://api.deepseek.com/v1',
        ),
        (
          profile: GroqProfile(),
          providerId: 'groq',
          defaultBaseUrl: 'https://api.groq.com/openai/v1',
        ),
        (
          profile: XAIProfile(),
          providerId: 'xai',
          defaultBaseUrl: 'https://api.x.ai/v1',
        ),
        (
          profile: PhindProfile(),
          providerId: 'phind',
          defaultBaseUrl: 'https://api.phind.com/v1',
        ),
      ];

      for (final entry in cases) {
        expect(entry.profile.providerId, entry.providerId);
        expect(entry.profile.defaultBaseUrl, entry.defaultBaseUrl);
        expect(
          entry.profile.routePolicy.resolveLanguageModelRoute(
            const ResolvedOpenAIChatModelSettings(),
          ),
          OpenAIRequestRoute.chatCompletions,
        );
        expect(
          entry.profile.buildHeaders(
            apiKey: 'test-key',
            extraHeaders: {'x-trace': 'trace-1'},
          ),
          {
            'authorization': 'Bearer test-key',
            'x-trace': 'trace-1',
          },
        );
      }
    });

    test('OpenRouter profile adds optional app attribution headers', () {
      const profile = OpenRouterProfile(
        appReferer: 'https://example.com',
        appTitle: 'Example App',
      );

      expect(
        profile.buildHeaders(
          apiKey: 'test-key',
          extraHeaders: {'x-trace': 'trace-1'},
        ),
        {
          'authorization': 'Bearer test-key',
          'HTTP-Referer': 'https://example.com',
          'X-OpenRouter-Title': 'Example App',
          'x-trace': 'trace-1',
        },
      );
    });

    test(
        'OpenAI factory uses profile defaults for provider id, base url, and headers',
        () {
      final model = OpenAI(
        apiKey: 'test-key',
        profile: const OpenRouterProfile(),
        transport: const _FakeTransportClient(),
      ).chatModel('openai/gpt-4o-mini');

      expect(model.providerId, 'openrouter');
      expect(model.baseUrl, 'https://openrouter.ai/api/v1');
      expect(
        model.defaultHeaders,
        {'authorization': 'Bearer test-key'},
      );
    });

    test('OpenAI-family provider descriptors own provider specification', () {
      final openAI = OpenAI(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      );
      final openRouter = OpenAI(
        apiKey: 'test-key',
        profile: const OpenRouterProfile(),
        transport: const _FakeTransportClient(),
      );

      expect(openAI.providerDescriptor.providerId, 'openai');
      expect(openAI.specification.modelFacets, {
        ProviderModelFacet.language,
        ProviderModelFacet.embedding,
        ProviderModelFacet.image,
        ProviderModelFacet.speech,
        ProviderModelFacet.transcription,
      });
      expect(
        openAI.specification.supportsInputShape(
          modelKind: ModelCapabilityKind.transcription,
          shapeId: ProviderInputShapeIds.audio,
        ),
        isTrue,
      );
      expect(
        openRouter.specification.modelFacets,
        {ProviderModelFacet.language},
      );
      expect(
        openRouter.specification.supportsInputShape(
          modelKind: ModelCapabilityKind.image,
          shapeId: ProviderInputShapeIds.text,
        ),
        isFalse,
      );
    });

    test('OpenAI factory normalizes compatible profile base urls', () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        baseUrl: 'https://example.test/v1/',
        profile: const OpenRouterProfile(),
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_or_1',
                'model': 'openai/gpt-4o-mini',
                'created': 1710000000,
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'stop',
                    'message': {
                      'role': 'assistant',
                      'content': 'hello',
                    },
                  },
                ],
                'usage': {
                  'prompt_tokens': 1,
                  'completion_tokens': 1,
                  'total_tokens': 2,
                },
              },
            );
          },
        ),
      ).chatModel('openai/gpt-4o-mini');

      await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('hello'),
          ],
        ),
      );

      expect(model.baseUrl, 'https://example.test/v1');
      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.uri.toString(),
        'https://example.test/v1/chat/completions',
      );
    });

    test('OpenRouter model settings shape the request model to :online',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        profile: const OpenRouterProfile(),
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_or_1',
                'model': 'openai/gpt-4o-mini:online',
                'created': 1710000000,
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'stop',
                    'message': {
                      'role': 'assistant',
                      'content': 'hello',
                    },
                  },
                ],
                'usage': {
                  'prompt_tokens': 1,
                  'completion_tokens': 1,
                  'total_tokens': 2,
                },
              },
            );
          },
        ),
      ).chatModel(
        'openai/gpt-4o-mini',
        settings: const OpenRouterChatModelSettings(
          search: OpenRouterSearchOptions.onlineModel(),
        ),
      );

      await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('hello'),
          ],
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(requestBody['model'], 'openai/gpt-4o-mini:online');
    });

    test('OpenRouter call options shape the request model to :online',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        profile: const OpenRouterProfile(),
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_or_1',
                'model': 'openai/gpt-4o-mini:online',
                'created': 1710000000,
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'stop',
                    'message': {
                      'role': 'assistant',
                      'content': 'hello',
                    },
                  },
                ],
                'usage': {
                  'prompt_tokens': 1,
                  'completion_tokens': 1,
                  'total_tokens': 2,
                },
              },
            );
          },
        ),
      ).chatModel('openai/gpt-4o-mini');

      await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('hello'),
          ],
          callOptions: const CallOptions(
            providerOptions: OpenRouterGenerateTextOptions(
              search: OpenRouterSearchOptions.onlineModel(),
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(requestBody['model'], 'openai/gpt-4o-mini:online');
    });

    test('OpenRouter call options are rejected on non-OpenRouter profiles',
        () async {
      final model = OpenAI(
        apiKey: 'test-key',
        profile: const DeepSeekProfile(),
        transport: const _FakeTransportClient(),
      ).chatModel('deepseek-chat');

      await expectLater(
        model.doGenerate(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage.text('hello'),
            ],
            callOptions: const CallOptions(
              providerOptions: OpenRouterGenerateTextOptions(
                search: OpenRouterSearchOptions.onlineModel(),
              ),
            ),
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('only valid for OpenRouter'),
          ),
        ),
      );
    });

    test('OpenRouter model settings are rejected on non-OpenRouter profiles',
        () {
      expect(
        () => OpenAI(
          apiKey: 'test-key',
          profile: const DeepSeekProfile(),
          transport: const _FakeTransportClient(),
        ).chatModel(
          'deepseek-chat',
          settings: const OpenRouterChatModelSettings(
            search: OpenRouterSearchOptions.onlineModel(),
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('only valid for OpenRouter'),
          ),
        ),
      );
    });

    test(
        'language model routes profiles without Responses API support to chat completions',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        profile: const DeepSeekProfile(),
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_1',
                'model': 'deepseek-chat',
                'created': 1710000000,
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'stop',
                    'message': {
                      'role': 'assistant',
                      'content': 'hello',
                    },
                  },
                ],
                'usage': {
                  'prompt_tokens': 1,
                  'completion_tokens': 1,
                  'total_tokens': 2,
                },
              },
            );
          },
        ),
      ).chatModel('deepseek-chat');

      final result = await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('hello'),
          ],
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.uri.toString(), contains('/chat/completions'));
      expect(result.text, 'hello');
      expect(result.providerMetadata?['deepseek'],
          containsPair('finishReason', 'stop'));
    });

    test('DeepSeek tool replay encodes matching role tool messages', () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        profile: const DeepSeekProfile(),
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_deepseek_tool_1',
                'model': 'deepseek-chat',
                'created': 1710000000,
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'stop',
                    'message': {
                      'role': 'assistant',
                      'content': 'The weather in Hanoi is warm.',
                    },
                  },
                ],
                'usage': {
                  'prompt_tokens': 8,
                  'completion_tokens': 6,
                  'total_tokens': 14,
                },
              },
            );
          },
        ),
      ).chatModel('deepseek-chat');

      await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('What is the weather in Hanoi?'),
            AssistantPromptMessage(
              parts: const [
                ToolCallPromptPart(
                  toolCallId: 'call_weather_1',
                  toolName: 'get_weather',
                  input: {'city': 'Hanoi'},
                ),
              ],
            ),
            ToolPromptMessage(
              toolName: 'get_weather',
              parts: [
                ToolResultPromptPart(
                  toolCallId: 'call_weather_1',
                  toolName: 'get_weather',
                  output: {
                    'city': 'Hanoi',
                    'temperatureC': 31,
                  },
                ),
              ],
            ),
          ],
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['messages'],
        [
          {
            'role': 'user',
            'content': 'What is the weather in Hanoi?',
          },
          {
            'role': 'assistant',
            'content': '',
            'tool_calls': [
              {
                'id': 'call_weather_1',
                'type': 'function',
                'function': {
                  'name': 'get_weather',
                  'arguments': '{"city":"Hanoi"}',
                },
              },
            ],
          },
          {
            'role': 'tool',
            'tool_call_id': 'call_weather_1',
            'content': '{"city":"Hanoi","temperatureC":31}',
          },
        ],
      );
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;
