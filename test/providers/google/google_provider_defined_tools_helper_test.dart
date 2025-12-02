import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Google provider-defined tools helpers', () {
    test('googleSearch() creates google.google_search spec', () {
      final factory = createGoogleGenerativeAI(apiKey: 'test-key');

      final spec = factory.providerTools.googleSearch(
        mode: 'MODE_DYNAMIC',
        dynamicThreshold: 1.0,
      );

      expect(spec.id, equals('google.google_search'));
      expect(spec.args['mode'], equals('MODE_DYNAMIC'));
      expect(spec.args['dynamicThreshold'], equals(1.0));
    });

    test('urlContext() creates google.url_context spec without args', () {
      final factory = createGoogleGenerativeAI(apiKey: 'test-key');

      final spec = factory.providerTools.urlContext();

      expect(spec.id, equals('google.url_context'));
      expect(spec.args, isEmpty);
    });

    test('fileSearch() creates google.file_search spec with args', () {
      final factory = createGoogleGenerativeAI(apiKey: 'test-key');

      final spec = factory.providerTools.fileSearch(
        fileSearchStoreNames: const ['fileSearchStores/my-store'],
        topK: 8,
        metadataFilter: 'doc.author = "alice"',
      );

      expect(spec.id, equals('google.file_search'));
      expect(
        spec.args['fileSearchStoreNames'],
        equals(['fileSearchStores/my-store']),
      );
      expect(spec.args['topK'], equals(8));
      expect(spec.args['metadataFilter'], equals('doc.author = "alice"'));
    });

    test('codeExecution() creates google.code_execution spec', () {
      final factory = createGoogleGenerativeAI(apiKey: 'test-key');

      final spec = factory.providerTools.codeExecution();

      expect(spec.id, equals('google.code_execution'));
      expect(spec.args, isEmpty);
    });

    test('vertexRagStore() creates google.vertex_rag_store spec', () {
      final factory = createGoogleGenerativeAI(apiKey: 'test-key');

      final spec = factory.providerTools.vertexRagStore(
        ragCorpus: 'projects/p/locations/l/ragCorpora/corpus-1',
        topK: 5,
      );

      expect(spec.id, equals('google.vertex_rag_store'));
      expect(
        spec.args['ragCorpus'],
        equals('projects/p/locations/l/ragCorpora/corpus-1'),
      );
      expect(spec.args['topK'], equals(5));
    });
  });
}

