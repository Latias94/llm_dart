import 'package:dio/dio.dart';
import 'package:llm_dart_phind/testing.dart';

/// Capturing Phind client used in tests to inspect request bodies.
class CapturingPhindClient extends PhindClient {
  Map<String, dynamic>? lastRequestBody;
  String? lastEndpoint;
  Map<String, String>? lastHeaders;

  CapturingPhindClient(super.config);

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

    return {
      'choices': [
        {
          'message': {
            'role': 'assistant',
            'content': 'ok',
          },
        },
      ],
    };
  }
}
