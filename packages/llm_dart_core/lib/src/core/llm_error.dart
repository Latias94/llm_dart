import 'package:dio/dio.dart';

/// Error types that can occur when interacting with LLM providers.
abstract class LLMError implements Exception {
  final String message;

  const LLMError(this.message);

  @override
  String toString() => message;
}

/// HTTP request/response errors
class HttpError extends LLMError {
  const HttpError(super.message);

  @override
  String toString() => 'HTTP error: $message';
}

/// Authentication and authorization errors
class AuthError extends LLMError {
  const AuthError(super.message);

  @override
  String toString() => 'Authentication error: $message';
}

/// Invalid request parameters or format
class InvalidRequestError extends LLMError {
  const InvalidRequestError(super.message);

  @override
  String toString() => 'Invalid request: $message';
}

/// Errors returned by the LLM provider
class ProviderError extends LLMError {
  const ProviderError(super.message);

  @override
  String toString() => 'Provider error: $message';
}

/// API response parsing or format error
class ResponseFormatError extends LLMError {
  final String rawResponse;

  const ResponseFormatError(super.message, this.rawResponse);

  @override
  String toString() =>
      'Response format error: $message. Raw response: $rawResponse';
}

/// Generic error
class GenericError extends LLMError {
  const GenericError(super.message);

  @override
  String toString() => message;
}

/// Timeout error for request timeouts
class TimeoutError extends LLMError {
  const TimeoutError(super.message);

  @override
  String toString() => 'Request timeout: $message';
}

/// Resource not found error (404)
class NotFoundError extends LLMError {
  const NotFoundError(super.message);

  @override
  String toString() => 'Resource not found: $message';
}

/// JSON serialization/deserialization errors
class JsonError extends LLMError {
  const JsonError(super.message);

  @override
  String toString() => 'JSON parsing error: $message';
}

/// Tool configuration error
class ToolConfigError extends LLMError {
  const ToolConfigError(super.message);

  @override
  String toString() => 'Tool configuration error: $message';
}

/// Tool execution error
class ToolExecutionError extends LLMError {
  final String toolName;
  final String? toolId;
  final Map<String, dynamic>? toolArguments;

  const ToolExecutionError(
    super.message, {
    required this.toolName,
    this.toolId,
    this.toolArguments,
  });

  @override
  String toString() => 'Tool execution error ($toolName): $message';
}

/// Tool validation error
class ToolValidationError extends LLMError {
  final String toolName;
  final String? parameterName;
  final dynamic providedValue;
  final String? expectedType;

  const ToolValidationError(
    super.message, {
    required this.toolName,
    this.parameterName,
    this.providedValue,
    this.expectedType,
  });

  @override
  String toString() {
    final parts = ['Tool validation error ($toolName): $message'];
    if (parameterName != null) {
      parts.add('Parameter: $parameterName');
    }
    if (expectedType != null) {
      parts.add('Expected type: $expectedType');
    }
    if (providedValue != null) {
      parts.add('Provided value: $providedValue');
    }
    return parts.join(', ');
  }
}

/// Structured output validation error
class StructuredOutputError extends LLMError {
  final String? schemaName;
  final Map<String, dynamic>? schema;
  final String? actualOutput;

  const StructuredOutputError(
    super.message, {
    this.schemaName,
    this.schema,
    this.actualOutput,
  });

  @override
  String toString() => 'Structured output error: $message';
}

/// Rate limit exceeded error
class RateLimitError extends LLMError {
  final Duration? retryAfter;
  final int? remainingRequests;

  const RateLimitError(super.message,
      {this.retryAfter, this.remainingRequests});

  @override
  String toString() =>
      'Rate limit exceeded: $message${retryAfter != null ? ' (retry after ${retryAfter!.inSeconds}s)' : ''}';
}

/// Quota exceeded error
class QuotaExceededError extends LLMError {
  final String? quotaType; // 'tokens', 'requests', 'credits'

  const QuotaExceededError(super.message, {this.quotaType});

  @override
  String toString() =>
      'Quota exceeded: $message${quotaType != null ? ' (quota type: $quotaType)' : ''}';
}

/// Model not available error
class ModelNotAvailableError extends LLMError {
  final String model;
  final List<String>? availableModels;

