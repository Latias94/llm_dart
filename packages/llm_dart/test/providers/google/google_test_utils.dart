import 'package:dio/dio.dart';
import 'package:llm_dart_google/testing.dart';

/// Capturing Google client used in tests to inspect request payloads.
class CapturingGoogleClient extends GoogleClient {
  Map<String, dynamic>? lastRequestBody;
  String? lastEndpoint;
  Map<String, String>? lastHeaders;

  CapturingGoogleClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) async {
    lastEndpoint = endpoint;
    lastRequestBody = data;
    lastHeaders = headers;

    // Return a minimal valid response structure.
    return {
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': 'ok'},
            ],
          },
        },
      ],
    };
  }
}
