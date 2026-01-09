import 'package:llm_dart_ollama/ollama.dart';
import 'package:test/test.dart';

void main() {
  test('Ollama chat response exposes providerMetadata aliases', () {
    final response = OllamaChatResponse({
      'model': 'llama3.2',
      'created_at': '2024-01-01T00:00:00Z',
      'done_reason': 'stop',
      'prompt_eval_count': 1,
      'eval_count': 2,
    });

    final metadata = response.providerMetadata;
    expect(metadata, isNotNull);
    expect(metadata, contains('ollama'));
    expect(metadata, contains('ollama.chat'));
  });
}
