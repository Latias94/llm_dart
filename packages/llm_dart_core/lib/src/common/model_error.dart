import 'dart:convert';

import '../serialization/json_codec_common.dart';

enum ModelErrorKind {
  unknown,
  provider,
  transport,
  validation,
  stream,
}

final class ModelError {
  final ModelErrorKind kind;
  final String message;
  final String? code;
  final int? statusCode;
  final bool? isRetryable;
  final Object? details;
  final String? originalType;

  const ModelError({
    required this.kind,
    required this.message,
    this.code,
    this.statusCode,
    this.isRetryable,
    this.details,
    this.originalType,
  });

  factory ModelError.fromUnknown(
    Object? error, {
    ModelErrorKind? kind,
    String? code,
    int? statusCode,
    bool? isRetryable,
    Object? details,
  }) {
    if (error case final ModelError modelError) {
      return modelError;
    }

    final resolvedKind = kind ?? _inferKind(error);
    final normalizedDetails = _normalizeDetails(
      details ?? _defaultDetails(error),
    );

    return ModelError(
      kind: resolvedKind,
      message: _extractMessage(error),
      code: code ?? _extractCode(error),
      statusCode: statusCode ?? _extractStatusCode(error),
      isRetryable: isRetryable ?? _extractRetryable(error),
      details: normalizedDetails,
      originalType: _extractOriginalType(error),
    );
  }

  factory ModelError.fromJson(
    Object? value, {
    String path = r'$.error',
    ModelErrorKind fallbackKind = ModelErrorKind.unknown,
  }) {
    if (value == null) {
      return const ModelError(
        kind: ModelErrorKind.unknown,
        message: 'Unknown error.',
      );
    }

    if (value is Map) {
      final map = asJsonMap(value, path: path);
      if (map.containsKey('kind') && map.containsKey('message')) {
        return ModelError(
          kind: ModelErrorKind.values.byName(
            asJsonString(map['kind'], path: '$path.kind'),
          ),
          message: asJsonString(map['message'], path: '$path.message'),
          code: asNullableJsonString(map['code'], path: '$path.code'),
          statusCode: asNullableJsonInt(
            map['statusCode'],
            path: '$path.statusCode',
          ),
          isRetryable: asNullableJsonBool(
            map['isRetryable'],
            path: '$path.isRetryable',
          ),
          details: map['details'],
          originalType: asNullableJsonString(
            map['originalType'],
            path: '$path.originalType',
          ),
        );
      }
    }

    return ModelError.fromUnknown(
      value,
      kind: fallbackKind,
    );
  }

