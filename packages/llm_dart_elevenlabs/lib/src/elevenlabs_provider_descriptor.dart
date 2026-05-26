import 'package:llm_dart_provider/llm_dart_provider.dart';

final class ElevenLabsProviderDescriptor {
  static const defaultProviderId = 'elevenlabs';

  const ElevenLabsProviderDescriptor();

  String get providerId => defaultProviderId;

  ProviderSpecification get specification => ProviderSpecification(
        providerId: providerId,
        modelFacets: const {
          ProviderModelFacet.speech,
          ProviderModelFacet.transcription,
        },
        capabilities: const [
          CapabilityDescriptor(
            id: ModelCapabilityFeatureIds.speechVoiceSelection,
          ),
          CapabilityDescriptor(
            id: ModelCapabilityFeatureIds.speechOutputFormat,
          ),
          CapabilityDescriptor(
            id: ModelCapabilityFeatureIds.transcriptionLanguageHints,
          ),
        ],
        supportedInputShapes: [
          ProviderInputShapeDescriptor(
            modelKind: ModelCapabilityKind.speech,
            shapeId: ProviderInputShapeIds.text,
          ),
          ProviderInputShapeDescriptor(
            modelKind: ModelCapabilityKind.transcription,
            shapeId: ProviderInputShapeIds.audio,
            mediaTypes: const ['audio/*', 'video/*'],
          ),
        ],
      );
}
