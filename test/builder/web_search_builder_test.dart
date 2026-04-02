import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Web Search Builder', () {
    test('searchLocation writes into webSearchConfig when no config exists',
        () {
      // ignore: deprecated_member_use_from_same_package
      final builder = LLMBuilder().searchLocation(WebSearchLocation.newYork());

      final config = builder.currentConfig
          .getExtension<WebSearchConfig>('webSearchConfig');
      expect(config, isNotNull);
      expect(config!.location?.city, 'New York');
      expect(config.location?.country, 'US');
    });

    test('searchLocation merges into existing webSearchConfig', () {
      // ignore: deprecated_member_use_from_same_package
      final builder = LLMBuilder().webSearch(
        maxUses: 3,
        allowedDomains: const ['wikipedia.org'],
        // ignore: deprecated_member_use_from_same_package
      ).searchLocation(WebSearchLocation.london());

      final config = builder.currentConfig
          .getExtension<WebSearchConfig>('webSearchConfig');
      expect(config, isNotNull);
      expect(config!.maxUses, 3);
      expect(config.allowedDomains, ['wikipedia.org']);
      expect(config.location?.city, 'London');
      expect(config.location?.country, 'GB');
    });

    test('newsSearch preserves an existing search location', () {
      // ignore: deprecated_member_use_from_same_package
      final builder = LLMBuilder()
          // ignore: deprecated_member_use_from_same_package
          .searchLocation(WebSearchLocation.sanFrancisco())
          // ignore: deprecated_member_use_from_same_package
          .newsSearch(
            maxResults: 10,
          );

      final config = builder.currentConfig
          .getExtension<WebSearchConfig>('webSearchConfig');
      expect(config, isNotNull);
      expect(config!.searchType, WebSearchType.news);
      expect(config.maxResults, 10);
      expect(config.location?.city, 'San Francisco');
      expect(config.location?.country, 'US');
    });

    test('advancedWebSearch preserves an existing search location by default',
        () {
      // ignore: deprecated_member_use_from_same_package
      final builder = LLMBuilder()
          // ignore: deprecated_member_use_from_same_package
          .searchLocation(WebSearchLocation.tokyo())
          // ignore: deprecated_member_use_from_same_package
          .advancedWebSearch(
            strategy: WebSearchStrategy.tool,
            maxUses: 2,
          );

      final config = builder.currentConfig
          .getExtension<WebSearchConfig>('webSearchConfig');
      expect(config, isNotNull);
      expect(config!.strategy, WebSearchStrategy.tool);
      expect(config.maxUses, 2);
      expect(config.location?.city, 'Tokyo');
      expect(config.location?.country, 'JP');
    });
  });
}
