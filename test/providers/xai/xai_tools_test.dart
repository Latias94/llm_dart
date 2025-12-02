import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('XAI tools facade', () {
    test('webSearch() exposes a unified schema', () {
      final factory = createXAI(apiKey: 'test-key');

      final tool = factory.tools.webSearch();

      expect(tool.toolType, equals('function'));
      expect(tool.function.name, equals('web_search'));

      final params = tool.function.parameters;
      expect(params.schemaType, equals('object'));
      expect(params.properties.containsKey('query'), isTrue);

      final queryParam = params.properties['query']!;
      expect(queryParam.propertyType, equals('string'));
      expect(queryParam.description, contains('Search query'));
    });
  });
}

