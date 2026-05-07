import 'dart:typed_data';

import 'package:llm_dart/models/file_models.dart';
import 'package:llm_dart/src/compatibility/providers/openai/openai_file_codec.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIFileCodec', () {
    const codec = OpenAIFileCodec();

    test('maps OpenAI file payloads to unified file objects', () {
      final file = codec.fileFromJson({
        'id': 'file-123',
        'bytes': 1024,
        'created_at': 1234567890,
        'filename': 'test.txt',
        'object': 'file',
        'purpose': 'assistants',
        'status': 'uploaded',
        'status_details': 'File uploaded successfully',
      });

      expect(file.id, 'file-123');
      expect(file.sizeBytes, 1024);
      expect(file.purpose, FilePurpose.assistants);
      expect(file.status, FileStatus.uploaded);
      expect(file.metadata, {'provider': 'openai'});
      expect(codec.fileToJson(file), {
        'id': 'file-123',
        'bytes': 1024,
        'created_at': 1234567890,
        'filename': 'test.txt',
        'object': 'file',
        'purpose': 'assistants',
        'status': 'uploaded',
        'status_details': 'File uploaded successfully',
      });
    });

    test('maps upload requests, list responses, delete responses, and queries',
        () {
      final uploadRequest = FileUploadRequest(
        file: Uint8List.fromList([1, 2, 3]),
        filename: 'test.txt',
        purpose: FilePurpose.assistants,
      );
      expect(codec.uploadRequestToJson(uploadRequest), {
        'filename': 'test.txt',
        'purpose': 'assistants',
      });

      final listResponse = codec.fileListFromJson({
        'object': 'list',
        'data': [
          {
            'id': 'file-123',
            'bytes': 1024,
            'created_at': 1234567890,
            'filename': 'test.txt',
            'object': 'file',
          },
        ],
        'total': 1,
        'limit': 20,
        'offset': 0,
      });
      expect(listResponse.data.single.id, 'file-123');
      expect(listResponse.total, 1);
      expect(codec.fileListToJson(listResponse)['total'], 1);

      final deleteResponse = codec.deleteResponseFromJson({
        'id': 'file-123',
        'object': 'file',
        'deleted': true,
      });
      expect(deleteResponse.deleted, isTrue);
      expect(codec.deleteResponseToJson(deleteResponse), {
        'id': 'file-123',
        'object': 'file',
        'deleted': true,
      });

      expect(
        codec.queryParameters(const FileListQuery(
          purpose: FilePurpose.assistants,
          limit: 20,
          order: 'desc',
          after: 'file-1',
        )),
        {
          'purpose': 'assistants',
          'limit': 20,
          'order': 'desc',
          'after': 'file-1',
        },
      );
    });
  });
}
