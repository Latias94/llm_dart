import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Google tools facade', () {
    test('webSearch() exposes a unified schema', () {
      final factory = createGoogleGenerativeAI(apiKey: 'test-key');

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

    test('urlContext() exposes an empty-args schema', () {
      final factory = createGoogleGenerativeAI(apiKey: 'test-key');

      final tool = factory.tools.urlContext();

      expect(tool.toolType, equals('function'));
      expect(tool.function.name, equals('url_context'));

      final params = tool.function.parameters;
      expect(params.schemaType, equals('object'));
      expect(params.properties, isEmpty);
      expect(params.required, isEmpty);
    });

    test('fileSearch() exposes File Search schema', () {
      final factory = createGoogleGenerativeAI(apiKey: 'test-key');

      final tool = factory.tools.fileSearch();

      expect(tool.toolType, equals('function'));
      expect(tool.function.name, equals('file_search'));

      final params = tool.function.parameters;
      expect(params.schemaType, equals('object'));
      expect(params.properties.containsKey('fileSearchStoreNames'), isTrue);
      expect(params.properties.containsKey('topK'), isTrue);
      expect(params.properties.containsKey('metadataFilter'), isTrue);

      final stores = params.properties['fileSearchStoreNames']!;
      expect(stores.propertyType, equals('array'));
      expect(stores.items, isNotNull);
      expect(stores.items!.propertyType, equals('string'));
      expect(params.required, contains('fileSearchStoreNames'));
    });

    test('codeExecution() exposes code execution schema', () {
      final factory = createGoogleGenerativeAI(apiKey: 'test-key');

      final tool = factory.tools.codeExecution();

      expect(tool.toolType, equals('function'));
      expect(tool.function.name, equals('code_execution'));

      final params = tool.function.parameters;
      expect(params.properties.containsKey('language'), isTrue);
      expect(params.properties.containsKey('code'), isTrue);
      expect(params.required, containsAll(<String>['language', 'code']));
    });

    test('vertexRagStore() exposes Vertex RAG Store schema', () {
      final factory = createGoogleGenerativeAI(apiKey: 'test-key');

      final tool = factory.tools.vertexRagStore();

      expect(tool.toolType, equals('function'));
      expect(tool.function.name, equals('vertex_rag_store'));

      final params = tool.function.parameters;
      expect(params.properties.containsKey('ragCorpus'), isTrue);
      expect(params.properties.containsKey('topK'), isTrue);
      expect(params.required, contains('ragCorpus'));
    });

    test('webSearchTool reuses webSearch schema', () {
      final factory = createGoogleGenerativeAI(apiKey: 'test-key');

      final schema = factory.tools.webSearch();
      final executable = factory.webSearchTool(
        modelId: 'gemini-1.5-flash',
      );

      expect(executable.schema.toolType, equals(schema.toolType));
      expect(executable.schema.function.name, equals(schema.function.name));
      expect(
        executable.schema.function.parameters.toJson(),
        equals(schema.function.parameters.toJson()),
      );
    });
  });
}
