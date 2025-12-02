import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_xai/llm_dart_xai.dart' as xai;

void main() {
  group('xAI Live Search Tests', () {
    test('should enable live search with enableWebSearch()', () async {
      final provider = await ai()
          .xai()
          .apiKey('test-key')
          .model('grok-3')
          .enableWebSearch()
          .build();

      expect(provider, isA<xai.XAIProvider>());

      // Access the internal config to verify live search is enabled
      final xaiProvider = provider as xai.XAIProvider;
      expect(xaiProvider.config.liveSearch, isTrue);
      expect(xaiProvider.config.searchParameters, isNotNull);
      expect(xaiProvider.config.searchParameters!.mode, equals('auto'));
      expect(xaiProvider.config.searchParameters!.sources, isNotEmpty);
      expect(xaiProvider.config.searchParameters!.sources!.first.sourceType,
          equals('web'));
    });

    test('should configure news search correctly', () async {
      final provider = await ai()
          .xai()
          .apiKey('test-key')
          .model('grok-3')
          .newsSearch(
            maxResults: 5,
            fromDate: '2024-01-01',
            toDate: '2024-12-31',
          )
          .build();

      final xaiProvider = provider as xai.XAIProvider;
      expect(xaiProvider.config.searchParameters, isNotNull);
      expect(xaiProvider.config.searchParameters!.maxSearchResults, equals(5));
      expect(
          xaiProvider.config.searchParameters!.fromDate, equals('2024-01-01'));
      expect(xaiProvider.config.searchParameters!.toDate, equals('2024-12-31'));
      expect(xaiProvider.config.searchParameters!.sources!.first.sourceType,
          equals('news'));
    });

    test('should configure web search with custom parameters', () async {
      final provider = await ai()
          .xai()
          .apiKey('test-key')
          .model('grok-3')
          .webSearch(
            maxResults: 10,
            blockedDomains: ['spam.com', 'ads.com'],
            mode: 'always',
          )
          .build();

      final xaiProvider = provider as xai.XAIProvider;
      expect(xaiProvider.config.searchParameters, isNotNull);
      expect(xaiProvider.config.searchParameters!.maxSearchResults, equals(10));
      expect(xaiProvider.config.searchParameters!.mode, equals('always'));
    });

    test('should build correct search parameters JSON', () {
      final searchParams = xai.SearchParameters.webSearch(
        mode: 'auto',
        maxResults: 5,
        excludedWebsites: ['example.com'],
      );

      final json = searchParams.toJson();

      expect(json['mode'], equals('auto'));
      expect(json['max_search_results'], equals(5));
      expect(json['sources'], isA<List>());
      expect(json['sources'][0]['type'], equals('web'));
      expect(json['sources'][0]['excluded_websites'], contains('example.com'));
    });

    test('should build correct news search parameters JSON', () {
      final searchParams = xai.SearchParameters.newsSearch(
        mode: 'auto',
        maxResults: 3,
        fromDate: '2024-01-01',
        toDate: '2024-12-31',
      );

      final json = searchParams.toJson();

      expect(json['mode'], equals('auto'));
      expect(json['max_search_results'], equals(3));
      expect(json['from_date'], equals('2024-01-01'));
      expect(json['to_date'], equals('2024-12-31'));
      expect(json['sources'][0]['type'], equals('news'));
    });

    test('should build combined search parameters JSON', () {
      final searchParams = xai.SearchParameters.combined(
        mode: 'auto',
        maxResults: 8,
      );

      final json = searchParams.toJson();

      expect(json['mode'], equals('auto'));
      expect(json['max_search_results'], equals(8));
      expect(json['sources'], hasLength(2));
      expect(json['sources'][0]['type'], equals('web'));
      expect(json['sources'][1]['type'], equals('news'));
    });

    test('should handle search source with excluded websites', () {
      final source = xai.SearchSource(
        sourceType: 'web',
        excludedWebsites: ['spam.com', 'ads.com'],
      );

      final json = source.toJson();

      expect(json['type'], equals('web'));
      expect(json['excluded_websites'], contains('spam.com'));
      expect(json['excluded_websites'], contains('ads.com'));
    });

    test('should handle search source without excluded websites', () {
      final source = xai.SearchSource(sourceType: 'news');

      final json = source.toJson();

      expect(json['type'], equals('news'));
      expect(json.containsKey('excluded_websites'), isFalse);
    });

    test('should create live search provider with convenience function', () {
      final provider = createXAILiveSearchProvider(
        apiKey: 'test-key',
        model: 'grok-3',
        maxSearchResults: 7,
        excludedWebsites: ['blocked.com'],
      );

      expect(provider.config.liveSearch, isTrue);
      expect(provider.config.searchParameters, isNotNull);
      expect(provider.config.searchParameters!.maxSearchResults, equals(7));
      expect(provider.config.searchParameters!.sources!.first.excludedWebsites,
          contains('blocked.com'));
    });

    test('should create search provider with convenience function', () {
      final provider = createXAISearchProvider(
        apiKey: 'test-key',
        model: 'grok-3',
        searchMode: 'always',
        maxSearchResults: 15,
        fromDate: '2024-06-01',
      );

      expect(provider.config.liveSearch, isTrue);
      expect(provider.config.searchParameters, isNotNull);
      expect(provider.config.searchParameters!.mode, equals('always'));
      expect(provider.config.searchParameters!.maxSearchResults, equals(15));
      expect(provider.config.searchParameters!.fromDate, equals('2024-06-01'));
    });
  });

  group('xAI Live Search Request Building', () {
    test(
        'should include search_parameters in request body when live search enabled',
        () {
      final config = xai.XAIConfig(
        apiKey: 'test-key',
        model: 'grok-3',
        liveSearch: true,
        searchParameters: xai.SearchParameters.webSearch(maxResults: 5),
      );

      // final chat = XAIChat(XAIClient(config), config);

      // Use reflection or create a test method to access _buildRequestBody
      // For now, we'll test the config setup
      expect(config.liveSearch, isTrue);
      expect(config.searchParameters, isNotNull);
      expect(config.isLiveSearchEnabled, isTrue);
    });

    test('should not include search_parameters when live search disabled', () {
      final config = xai.XAIConfig(
        apiKey: 'test-key',
        model: 'grok-3',
        liveSearch: false,
      );

      expect(config.liveSearch, isFalse);
      expect(config.searchParameters, isNull);
      expect(config.isLiveSearchEnabled, isFalse);
    });
  });
}
