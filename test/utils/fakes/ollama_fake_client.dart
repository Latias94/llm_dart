import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_ollama/client.dart';

class FakeOllamaClient extends OllamaClient {
  Stream<String>? streamResponse;

  FakeOllamaClient(super.config);

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) {
    return streamResponse ?? const Stream<String>.empty();
  }
}
