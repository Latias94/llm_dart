import 'package:dio/dio.dart';
import 'package:llm_dart_deepseek/llm_dart_deepseek.dart' as deepseek;

/// Capturing DeepSeek client used in tests to inspect JSON request bodies.
class CapturingDeepSeekClient extends deepseek.DeepSeekClient {
  Map<String, dynamic>? lastRequestBody;
  String? lastEndpoint;

  CapturingDeepSeekClient(deepseek.DeepSeekConfig config) : super(config);

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
          'text': 'completed text',
        },
      ],
      'usage': {
        'prompt_tokens': 5,
        'completion_tokens': 10,
        'total_tokens': 15,
      },
    };
  }
}

/// Fake DeepSeek client that returns a synthetic SSE-style stream.
///
/// The [chunks] parameter contains raw SSE data lines that will be
/// yielded in order by [postStreamRaw], mirroring DeepSeek's streaming
/// interface in a deterministic way.
class FakeDeepSeekStreamClient extends deepseek.DeepSeekClient {
  final List<String> chunks;

  FakeDeepSeekStreamClient(
    deepseek.DeepSeekConfig config, {
    required this.chunks,
  }) : super(config);

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async* {
    for (final chunk in chunks) {
      yield chunk;
    }
  }
}
