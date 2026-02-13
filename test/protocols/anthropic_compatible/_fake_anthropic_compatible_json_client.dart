import 'package:llm_dart_anthropic_compatible/client.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

class FakeAnthropicCompatibleJsonClient extends AnthropicClient {
  final List<Map<String, dynamic>> _responses;
  final List<Map<String, dynamic>> requests = [];

  FakeAnthropicCompatibleJsonClient(
    super.config, {
    required List<Map<String, dynamic>> responses,
  }) : _responses = List<Map<String, dynamic>>.from(responses);

  Map<String, dynamic> _consumeNextResponse(
    String endpoint,
    Map<String, dynamic> data,
  ) {
    requests.add(Map<String, dynamic>.from(data));
    if (_responses.isEmpty) {
      throw StateError('No more fake responses configured for $endpoint');
    }
    return _responses.removeAt(0);
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    return _consumeNextResponse(endpoint, data);
  }

  @override
  Future<({Map<String, dynamic> json, Map<String, String> headers})>
      postJsonWithHeaders(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    return (
      json: _consumeNextResponse(endpoint, data),
      headers: const <String, String>{},
    );
  }
}
