import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/core/cancellation.dart';

class FakeAnthropicCompatibleClient extends AnthropicClient {
  final List<String> chunks;

  FakeAnthropicCompatibleClient(
    super.config, {
    required this.chunks,
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
}
