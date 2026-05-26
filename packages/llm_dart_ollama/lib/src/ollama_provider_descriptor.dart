import 'package:llm_dart_provider/llm_dart_provider.dart';

final class OllamaProviderDescriptor {
  static const defaultProviderId = 'ollama';

  const OllamaProviderDescriptor();

  String get providerId => defaultProviderId;

  ProviderSpecification get specification => ProviderSpecification(
        providerId: providerId,
        modelFacets: const {
          ProviderModelFacet.language,
          ProviderModelFacet.embedding,
        },
        capabilities: const [
          CapabilityDescriptor(
            id: ModelCapabilityFeatureIds.languageStreaming,
          ),
          CapabilityDescriptor(
            id: ModelCapabilityFeatureIds.languageFunctionTools,
            confidence: CapabilityConfidence.inferred,
          ),
        ],
        supportedInputShapes: [
          ProviderInputShapeDescriptor(
            modelKind: ModelCapabilityKind.language,
            shapeId: ProviderInputShapeIds.text,
          ),
          ProviderInputShapeDescriptor(
            modelKind: ModelCapabilityKind.language,
            shapeId: ProviderInputShapeIds.image,
            mediaTypes: const ['image/*'],
            confidence: CapabilityConfidence.inferred,
          ),
          ProviderInputShapeDescriptor(
            modelKind: ModelCapabilityKind.embedding,
            shapeId: ProviderInputShapeIds.text,
          ),
        ],
      );
}
