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

    test('enterpriseWebSearch creates ProviderTool with stable id', () {
      final tool = GoogleProviderTools.enterpriseWebSearch();
      expect(tool.id, equals('google.enterprise_web_search'));
      expect(tool.options, equals(const {}));
    });

    test('googleMaps creates ProviderTool with stable id', () {
      final tool = GoogleProviderTools.googleMaps();
      expect(tool.id, equals('google.google_maps'));
      expect(tool.options, equals(const {}));
    });

    test('fileSearch creates ProviderTool with stable id and options', () {
      final tool = GoogleProviderTools.fileSearch(
        fileSearchStoreNames: const ['projects/foo/fileSearchStores/bar'],
        metadataFilter: 'author=Robert Graves',
        topK: 5,
      );
      expect(tool.id, equals('google.file_search'));
      expect(
        tool.options,
        equals({
          'fileSearchStoreNames': ['projects/foo/fileSearchStores/bar'],
          'metadataFilter': 'author=Robert Graves',
          'topK': 5,
        }),
      );
    });

    test('vertexRagStore creates ProviderTool with stable id and options', () {
      final tool = GoogleProviderTools.vertexRagStore(
        ragCorpus: 'projects/p/locations/l/ragCorpora/c',
        topK: 3,
      );
      expect(tool.id, equals('google.vertex_rag_store'));
      expect(
        tool.options,
        equals({
          'ragCorpus': 'projects/p/locations/l/ragCorpora/c',
          'topK': 3,
        }),
      );
    });
  });
}
