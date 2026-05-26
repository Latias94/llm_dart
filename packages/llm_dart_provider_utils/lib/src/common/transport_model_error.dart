import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

ModelError transportErrorToModelError(Object error) {
  if (error case final ModelError modelError) {
    return modelError;
  }

  return modelErrorFrom(
    switch (error) {
      ProviderCancelledException(:final reason) => ModelException.transport(
          message: reason?.toString() ?? error.message,
          code: 'transport-cancelled',
          isRetryable: false,
          details: {
            if (error.reason != null) 'reason': _jsonSafeOrString(error.reason),
          },
          originalType: error.runtimeType.toString(),
        ),
      TransportHttpException() => ModelException.transport(
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
          cause: error,
          originalType: error.runtimeType.toString(),
        ),
      TransportTimeoutException() => ModelException.transport(
          message: error.message,
          code: 'transport-timeout',
          isRetryable: true,
          details: {
            if (error.uri != null) 'uri': error.uri.toString(),
          },
          cause: error,
          originalType: error.runtimeType.toString(),
        ),
      TransportNetworkException() => ModelException.transport(
          message: error.message,
          code: 'transport-network',
          isRetryable: true,
          details: {
            if (error.uri != null) 'uri': error.uri.toString(),
          },
          cause: error,
          originalType: error.runtimeType.toString(),
        ),
      TransportResponseFormatException() => ModelException.transport(
          message: error.message,
          code: 'transport-response-format',
          isRetryable: false,
          details: {
            if (error.uri != null) 'uri': error.uri.toString(),
            if (error.responseBody != null)
              'responseBody': _jsonSafeOrString(error.responseBody),
          },
          cause: error,
          originalType: error.runtimeType.toString(),
        ),
      TransportCancelledException(:final reason) => ModelException.transport(
          message: reason?.toString() ?? error.message,
          code: 'transport-cancelled',
          isRetryable: false,
          details: {
            if (error.reason != null) 'reason': _jsonSafeOrString(error.reason),
          },
          cause: error,
          originalType: error.runtimeType.toString(),
        ),
      TransportException() => ModelException.transport(
          message: error.message,
          code: 'transport-error',
          details: {
            if (error.uri != null) 'uri': error.uri.toString(),
          },
          cause: error,
          originalType: error.runtimeType.toString(),
        ),
      _ => modelErrorFrom(
          error,
          kind: ModelErrorKind.transport,
        ),
    },
  );
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
