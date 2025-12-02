import 'package:dio/dio.dart';
import 'package:llm_dart/llm_dart.dart';

/// Capturing Phind client used in tests to inspect request bodies.
class CapturingPhindClient extends PhindClient {
  Map<String, dynamic>? lastRequestBody;
  String? lastEndpoint;

  CapturingPhindClient(PhindConfig config) : super(config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastRequestBody = data;

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
