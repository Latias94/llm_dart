import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:test/test.dart';

class _CapturingOpenAIClient extends OpenAIClient {
  String? lastEndpoint;
  Map<String, dynamic>? lastBody;

  _CapturingOpenAIClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastBody = body;
    return {
      'choices': [
        {
          'message': {'content': 'ok'},
        }
      ],
    };
  }
}

void main() {
  group('Groq providerOptions request body (OpenAI-compatible)', () {
    test('maps Groq Vercel-style providerOptions into request body', () async {
      final llmConfig = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://api.groq.com/openai/v1/',
        model: 'qwen/qwen3-32b',
        user: 'user-from-standard',
        serviceTier: ServiceTier.priority,
        providerOptions: {
          'groq': {
            'reasoningFormat': 'parsed',
            'reasoningEffort': 'default',
            'parallelToolCalls': true,
            'user': 'user-from-options',
            'serviceTier': 'flex',
            'structuredOutputs': false,
            'jsonSchema': const StructuredOutputFormat(
              name: 'response',
              schema: {
                'type': 'object',
                'properties': {
                  'answer': {'type': 'string'},
                },
                'required': ['answer'],
              },
            ),
          },
        },
      );

      final config = OpenAICompatibleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'groq',
        providerName: 'Groq',
      );
      final client = _CapturingOpenAIClient(config);
      final chat = OpenAIChat(client, config);

      await chat.chat([ChatMessage.user('hi')]);

      final body = client.lastBody;
      expect(body, isNotNull);
      expect(body!['reasoning_format'], equals('parsed'));
      expect(body['reasoning_effort'], equals('default'));
      expect(body['parallel_tool_calls'], isTrue);
      expect(body['user'], equals('user-from-options'));
      expect(body['service_tier'], equals('flex'));

      final responseFormat = body['response_format'] as Map<String, dynamic>?;
      expect(responseFormat, isNotNull);
      expect(responseFormat!['type'], equals('json_object'));
    });

    test('structuredOutputs defaults to true (json_schema)', () async {
      final llmConfig = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://api.groq.com/openai/v1/',
        model: 'moonshotai/kimi-k2-instruct-0905',
        providerOptions: {
          'groq': {
            'jsonSchema': const StructuredOutputFormat(
              name: 'response',
              schema: {
                'type': 'object',
                'properties': {
                  'answer': {'type': 'string'},
                },
                'required': ['answer'],
              },
            ),
          },
        },
      );

      final config = OpenAICompatibleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'groq',
        providerName: 'Groq',
      );
      final client = _CapturingOpenAIClient(config);
      final chat = OpenAIChat(client, config);

      await chat.chat([ChatMessage.user('hi')]);

      final body = client.lastBody;
      expect(body, isNotNull);

      final responseFormat = body!['response_format'] as Map<String, dynamic>?;
      expect(responseFormat, isNotNull);
      expect(responseFormat!['type'], equals('json_schema'));
    });
  });
}
