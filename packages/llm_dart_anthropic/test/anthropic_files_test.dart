import 'dart:typed_data';

import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('AnthropicFiles', () {
    test('uploadFile sends multipart request and parses descriptor', () async {
      TransportRequest? capturedRequest;

      final files = Anthropic(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'id': 'file_upload',
                'type': 'file',
                'filename': 'notes.txt',
                'mime_type': 'text/plain',
                'size_bytes': 11,
                'created_at': '2026-03-29T09:00:00Z',
                'downloadable': true,
              },
            );
          },
        ),
      ).files();

      final descriptor = await files.uploadFile(
        const AnthropicFileUpload(
          bytes: [104, 101, 108, 108, 111],
          filename: 'notes.txt',
          mediaType: 'text/plain',
        ),
        timeout: const Duration(seconds: 5),
        headers: const {
          'x-call': '2',
        },
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.uri.toString(),
          'https://api.anthropic.com/v1/files');
      expect(capturedRequest!.method, TransportMethod.post);
      expect(capturedRequest!.responseType, TransportResponseType.json);
      expect(capturedRequest!.timeout, const Duration(seconds: 5));
      expect(capturedRequest!.headers['x-api-key'], 'test-key');
      expect(capturedRequest!.headers['accept'], 'application/json');
      expect(capturedRequest!.headers['x-call'], '2');
      expect(capturedRequest!.headers['content-type'],
          startsWith('multipart/form-data; boundary='));
      expect(
        capturedRequest!.headers['anthropic-beta']!.split(','),
        ['files-api-2025-04-14'],
      );

      final body = String.fromCharCodes(capturedRequest!.body! as List<int>);
      expect(body, contains('name="file"; filename="notes.txt"'));
      expect(body, contains('Content-Type: text/plain'));
      expect(body, contains('hello'));

      expect(descriptor.id, 'file_upload');
      expect(descriptor.filename, 'notes.txt');
      expect(descriptor.mimeType, 'text/plain');
    });

    test('listFiles and deleteFile use modern files endpoints', () async {
      final requests = <TransportRequest>[];
      var callCount = 0;

      final files = Anthropic(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            requests.add(request);
            callCount += 1;

            if (callCount == 1) {
              return const TransportResponse(
                statusCode: 200,
                body: {
                  'data': [
                    {
                      'id': 'file_123',
                      'type': 'file',
                      'filename': 'report.csv',
                      'mime_type': 'text/csv',
                      'size_bytes': 321,
                      'created_at': '2026-03-29T10:00:00Z',
                      'downloadable': true,
                    },
                  ],
                  'first_id': 'file_123',
                  'last_id': 'file_123',
                  'has_more': false,
                },
              );
            }

            return const TransportResponse(
              statusCode: 200,
              body: '',
            );
          },
        ),
      ).files();

      final listed = await files.listFiles(
        beforeId: 'file_before',
        afterId: 'file_after',
        limit: 20,
      );
      final deleted = await files.deleteFile('file_123');

      expect(requests, hasLength(2));
      expect(requests[0].method, TransportMethod.get);
      expect(requests[0].uri.path, '/v1/files');
      expect(requests[0].uri.queryParameters, {
        'before_id': 'file_before',
        'after_id': 'file_after',
        'limit': '20',
      });
      expect(requests[0].responseType, TransportResponseType.json);
      expect(requests[1].method, TransportMethod.delete);
      expect(
        requests[1].uri.toString(),
        'https://api.anthropic.com/v1/files/file_123',
      );
      expect(requests[1].responseType, TransportResponseType.plainText);

      expect(listed.data.single.id, 'file_123');
      expect(listed.firstId, 'file_123');
      expect(listed.hasMore, isFalse);
      expect(deleted.id, 'file_123');
      expect(deleted.deleted, isTrue);
    });

    test('getFile sends files beta headers and parses metadata', () async {
      TransportRequest? capturedRequest;

      final files = Anthropic(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'id': 'file_123',
                'type': 'file',
                'filename': 'report.csv',
                'mime_type': 'text/csv',
                'size_bytes': 321,
                'created_at': '2026-03-29T10:00:00Z',
                'downloadable': true,
              },
            );
          },
        ),
      ).files(
        settings: const AnthropicFilesSettings(
          headers: {
            'anthropic-beta': 'custom-beta',
            'x-settings': '1',
          },
          betaFeatures: ['secondary-beta'],
        ),
      );

      final descriptor = await files.getFile(
        'file_123',
        timeout: const Duration(seconds: 5),
        headers: const {
          'anthropic-beta': 'runtime-beta',
          'x-call': '2',
        },
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.uri.toString(),
        'https://api.anthropic.com/v1/files/file_123',
      );
      expect(capturedRequest!.method, TransportMethod.get);
      expect(capturedRequest!.responseType, TransportResponseType.json);
      expect(capturedRequest!.timeout, const Duration(seconds: 5));
      expect(capturedRequest!.headers['x-api-key'], 'test-key');
      expect(capturedRequest!.headers['anthropic-version'], '2023-06-01');
      expect(capturedRequest!.headers['accept'], 'application/json');
      expect(capturedRequest!.headers.containsKey('content-type'), isFalse);
      expect(capturedRequest!.headers['x-settings'], '1');
      expect(capturedRequest!.headers['x-call'], '2');
      expect(
        capturedRequest!.headers['anthropic-beta']!.split(','),
        [
          'custom-beta',
          'files-api-2025-04-14',
          'runtime-beta',
          'secondary-beta',
        ],
      );

      expect(descriptor.id, 'file_123');
      expect(descriptor.type, 'file');
      expect(descriptor.filename, 'report.csv');
      expect(descriptor.mimeType, 'text/csv');
      expect(descriptor.sizeBytes, 321);
      expect(
        descriptor.createdAt,
        DateTime.parse('2026-03-29T10:00:00Z'),
      );
      expect(descriptor.downloadable, isTrue);
    });

    test(
        'execution file handles can resolve metadata and download bytes through files API',
        () async {
      final requests = <TransportRequest>[];

      final anthropic = Anthropic(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            requests.add(request);

            if (request.uri.path.endsWith('/content')) {
              return TransportResponse(
                statusCode: 200,
                headers: const {
                  'content-type': 'application/octet-stream',
                },
                body: Uint8List.fromList([1, 2, 3]),
              );
            }

            return const TransportResponse(
              statusCode: 200,
              body: {
                'id': 'file_456',
                'type': 'file',
                'filename': 'plot.png',
                'mime_type': 'image/png',
                'size_bytes': 3,
                'created_at': '2026-03-29T12:00:00Z',
                'downloadable': true,
              },
            );
          },
        ),
      );

      final replay = AnthropicCodeExecutionReplay.fromJson({
        'schema': AnthropicCodeExecutionReplay.schema,
        'replayRole': 'tool',
        'toolCallId': 'srvtoolu_1',
        'toolName': AnthropicCodeExecutionReplay.canonicalToolName,
        'blockType': 'bash_code_execution_tool_result',
        'block': {
          'type': 'bash_code_execution_tool_result',
          'tool_use_id': 'srvtoolu_1',
          'content': {
            'type': 'bash_code_execution_result',
            'stdout': 'done',
            'stderr': '',
            'return_code': 0,
            'content': [
              {
                'type': 'bash_code_execution_output',
                'file_id': 'file_456',
              },
            ],
          },
        },
      });

      final handle = replay.fileHandles.single;
      final files = anthropic.files(
        settings: const AnthropicFilesSettings(
          betaFeatures: ['custom-files-beta'],
        ),
      );

      final descriptor = await handle.getMetadata(files);
      final download = await handle.download(
        files,
        headers: const {
          'x-download': '1',
        },
      );

      expect(handle.fileId, 'file_456');
      expect(descriptor.filename, 'plot.png');
      expect(descriptor.mimeType, 'image/png');
      expect(download.fileId, 'file_456');
      expect(download.bytes.toList(), [1, 2, 3]);
      expect(download.contentType, 'application/octet-stream');

      expect(requests, hasLength(2));
      expect(
        requests[0].uri.toString(),
        'https://api.anthropic.com/v1/files/file_456',
      );
      expect(requests[0].responseType, TransportResponseType.json);
      expect(
        requests[0].headers['anthropic-beta']!.split(','),
        [
          'custom-files-beta',
          'files-api-2025-04-14',
        ],
      );

      expect(
        requests[1].uri.toString(),
        'https://api.anthropic.com/v1/files/file_456/content',
      );
      expect(requests[1].responseType, TransportResponseType.bytes);
      expect(requests[1].headers['x-download'], '1');
      expect(
        requests[1].headers['anthropic-beta']!.split(','),
        [
          'custom-files-beta',
          'files-api-2025-04-14',
        ],
      );
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;
