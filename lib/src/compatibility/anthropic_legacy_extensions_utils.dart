part of 'anthropic_legacy_extensions.dart';

AnthropicLegacyCacheControl _parseCacheControl(
  Object? value, {
  required String path,
}) {
  final map = _asMap(value, path: path);
  final type = map['type'];
  if (type is! String || type.isEmpty) {
    throw UnsupportedError('Anthropic cache control at $path requires a type.');
  }

  if (type != 'ephemeral') {
    throw UnsupportedError(
      'Anthropic compatibility only supports ephemeral cache controls today.',
    );
  }

  final ttl = map['ttl'];
  if (ttl != null && (ttl is! String || ttl.isEmpty)) {
    throw UnsupportedError(
      'Anthropic cache control ttl at $path must be a non-empty string when provided.',
    );
  }

  return AnthropicLegacyCacheControl.ephemeral(
    ttl: ttl as String?,
  );
}

String _parseRequiredString(
  Object? value, {
  required String path,
}) {
  if (value is! String || value.isEmpty) {
    throw UnsupportedError(
      'Expected a non-empty string at $path.',
    );
  }

  return value;
}

Uri _parseHttpUri(
  Object? value, {
  required String path,
}) {
  final raw = _parseRequiredString(
    value,
    path: path,
  );
  final uri = Uri.tryParse(raw);
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    throw UnsupportedError(
      'Expected an HTTP or HTTPS URI at $path.',
    );
  }

  return uri;
}

List<int> _decodeBase64(
  String value, {
  required String path,
}) {
  try {
    return base64Decode(value);
  } catch (_) {
    throw UnsupportedError(
      'Expected valid base64 data at $path.',
    );
  }
}

Object? _normalizeJsonPayload(
  Object? value, {
  required String path,
}) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }

  if (value is List) {
    return [
      for (var index = 0; index < value.length; index++)
        _normalizeJsonPayload(
          value[index],
          path: '$path[$index]',
        ),
    ];
  }

  if (value is Map) {
    final normalized = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw UnsupportedError('Expected a string key at $path.');
      }

      normalized[entry.key as String] = _normalizeJsonPayload(
        entry.value,
        path: '$path.${entry.key}',
      );
    }
    return normalized;
  }

  throw UnsupportedError(
    'Expected a JSON-safe value at $path, but received ${value.runtimeType}.',
  );
}

Map<String, Object?> _asMap(
  Object? value, {
  required String path,
}) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return value.map(
      (key, nestedValue) {
        if (key is! String) {
          throw UnsupportedError('Expected a string key at $path.');
        }

        return MapEntry(key, _toObject(nestedValue));
      },
    );
  }

  throw UnsupportedError('Expected a map at $path.');
}

Object? _toObject(Object? value) {
  if (value == null || value is bool || value is num || value is String) {
    return value;
  }

  if (value is List) {
    return value.map(_toObject).toList(growable: false);
  }

  if (value is Map) {
    return value.map(
      (key, nestedValue) {
        if (key is! String) {
          throw UnsupportedError(
            'Expected a string key in Anthropic legacy metadata.',
          );
        }

        return MapEntry(key, _toObject(nestedValue));
      },
    );
  }

  return value.toString();
}

dynamic _toDynamic(Object? value) {
  if (value == null || value is bool || value is num || value is String) {
    return value;
  }

  if (value is List) {
    return value.map(_toDynamic).toList(growable: false);
  }

  if (value is Map<String, Object?>) {
    return value.map(
      (key, nestedValue) => MapEntry(key, _toDynamic(nestedValue)),
    );
  }

  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(
        key.toString(),
        _toDynamic(nestedValue),
      ),
    );
  }

  return value.toString();
}
