import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_family_profile.dart';
import 'openai_family_route_policy.dart';
import 'resolved_openai_chat_settings.dart';

final class OpenAIFamilyProviderDescriptor {
  final OpenAIFamilyProfile profile;
  final OpenAIFamilyModelFacetSupport modelFacetSupport;

  OpenAIFamilyProviderDescriptor({
    required this.profile,
    OpenAIFamilyModelFacetSupport? modelFacetSupport,
  }) : modelFacetSupport = modelFacetSupport ??
            modelFacetSupportForOpenAIFamilyProfile(profile);

  String get providerId => profile.providerId;

  ProviderSpecification get specification => ProviderSpecification(
        providerId: providerId,
        modelFacets: modelFacets,
        capabilities: capabilities,
        supportedInputShapes: supportedInputShapes,
      );

  List<ProviderModelFacet> get modelFacets {
    return [
      ProviderModelFacet.language,
      if (modelFacetSupport.embedding) ProviderModelFacet.embedding,
      if (modelFacetSupport.image) ProviderModelFacet.image,
      if (modelFacetSupport.speech) ProviderModelFacet.speech,
      if (modelFacetSupport.transcription) ProviderModelFacet.transcription,
    ];
  }

  List<CapabilityDescriptor> get capabilities {
    return [
      const CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.languageStreaming,
      ),
      const CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.languageFunctionTools,
      ),
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.languageStructuredOutput,
        confidence: _structuredOutputConfidence,
      ),
    ];
  }

  List<ProviderInputShapeDescriptor> get supportedInputShapes {
    return [
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
        modelKind: ModelCapabilityKind.language,
        shapeId: ProviderInputShapeIds.file,
        mediaTypes: const ['application/pdf', 'text/*'],
        confidence: profile.providerId == 'openai'
            ? CapabilityConfidence.known
            : CapabilityConfidence.inferred,
      ),
      if (modelFacetSupport.image)
        ProviderInputShapeDescriptor(
          modelKind: ModelCapabilityKind.image,
          shapeId: ProviderInputShapeIds.text,
        ),
      if (modelFacetSupport.image)
        ProviderInputShapeDescriptor(
          modelKind: ModelCapabilityKind.image,
          shapeId: ProviderInputShapeIds.image,
          mediaTypes: const ['image/*'],
        ),
      if (modelFacetSupport.speech)
        ProviderInputShapeDescriptor(
          modelKind: ModelCapabilityKind.speech,
          shapeId: ProviderInputShapeIds.text,
        ),
      if (modelFacetSupport.transcription)
        ProviderInputShapeDescriptor(
          modelKind: ModelCapabilityKind.transcription,
          shapeId: ProviderInputShapeIds.audio,
          mediaTypes: const ['audio/*', 'video/*'],
        ),
    ];
  }

  CapabilityConfidence get _structuredOutputConfidence {
    return profile.routePolicy.resolveLanguageModelRoute(
              ResolvedOpenAIChatModelSettings(),
            ) ==
            OpenAIRequestRoute.responses
        ? CapabilityConfidence.known
        : CapabilityConfidence.inferred;
  }
}
