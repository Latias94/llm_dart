import 'json_codec_common.dart';
import 'model_error_kind.dart';
import 'model_error_normalization.dart';
import 'model_error_value_support.dart';
import 'model_exception.dart';

export 'model_error_kind.dart';

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

    if (error case final ModelException exception) {
      return ModelError(
        kind: kind ?? exception.kind,
        message: exception.message,
        code: code ?? exception.code,
        statusCode: statusCode ?? exception.statusCode,
        isRetryable: isRetryable ?? exception.isRetryable,
        details: normalizeModelErrorDetails(details ?? exception.details),
        originalType:
            exception.originalType ?? exception.runtimeType.toString(),
      );
    }

    final resolvedKind = kind ?? inferModelErrorKind(error);
    final normalizedDetails = normalizeModelErrorDetails(
      details ?? defaultModelErrorDetails(error),
    );

    return ModelError(
      kind: resolvedKind,
      message: extractModelErrorMessage(error),
      code: code ?? extractModelErrorCode(error),
      statusCode: statusCode ?? extractModelErrorStatusCode(error),
      isRetryable: isRetryable ?? extractModelErrorRetryable(error),
      details: normalizedDetails,
      originalType: extractModelErrorOriginalType(error),
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
        modelErrorDeepEquals(other.details, details);
  }

  @override
  int get hashCode => Object.hash(
        kind,
        message,
        code,
        statusCode,
        isRetryable,
        originalType,
        modelErrorDeepHash(details),
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
