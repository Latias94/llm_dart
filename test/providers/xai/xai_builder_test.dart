import 'package:llm_dart/builder/llm_builder.dart';
import 'package:llm_dart/models/tool_models.dart';
import 'package:llm_dart/providers/xai/xai.dart';
import 'package:llm_dart/src/compatibility/config/legacy_config_keys.dart';
import 'package:llm_dart/src/compatibility/config/legacy_provider_options.dart';
import 'package:test/test.dart';

void main() {
  group('XAIBuilder', () {
    test('stores callback options under namespaced providerOptions', () {
      const schema = StructuredOutputFormat(
        name: 'answer',
        schema: {
          'type': 'object',
          'properties': {
            'value': {'type': 'string'},
          },
        },
      );

      final builder = LLMBuilder().xai(
        (xai) => xai
            .liveSearch(true)
            .webSearch(maxResults: 5, excludedWebsites: ['example.com'])
            .jsonSchema(schema)
            .embeddingEncodingFormat('float')
            .embeddingDimensions(1536),
      );
      final xaiOptions = legacyProviderOptionsNamespace(
        builder.currentConfig,
        LegacyProviderOptionNamespaces.xai,
      );
      final searchParameters =
          xaiOptions[LegacyExtensionKeys.xaiSearchParameters]
              as SearchParameters;

      expect(xaiOptions[LegacyExtensionKeys.xaiLiveSearch], isTrue);
      expect(searchParameters.mode, 'auto');
      expect(searchParameters.maxSearchResults, 5);
      expect(searchParameters.sources, hasLength(1));
      expect(searchParameters.sources!.single.excludedWebsites, [
        'example.com',
      ]);
      expect(xaiOptions[LegacyExtensionKeys.jsonSchema], same(schema));
      expect(xaiOptions[LegacyExtensionKeys.embeddingEncodingFormat], 'float');
      expect(xaiOptions[LegacyExtensionKeys.embeddingDimensions], 1536);
    });

    test('builds provider from namespaced callback options', () async {
      const schema = StructuredOutputFormat(
        name: 'answer',
        schema: {
          'type': 'object',
          'properties': {
            'value': {'type': 'string'},
          },
        },
      );

      final provider = await LLMBuilder()
          .xai(
            (xai) => xai
                .liveSearch(true)
                .newsSearch(maxResults: 3, fromDate: '2026-01-01')
                .jsonSchema(schema)
                .embeddingDimensions(1024),
          )
          .apiKey('test-key')
          .model('grok-3')
          .build();

      expect(provider, isA<XAIProvider>());

      final xaiProvider = provider as XAIProvider;
      expect(xaiProvider.config.liveSearch, isTrue);
      expect(xaiProvider.config.searchParameters?.maxSearchResults, 3);
      expect(xaiProvider.config.searchParameters?.fromDate, '2026-01-01');
      expect(xaiProvider.config.jsonSchema, same(schema));
      expect(xaiProvider.config.embeddingDimensions, 1024);
    });
  });
}
