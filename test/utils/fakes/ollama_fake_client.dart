import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_ollama/client.dart';

class FakeOllamaClient extends OllamaClient {
  String? lastEndpoint;
  Map<String, dynamic>? lastBody;

  Map<String, dynamic> jsonResponse = const <String, dynamic>{};
  Map<String, String> jsonHeaders = const <String, String>{};
  Stream<String>? streamResponse;
  Map<String, String> streamHeaders = const <String, String>{};

  FakeOllamaClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastBody = data;
    return jsonResponse;
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
    return (json: jsonResponse, headers: jsonHeaders);
  }

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) {
    lastEndpoint = endpoint;
    lastBody = data;
    return streamResponse ?? const Stream<String>.empty();
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
    return (
      stream: streamResponse ?? const Stream<String>.empty(),
      headers: streamHeaders,
    );
  }
}
