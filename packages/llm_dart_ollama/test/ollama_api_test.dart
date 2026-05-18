import 'package:llm_dart_ollama/src/ollama_api.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('decodeOllamaJsonObject', () {
    test('preserves the Ollama response name in JSON object errors', () {
      expect(
        () => decodeOllamaJsonObject(
          '[]',
          responseName: 'chat response',
        ),
        throwsA(
          isA<TransportResponseFormatException>().having(
            (error) => error.message,
            'message',
            'Ollama chat response API returned JSON that is not an object',
          ),
        ),
      );
    });
  });
}
