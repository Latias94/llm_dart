import 'dart:convert';

import 'json_codec_common.dart';
import 'model_error_kind.dart';
import 'model_error_value_support.dart';

ModelErrorKind inferModelErrorKind(Object? error) {
  return switch (error) {
    FormatException() || ArgumentError() => ModelErrorKind.validation,
    StateError() => ModelErrorKind.stream,
    _ => ModelErrorKind.unknown,
  };
}

String extractModelErrorMessage(Object? error) {
  return switch (error) {
    null => 'Unknown error.',
    String() when error.trim().isNotEmpty => error,
    Map() =>
      _extractMapMessage(error) ?? _stringifyModelErrorStructuredValue(error),
    List() => _stringifyModelErrorStructuredValue(error),
    FormatException(:final message) => message,
    ArgumentError(:final message) when message != null => message.toString(),
    _ => '$error',
  };
}

String? extractModelErrorCode(Object? error) {
  return switch (error) {
    Map() => _extractMapString(
        error,
        const ['code', 'type', 'errorCode'],
      ),
    _ => null,
  };
}

int? extractModelErrorStatusCode(Object? error) {
  return switch (error) {
    Map() => _extractMapInt(
        error,
        const ['statusCode', 'status_code', 'httpStatus', 'http_status'],
      ),
    _ => null,
  };
}

bool? extractModelErrorRetryable(Object? error) {
  return switch (error) {
    Map() => _extractMapBool(
        error,
        const ['isRetryable', 'retryable'],
      ),
    _ => null,
  };
}

Object? defaultModelErrorDetails(Object? error) {
  return switch (error) {
    Map() || List() => error,
    FormatException(
      :final source,
      :final offset,
    ) =>
      {
        if (source != null) 'source': normalizeModelErrorDetails(source),
        if (offset != null) 'offset': offset,
      },
    ArgumentError(
      :final name,
      :final invalidValue,
    ) =>
      {
        if (name != null) 'name': name,
        if (invalidValue != null)
          'invalidValue': normalizeModelErrorDetails(invalidValue),
      },
    _ => null,
  };
}

String? extractModelErrorOriginalType(Object? error) {
  return switch (error) {
    null || String() || Map() || List() || bool() || num() => null,
    _ => error.runtimeType.toString(),
  };
}

Object? normalizeModelErrorDetails(Object? value) {
  if (value == null) {
    return null;
  }

  try {
    return freezeModelErrorJsonValue(
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

String _stringifyModelErrorStructuredValue(Object value) {
  try {
    return jsonEncode(value);
  } on JsonUnsupportedObjectError {
    return '$value';
  }
}
