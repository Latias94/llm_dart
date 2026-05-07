import 'package:llm_dart/models/file_models.dart';
import 'package:llm_dart/src/compatibility/providers/anthropic/anthropic_file_codec.dart';
import 'package:test/test.dart';

void main() {
  group('AnthropicFileCodec', () {
    const codec = AnthropicFileCodec();

    test('maps Anthropic file payloads to unified file objects', () {
      final file = codec.fileFromJson({
        'id': 'file_123',
        'filename': 'notes.txt',
        'mime_type': 'text/plain',
        'size_bytes': 42,
        'created_at': '2026-04-14T08:00:00.000Z',
        'downloadable': true,
        'type': 'file',
      });

      expect(file.id, 'file_123');
      expect(file.filename, 'notes.txt');
      expect(file.mimeType, 'text/plain');
      expect(file.sizeBytes, 42);
      expect(file.downloadable, isTrue);
      expect(file.metadata, {'provider': 'anthropic'});
      expect(codec.fileToJson(file), {
        'id': 'file_123',
        'size_bytes': 42,
        'created_at': '2026-04-14T08:00:00.000Z',
        'filename': 'notes.txt',
        'type': 'file',
        'mime_type': 'text/plain',
        'downloadable': true,
      });
    });

    test('maps list responses and query parameters', () {
      final response = codec.fileListFromJson({
        'data': [
          {
            'id': 'file_123',
            'filename': 'notes.txt',
            'mime_type': 'text/plain',
            'size_bytes': 42,
            'created_at': '2026-04-14T08:00:00.000Z',
          },
        ],
        'first_id': 'file_123',
        'last_id': 'file_123',
        'has_more': false,
      });

      expect(response.data.single.id, 'file_123');
      expect(response.firstId, 'file_123');
      expect(response.hasMore, isFalse);
      expect(codec.fileListToJson(response)['first_id'], 'file_123');

      expect(
        codec.queryParameters(const FileListQuery(
          beforeId: 'before_1',
          afterId: 'after_1',
          limit: 20,
        )),
        {
          'before_id': 'before_1',
          'after_id': 'after_1',
          'limit': '20',
        },
      );
    });
  });
}
