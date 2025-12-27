import 'package:test/test.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

void main() {
  group('ToolNameMapping', () {
    test('should keep function tool names when no collisions', () {
      final mapping = createToolNameMapping(
        functionToolNames: const ['get_weather', 'get_time'],
        providerToolRequestNamesById: const {
          'openai.web_search_preview': 'web_search_preview',
        },
      );

      expect(
          mapping.requestNameForFunction('get_weather'), equals('get_weather'));
      expect(mapping.requestNameForFunction('get_time'), equals('get_time'));
      expect(
        mapping.requestNameForProviderToolId('openai.web_search_preview'),
        equals('web_search_preview'),
      );
    });

    test('should rewrite colliding function tool names', () {
      final mapping = createToolNameMapping(
        functionToolNames: const [
          'web_search_preview',
          'web_search_preview__1'
        ],
        providerToolRequestNamesById: const {
          'openai.web_search_preview': 'web_search_preview',
        },
      );

      expect(
        mapping.requestNameForFunction('web_search_preview'),
        equals('web_search_preview__2'),
      );
      expect(
        mapping.requestNameForFunction('web_search_preview__1'),
        equals('web_search_preview__1'),
      );

      expect(
        mapping.originalFunctionNameForRequestName('web_search_preview__2'),
        equals('web_search_preview'),
      );
      expect(
        mapping.providerToolIdForRequestName('web_search_preview'),
        equals('openai.web_search_preview'),
      );
    });
  });
}
