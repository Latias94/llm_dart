import 'package:llm_dart_provider/llm_dart_provider.dart';

final class GoogleProviderDescriptor {
  static const defaultProviderId = 'google';

  const GoogleProviderDescriptor();

  String get providerId => defaultProviderId;

  ProviderSpecification get specification => ProviderSpecification(
        providerId: providerId,
        modelFacets: const {
          ProviderModelFacet.language,
          ProviderModelFacet.embedding,
          ProviderModelFacet.image,
          ProviderModelFacet.speech,
        },
        capabilities: const [
          CapabilityDescriptor(
            id: ModelCapabilityFeatureIds.languageStreaming,
          ),
          CapabilityDescriptor(
            id: ModelCapabilityFeatureIds.languageFunctionTools,
          ),
          CapabilityDescriptor(
            id: ModelCapabilityFeatureIds.languageStructuredOutput,
          ),
          CapabilityDescriptor(
            id: ModelCapabilityFeatureIds.embeddingBatch,
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
          ),
          ProviderInputShapeDescriptor(
            modelKind: ModelCapabilityKind.language,
            shapeId: ProviderInputShapeIds.file,
            mediaTypes: const ['application/pdf', 'text/*'],
            confidence: CapabilityConfidence.inferred,
          ),
          ProviderInputShapeDescriptor(
            modelKind: ModelCapabilityKind.embedding,
            shapeId: ProviderInputShapeIds.text,
          ),
          ProviderInputShapeDescriptor(
            modelKind: ModelCapabilityKind.image,
            shapeId: ProviderInputShapeIds.text,
          ),
          ProviderInputShapeDescriptor(
            modelKind: ModelCapabilityKind.image,
            shapeId: ProviderInputShapeIds.image,
            mediaTypes: const ['image/*'],
          ),
          ProviderInputShapeDescriptor(
            modelKind: ModelCapabilityKind.speech,
            shapeId: ProviderInputShapeIds.text,
          ),
        ],
      );
}
