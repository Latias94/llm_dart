import 'package:llm_dart_anthropic/src/anthropic_files_route_support.dart';
import 'package:test/test.dart';

void main() {
  group('AnthropicFilesRouteSupport', () {
    const routes = AnthropicFilesRouteSupport(
      baseUrl: 'https://api.anthropic.com/v1',
    );

    test('builds list, item, and content routes', () {
      expect(routes.filesUri.toString(), 'https://api.anthropic.com/v1/files');
      expect(
        routes
            .fileListUri(
              beforeId: 'file before',
              afterId: 'file after',
              limit: 20,
            )
            .toString(),
        'https://api.anthropic.com/v1/files?before_id=file+before&after_id=file+after&limit=20',
      );
      expect(
        routes.fileUri(' file_123 ').toString(),
        'https://api.anthropic.com/v1/files/file_123',
      );
      expect(
        routes.fileContentUri(' file_123 ').toString(),
        'https://api.anthropic.com/v1/files/file_123/content',
      );
    });

    test('rejects invalid route parameters', () {
      expect(
        () => routes.fileListUri(limit: 0),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'limit',
          ),
        ),
      );
      expect(
        () => routes.fileUri('  '),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'fileId',
          ),
        ),
      );
    });
  });
}
