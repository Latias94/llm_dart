import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic capability profile integration', () {
    test('language models expose capabilityProfile directly', () {
      final model = Anthropic(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).chatModel('claude-sonnet-4-5');

      expect(model, isA<CapabilityDescribedModel>());
      expect(model.capabilityProfile.providerId, 'anthropic');
      expect(model.capabilityProfile.modelId, 'claude-sonnet-4-5');
      expect(model.capabilityProfile.kind, ModelCapabilityKind.language);
      expect(
        model.capabilityProfile.supports(
          ModelCapabilityFeatureIds.languageReasoningOutput,
        ),
        isTrue,
      );
      expect(
        model.capabilityProfile
            .providerFeature('anthropic', 'api.route')
            ?.detail,
        'messages',
      );
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;