  const ModelNotAvailableError(this.model, {this.availableModels})
      : super('Model not available: $model');

  @override
  String toString() {
    if (availableModels != null && availableModels!.isNotEmpty) {
      return '$message. Available models: ${availableModels!.join(', ')}';
    }
    return message;
  }
}

/// Request cancellation error
///
/// This error is thrown when a request is cancelled via CancelToken.
/// Use [CancellationHelper.isCancelled] to detect cancellation errors.
class CancelledError extends LLMError {
  const CancelledError([super.message = 'Request cancelled']);

  @override
  String toString() => 'Request cancelled: $message';
}

/// Content filter error
class ContentFilterError extends LLMError {
  final String? filterType; // 'safety', 'content_policy', etc.

  const ContentFilterError(super.message, {this.filterType});

  @override
  String toString() =>
      'Content filtered: $message${filterType != null ? ' (filter: $filterType)' : ''}';
}

/// Server error (5xx status codes)
class ServerError extends LLMError {
  final int? statusCode;

  const ServerError(super.message, {this.statusCode});

  @override
  String toString() =>
      'Server error: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

/// Unsupported capability error
///
/// Thrown when trying to build a provider with a capability it doesn't support.
/// This is used by the capability factory methods in LLMBuilder.
class UnsupportedCapabilityError extends LLMError {
  final String? providerId;
  final String? capabilityName;
  final List<String>? supportedProviders;

  const UnsupportedCapabilityError(
    super.message, {
    this.providerId,
    this.capabilityName,
    this.supportedProviders,
  });

  @override
  String toString() {
    final parts = ['Unsupported capability: $message'];
    if (providerId != null && capabilityName != null) {
      parts.add('Provider "$providerId" does not support $capabilityName');
    }
    if (supportedProviders != null && supportedProviders!.isNotEmpty) {
      parts.add('Supported providers: ${supportedProviders!.join(', ')}');
    }
    return parts.join('. ');
  }
}

/// OpenAI Responses API specific error
class OpenAIResponsesError extends LLMError {
  final String? responseId;
  final String? errorType;

  const OpenAIResponsesError(
    super.message, {
    this.responseId,
    this.errorType,
  });

  @override
  String toString() {
    final parts = ['OpenAI Responses API error: $message'];
    if (responseId != null) {
      parts.add('Response ID: $responseId');
    }
    if (errorType != null) {
      parts.add('Error type: $errorType');
    }
    return parts.join('. ');
  }
}

/// Dio error handler utility for consistent error handling across providers
class DioErrorHandler {
  /// Handle Dio errors and convert to appropriate LLM errors
  static LLMError handleDioError(DioException e, String providerName) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutError('${e.message}');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        if (statusCode != null) {
          // Extract clean error message from response data
          String errorMessage = data?.toString() ?? 'Unknown error';
          if (data is Map<String, dynamic>) {
            final error = data['error'];
            if (error is Map<String, dynamic>) {
              errorMessage = error['message']?.toString() ?? errorMessage;
            } else if (error is String) {
              errorMessage = error;
            }
          }
          return HttpErrorMapper.mapStatusCode(
            statusCode,
            errorMessage,
            data is Map<String, dynamic> ? data : null,
          );
        } else {
          return ProviderError('$providerName HTTP error: $data');
        }
      case DioExceptionType.cancel:
        return CancelledError(e.message ?? 'Request cancelled');
      case DioExceptionType.connectionError:
        return HttpError('Connection error: ${e.message}');
      case DioExceptionType.badCertificate:
        return HttpError('SSL certificate error: ${e.message}');
      case DioExceptionType.unknown:
        return GenericError('$providerName request failed: ${e.message}');
    }
  }
}

