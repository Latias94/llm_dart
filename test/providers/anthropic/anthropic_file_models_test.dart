import 'dart:typed_data';

import 'package:llm_dart/providers/anthropic/files.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic file models extraction', () {
    test('keeps file model JSON round-trip on the legacy files export path',
        () {
      final file = AnthropicFile.fromJson({
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
      expect(file.toJson(), {
        'id': 'file_123',
        'filename': 'notes.txt',
        'mime_type': 'text/plain',
        'size_bytes': 42,
        'created_at': '2026-04-14T08:00:00.000Z',
        'downloadable': true,
        'type': 'file',
      });
    });

    test('keeps file list response and query helpers unchanged', () {
      final response = AnthropicFileListResponse.fromJson({
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
      expect(response.data.single.downloadable, isFalse);
      expect(response.toJson()['first_id'], 'file_123');
      expect(response.toJson()['has_more'], isFalse);

      const query = AnthropicFileListQuery(
        beforeId: 'before_1',
        afterId: 'after_1',
        limit: 20,
      );
      expect(query.toQueryParams(), {
        'before_id': 'before_1',
        'after_id': 'after_1',
        'limit': '20',
      });
    });

    test('keeps upload request data model available from files export', () {
      final request = AnthropicFileUploadRequest(
        file: Uint8List.fromList([1, 2, 3]),
        filename: 'payload.bin',
      );

      expect(request.file, [1, 2, 3]);
      expect(request.filename, 'payload.bin');
    });
  });
}
