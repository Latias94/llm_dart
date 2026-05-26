import '../model/model_capability_profile.dart';
import 'provider.dart';
import 'provider_specification.dart';

/// How strictly a capability descriptor should be interpreted.
enum CapabilityGateMode {
  /// Use for request/runtime validation.
  ///
  /// Only known or user-provided descriptors satisfy hard requirements.
  requirement,

  /// Use for UI affordances, discovery, and documentation.
  ///
  /// Inferred descriptors can be surfaced, but provider codecs still own final
  /// request validation.
  affordance,
}

/// Result of checking one capability descriptor.
final class CapabilityGateDecision {
  final bool allowed;
  final CapabilityConfidence? confidence;
  final String? reason;

  const CapabilityGateDecision.supported({
    this.confidence = CapabilityConfidence.known,
  })  : allowed = true,
        reason = null;

  const CapabilityGateDecision.unsupported({
    this.confidence,
    required this.reason,
  }) : allowed = false;

  bool get unsupported => !allowed;

  @override
  String toString() {
    if (allowed) {
      return 'CapabilityGateDecision.supported('
          'confidence: $confidence'
          ')';
    }
    return 'CapabilityGateDecision.unsupported('
        'confidence: $confidence, '
        'reason: $reason'
        ')';
  }
}

/// Descriptor-backed gate for provider-level capability checks.
///
/// Provider specifications describe stable provider families without naming
/// concrete providers in app/runtime code. A gate converts those descriptors
/// into explicit decisions for hard requirements and softer affordances.
final class ProviderCapabilityGate {
  final ProviderSpecification specification;
  final Provider? provider;

  const ProviderCapabilityGate.forSpecification(this.specification)
      : provider = null;

  ProviderCapabilityGate.forProvider(Provider this.provider)
      : specification = provider.specification;

  CapabilityGateDecision modelFacet(ProviderModelFacet facet) {
    if (!specification.supportsModelFacet(facet)) {
      return CapabilityGateDecision.unsupported(
        reason: 'Provider "${specification.providerId}" does not declare '
            '$facet.',
      );
    }

    final provider = this.provider;
    if (provider != null && !_implementsModelFacet(provider, facet)) {
      return CapabilityGateDecision.unsupported(
        reason: 'Provider "${specification.providerId}" declares $facet but '
            'the provider object does not implement the matching model '
            'factory interface.',
      );
    }

    if (provider != null && !_declaresFacetSupport(provider, facet)) {
      return CapabilityGateDecision.unsupported(
        reason: 'Provider "${specification.providerId}" explicitly disables '
            '$facet.',
      );
    }

    return const CapabilityGateDecision.supported();
  }

  CapabilityGateDecision sharedCapability(
    String featureId, {
    CapabilityGateMode mode = CapabilityGateMode.requirement,
  }) {
    final descriptor = specification.capability(featureId);
    if (descriptor == null) {
      return CapabilityGateDecision.unsupported(
        reason: 'Provider "${specification.providerId}" does not declare '
            'shared capability "$featureId".',
      );
    }
    return _decisionForConfidence(
      descriptor.confidence,
      mode: mode,
      subject: 'shared capability "$featureId"',
    );
  }

  CapabilityGateDecision providerFeature(
    String providerId,
    String featureId, {
    CapabilityGateMode mode = CapabilityGateMode.requirement,
  }) {
    for (final descriptor in specification.providerFeatures) {
      if (descriptor.providerId == providerId &&
          descriptor.featureId == featureId) {
        return _decisionForConfidence(
          descriptor.confidence,
          mode: mode,
          subject: 'provider feature "$providerId.$featureId"',
        );
      }
    }
    return CapabilityGateDecision.unsupported(
      reason: 'Provider "${specification.providerId}" does not declare '
          'provider feature "$providerId.$featureId".',
    );
  }

  CapabilityGateDecision inputShape({
    required ModelCapabilityKind modelKind,
    required String shapeId,
    String? mediaType,
    CapabilityGateMode mode = CapabilityGateMode.requirement,
  }) {
    final descriptor = specification.inputShape(
      modelKind: modelKind,
      shapeId: shapeId,
    );
    if (descriptor == null) {
      return CapabilityGateDecision.unsupported(
        reason: 'Provider "${specification.providerId}" does not declare '
            '$modelKind input shape "$shapeId".',
      );
    }

    final confidenceDecision = _decisionForConfidence(
      descriptor.confidence,
      mode: mode,
      subject: '$modelKind input shape "$shapeId"',
    );
    if (confidenceDecision.unsupported) {
      return confidenceDecision;
    }

    if (mediaType != null &&
        descriptor.mediaTypes.isNotEmpty &&
        !_matchesMediaType(mediaType, descriptor.mediaTypes)) {
      return CapabilityGateDecision.unsupported(
        confidence: descriptor.confidence,
        reason: 'Provider "${specification.providerId}" declares '
            '$modelKind input shape "$shapeId", but media type "$mediaType" '
            'does not match ${descriptor.mediaTypes}.',
      );
    }

    return confidenceDecision;
  }
}

