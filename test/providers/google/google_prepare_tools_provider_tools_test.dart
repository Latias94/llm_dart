import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_google/client.dart';
import 'package:test/test.dart';

class _CapturingGoogleClient extends GoogleClient {
  Map<String, dynamic>? lastBody;

  _CapturingGoogleClient(super.config);

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) {
    lastBody = data;
    return Stream<String>.empty();
  }
}

void main() {
  group('Google providerTools request shaping (AI SDK parity)', () {
    test('adds enterpriseWebSearch on gemini-2.5 models', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-2.5-flash',
        providerTools: const [
          ProviderTool(id: 'google.enterprise_web_search'),
        ],
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat
          .chatStreamParts([ChatMessage.user('hi')], tools: const []).toList();

      final tools = client.lastBody?['tools'] as List?;
      expect(tools, isNotNull);
      expect(
          tools!.any((t) => t is Map && t.containsKey('enterpriseWebSearch')),
          isTrue);
    });

    test('does not add enterpriseWebSearch on gemini-1.5 models', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash',
        providerTools: const [
          ProviderTool(id: 'google.enterprise_web_search'),
        ],
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat
          .chatStreamParts([ChatMessage.user('hi')], tools: const []).toList();

      expect(client.lastBody?.containsKey('tools'), isFalse);
    });

    test('adds googleMaps on gemini-2.5 models', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-2.5-flash',
        providerTools: const [
          ProviderTool(id: 'google.google_maps'),
        ],
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat
          .chatStreamParts([ChatMessage.user('hi')], tools: const []).toList();

      final tools = client.lastBody?['tools'] as List?;
      expect(tools, isNotNull);
      expect(
          tools!.any((t) => t is Map && t.containsKey('googleMaps')), isTrue);
    });

    test('does not add googleMaps on gemini-1.5 models', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash',
        providerTools: const [
          ProviderTool(id: 'google.google_maps'),
        ],
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat
          .chatStreamParts([ChatMessage.user('hi')], tools: const []).toList();

      expect(client.lastBody?.containsKey('tools'), isFalse);
    });

    test('adds fileSearch on gemini-2.5 models', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-2.5-pro',
        providerTools: const [
          ProviderTool(
            id: 'google.file_search',
            options: {
              'fileSearchStoreNames': ['projects/foo/fileSearchStores/bar'],
              'metadataFilter': 'author=Robert Graves',
              'topK': 5,
            },
          ),
        ],
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat
          .chatStreamParts([ChatMessage.user('hi')], tools: const []).toList();

      final tools = client.lastBody?['tools'] as List?;
      expect(tools, isNotNull);

      final fileSearch = tools!
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .where((m) => m.containsKey('fileSearch'))
          .map((m) => m['fileSearch'])
          .first;

      expect(
        fileSearch,
        equals({
          'fileSearchStoreNames': ['projects/foo/fileSearchStores/bar'],
          'metadataFilter': 'author=Robert Graves',
          'topK': 5,
        }),
      );
    });

    test('does not add fileSearch on unsupported models', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash-8b',
        providerTools: const [
          ProviderTool(
            id: 'google.file_search',
            options: {
              'fileSearchStoreNames': ['projects/foo/fileSearchStores/bar'],
            },
          ),
        ],
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat
          .chatStreamParts([ChatMessage.user('hi')], tools: const []).toList();

      expect(client.lastBody?.containsKey('tools'), isFalse);
    });

    test('adds vertex_rag_store retrieval on gemini-2.5 models', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-2.5-flash',
        providerTools: const [
          ProviderTool(
            id: 'google.vertex_rag_store',
            options: {
              'ragCorpus': 'projects/p/locations/l/ragCorpora/c',
              'topK': 3,
            },
          ),
        ],
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat
          .chatStreamParts([ChatMessage.user('hi')], tools: const []).toList();

      final tools = client.lastBody?['tools'] as List?;
      expect(tools, isNotNull);
      final retrieval = tools!
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .where((m) => m.containsKey('retrieval'))
          .map((m) => m['retrieval'])
          .first as Map;

      expect(
        retrieval,
        equals({
          'vertex_rag_store': {
            'rag_resources': {
              'rag_corpus': 'projects/p/locations/l/ragCorpora/c',
            },
            'similarity_top_k': 3,
          },
        }),
      );
    });

    test(
        'google_search dynamicRetrievalConfig is only sent for gemini-1.5-flash (non-8b)',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash',
        providerTools: const [
          ProviderTool(
            id: 'google.google_search',
            options: {
              'enabled': true,
              'mode': 'MODE_DYNAMIC',
              'dynamicThreshold': 0.5,
            },
          ),
        ],
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat
          .chatStreamParts([ChatMessage.user('hi')], tools: const []).toList();

      final tools = client.lastBody?['tools'] as List?;
      expect(tools, isNotNull);
      final webSearch = tools!
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .where((m) => m.containsKey('googleSearchRetrieval'))
          .map((m) => m['googleSearchRetrieval'])
          .first as Map<String, dynamic>;

      expect(
        webSearch['dynamicRetrievalConfig'],
        equals({
          'mode': 'MODE_DYNAMIC',
          'dynamicThreshold': 0.5,
        }),
      );
    });

    test('google_search ignores dynamicRetrievalConfig on gemini-1.5-flash-8b',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash-8b',
        providerTools: const [
          ProviderTool(
            id: 'google.google_search',
            options: {
              'enabled': true,
              'mode': 'MODE_DYNAMIC',
              'dynamicThreshold': 0.5,
            },
          ),
        ],
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      await chat
          .chatStreamParts([ChatMessage.user('hi')], tools: const []).toList();

      final tools = client.lastBody?['tools'] as List?;
      expect(tools, isNotNull);
      final webSearch = tools!
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .where((m) => m.containsKey('googleSearchRetrieval'))
          .map((m) => m['googleSearchRetrieval'])
          .first as Map<String, dynamic>;

      expect(webSearch.containsKey('dynamicRetrievalConfig'), isFalse);
    });
  });
}