  JsonMap toJsonMap({
    String path = r'$.error',
  }) {
    return {
      'kind': kind.name,
      'message': message,
      if (code != null) 'code': code,
      if (statusCode != null) 'statusCode': statusCode,
      if (isRetryable != null) 'isRetryable': isRetryable,
      if (details != null)
        'details': ensureJsonValue(details, path: '$path.details'),
      if (originalType != null) 'originalType': originalType,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is ModelError &&
        other.kind == kind &&
        other.message == message &&
        other.code == code &&
        other.statusCode == statusCode &&
        other.isRetryable == isRetryable &&
        other.originalType == originalType &&
        _deepEquals(other.details, details);
  }

  @override
  int get hashCode => Object.hash(
        kind,
        message,
        code,
        statusCode,
        isRetryable,
        originalType,
        _deepHash(details),
      );

  @override
  String toString() {
    return 'ModelError('
        'kind: $kind, '
        'message: $message, '
        'code: $code, '
        'statusCode: $statusCode, '
        'isRetryable: $isRetryable, '
        'originalType: $originalType, '
        'details: $details'
        ')';
  }
}

ModelErrorKind _inferKind(Object? error) {
  return switch (error) {
    FormatException() || ArgumentError() => ModelErrorKind.validation,
    StateError() => ModelErrorKind.stream,
    _ => ModelErrorKind.unknown,
  };
}

String _extractMessage(Object? error) {
  return switch (error) {
    null => 'Unknown error.',
    String() when error.trim().isNotEmpty => error,
    Map() => _extractMapMessage(error) ?? _stringifyStructuredValue(error),
    List() => _stringifyStructuredValue(error),
    FormatException(:final message) => message,
    ArgumentError(:final message) when message != null => message.toString(),
    _ => '$error',
  };
}

String? _extractCode(Object? error) {
  return switch (error) {
    Map() => _extractMapString(
        error,
        const ['code', 'type', 'errorCode'],
      ),
    _ => null,
  };
}

int? _extractStatusCode(Object? error) {
  return switch (error) {
    Map() => _extractMapInt(
        error,
        const ['statusCode', 'status_code', 'httpStatus', 'http_status'],
      ),
    _ => null,
  };
}

bool? _extractRetryable(Object? error) {
  return switch (error) {
    Map() => _extractMapBool(
        error,
        const ['isRetryable', 'retryable'],
      ),
    _ => null,
  };
}

Object? _defaultDetails(Object? error) {
  return switch (error) {
    Map() || List() => error,
    FormatException(
      :final source,
      :final offset,
    ) =>
      {
        if (source != null) 'source': _normalizeDetails(source),
        if (offset != null) 'offset': offset,
      },
    ArgumentError(
      :final name,
      :final invalidValue,
    ) =>
      {
        if (name != null) 'name': name,
        if (invalidValue != null)
          'invalidValue': _normalizeDetails(invalidValue),
      },
    _ => null,
  };
}

String? _extractOriginalType(Object? error) {
  return switch (error) {
    null || String() || Map() || List() || bool() || num() => null,
    _ => error.runtimeType.toString(),
  };
}

Object? _normalizeDetails(Object? value) {
  if (value == null) {
    return null;
  }

  try {
    return _freezeJsonValue(
      ensureJsonValue(value, path: r'$.error.details'),
    );
  } on FormatException {
    return '$value';
  }
}

String? _extractMapMessage(Map value) {
  final message = value['message'];
  if (message is String && message.trim().isNotEmpty) {
    return message;
  }

  final error = value['error'];
  if (error is String && error.trim().isNotEmpty) {
    return error;
  }

  return null;
}

String? _extractMapString(
  Map value,
  List<String> keys,
) {
  for (final key in keys) {
    final candidate = value[key];
    if (candidate is String && candidate.isNotEmpty) {
      return candidate;
    }
  }

  return null;
}

int? _extractMapInt(
  Map value,
  List<String> keys,
) {
  for (final key in keys) {
    final candidate = value[key];
    if (candidate is int) {
      return candidate;
    }
  }

  return null;
}

bool? _extractMapBool(
  Map value,
  List<String> keys,
) {
  for (final key in keys) {
    final candidate = value[key];
    if (candidate is bool) {
      return candidate;
    }
  }

  return null;
}

String _stringifyStructuredValue(Object value) {
  try {
    return jsonEncode(value);
  } on JsonUnsupportedObjectError {
    return '$value';
  }
}

Object? _freezeJsonValue(Object? value) {
  return switch (value) {
    List() => List<Object?>.unmodifiable(value.map(_freezeJsonValue)),
    Map() => Map<String, Object?>.unmodifiable(
        asJsonMap(value, path: r'$.error.details').map((key, nested) {
          return MapEntry(key, _freezeJsonValue(nested));
        }),
      ),
    _ => value,
  };
}

bool _deepEquals(Object? left, Object? right) {
  if (identical(left, right)) {
    return true;
  }

  if (left is Map && right is Map) {
    if (left.length != right.length) {
      return false;
    }

    for (final entry in left.entries) {
      if (!right.containsKey(entry.key)) {
        return false;
      }

      if (!_deepEquals(entry.value, right[entry.key])) {
        return false;
      }
    }

    return true;
  }

  if (left is List && right is List) {
    if (left.length != right.length) {
      return false;
    }

    for (var index = 0; index < left.length; index += 1) {
      if (!_deepEquals(left[index], right[index])) {
        return false;
      }
    }

    return true;
  }

  return left == right;
}

int _deepHash(Object? value) {
  return switch (value) {
    null => 0,
    Map() => Object.hashAll(
        value.entries
            .map(
              (entry) => (
                key: entry.key.toString(),
                hash: Object.hash(
                  entry.key,
                  _deepHash(entry.value),
                ),
              ),
            )
            .toList()
          ..sort((left, right) => left.key.compareTo(right.key)),
      ),
    List() => Object.hashAll(value.map(_deepHash)),
    _ => value.hashCode,
  };
}
