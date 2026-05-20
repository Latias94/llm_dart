import 'package:llm_dart_ollama/llm_dart_ollama.dart';
import 'package:llm_dart_ollama/src/ollama_model_catalog_models.dart'
    show decodeOllamaInstalledModelsList;
import 'package:test/test.dart';

void main() {
  group('Ollama model catalog models', () {
    test('round-trips installed model details', () {
      final model = OllamaInstalledModel.fromJson({
        'name': 'llama3.2:latest',
        'modified_at': '2026-04-23T10:00:00Z',
        'size': 123,
        'digest': 'sha256:abc',
        'details': {
          'format': 'gguf',
          'family': 'llama',
          'families': ['llama', 'mllama'],
          'parameter_size': '8B',
          'quantization_level': 'Q4_K_M',
        },
      });

      expect(model.name, 'llama3.2:latest');
      expect(model.modifiedAt, DateTime.parse('2026-04-23T10:00:00Z'));
      expect(model.details?.families, ['llama', 'mllama']);
      expect(model.toJson(), {
        'name': 'llama3.2:latest',
        'modified_at': DateTime.parse('2026-04-23T10:00:00Z').toIso8601String(),
        'size': 123,
        'digest': 'sha256:abc',
        'details': {
          'format': 'gguf',
          'family': 'llama',
          'families': ['llama', 'mllama'],
          'parameter_size': '8B',
          'quantization_level': 'Q4_K_M',
        },
      });
    });

    test('decodes model catalog lists with path-aware errors', () {
      expect(
        () => decodeOllamaInstalledModelsList({
          'models': [
            {'name': ''},
          ],
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('model.name'),
          ),
        ),
      );

      expect(
        () => decodeOllamaInstalledModelsList({'models': 'not-list'}),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('catalog.models'),
          ),
        ),
      );
    });
  });
}
