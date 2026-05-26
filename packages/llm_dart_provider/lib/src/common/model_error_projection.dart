import 'model_error.dart';

ModelError modelErrorFrom(
  Object? error, {
  ModelErrorKind? kind,
  String? code,
  int? statusCode,
  bool? isRetryable,
  Object? details,
}) {
  return ModelError.fromUnknown(
    error,
    kind: kind,
    code: code,
    statusCode: statusCode,
    isRetryable: isRetryable,
    details: details,
  );
}