/// Descriptor-backed gate for concrete model capability profiles.
final class ModelCapabilityGate {
  final ModelCapabilityProfile profile;

  const ModelCapabilityGate(this.profile);

  CapabilityGateDecision modelKind(ModelCapabilityKind kind) {
    if (profile.kind == kind) {
      return const CapabilityGateDecision.supported();
    }
    return CapabilityGateDecision.unsupported(
      reason: 'Model "${profile.providerId}:${profile.modelId}" is '
          '${profile.kind}, not $kind.',
    );
  }

  CapabilityGateDecision sharedCapability(
    String featureId, {
    CapabilityGateMode mode = CapabilityGateMode.requirement,
  }) {
    final descriptor = profile.sharedFeature(featureId);
    if (descriptor == null) {
      return CapabilityGateDecision.unsupported(
        reason: 'Model "${profile.providerId}:${profile.modelId}" does not '
            'declare shared capability "$featureId".',
      );
    }
    return _decisionForConfidence(
      descriptor.confidence,
      mode: mode,
      subject: 'shared capability "$featureId"',
    );
  }

  CapabilityGateDecision providerFeature(
    String providerId,
    String featureId, {
    CapabilityGateMode mode = CapabilityGateMode.requirement,
  }) {
    final descriptor = profile.providerFeature(providerId, featureId);
    if (descriptor == null) {
      return CapabilityGateDecision.unsupported(
        reason: 'Model "${profile.providerId}:${profile.modelId}" does not '
            'declare provider feature "$providerId.$featureId".',
      );
    }
    return _decisionForConfidence(
      descriptor.confidence,
      mode: mode,
      subject: 'provider feature "$providerId.$featureId"',
    );
  }
}

CapabilityGateDecision _decisionForConfidence(
  CapabilityConfidence confidence, {
  required CapabilityGateMode mode,
  required String subject,
}) {
  return switch (confidence) {
    CapabilityConfidence.known ||
    CapabilityConfidence.userProvided =>
      CapabilityGateDecision.supported(confidence: confidence),
    CapabilityConfidence.inferred when mode == CapabilityGateMode.affordance =>
      CapabilityGateDecision.supported(confidence: confidence),
    CapabilityConfidence.inferred => CapabilityGateDecision.unsupported(
        confidence: confidence,
        reason: '$subject is inferred and cannot satisfy a hard requirement.',
      ),
    CapabilityConfidence.unknown => CapabilityGateDecision.unsupported(
        confidence: confidence,
        reason: '$subject has unknown support.',
      ),
  };
}

bool _implementsModelFacet(Provider provider, ProviderModelFacet facet) {
  return switch (facet) {
    ProviderModelFacet.language => provider is LanguageModelProvider,
    ProviderModelFacet.embedding => provider is EmbeddingModelProvider,
    ProviderModelFacet.image => provider is ImageModelProvider,
    ProviderModelFacet.speech => provider is SpeechModelProvider,
    ProviderModelFacet.transcription => provider is TranscriptionModelProvider,
  };
}

bool _declaresFacetSupport(Provider provider, ProviderModelFacet facet) {
  if (provider is! ProviderModelFacetSupport) {
    return true;
  }
  return switch (facet) {
    ProviderModelFacet.language => provider.supportsLanguageModels,
    ProviderModelFacet.embedding => provider.supportsEmbeddingModels,
    ProviderModelFacet.image => provider.supportsImageModels,
    ProviderModelFacet.speech => provider.supportsSpeechModels,
    ProviderModelFacet.transcription => provider.supportsTranscriptionModels,
  };
}

bool _matchesMediaType(String mediaType, Set<String> supportedMediaTypes) {
  final normalized = mediaType.toLowerCase();
  for (final supported in supportedMediaTypes) {
    final normalizedSupported = supported.toLowerCase();
    if (normalizedSupported == normalized || normalizedSupported == '*/*') {
      return true;
    }
    if (normalizedSupported.endsWith('/*')) {
      final prefix = normalizedSupported.substring(
        0,
        normalizedSupported.length - 1,
      );
      if (normalized.startsWith(prefix)) {
        return true;
      }
    }
  }
  return false;
}
