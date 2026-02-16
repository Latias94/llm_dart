import 'package:llm_dart_groq/provider_tools.dart';
import 'package:test/test.dart';

void main() {
  group('GroqProviderTools', () {
    test('browserSearch creates ProviderTool with stable id', () {
      final tool = GroqProviderTools.browserSearch();

      expect(tool.id, equals('groq.browser_search'));
      expect(tool.name, equals('browser_search'));
    });
  });
}
