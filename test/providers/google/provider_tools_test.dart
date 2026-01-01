import 'package:llm_dart_google/provider_tools.dart';
import 'package:llm_dart_google/web_search_tool_options.dart';
import 'package:test/test.dart';

void main() {
  group('GoogleProviderTools', () {
    test('webSearch creates ProviderTool with stable id', () {
      final tool = GoogleProviderTools.webSearch(
        options: const GoogleWebSearchToolOptions(
          mode: GoogleDynamicRetrievalMode.dynamic,
          dynamicThreshold: 0.5,
        ),
      );

      expect(tool.id, equals('google.google_search'));
      expect(tool.options['mode'], equals('MODE_DYNAMIC'));
      expect(tool.options['dynamicThreshold'], equals(0.5));
      expect(tool.options['enabled'], isTrue);
    });
  });
}
