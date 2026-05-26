import 'model_error_kind.dart';

final class ModelException implements Exception {
  final ModelErrorKind kind;
  final String message;
  final String? code;
  final int? statusCode;
  final bool? isRetryable;
  final Object? details;
  final Object? cause;
  final String? originalType;

  const ModelException({
    required this.kind,
    required this.message,
    this.code,
    this.statusCode,
    this.isRetryable,
    this.details,
    this.cause,
    this.originalType,
  });

  const ModelException.provider({
    required this.message,
    this.code,
    this.statusCode,
    this.isRetryable,
    this.details,
    this.cause,
    this.originalType,
  }) : kind = ModelErrorKind.provider;

  const ModelException.transport({
    required this.message,
    this.code,
    this.statusCode,
    this.isRetryable,
    this.details,
    this.cause,
    this.originalType,
  }) : kind = ModelErrorKind.transport;

  const ModelException.validation({
    required this.message,
    this.code,
    this.statusCode,
    this.isRetryable,
    this.details,
    this.cause,
    this.originalType,
  }) : kind = ModelErrorKind.validation;

  const ModelException.stream({
    required this.message,
    this.code,
    this.statusCode,
    this.isRetryable,
    this.details,
    this.cause,
    this.originalType,
  }) : kind = ModelErrorKind.stream;

  @override
  String toString() {
    final buffer = StringBuffer('ModelException(');
    buffer.write('kind: $kind');
    buffer.write(', message: $message');
    if (code != null) {
      buffer.write(', code: $code');
    }
    if (statusCode != null) {
      buffer.write(', statusCode: $statusCode');
    }
    if (isRetryable != null) {
      buffer.write(', isRetryable: $isRetryable');
    }
    if (cause != null) {
      buffer.write(', cause: $cause');
    }
    buffer.write(')');
    return buffer.toString();
  }
}
