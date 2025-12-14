import 'package:llm_dart_ollama/llm_dart_ollama.dart';
import 'package:test/test.dart';

void main() {
  test('public API smoke', () {
    expect(registerOllamaProvider, isNotNull);
    expect(createOllama, isNotNull);
    expect(Ollama, isNotNull);
  });
}
