import 'dart:convert';
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
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastUri = options.uri;
    lastHeaders = options.headers.isEmpty
        ? null
        : Map<String, dynamic>.from(options.headers);

    final body = jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': 'ok'},
            ],
          },
          'finishReason': 'STOP',
        },
      ],
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
  group('Google Vertex express API key auth (AI SDK parity)', () {
    test('sends API key via x-goog-api-key header (not query)', () async {
      final config = GoogleConfig(
        providerOptionsName: 'google-vertex',
        providerId: 'google-vertex',
        apiKey: 'test-vertex-key',
        baseUrl: googleVertexBaseUrl,
        model: 'gemini-2.5-pro',
      );

      final client = GoogleClient(config);
      final adapter = _CapturingAdapter();
      client.dio.httpClientAdapter = adapter;

      await client.postJson(
        'models/${config.model}:generateContent',
        const {'contents': []},
      );

      final uri = adapter.lastUri;
      expect(uri, isNotNull);
      expect(uri.toString(),
          'https://aiplatform.googleapis.com/v1/publishers/google/models/${config.model}:generateContent');
      expect(uri!.queryParameters.containsKey('key'), isFalse);

      final headers = adapter.lastHeaders;
      expect(headers, isNotNull);
      final apiKeyHeader = headers!.entries
          .firstWhere(
            (e) => e.key.toLowerCase() == 'x-goog-api-key',
            orElse: () => const MapEntry<String, dynamic>('', null),
          )
          .value;
      expect(apiKeyHeader, equals('test-vertex-key'));
    });
  });

  group('Vertex AI non-express API key auth (best-effort)', () {
    test('still uses x-goog-api-key header with regional baseUrl', () async {
      const fullModelPath =
          'projects/test-project/locations/us-central1/publishers/google/models/gemini-2.5-pro';

      final config = GoogleConfig(
        providerOptionsName: 'google-vertex',
        providerId: 'google-vertex',
        apiKey: 'test-vertex-key',
        baseUrl: 'https://us-central1-aiplatform.googleapis.com/v1/',
        model: fullModelPath,
      );

      final client = GoogleClient(config);
      final adapter = _CapturingAdapter();
      client.dio.httpClientAdapter = adapter;

      await client.postJson(
        '$fullModelPath:generateContent',
        const {'contents': []},
      );

      final uri = adapter.lastUri;
      expect(uri, isNotNull);
      expect(
        uri.toString(),
        'https://us-central1-aiplatform.googleapis.com/v1/$fullModelPath:generateContent',
      );
      expect(uri!.queryParameters.containsKey('key'), isFalse);

      final headers = adapter.lastHeaders;
      expect(headers, isNotNull);
      final apiKeyHeader = headers!.entries
          .firstWhere(
            (e) => e.key.toLowerCase() == 'x-goog-api-key',
            orElse: () => const MapEntry<String, dynamic>('', null),
          )
          .value;
      expect(apiKeyHeader, equals('test-vertex-key'));
    });
  });
}
