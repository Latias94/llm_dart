import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_google/client.dart';
import 'package:test/test.dart';

class _CapturingAdapter implements HttpClientAdapter {
  Uri? lastUri;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastUri = options.uri;

    final body = jsonEncode({
      'file': {
        'name': 'files/123',
        'displayName': 'test.bin',
        'mimeType': 'application/octet-stream',
        'sizeBytes': '3',
        'state': 'ACTIVE',
        'uri': 'https://example.com/files/123',
      },
    });

    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  group('Google upload endpoint', () {
    test('uses host root (not /v1beta) for upload', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash',
      );
      final config = GoogleConfig.fromLLMConfig(llmConfig);
      final client = GoogleClient(config);
      final adapter = _CapturingAdapter();
      client.dio.httpClientAdapter = adapter;

      final chat = GoogleChat(client, config);
      await chat.uploadFile(
        data: [1, 2, 3],
        mimeType: 'application/octet-stream',
        displayName: 'test.bin',
      );

      expect(
        adapter.lastUri.toString(),
        'https://generativelanguage.googleapis.com/upload/v1beta/files?key=test-key',
      );
    });

    test('derives upload host from custom baseUrl', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://proxy.example.com/v1beta/',
        model: 'gemini-1.5-flash',
      );
      final config = GoogleConfig.fromLLMConfig(llmConfig);
      final client = GoogleClient(config);
      final adapter = _CapturingAdapter();
      client.dio.httpClientAdapter = adapter;

      final chat = GoogleChat(client, config);
      await chat.uploadFile(
        data: [1, 2, 3],
        mimeType: 'application/octet-stream',
        displayName: 'test.bin',
      );

      expect(
        adapter.lastUri.toString(),
        'https://proxy.example.com/upload/v1beta/files?key=test-key',
      );
    });
  });
}
