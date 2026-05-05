/// Coarse capability family implemented by a concrete model.
enum ModelCapabilityKind {
  language,
  embedding,
  image,
  speech,
  transcription,
}

/// Confidence level for a capability description.
enum CapabilityConfidence {
  /// The library has an explicit provider/model rule for this capability.
  known,

  /// The library inferred the capability from model naming or provider family
  /// rules, but the provider does not publish a precise contract.
  inferred,

  /// The capability is intentionally unknown.
  unknown,

  /// The capability was provided by user configuration.
  userProvided,
}

/// Stable shared feature identifiers used by app-facing capability checks.
abstract final class ModelCapabilityFeatureIds {
  static const languageStreaming = 'language.streaming';
  static const languageFunctionTools = 'language.tool.function';
  static const languageToolChoice = 'language.tool.choice';
  static const languageStructuredOutput = 'language.output.structured';
  static const languageJsonResponseFormat = 'language.output.json';
  static const languageReasoningOutput = 'language.output.reasoning';
  static const languageTextInput = 'language.input.text';
  static const languageImageInput = 'language.input.image';
  static const languageFileInput = 'language.input.file';
  static const languageAudioInput = 'language.input.audio';
  static const languageSourceOutput = 'language.output.source';
  static const languageFileOutput = 'language.output.file';
  static const languageApprovalRequests = 'language.tool.approval';

  static const embeddingBatch = 'embedding.batch';
  static const embeddingDimensions = 'embedding.dimensions';

  static const imageMultipleOutput = 'image.output.multiple';
  static const imageEditing = 'image.edit';

  static const speechOutputFormat = 'speech.output.format';
  static const speechVoiceSelection = 'speech.voice.selection';

  static const transcriptionTimestamps = 'transcription.timestamps';
  static const transcriptionLanguageHints = 'transcription.languageHints';
}

/// Shared model feature description.
final class CapabilityDescriptor {
  final String id;
  final CapabilityConfidence confidence;

  const CapabilityDescriptor({
    required this.id,
    this.confidence = CapabilityConfidence.known,
  }) : assert(id != '', 'CapabilityDescriptor.id must not be empty.');

  @override
  bool operator ==(Object other) {
    return other is CapabilityDescriptor &&
        other.id == id &&
        other.confidence == confidence;
  }

  @override
  int get hashCode => Object.hash(id, confidence);

  @override
  String toString() {
    return 'CapabilityDescriptor(id: $id, confidence: $confidence)';
  }
}

/// Provider-owned feature description.
final class ProviderFeatureDescriptor {
  final String providerId;
  final String featureId;
  final CapabilityConfidence confidence;
  final Object? detail;

  const ProviderFeatureDescriptor({
    required this.providerId,
    required this.featureId,
    this.confidence = CapabilityConfidence.known,
    this.detail,
  })  : assert(
          providerId != '',
          'ProviderFeatureDescriptor.providerId must not be empty.',
        ),
        assert(
          featureId != '',
          'ProviderFeatureDescriptor.featureId must not be empty.',
        );

  @override
  bool operator ==(Object other) {
    return other is ProviderFeatureDescriptor &&
        other.providerId == providerId &&
        other.featureId == featureId &&
        other.confidence == confidence &&
        other.detail == detail;
  }

  @override
  int get hashCode => Object.hash(
        providerId,
        featureId,
        confidence,
        detail,
      );

  @override
  String toString() {
    return 'ProviderFeatureDescriptor('
        'providerId: $providerId, '
        'featureId: $featureId, '
        'confidence: $confidence, '
        'detail: $detail'
        ')';
  }
}

/// Descriptive capability profile for one concrete model.
///
/// This is an app-facing description, not a remote-provider guarantee. Provider
/// codecs still own final validation, warnings, and request shaping.
final class ModelCapabilityProfile {
  final String providerId;
  final String modelId;
  final ModelCapabilityKind kind;
  final Set<CapabilityDescriptor> sharedFeatures;
  final List<ProviderFeatureDescriptor> providerFeatures;

  ModelCapabilityProfile({
    required this.providerId,
    required this.modelId,
    required this.kind,
    Iterable<CapabilityDescriptor> sharedFeatures = const [],
    Iterable<ProviderFeatureDescriptor> providerFeatures = const [],
  })  : assert(
          providerId != '',
          'ModelCapabilityProfile.providerId must not be empty.',
        ),
        assert(
          modelId != '',
          'ModelCapabilityProfile.modelId must not be empty.',
        ),
        sharedFeatures = Set.unmodifiable(sharedFeatures),
        providerFeatures = List.unmodifiable(providerFeatures);

  bool supports(String featureId) {
    return sharedFeature(featureId) != null;
  }

  bool supportsAll(Iterable<String> featureIds) {
    return featureIds.every(supports);
  }

  bool supportsAny(Iterable<String> featureIds) {
    return featureIds.any(supports);
  }

  CapabilityDescriptor? sharedFeature(String featureId) {
    for (final feature in sharedFeatures) {
      if (feature.id == featureId) {
        return feature;
      }
    }
    return null;
  }

  List<ProviderFeatureDescriptor> providerFeaturesFor(String providerId) {
    return [
      for (final feature in providerFeatures)
        if (feature.providerId == providerId) feature,
    ];
  }

  ProviderFeatureDescriptor? providerFeature(
    String providerId,
    String featureId,
  ) {
    for (final feature in providerFeatures) {
      if (feature.providerId == providerId && feature.featureId == featureId) {
        return feature;
      }
    }
    return null;
  }
}

/// Optional marker for models that can describe their capabilities.
///
/// Existing model interfaces do not require this marker. Provider packages can
/// adopt it incrementally without breaking third-party model implementations.
abstract interface class CapabilityDescribedModel {
  ModelCapabilityProfile get capabilityProfile;
}
