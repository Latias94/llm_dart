import 'package:llm_dart_provider/llm_dart_provider.dart';

final class AnthropicProviderDescriptor {
  static const defaultProviderId = 'anthropic';

  const AnthropicProviderDescriptor();

  String get providerId => defaultProviderId;

  ProviderSpecification get specification => ProviderSpecification(
        providerId: providerId,
        modelFacets: const {
          ProviderModelFacet.language,
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
          ),
        ],
      );
}
