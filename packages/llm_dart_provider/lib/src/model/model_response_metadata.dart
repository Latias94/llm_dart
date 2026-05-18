final class ModelResponseMetadata {
  final String? id;
  final DateTime? timestamp;
  final String? modelId;
  final Map<String, String> headers;

  const ModelResponseMetadata({
    this.id,
    this.timestamp,
    this.modelId,
    this.headers = const {},
  });

  bool get isEmpty =>
      id == null && timestamp == null && modelId == null && headers.isEmpty;

  bool get isNotEmpty => !isEmpty;

  @override
  bool operator ==(Object other) {
    return other is ModelResponseMetadata &&
        other.id == id &&
        other.timestamp == timestamp &&
        other.modelId == modelId &&
        _mapEquals(other.headers, headers);
  }

  @override
  int get hashCode => Object.hash(
        id,
        timestamp,
        modelId,
        _mapHash(headers),
      );

  @override
  String toString() {
    return 'ModelResponseMetadata('
        'id: $id, '
        'timestamp: $timestamp, '
        'modelId: $modelId, '
        'headers: $headers'
        ')';
  }
}

ModelResponseMetadata? modelResponseMetadataFrom({
  ModelResponseMetadata? metadata,
  String? id,
  DateTime? timestamp,
  String? modelId,
  Map<String, String>? headers,
}) {
  final hasLegacyValues = id != null ||
      timestamp != null ||
      modelId != null ||
      (headers != null && headers.isNotEmpty);

  if (metadata == null) {
    if (!hasLegacyValues) {
      return null;
    }

    return ModelResponseMetadata(
      id: id,
      timestamp: timestamp,
      modelId: modelId,
      headers: headers ?? const {},
    );
  }

  if (!hasLegacyValues) {
    return metadata;
  }

  return ModelResponseMetadata(
    id: metadata.id ?? id,
    timestamp: metadata.timestamp ?? timestamp,
    modelId: metadata.modelId ?? modelId,
    headers: metadata.headers.isNotEmpty
        ? metadata.headers
        : headers ?? const {},
  );
}

bool _mapEquals(Map<String, String> left, Map<String, String> right) {
  if (identical(left, right)) {
    return true;
  }

  if (left.length != right.length) {
    return false;
  }

  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) {
      return false;
    }
  }

  return true;
}

int _mapHash(Map<String, String> value) {
  final entries = value.entries.toList(growable: false)
    ..sort((left, right) => left.key.compareTo(right.key));

  return Object.hashAll(
    entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}
