import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_google/client.dart';
import 'package:test/test.dart';

class _CapturingAdapter implements HttpClientAdapter {
  Uri? lastUri;
  Map<String, dynamic>? lastHeaders;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastUri = options.uri;
    lastHeaders = options.headers.isEmpty ? null : Map<String, dynamic>.from(options.headers);

    return ResponseBody(
      Stream<Uint8List>.empty(),
      200,
      headers: {
        Headers.contentTypeHeader: ['text/event-stream'],
      },
    );
  }
}

void main() {
  group('Google streaming endpoint (AI SDK parity)', () {
    test('uses alt=sse for streamGenerateContent', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-2.5-flash',
      );
      final config = GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);

      final client = GoogleClient(config);
      final adapter = _CapturingAdapter();
      client.dio.httpClientAdapter = adapter;

      // Trigger a streaming request (we don't care about the body).
      await client
          .postStreamRaw(
            'models/${config.model}:streamGenerateContent?alt=sse',
            const {},
          )
          .drain<void>();

      expect(
        adapter.lastUri.toString(),
        'https://generativelanguage.googleapis.com/v1beta/models/${config.model}:streamGenerateContent?alt=sse&key=test-key',
      );

      final accept = adapter.lastHeaders?.entries
          .firstWhere(
            (e) => e.key.toLowerCase() == 'accept',
            orElse: () => const MapEntry<String, dynamic>('', null),
          )
          .value;
      expect(accept, equals('text/event-stream'));
    });
  });
}
