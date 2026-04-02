import 'package:llm_dart_core/llm_dart_core.dart';

import 'transport_exception.dart';

ModelError transportErrorToModelError(Object error) {
  if (error case final ModelError modelError) {
    return modelError;
  }

  return switch (error) {
    TransportHttpException() => ModelError(
        kind: ModelErrorKind.transport,
        message: error.message,
        code: 'transport-http',
        statusCode: error.statusCode,
        isRetryable: _isRetryableStatusCode(error.statusCode),
        details: {
          if (error.uri != null) 'uri': error.uri.toString(),
          if (error.headers.isNotEmpty) 'headers': error.headers,
          if (error.responseBody != null)
            'responseBody': _jsonSafeOrString(error.responseBody),
        },
        originalType: error.runtimeType.toString(),
      ),
    TransportTimeoutException() => ModelError(
        kind: ModelErrorKind.transport,
        message: error.message,
        code: 'transport-timeout',
        isRetryable: true,
        details: {
          if (error.uri != null) 'uri': error.uri.toString(),
        },
        originalType: error.runtimeType.toString(),
      ),
    TransportNetworkException() => ModelError(
        kind: ModelErrorKind.transport,
        message: error.message,
        code: 'transport-network',
        isRetryable: true,
        details: {
          if (error.uri != null) 'uri': error.uri.toString(),
        },
        originalType: error.runtimeType.toString(),
      ),
    TransportResponseFormatException() => ModelError(
        kind: ModelErrorKind.transport,
        message: error.message,
        code: 'transport-response-format',
        isRetryable: false,
        details: {
          if (error.uri != null) 'uri': error.uri.toString(),
        },
        originalType: error.runtimeType.toString(),
      ),
    TransportCancelledException() => ModelError(
        kind: ModelErrorKind.transport,
        message: error.message,
        code: 'transport-cancelled',
        isRetryable: false,
        details: {
          if (error.reason != null) 'reason': _jsonSafeOrString(error.reason),
        },
        originalType: error.runtimeType.toString(),
      ),
    TransportException() => ModelError(
        kind: ModelErrorKind.transport,
        message: error.message,
        code: 'transport-error',
        details: {
          if (error.uri != null) 'uri': error.uri.toString(),
        },
        originalType: error.runtimeType.toString(),
      ),
    _ => ModelError.fromUnknown(
        error,
        kind: ModelErrorKind.transport,
      ),
  };
}

bool _isRetryableStatusCode(int statusCode) {
  return statusCode == 408 ||
      statusCode == 409 ||
      statusCode == 429 ||
      statusCode >= 500;
}

Object? _jsonSafeOrString(Object? value) {
  return switch (value) {
    null || bool() || num() || String() => value,
    List() => value.map(_jsonSafeOrString).toList(growable: false),
    Map() => value.map((key, nestedValue) {
        return MapEntry(
          key.toString(),
          _jsonSafeOrString(nestedValue),
        );
      }),
    _ => '$value',
  };
}
