import 'package:llm_dart_anthropic_compatible/client.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

class FakeAnthropicClient extends AnthropicClient {
  String? lastEndpoint;
  Map<String, dynamic>? lastBody;

  Map<String, dynamic> response = const {};
  Map<String, String> jsonHeaders = const <String, String>{};
  Stream<String> streamResponse = const Stream<String>.empty();
  Map<String, String> streamHeaders = const <String, String>{};

  FakeAnthropicClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastBody = data;
    return response;
  }

  @override
  Future<({Map<String, dynamic> json, Map<String, String> headers})>
      postJsonWithHeaders(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastBody = data;
    return (json: response, headers: jsonHeaders);
  }

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) {
    lastEndpoint = endpoint;
    lastBody = data;
    return streamResponse;
  }

  @override
  Future<({Stream<String> stream, Map<String, String> headers})>
      postStreamRawWithHeaders(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastBody = data;
    return (stream: streamResponse, headers: streamHeaders);
  }
}
