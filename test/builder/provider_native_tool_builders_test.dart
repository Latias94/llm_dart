import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Provider-native tool builders', () {
    test('anthropic.webSearchTool() writes ProviderTool', () {
      final builder = ai().anthropic((anthropic) => anthropic.webSearchTool());

      expect(builder.currentConfig.providerTools, isNotNull);
      expect(
        builder.currentConfig.providerTools!.map((t) => t.id).toList(),
        equals(['anthropic.web_search_20250305']),
      );
    });

    test('google.webSearchTool() writes ProviderTool', () {
      final builder = ai().google((google) => google.webSearchTool());

      expect(builder.currentConfig.providerTools, isNotNull);
      expect(
        builder.currentConfig.providerTools!.map((t) => t.id).toList(),
        equals(['google.google_search']),
      );
    });
  });
}
