import 'package:llm_dart_core/core/config.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_core/models/tool_models.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI-compatible request builder conformance', () {
    test('injects config.systemPrompt when no system message exists', () {
      final llmConfig = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-4o',
        systemPrompt: 'sys',
      );

      final config = OpenAICompatibleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'deepseek',
        providerName: 'DeepSeek',
      );

      final client = OpenAIClient(config);
      final builder = OpenAIRequestBuilder(config);

      final body = builder.buildChatCompletionsRequestBody(
        client,
        messages: [ChatMessage.user('hi')],
        tools: const [],
        stream: false,
      );

      final messages = body['messages'] as List<dynamic>;
      expect(messages.first, isA<Map>());
      expect((messages.first as Map)['role'], equals('system'));
      expect((messages.first as Map)['content'], equals('sys'));
    });

    test('does not inject config.systemPrompt when a system message exists',
        () {
      final llmConfig = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-4o',
        systemPrompt: 'sys',
      );

      final config = OpenAICompatibleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'deepseek',
        providerName: 'DeepSeek',
      );

      final client = OpenAIClient(config);
      final builder = OpenAIRequestBuilder(config);

      final body = builder.buildChatCompletionsRequestBody(
        client,
        messages: [ChatMessage.system('sys2'), ChatMessage.user('hi')],
        tools: const [],
        stream: false,
      );

      final messages = body['messages'] as List<dynamic>;
      final systemCount =
          messages.whereType<Map>().where((m) => m['role'] == 'system').length;
      expect(systemCount, equals(1));
      expect((messages.first as Map)['content'], equals('sys2'));
    });

    test('extraBody overrides standard fields (escape hatch wins)', () {
      final llmConfig = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-4o',
        providerOptions: const {
          'deepseek': {
            'extraBody': {
              'temperature': 0.123,
              'foo': 'bar',
            },
          },
        },
        temperature: 0.9,
      );

      final config = OpenAICompatibleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'deepseek',
        providerName: 'DeepSeek',
      );

      final client = OpenAIClient(config);
      final builder = OpenAIRequestBuilder(config);

      final body = builder.buildChatCompletionsRequestBody(
        client,
        messages: [ChatMessage.user('hi')],
        tools: const [],
        stream: false,
      );

      expect(body['temperature'], equals(0.123));
      expect(body['foo'], equals('bar'));
    });

    test('Groq structuredOutputs=false downgrades json_schema to json_object',
        () {
      final llmConfig = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://api.groq.com/openai/v1/',
        model: 'moonshotai/kimi-k2-instruct-0905',
        providerOptions: const {
          'groq': {
            'structuredOutputs': false,
            'jsonSchema': StructuredOutputFormat(
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

      final client = OpenAIClient(config);
      final builder = OpenAIRequestBuilder(config);

      final body = builder.buildChatCompletionsRequestBody(
        client,
        messages: [ChatMessage.user('hi')],
        tools: const [],
        stream: false,
      );

      final responseFormat = body['response_format'] as Map<String, dynamic>?;
      expect(responseFormat, isNotNull);
      expect(responseFormat!['type'], equals('json_object'));
    });

    test(
        'Groq-openai structuredOutputs=false downgrades json_schema to json_object',
        () {
      final llmConfig = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://api.groq.com/openai/v1/',
        model: 'moonshotai/kimi-k2-instruct-0905',
        providerOptions: const {
          'groq-openai': {
            'structuredOutputs': false,
            'jsonSchema': StructuredOutputFormat(
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
        providerId: 'groq-openai',
        providerName: 'Groq (OpenAI-compatible)',
      );

      final client = OpenAIClient(config);
      final builder = OpenAIRequestBuilder(config);

      final body = builder.buildChatCompletionsRequestBody(
        client,
        messages: [ChatMessage.user('hi')],
        tools: const [],
        stream: false,
      );

      final responseFormat = body['response_format'] as Map<String, dynamic>?;
      expect(responseFormat, isNotNull);
      expect(responseFormat!['type'], equals('json_object'));
    });

    test('xAI liveSearch injects search_parameters when enabled', () {
      final llmConfig = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-3',
        providerOptions: const {
          'xai': {
            'liveSearch': true,
            'searchParameters': {
              'mode': 'always',
              'sources': [
                {'type': 'web'}
              ],
              'max_search_results': 3,
            },
          },
        },
      );

      final config = OpenAICompatibleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'xai',
        providerName: 'xAI',
      );

      final client = OpenAIClient(config);
      final builder = OpenAIRequestBuilder(config);

      final body = builder.buildChatCompletionsRequestBody(
        client,
        messages: [ChatMessage.user('hi')],
        tools: const [],
        stream: false,
      );

      final searchParameters =
          body['search_parameters'] as Map<String, dynamic>?;
      expect(searchParameters, isNotNull);
      expect(searchParameters!['mode'], equals('always'));
      expect(searchParameters['max_search_results'], equals(3));
    });

    test('xAI-openai liveSearch injects search_parameters when enabled', () {
      final llmConfig = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-3',
        providerOptions: const {
          'xai-openai': {
            'liveSearch': true,
            'searchParameters': {
              'mode': 'always',
              'sources': [
                {'type': 'web'}
              ],
              'max_search_results': 3,
            },
          },
        },
      );

      final config = OpenAICompatibleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'xai-openai',
        providerName: 'xAI (OpenAI-compatible)',
      );

      final client = OpenAIClient(config);
      final builder = OpenAIRequestBuilder(config);

      final body = builder.buildChatCompletionsRequestBody(
        client,
        messages: [ChatMessage.user('hi')],
        tools: const [],
        stream: false,
      );

      final searchParameters =
          body['search_parameters'] as Map<String, dynamic>?;
      expect(searchParameters, isNotNull);
      expect(searchParameters!['mode'], equals('always'));
      expect(searchParameters['max_search_results'], equals(3));
    });

    test('xAI liveSearch defaults to web search parameters', () {
      final llmConfig = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-3',
        providerOptions: const {
          'xai': {
            'liveSearch': true,
          },
        },
      );

      final config = OpenAICompatibleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'xai',
        providerName: 'xAI',
      );

      final client = OpenAIClient(config);
      final builder = OpenAIRequestBuilder(config);

      final body = builder.buildChatCompletionsRequestBody(
        client,
        messages: [ChatMessage.user('hi')],
        tools: const [],
        stream: false,
      );

      final searchParameters =
          body['search_parameters'] as Map<String, dynamic>?;
      expect(searchParameters, isNotNull);
      expect(searchParameters!['mode'], equals('auto'));
      expect(searchParameters['sources'], isA<List>());
    });

    test('DeepSeek-openai forwards responseFormat to response_format', () {
      final llmConfig = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://api.deepseek.com/v1/',
        model: 'deepseek-chat',
        providerOptions: const {
          'deepseek-openai': {
            'responseFormat': {'type': 'json_object'},
          },
        },
      );

      final config = OpenAICompatibleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'deepseek-openai',
        providerName: 'DeepSeek (OpenAI-compatible)',
      );

      final client = OpenAIClient(config);
      final builder = OpenAIRequestBuilder(config);

      final body = builder.buildChatCompletionsRequestBody(
        client,
        messages: [ChatMessage.user('hi')],
        tools: const [],
        stream: false,
      );

      final responseFormat = body['response_format'] as Map<String, dynamic>?;
      expect(responseFormat, isNotNull);
      expect(responseFormat!['type'], equals('json_object'));
    });

    test('OpenRouter maps reasoningEffort to reasoning.effort', () {
      final llmConfig = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://openrouter.ai/api/v1/',
        model: 'anthropic/claude-3.5-sonnet',
        providerOptions: const {
          'openrouter': {
            'reasoningEffort': 'low',
          },
        },
      );

      final config = OpenAICompatibleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'openrouter',
        providerName: 'OpenRouter',
      );

      final client = OpenAIClient(config);
      final builder = OpenAIRequestBuilder(config);

      final body = builder.buildChatCompletionsRequestBody(
        client,
        messages: [ChatMessage.user('hi')],
        tools: const [],
        stream: false,
      );

      final reasoning = body['reasoning'] as Map<String, dynamic>?;
      expect(reasoning, isNotNull);
      expect(reasoning!['effort'], equals('low'));
    });
  });
}
