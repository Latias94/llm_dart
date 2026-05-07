import 'dart:typed_data';

import 'package:llm_dart/models/file_models.dart';
import 'package:test/test.dart';

void main() {
  group('file models', () {
    test('FileObject exposes provider-neutral JSON', () {
      final file = FileObject(
        id: 'file-123',
        sizeBytes: 1024,
        createdAt: DateTime.parse('2026-04-14T08:00:00.000Z'),
        filename: 'notes.txt',
        purpose: FilePurpose.general,
        status: FileStatus.uploaded,
        mimeType: 'text/plain',
        downloadable: true,
        metadata: const {'provider': 'test'},
      );

      expect(file.toJson(), {
        'id': 'file-123',
        'size_bytes': 1024,
        'created_at': '2026-04-14T08:00:00.000Z',
        'filename': 'notes.txt',
        'object': 'file',
        'purpose': 'general',
        'status': 'uploaded',
        'mime_type': 'text/plain',
        'downloadable': true,
        'metadata': {'provider': 'test'},
      });
      expect(file.toString(), contains('"id":"file-123"'));
    });

    test('request, list response, delete response, and query stay neutral', () {
      final uploadRequest = FileUploadRequest(
        file: Uint8List.fromList([1, 2, 3]),
        filename: 'notes.txt',
        purpose: FilePurpose.general,
      );
      expect(uploadRequest.filename, 'notes.txt');
      expect(uploadRequest.file, [1, 2, 3]);

      final file = FileObject(
        id: 'file-123',
        sizeBytes: 1024,
        createdAt: DateTime.parse('2026-04-14T08:00:00.000Z'),
        filename: 'notes.txt',
      );
      const query = FileListQuery(
        purpose: FilePurpose.general,
        limit: 20,
        beforeId: 'before_1',
        afterId: 'after_1',
      );
      final listResponse = FileListResponse(
        data: [file],
        firstId: 'file-123',
        lastId: 'file-123',
        hasMore: false,
      );
      const deleteResponse = FileDeleteResponse(
        id: 'file-123',
        deleted: true,
      );

      expect(query.limit, 20);
      expect(listResponse.data.single.id, 'file-123');
      expect(listResponse.hasMore, isFalse);
      expect(deleteResponse.deleted, isTrue);
    });
  });
}
