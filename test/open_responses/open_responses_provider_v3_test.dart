import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_open_responses/llm_dart_open_responses.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;
import 'package:test/test.dart';

void main() {
  group('open responses provider (ProviderV3 parity)', () {
    test('exposes specificationVersion and languageModel', () {
      final openResponses = createOpenResponses(
        name: 'local',
        url: 'http://localhost:1234/v1/responses',
      );

      expect(openResponses.specificationVersion, equals('v3'));

      final model = openResponses.languageModel('mistral/test');
      expect(model, isA<ChatCapability>());

      final model2 = openResponses('mistral/test');
      expect(model2, isA<ChatCapability>());
    });

    test('throws NoSuchModelError for unsupported model types', () {
      final openResponses = createOpenResponses(
        name: 'local',
        url: 'http://localhost:1234/v1/responses',
      );

      expect(
        () => openResponses.embeddingModel('text-embedding-3-small'),
        throwsA(
          predicate(
            (e) =>
                e is provider.NoSuchModelError &&
                e.modelType == 'embeddingModel',
          ),
        ),
      );

      expect(
        () => openResponses.imageModel('gpt-image-1'),
        throwsA(
          predicate(
            (e) =>
                e is provider.NoSuchModelError && e.modelType == 'imageModel',
          ),
        ),
      );
    });
  });
}
