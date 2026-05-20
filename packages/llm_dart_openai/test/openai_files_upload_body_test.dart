import 'dart:convert';

import 'package:llm_dart_openai/src/files/openai_files_options.dart';
import 'package:llm_dart_openai/src/files/openai_files_upload_body.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI files upload body projection', () {
    test('maps file upload request to multipart body fields', () {
      final body = buildOpenAIFileUploadBody(
        OpenAIFileUpload(
          bytes: utf8.encode('hello files'),
          filename: 'notes.jsonl',
          purpose: OpenAIFilePurposes.assistants,
          mediaType: 'application/jsonl',
          expiresAfter: 3600,
        ),
      );

      expect(body.contentType, startsWith('multipart/form-data; boundary='));

      final encodedBody = utf8.decode(body.bytes);
      expect(encodedBody, contains('name="file"; filename="notes.jsonl"'));
      expect(encodedBody, contains('Content-Type: application/jsonl'));
      expect(encodedBody, contains('hello files'));
      expect(encodedBody, contains('name="purpose"'));
      expect(encodedBody, contains(OpenAIFilePurposes.assistants));
      expect(encodedBody, contains('name="expires_after"'));
      expect(encodedBody, contains('3600'));
    });

    test('rejects invalid upload requests before transport construction', () {
      expect(
        () => buildOpenAIFileUploadBody(
          const OpenAIFileUpload(
            bytes: [],
            filename: 'notes.jsonl',
            purpose: OpenAIFilePurposes.assistants,
          ),
        ),
        throwsArgumentError,
      );

      expect(
        () => buildOpenAIFileUploadBody(
          OpenAIFileUpload(
            bytes: utf8.encode('hello'),
            filename: 'notes.jsonl',
            purpose: OpenAIFilePurposes.assistants,
            expiresAfter: 0,
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}
