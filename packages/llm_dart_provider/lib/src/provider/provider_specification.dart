import '../model/model_capability_profile.dart';
import '../model/model_reference.dart';

/// Provider contract version implemented by a provider object.
///
/// The provider package intentionally exposes one current Dart-native
/// specification version. Add a new enum value only when multiple provider
/// contract versions must coexist at runtime.
enum ProviderSpecificationVersion {
  v1('v1');

  final String value;

  const ProviderSpecificationVersion(this.value);
}

/// Model families that a provider object can expose.
enum ProviderModelFacet {
  language,
  embedding,
  image,
  speech,
  transcription,
}

/// Stable input-shape identifiers used by provider specifications.
abstract final class ProviderInputShapeIds {
  static const text = 'input.text';
  static const image = 'input.image';
  static const file = 'input.file';
  static const audio = 'input.audio';
  static const mask = 'input.mask';
  static const url = 'input.url';
  static const bytes = 'input.bytes';
  static const providerReference = 'input.providerReference';
}

/// Describes one input shape a provider can accept for a model family.
final class ProviderInputShapeDescriptor {
  final ModelCapabilityKind modelKind;
  final String shapeId;
  final CapabilityConfidence confidence;
  final Set<String> mediaTypes;
  final Object? detail;

  ProviderInputShapeDescriptor({
    required this.modelKind,
    required this.shapeId,
    this.confidence = CapabilityConfidence.known,
    Iterable<String> mediaTypes = const [],
    this.detail,
  })  : assert(
          shapeId != '',
          'ProviderInputShapeDescriptor.shapeId must not be empty.',
        ),
        mediaTypes = Set.unmodifiable(mediaTypes);

  @override
  bool operator ==(Object other) {
    return other is ProviderInputShapeDescriptor &&
        other.modelKind == modelKind &&
        other.shapeId == shapeId &&
        other.confidence == confidence &&
        _stringSetsEqual(other.mediaTypes, mediaTypes) &&
        other.detail == detail;
  }

  @override
  int get hashCode => Object.hash(
        modelKind,
        shapeId,
        confidence,
        Object.hashAll(mediaTypes),
        detail,
      );

  @override
  String toString() {
    return 'ProviderInputShapeDescriptor('
        'modelKind: $modelKind, '
        'shapeId: $shapeId, '
        'confidence: $confidence, '
        'mediaTypes: $mediaTypes, '
        'detail: $detail'
        ')';
  }
}

/// Frozen provider-object specification.
///
/// This is provider-facing contract metadata. It is not a concrete model
/// capability profile and should not replace typed provider options or
/// provider-owned model describers.
final class ProviderSpecification {
  final ProviderSpecificationVersion version;
  final String providerId;
  final Set<ProviderModelFacet> modelFacets;
  final Set<CapabilityDescriptor> capabilities;
  final List<ProviderFeatureDescriptor> providerFeatures;
  final List<ProviderInputShapeDescriptor> supportedInputShapes;

  ProviderSpecification({
    this.version = ProviderSpecificationVersion.v1,
    required this.providerId,
    Iterable<ProviderModelFacet> modelFacets = const [],
    Iterable<CapabilityDescriptor> capabilities = const [],
    Iterable<ProviderFeatureDescriptor> providerFeatures = const [],
    Iterable<ProviderInputShapeDescriptor> supportedInputShapes = const [],
  })  : modelFacets = Set.unmodifiable(modelFacets),
        capabilities = Set.unmodifiable(capabilities),
        providerFeatures = List.unmodifiable(providerFeatures),
        supportedInputShapes = List.unmodifiable(supportedInputShapes) {
    ModelReference.validateProviderId(
      providerId,
      parameterName: 'providerId',
    );
  }

  bool supportsModelFacet(ProviderModelFacet facet) {
    return modelFacets.contains(facet);
  }

  bool supportsCapability(String featureId) {
    return capability(featureId) != null;
  }

  CapabilityDescriptor? capability(String featureId) {
    for (final descriptor in capabilities) {
      if (descriptor.id == featureId) {
        return descriptor;
      }
    }
    return null;
  }

  List<ProviderInputShapeDescriptor> inputShapesFor(
    ModelCapabilityKind modelKind,
  ) {
    return [
      for (final shape in supportedInputShapes)
        if (shape.modelKind == modelKind) shape,
    ];
  }

  bool supportsInputShape({
    required ModelCapabilityKind modelKind,
    required String shapeId,
  }) {
    return inputShape(
          modelKind: modelKind,
          shapeId: shapeId,
        ) !=
        null;
  }

  ProviderInputShapeDescriptor? inputShape({
    required ModelCapabilityKind modelKind,
    required String shapeId,
  }) {
    for (final shape in supportedInputShapes) {
      if (shape.modelKind == modelKind && shape.shapeId == shapeId) {
        return shape;
      }
    }
    return null;
  }
}

bool _stringSetsEqual(Set<String> left, Set<String> right) {
  if (left.length != right.length) {
    return false;
  }
  return left.every(right.contains);
}
