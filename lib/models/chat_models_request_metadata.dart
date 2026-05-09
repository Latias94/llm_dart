/// Reasoning effort levels for models that support reasoning
enum ReasoningEffort {
  minimal,
  low,
  medium,
  high;

  /// Convert to string value for API requests
  String get value {
    switch (this) {
      case ReasoningEffort.minimal:
        return 'minimal';
      case ReasoningEffort.low:
        return 'low';
      case ReasoningEffort.medium:
        return 'medium';
      case ReasoningEffort.high:
        return 'high';
    }
  }

  /// Create from string value
  static ReasoningEffort? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'minimal':
        return ReasoningEffort.minimal;
      case 'low':
        return ReasoningEffort.low;
      case 'medium':
        return ReasoningEffort.medium;
      case 'high':
        return ReasoningEffort.high;
      default:
        return null;
    }
  }
}

/// Verbosity levels for controlling output detail (GPT-5 feature)
enum Verbosity {
  low,
  medium,
  high;

  /// Convert to string value for API requests
  String get value {
    switch (this) {
      case Verbosity.low:
        return 'low';
      case Verbosity.medium:
        return 'medium';
      case Verbosity.high:
        return 'high';
    }
  }

  /// Create from string value
  static Verbosity? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'low':
        return Verbosity.low;
      case 'medium':
        return Verbosity.medium;
      case 'high':
        return Verbosity.high;
      default:
        return null;
    }
  }
}

/// Service tier levels for API requests
enum ServiceTier {
  auto,
  standard,
  priority;

  /// Convert to string value for API requests
  String get value {
    switch (this) {
      case ServiceTier.auto:
        return 'auto';
      case ServiceTier.standard:
        return 'standard_only';
      case ServiceTier.priority:
        return 'priority';
    }
  }

  /// Create from string value
  static ServiceTier? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'auto':
        return ServiceTier.auto;
      case 'standard':
      case 'standard_only':
        return ServiceTier.standard;
      case 'priority':
        return ServiceTier.priority;
      default:
        return null;
    }
  }
}

/// Request metadata for tracking and analytics
class RequestMetadata {
  /// External identifier for the user associated with the request
  final String? userId;

  /// Additional custom metadata
  final Map<String, dynamic>? customData;

  const RequestMetadata({
    this.userId,
    this.customData,
  });

  Map<String, dynamic> toJson() => {
        if (userId != null) 'user_id': userId,
        if (customData != null) ...customData!,
      };

  factory RequestMetadata.fromJson(Map<String, dynamic> json) =>
      RequestMetadata(
        userId: json['user_id'] as String?,
        customData: Map<String, dynamic>.from(json)..remove('user_id'),
      );

  @override
  String toString() =>
      'RequestMetadata(userId: $userId, customData: $customData)';
}
