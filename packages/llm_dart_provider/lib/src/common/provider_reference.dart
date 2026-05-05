import 'json_codec_common.dart';

final class ProviderReference {
  static final RegExp _providerIdPattern = RegExp(
    r'^[a-z0-9]+(?:[._-][a-z0-9]+)*$',
  );

  final Map<String, String> values;

  const ProviderReference(this.values);

  factory ProviderReference.forProvider(
    String providerId,
    String value,
  ) {
    return ProviderReference({
      providerId: value,
    });
  }

  bool get isEmpty => values.isEmpty;

  bool get isNotEmpty => values.isNotEmpty;

  bool containsProvider(String providerId) => values.containsKey(providerId);

  String? operator [](String providerId) => values[providerId];

  String requireProvider(
    String providerId, {
    String? context,
  }) {
    final value = values[providerId];
    if (value != null && value.isNotEmpty) {
      return value;
    }

    final available = values.keys.toList()..sort();
    final location = context == null ? '' : ' for $context';
    throw UnsupportedError(
      'Provider reference$location does not contain an entry for '
      '"$providerId". Available providers: ${available.join(', ')}.',
    );
  }

  JsonMap toJsonMap({
    String path = r'$.providerReference',
  }) {
    final normalized = <String, Object?>{};
    for (final entry in values.entries) {
      _validateProviderId(entry.key, path: path);
      if (entry.value.isEmpty) {
        throw FormatException(
          'Expected non-empty provider reference value at $path.${entry.key}.',
        );
      }
      normalized[entry.key] = entry.value;
    }

    return Map<String, Object?>.unmodifiable(normalized);
  }

  static ProviderReference fromJson(
    Object? value, {
    String path = r'$.providerReference',
  }) {
    final map = asJsonMap(value, path: path);
    return ProviderReference(
      Map<String, String>.unmodifiable(
        map.map(
          (providerId, referenceValue) {
            _validateProviderId(providerId, path: path);
            return MapEntry(
              providerId,
              asJsonString(referenceValue, path: '$path.$providerId'),
            );
          },
        ),
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! ProviderReference || values.length != other.values.length) {
      return false;
    }

    for (final entry in values.entries) {
      if (other.values[entry.key] != entry.value) {
        return false;
      }
    }

    return true;
  }

  @override
  int get hashCode => Object.hashAll(
        values.entries.map((entry) => MapEntry(entry.key, entry.value)).toList()
          ..sort((left, right) => left.key.compareTo(right.key)),
      );

  @override
  String toString() => 'ProviderReference($values)';

  static void _validateProviderId(
    String providerId, {
    required String path,
  }) {
    if (_providerIdPattern.hasMatch(providerId)) {
      return;
    }

    throw FormatException(
      'Expected provider reference key at $path, got "$providerId".',
    );
  }
}