/// HTTP error mapper utility
class HttpErrorMapper {
  /// Map HTTP status code to appropriate LLM error
  static LLMError mapStatusCode(int statusCode, String message,
      [Map<String, dynamic>? responseData]) {
    // Check for specific error types based on response data
    if (responseData != null) {
      final specificError = _mapSpecificError(message, responseData);
      if (specificError != null) return specificError;
    }

    switch (statusCode) {
      case 400:
        return InvalidRequestError(message);
      case 401:
        return AuthError(message);
      case 402:
        // DeepSeek API specific: Insufficient Balance
        return QuotaExceededError(message, quotaType: 'credits');
      case 403:
        return AuthError('Forbidden: $message');
      case 404:
        final model = responseData?['model'] as String?;
        return ModelNotAvailableError(model ?? 'unknown');
      case 422:
        return InvalidRequestError('Validation error: $message');
      case 429:
        final retryAfter = responseData?['retry_after'] as int?;
        final remaining = responseData?['remaining_requests'] as int?;
        return RateLimitError(
          message,
          retryAfter: retryAfter != null ? Duration(seconds: retryAfter) : null,
          remainingRequests: remaining,
        );
      case 500:
        return ServerError(message, statusCode: statusCode);
      case 502:
        return ServerError('Bad Gateway: $message', statusCode: statusCode);
      case 503:
        return ServerError('Service Unavailable: $message',
            statusCode: statusCode);
      case 504:
        return ServerError('Gateway Timeout: $message', statusCode: statusCode);
      default:
        if (statusCode >= 400 && statusCode < 500) {
          return HttpError(message);
        } else if (statusCode >= 500) {
          return ServerError(message, statusCode: statusCode);
        } else {
          return HttpError(message);
        }
    }
  }

  /// Map specific error types based on error content
  static LLMError? _mapSpecificError(
      String message, Map<String, dynamic> responseData) {
    final errorField = responseData['error'];

    // Handle both Map and String error formats
    Map<String, dynamic>? error;
    String? errorType;
    String? errorCode;

    if (errorField is Map<String, dynamic>) {
      error = errorField;
      errorType = error['type'] as String?;
      errorCode = error['code'] as String?;
    } else if (errorField is String) {
      // If error is a string, use it as the error message
      // and try to extract type/code from the message
      if (errorField.toLowerCase().contains('authentication') ||
          errorField.toLowerCase().contains('api key')) {
        return AuthError(errorField);
      }
      if (errorField.toLowerCase().contains('quota') ||
          errorField.toLowerCase().contains('billing')) {
        return QuotaExceededError(errorField);
      }
      if (errorField.toLowerCase().contains('model') &&
          errorField.toLowerCase().contains('not found')) {
        return ModelNotAvailableError('unknown');
      }
      // For other string errors, return null to use default handling
      return null;
    } else {
      return null;
    }

    // Content filter errors
    if (errorType == 'content_filter' ||
        errorCode == 'content_filter' ||
        message.toLowerCase().contains('content policy') ||
        message.toLowerCase().contains('content filter')) {
      return ContentFilterError(message, filterType: errorType ?? errorCode);
    }

    // Model not available errors
    if (errorType == 'model_not_found' ||
        errorCode == 'model_not_found' ||
        message.toLowerCase().contains('model') &&
            message.toLowerCase().contains('not found')) {
      final model = error['model'] as String? ??
          responseData['model'] as String? ??
          'unknown';
      return ModelNotAvailableError(model);
    }

    // Quota exceeded errors
    if (errorType == 'insufficient_quota' ||
        errorCode == 'insufficient_quota' ||
        message.toLowerCase().contains('quota') ||
        message.toLowerCase().contains('billing')) {
      String? quotaType;
      if (message.toLowerCase().contains('token')) {
        quotaType = 'tokens';
      } else if (message.toLowerCase().contains('request')) {
        quotaType = 'requests';
      } else if (message.toLowerCase().contains('credit')) {
        quotaType = 'credits';
      }

      return QuotaExceededError(message, quotaType: quotaType);
    }

    return null;
  }

  /// Extract retry-after duration from response headers
  static Duration? extractRetryAfter(Map<String, dynamic>? headers) {
    if (headers == null) return null;

    final retryAfter = headers['retry-after'] ?? headers['Retry-After'];
    if (retryAfter == null) return null;

    if (retryAfter is int) {
      return Duration(seconds: retryAfter);
    } else if (retryAfter is String) {
      final seconds = int.tryParse(retryAfter);
      if (seconds != null) {
        return Duration(seconds: seconds);
      }
    }

    return null;
  }
}
