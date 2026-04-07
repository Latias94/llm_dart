base class TransportException implements Exception {
  final String message;
  final Uri? uri;
  final Object? cause;

  const TransportException(
    this.message, {
    this.uri,
    this.cause,
  });

  @override
  String toString() {
    final buffer = StringBuffer(runtimeType);
    buffer.write('(');
    buffer.write('message: $message');
    if (uri != null) {
      buffer.write(', uri: $uri');
    }
    if (cause != null) {
      buffer.write(', cause: $cause');
    }
    buffer.write(')');
    return buffer.toString();
  }
}

final class TransportTimeoutException extends TransportException {
  const TransportTimeoutException(
    super.message, {
    super.uri,
    super.cause,
  });
}

final class TransportNetworkException extends TransportException {
  const TransportNetworkException(
    super.message, {
    super.uri,
    super.cause,
  });
}

final class TransportResponseFormatException extends TransportException {
  final Object? responseBody;

  const TransportResponseFormatException(
    super.message, {
    this.responseBody,
    super.uri,
    super.cause,
  });
}

final class TransportHttpException extends TransportException {
  final int statusCode;
  final Map<String, String> headers;
  final Object? responseBody;

  const TransportHttpException(
    super.message, {
    required this.statusCode,
    this.headers = const {},
    this.responseBody,
    super.uri,
    super.cause,
  });
}
