import 'package:llm_dart/llm_dart.dart';
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
