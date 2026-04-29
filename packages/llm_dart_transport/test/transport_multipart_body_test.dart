import 'dart:convert';

import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  test('buildTransportMultipartBody encodes text and file fields', () {
    final body = buildTransportMultipartBody(
      boundary: 'test-boundary',
      fields: [
        TransportMultipartField.text(
          name: 'purpose',
          value: 'assistants',
        ),
        TransportMultipartField.file(
          name: 'file',
          filename: 'notes.txt',
          mediaType: 'text/plain',
          bytes: utf8.encode('hello'),
        ),
      ],
    );

    expect(body.contentType, 'multipart/form-data; boundary=test-boundary');

    final text = utf8.decode(body.bytes);
    expect(text, contains('--test-boundary'));
    expect(text, contains('name="purpose"'));
    expect(text, contains('assistants'));
    expect(text, contains('name="file"; filename="notes.txt"'));
    expect(text, contains('Content-Type: text/plain'));
    expect(text, contains('hello'));
    expect(text, endsWith('--test-boundary--\r\n'));
  });
}
