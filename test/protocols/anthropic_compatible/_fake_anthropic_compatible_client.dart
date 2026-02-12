import 'package:llm_dart_anthropic_compatible/client.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

class FakeAnthropicCompatibleClient extends AnthropicClient {
  final List<String> chunks;
  final Map<String, String> headers;

  FakeAnthropicCompatibleClient(
    super.config, {
    required this.chunks,
    this.headers = const <String, String>{},
  });

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async* {
    for (final chunk in chunks) {
      yield chunk;
    }
  }

  @override
  Future<({Stream<String> stream, Map<String, String> headers})>
      postStreamRawWithHeaders(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    return (
      stream: postStreamRaw(endpoint, data, cancelToken: cancelToken),
      headers: headers
    );
  }
}
