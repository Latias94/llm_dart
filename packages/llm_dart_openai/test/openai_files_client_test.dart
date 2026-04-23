import 'dart:convert';
import 'dart:typed_data';

import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIFilesClient', () {
    test('uploadFile sends multipart request with configured headers',
        () async {
      TransportRequest? capturedRequest;

      final files = OpenAI(
        apiKey: 'test-key',
        transport: FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: _fileJson(
                id: 'file_123',
                filename: 'notes.jsonl',
                purpose: OpenAIFilePurposes.assistants,
                bytes: 11,
              ),
            );
          },
        ),
      ).files(
        settings: const OpenAIFilesSettings(
          organization: 'org_123',
          project: 'proj_456',
          headers: {
            'x-settings': '1',
          },
        ),
      );

      final uploaded = await files.uploadFile(
        OpenAIFileUpload(
          bytes: utf8.encode('hello files'),
          filename: 'notes.jsonl',
          purpose: OpenAIFilePurposes.assistants,
          mediaType: 'application/jsonl',
        ),
        timeout: const Duration(seconds: 5),
        headers: const {
          'x-call': '2',
        },
      );

      expect(capturedRequest, isNotNull);
      expect(
          capturedRequest!.uri.toString(), 'https://api.openai.com/v1/files');
      expect(capturedRequest!.method, TransportMethod.post);
      expect(capturedRequest!.responseType, TransportResponseType.json);
      expect(capturedRequest!.timeout, const Duration(seconds: 5));
      expect(
        capturedRequest!.headers,
        containsPair('authorization', 'Bearer test-key'),
      );
      expect(
        capturedRequest!.headers,
        containsPair('openai-organization', 'org_123'),
      );
      expect(
        capturedRequest!.headers,
        containsPair('openai-project', 'proj_456'),
      );
      expect(
          capturedRequest!.headers, containsPair('accept', 'application/json'));
      expect(capturedRequest!.headers, containsPair('x-settings', '1'));
      expect(capturedRequest!.headers, containsPair('x-call', '2'));
      expect(
        capturedRequest!.headers['content-type'],
        startsWith('multipart/form-data; boundary='),
      );

      final body = utf8.decode(capturedRequest!.body! as List<int>);
      expect(body, contains('name="file"; filename="notes.jsonl"'));
      expect(body, contains('Content-Type: application/jsonl'));
      expect(body, contains('hello files'));
      expect(body, contains('name="purpose"'));
      expect(body, contains(OpenAIFilePurposes.assistants));

      expect(uploaded.id, 'file_123');
      expect(uploaded.filename, 'notes.jsonl');
      expect(uploaded.purpose, OpenAIFilePurposes.assistants);
      expect(uploaded.sizeBytes, 11);
    });

    test('list retrieve download and delete use file endpoints', () async {
      final requests = <TransportRequest>[];
      var callCount = 0;

      final files = OpenAI(
        apiKey: 'test-key',
        transport: FakeTransportClient(
          onSend: (request) async {
            requests.add(request);
            callCount += 1;

            return switch (callCount) {
              1 => TransportResponse(
                  statusCode: 200,
                  body: {
                    'object': 'list',
                    'data': [
                      _fileJson(
                        id: 'file_123',
                        filename: 'notes.jsonl',
                        purpose: OpenAIFilePurposes.assistants,
                        bytes: 11,
                      ),
                    ],
                    'first_id': 'file_123',
                    'last_id': 'file_123',
                    'has_more': false,
                  },
                ),
              2 => TransportResponse(
                  statusCode: 200,
                  body: _fileJson(
                    id: 'file_123',
                    filename: 'notes.jsonl',
                    purpose: OpenAIFilePurposes.assistants,
                    bytes: 11,
                    expiresAt: 1710003600,
                  ),
                ),
              3 => TransportResponse(
                  statusCode: 200,
                  headers: const {
                    'content-type': 'text/plain',
                  },
                  body: Uint8List.fromList(utf8.encode('downloaded')),
                ),
              4 => const TransportResponse(
                  statusCode: 200,
                  body: {
                    'id': 'file_123',
                    'object': 'file',
                    'deleted': true,
                  },
                ),
              _ => throw StateError('Unexpected request $callCount'),
            };
          },
        ),
      ).files();

      final listed = await files.listFiles(
        purpose: OpenAIFilePurposes.assistants,
        limit: 20,
        order: 'desc',
        after: 'file_before',
      );
      final retrieved = await files.retrieveFile('file_123');
      final downloaded = await files.downloadFile('file_123');
      final deleted = await files.deleteFile('file_123');

      expect(requests, hasLength(4));
      expect(requests[0].method, TransportMethod.get);
      expect(requests[0].uri.path, '/v1/files');
      expect(requests[0].uri.queryParameters, {
        'purpose': OpenAIFilePurposes.assistants,
        'limit': '20',
        'order': 'desc',
        'after': 'file_before',
      });
      expect(requests[1].uri.toString(),
          'https://api.openai.com/v1/files/file_123');
      expect(requests[2].uri.toString(),
          'https://api.openai.com/v1/files/file_123/content');
      expect(requests[2].responseType, TransportResponseType.bytes);
      expect(requests[3].method, TransportMethod.delete);
      expect(requests[3].uri.toString(),
          'https://api.openai.com/v1/files/file_123');

      expect(listed.data.single.id, 'file_123');
      expect(listed.firstId, 'file_123');
      expect(listed.hasMore, isFalse);
      expect(
          retrieved.expiresAt,
          DateTime.fromMillisecondsSinceEpoch(
            1710003600 * 1000,
            isUtc: true,
          ));
      expect(downloaded.contentType, 'text/plain');
      expect(downloaded.text(), 'downloaded');
      expect(deleted.deleted, isTrue);
    });

    test('rejects invalid uploads and non-openai profiles', () async {
      final files = OpenAI(apiKey: 'test-key').files();

      await expectLater(
        files.uploadFile(
          const OpenAIFileUpload(
            bytes: [],
            filename: 'empty.txt',
            purpose: OpenAIFilePurposes.assistants,
          ),
        ),
        throwsArgumentError,
      );

      expect(
        () => OpenAI(
          apiKey: 'test-key',
          profile: const XAIProfile(),
        ).files(),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            contains('supports only the OpenAI profile'),
          ),
        ),
      );
    });
  });
}

Map<String, Object?> _fileJson({
  required String id,
  required String filename,
  required String purpose,
  required int bytes,
  int createdAt = 1710000000,
  int? expiresAt,
}) {
  return {
    'id': id,
    'object': 'file',
    'bytes': bytes,
    'created_at': createdAt,
    'filename': filename,
    'purpose': purpose,
    'status': 'processed',
    'status_details': null,
    if (expiresAt != null) 'expires_at': expiresAt,
  };
}
