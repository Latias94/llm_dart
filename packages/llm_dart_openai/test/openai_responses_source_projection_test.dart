import 'package:llm_dart_openai/src/responses/openai_responses_source_projection.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI Responses source projection', () {
    test('projects URL citations', () {
      final source = decodeOpenAIResponsesSourceAnnotation({
        'type': 'url_citation',
        'url': 'https://example.com',
        'title': 'Example',
        'start_index': 4,
        'end_index': 12,
      });

      expect(source, isNotNull);
      expect(source!.kind, SourceReferenceKind.url);
      expect(source.sourceId, 'https://example.com');
      expect(source.uri, Uri.parse('https://example.com'));
      expect(source.title, 'Example');
      expect(source.providerMetadata?['openai'], {
        'annotationType': 'url_citation',
        'startIndex': 4,
        'endIndex': 12,
      });
      expect(
        openAIResponsesAnnotationKey({
          'type': 'url_citation',
          'url': 'https://example.com',
          'start_index': 4,
          'end_index': 12,
        }),
        'url:https://example.com:4:12',
      );
    });

    test('projects file and container citations as document sources', () {
      final fileSource = decodeOpenAIResponsesSourceAnnotation({
        'type': 'file_citation',
        'file_id': 'file_1',
        'filename': 'resource.txt',
        'index': 7,
      });
      final containerSource = decodeOpenAIResponsesSourceAnnotation({
        'type': 'container_file_citation',
        'container_id': 'cntr_1',
        'file_id': 'cfile_1',
        'filename': 'data.csv',
      });

      expect(fileSource, isNotNull);
      expect(fileSource!.kind, SourceReferenceKind.document);
      expect(fileSource.sourceId, 'file_1');
      expect(fileSource.filename, 'resource.txt');
      expect(fileSource.mediaType, 'text/plain');
      expect(fileSource.providerMetadata?['openai'], {
        'annotationType': 'file_citation',
        'fileId': 'file_1',
        'index': 7,
      });

      expect(containerSource, isNotNull);
      expect(containerSource!.kind, SourceReferenceKind.document);
      expect(containerSource.sourceId, 'cfile_1');
      expect(containerSource.filename, 'data.csv');
      expect(containerSource.providerMetadata?['openai'], {
        'annotationType': 'container_file_citation',
        'fileId': 'cfile_1',
        'containerId': 'cntr_1',
      });
    });

    test('projects file paths and deduplicates stream source events', () {
      final emittedKeys = <String>{};
      final annotation = {
        'type': 'file_path',
        'file_id': 'file_path_1',
        'index': 3,
      };

      final firstEvent = decodeOpenAIResponsesSourceEvent(
        annotation,
        emittedAnnotationKeys: emittedKeys,
      );
      final secondEvent = decodeOpenAIResponsesSourceEvent(
        annotation,
        emittedAnnotationKeys: emittedKeys,
      );

      expect(firstEvent, isNotNull);
      expect(firstEvent!.source.kind, SourceReferenceKind.document);
      expect(firstEvent.source.sourceId, 'file_path_1');
      expect(firstEvent.source.mediaType, 'application/octet-stream');
      expect(firstEvent.source.providerMetadata?['openai'], {
        'annotationType': 'file_path',
        'fileId': 'file_path_1',
        'index': 3,
      });
      expect(secondEvent, isNull);
      expect(emittedKeys, {'file_path:file_path_1:3'});
    });
  });
}
