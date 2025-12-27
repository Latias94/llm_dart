import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIProviderTools', () {
    test('webSearch creates ProviderTool with stable id', () {
      final tool = OpenAIProviderTools.webSearch(
          contextSize: OpenAIWebSearchContextSize.high);

      expect(tool.id, equals('openai.web_search_preview'));
      expect(tool.options['search_context_size'], equals('high'));
    });

    test('fileSearch creates ProviderTool with stable id', () {
      final tool = OpenAIProviderTools.fileSearch(
        vectorStoreIds: const ['vs_123'],
        parameters: const {'max_num_results': 5},
      );

      expect(tool.id, equals('openai.file_search'));
      expect(tool.options['vector_store_ids'], equals(['vs_123']));
      expect(tool.options['max_num_results'], equals(5));
    });

    test('computerUse creates ProviderTool with stable id', () {
      final tool = OpenAIProviderTools.computerUse(
        displayWidth: 1024,
        displayHeight: 768,
        environment: 'browser',
        parameters: const {'timeout': 30},
      );

      expect(tool.id, equals('openai.computer_use_preview'));
      expect(tool.options['display_width'], equals(1024));
      expect(tool.options['display_height'], equals(768));
      expect(tool.options['environment'], equals('browser'));
      expect(tool.options['timeout'], equals(30));
    });
  });
}
