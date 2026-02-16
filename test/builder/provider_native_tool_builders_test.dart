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

    test('anthropic.bashTool() writes ProviderTool', () {
      final builder = ai().anthropic((anthropic) => anthropic.bashTool());

      expect(builder.currentConfig.providerTools, isNotNull);
      expect(
        builder.currentConfig.providerTools!.map((t) => t.id).toList(),
        equals(['anthropic.bash_20250124']),
      );
    });

    test('anthropic.codeExecutionTool() writes ProviderTool', () {
      final builder =
          ai().anthropic((anthropic) => anthropic.codeExecutionTool());

      expect(builder.currentConfig.providerTools, isNotNull);
      expect(
        builder.currentConfig.providerTools!.map((t) => t.id).toList(),
        equals(['anthropic.code_execution_20250825']),
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
