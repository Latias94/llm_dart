import 'dart:typed_data';

import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('AnthropicFiles', () {
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
