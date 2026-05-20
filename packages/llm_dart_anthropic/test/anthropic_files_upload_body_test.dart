import 'dart:convert';

import 'package:llm_dart_anthropic/src/anthropic_file_types.dart';
import 'package:llm_dart_anthropic/src/anthropic_files_upload_body.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic files upload body projection', () {
    test('maps upload request to multipart body fields', () {
      final body = buildAnthropicFileUploadBody(
        AnthropicFileUpload(
          bytes: utf8.encode('hello files'),
          filename: 'notes.txt',
          mediaType: 'text/plain',
        ),
      );

      expect(body.contentType, startsWith('multipart/form-data; boundary='));

      final encodedBody = utf8.decode(body.bytes);
      expect(encodedBody, contains('name="file"; filename="notes.txt"'));
      expect(encodedBody, contains('Content-Type: text/plain'));
      expect(encodedBody, contains('hello files'));
    });

    test('rejects invalid upload requests before transport construction', () {
      expect(
        () => buildAnthropicFileUploadBody(
          const AnthropicFileUpload(
            bytes: [],
            filename: 'notes.txt',
          ),
        ),
        throwsArgumentError,
      );

      expect(
        () => buildAnthropicFileUploadBody(
          AnthropicFileUpload(
            bytes: utf8.encode('hello'),
            filename: '   ',
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}
