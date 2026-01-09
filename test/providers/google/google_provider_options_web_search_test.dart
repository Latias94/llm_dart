import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_google/client.dart';
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';

void main() {
  group('Google providerOptions web search', () {
    test('adds google_search tool when providerOptions.webSearchEnabled=true',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash',
        providerOptions: const {
          'google': {
            'webSearchEnabled': true,
          },
        },
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = FakeGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat
          .chatStreamParts([ChatMessage.user('hi')], tools: const []).toList();

      final tools = client.lastBody?['tools'];
      expect(tools, isA<List>());
      final list = tools as List;
      final hasGoogleSearch =
          list.any((t) => t is Map && t.containsKey('googleSearchRetrieval'));
      expect(hasGoogleSearch, isTrue);
    });

    test('adds google_search tool when providerOptions.webSearch.enabled=true',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash',
        providerOptions: const {
          'google': {
            'webSearch': {
              'enabled': true,
            },
          },
        },
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = FakeGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat
          .chatStreamParts([ChatMessage.user('hi')], tools: const []).toList();

      final tools = client.lastBody?['tools'];
      expect(tools, isA<List>());
      final list = tools as List;
      final hasGoogleSearch =
          list.any((t) => t is Map && t.containsKey('googleSearchRetrieval'));
      expect(hasGoogleSearch, isTrue);
    });

    test(
        'allows a function tool named google_search when provider-native web search is disabled',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash',
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = FakeGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chatStreamParts(
        [ChatMessage.user('hi')],
        tools: [
          Tool.function(
            name: 'google_search',
            description: 'Local tool with reserved name',
            parameters: const ParametersSchema(
              schemaType: 'object',
              properties: {},
              required: [],
            ),
          ),
        ],
      ).toList();

      final tools = client.lastBody?['tools'];
      expect(tools, isA<List>());
      final list = tools as List;

      final functionDeclarations = list
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .where((m) => m['functionDeclarations'] is List)
          .expand((m) => (m['functionDeclarations'] as List))
          .whereType<Map>()
          .map((m) => m['name'])
          .whereType<String>()
          .toList();

      expect(functionDeclarations, contains('google_search'));

      final hasGoogleSearchBuiltIn =
          list.any((t) => t is Map && t.containsKey('googleSearchRetrieval'));
      expect(hasGoogleSearchBuiltIn, isFalse);
    });

    test('ignores function tools when provider-native web search is enabled',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash',
        providerOptions: const {
          'google': {
            'webSearchEnabled': true,
          },
        },
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = FakeGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chatStreamParts(
        [ChatMessage.user('hi')],
        tools: [
          Tool.function(
            name: 'google_search',
            description: 'Local tool with colliding name',
            parameters: const ParametersSchema(
              schemaType: 'object',
              properties: {},
              required: [],
            ),
          ),
        ],
      ).toList();

      final tools = client.lastBody?['tools'];
      expect(tools, isA<List>());
      final list = tools as List;

      final hasGoogleSearchBuiltIn =
          list.any((t) => t is Map && t.containsKey('googleSearchRetrieval'));
      expect(hasGoogleSearchBuiltIn, isTrue);

      final hasFunctionDeclarations =
          list.any((t) => t is Map && t.containsKey('functionDeclarations'));
      expect(hasFunctionDeclarations, isFalse);
    });

    test(
        'adds google_search tool when providerTools includes google.google_search',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash',
        providerTools: const [
          ProviderTool(id: 'google.google_search'),
        ],
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = FakeGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat
          .chatStreamParts([ChatMessage.user('hi')], tools: const []).toList();

      final tools = client.lastBody?['tools'];
      expect(tools, isA<List>());
      final list = tools as List;
      final hasGoogleSearch =
          list.any((t) => t is Map && t.containsKey('googleSearchRetrieval'));
      expect(hasGoogleSearch, isTrue);
    });

    test('ignores function tools when providerTools enables web search',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash',
        providerTools: const [
          ProviderTool(id: 'google.google_search'),
        ],
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = FakeGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chatStreamParts(
        [ChatMessage.user('hi')],
        tools: [
          Tool.function(
            name: 'google_search',
            description: 'Local tool with colliding name',
            parameters: const ParametersSchema(
              schemaType: 'object',
              properties: {},
              required: [],
            ),
          ),
        ],
      ).toList();

      final tools = client.lastBody?['tools'];
      expect(tools, isA<List>());
      final list = tools as List;

      final hasGoogleSearchBuiltIn =
          list.any((t) => t is Map && t.containsKey('googleSearchRetrieval'));
      expect(hasGoogleSearchBuiltIn, isTrue);

      final hasFunctionDeclarations =
          list.any((t) => t is Map && t.containsKey('functionDeclarations'));
      expect(hasFunctionDeclarations, isFalse);
    });

    test(
        'bridges google.google_search ProviderTool options into googleSearchRetrieval.dynamicRetrievalConfig',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash',
        providerTools: const [
          ProviderTool(
            id: 'google.google_search',
            options: {
              'mode': 'MODE_DYNAMIC',
              'dynamicThreshold': 0.3,
            },
          ),
        ],
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = FakeGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat
          .chatStreamParts([ChatMessage.user('hi')], tools: const []).toList();

      final tools = client.lastBody?['tools'];
      expect(tools, isA<List>());
      final list = tools as List;
      final map =
          list.whereType<Map>().map((m) => Map<String, dynamic>.from(m));
      final toolEntry = map.firstWhere(
        (m) => m.containsKey('googleSearchRetrieval'),
      );
      final retrieval =
          Map<String, dynamic>.from(toolEntry['googleSearchRetrieval'] as Map);
      final dynamicConfig =
          Map<String, dynamic>.from(retrieval['dynamicRetrievalConfig'] as Map);
      expect(dynamicConfig['mode'], equals('MODE_DYNAMIC'));
      expect(dynamicConfig['dynamicThreshold'], equals(0.3));
    });

    test(
        'gemini-2 models inject googleSearch and ignore dynamic retrieval args',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-2.0-flash',
        providerTools: const [
          ProviderTool(
            id: 'google.google_search',
            options: {
              'mode': 'MODE_DYNAMIC',
              'dynamicThreshold': 0.3,
            },
          ),
        ],
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = FakeGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat
          .chatStreamParts([ChatMessage.user('hi')], tools: const []).toList();

      final tools = client.lastBody?['tools'];
      expect(tools, isA<List>());
      final list = tools as List;
      final map =
          list.whereType<Map>().map((m) => Map<String, dynamic>.from(m));
      final hasGoogleSearch = map.any((m) => m.containsKey('googleSearch'));
      expect(hasGoogleSearch, isTrue);
      final hasGoogleSearchRetrieval =
          map.any((m) => m.containsKey('googleSearchRetrieval'));
      expect(hasGoogleSearchRetrieval, isFalse);
    });

    test('gemini-2 injects codeExecution and urlContext provider tools',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-2.0-flash',
        providerTools: const [
          ProviderTool(id: 'google.code_execution'),
          ProviderTool(id: 'google.url_context'),
        ],
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = FakeGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat
          .chatStreamParts([ChatMessage.user('hi')], tools: const []).toList();

      final tools = client.lastBody?['tools'];
      expect(tools, isA<List>());
      final list = tools as List;
      final map =
          list.whereType<Map>().map((m) => Map<String, dynamic>.from(m));

      expect(map.any((m) => m.containsKey('codeExecution')), isTrue);
      expect(map.any((m) => m.containsKey('urlContext')), isTrue);
    });

    test('ignores function tools when google.code_execution is enabled',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-2.0-flash',
        providerTools: const [
          ProviderTool(id: 'google.code_execution'),
        ],
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = FakeGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat.chatStreamParts(
        [ChatMessage.user('hi')],
        tools: [
          Tool.function(
            name: 'code_execution',
            description: 'Local tool with colliding name',
            parameters: const ParametersSchema(
              schemaType: 'object',
              properties: {},
              required: [],
            ),
          ),
        ],
      ).toList();

      final tools = client.lastBody?['tools'];
      expect(tools, isA<List>());
      final list = tools as List;

      final hasCodeExecutionBuiltIn =
          list.any((t) => t is Map && t.containsKey('codeExecution'));
      expect(hasCodeExecutionBuiltIn, isTrue);

      final hasFunctionDeclarations =
          list.any((t) => t is Map && t.containsKey('functionDeclarations'));
      expect(hasFunctionDeclarations, isFalse);
    });
  });
}
