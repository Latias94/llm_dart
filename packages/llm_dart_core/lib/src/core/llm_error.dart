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

// DioErrorHandler and HttpErrorMapper have been moved to the
// `llm_dart_provider_utils` package to keep `llm_dart_core` free of
// HTTP client dependencies. Providers should use the implementations
// from `llm_dart_provider_utils`.
