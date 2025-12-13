import 'package:dio/dio.dart';
import 'package:llm_dart/llm_dart.dart';

/// Capturing Google client used in tests to inspect request payloads.
class CapturingGoogleClient extends GoogleClient {
  Map<String, dynamic>? lastRequestBody;
  String? lastEndpoint;

  CapturingGoogleClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastRequestBody = data;

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
