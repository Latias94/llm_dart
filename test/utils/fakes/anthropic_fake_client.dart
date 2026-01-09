import 'package:dio/dio.dart' hide CancelToken;
import 'package:llm_dart_anthropic_compatible/client.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

class FakeAnthropicClient extends AnthropicClient {
  String? lastEndpoint;
  Map<String, dynamic>? lastBody;

  Map<String, dynamic> response = const {};
  Stream<String> streamResponse = const Stream<String>.empty();

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
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) {
    lastEndpoint = endpoint;
    lastBody = data;
    return streamResponse;
  }
}
