import 'package:llm_dart_ollama/llm_dart_ollama.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:test/test.dart';

void main() {
  group('Ollama capability profile integration', () {
    test('language models expose capabilityProfile directly', () {
      final model = Ollama(
        transport: const _FakeTransportClient(),
      ).chatModel('llama3.2-vision');

      expect(model, isA<CapabilityDescribedModel>());
      expect(model.capabilityProfile.providerId, 'ollama');
      expect(model.capabilityProfile.kind, ModelCapabilityKind.language);
      expect(
        model.capabilityProfile.supports(
          ModelCapabilityFeatureIds.languageImageInput,
        ),
        isTrue,
      );
    });

    test('embedding models expose capabilityProfile directly', () {
      final model = Ollama(
        transport: const _FakeTransportClient(),
      ).embeddingModel('nomic-embed-text');

      expect(model, isA<CapabilityDescribedModel>());
      expect(model.capabilityProfile.kind, ModelCapabilityKind.embedding);
      expect(
        model.capabilityProfile.supports(
          ModelCapabilityFeatureIds.embeddingBatch,
        ),
        isTrue,
      );
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;
