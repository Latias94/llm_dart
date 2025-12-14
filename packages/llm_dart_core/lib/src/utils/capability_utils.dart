import '../core/capability.dart';

/// Utility class for capability checking and safe execution.
///
/// Provides several helper methods based on capability enums and
/// interface detection, useful for:
/// - Checking at runtime whether a provider supports a capability;
/// - Safely executing operations based on capabilities (with fallback or errors);
/// - Building capability matrices and validation reports.
class CapabilityUtils {
  // ========== Basic Capability Checking ==========

  /// Simple capability check using interface type.
  ///
  /// The simplest capability check: use Dart's `is` operator to test
  /// whether the provider implements the interface.
  static bool hasCapability<T>(dynamic provider) {
    return provider is T;
  }

  /// Check capability using enum (requires [ProviderCapabilities]).
  ///
  /// Suitable for centralized capability management and dynamic queries.
  static bool supportsCapability(dynamic provider, LLMCapability capability) {
    if (provider is ProviderCapabilities) {
      return provider.supports(capability);
    }
    return false;
  }

  /// Check multiple capabilities at once.
  ///
  /// Useful when you have a strongly constrained set of required capabilities.
  static bool supportsAllCapabilities(
    dynamic provider,
    Set<LLMCapability> capabilities,
  ) {
    if (provider is! ProviderCapabilities) return false;
    return capabilities.every((cap) => provider.supports(cap));
  }

  /// Check if provider supports any of the given capabilities.
  ///
  /// Useful for graceful-degradation scenarios where any capability
  /// in the set is acceptable.
  static bool supportsAnyCapability(
    dynamic provider,
    Set<LLMCapability> capabilities,
  ) {
    if (provider is! ProviderCapabilities) return false;
    return capabilities.any((cap) => provider.supports(cap));
  }

  // ========== Safe Execution Patterns ==========

  /// Execute action safely with capability check.
  ///
  /// If the provider does not implement capability `T`, returns `null`
  /// instead of throwing an exception.
  static Future<R?> withCapability<T, R>(
    dynamic provider,
    Future<R> Function(T) action,
  ) async {
    if (provider is T) {
      return await action(provider);
    }
    return null;
  }

  /// Execute action safely with error handling.
  ///
  /// Throws [CapabilityError] if the provider does not support `T`.
  static Future<R> requireCapability<T, R>(
    dynamic provider,
    Future<R> Function(T) action, {
    String? capabilityName,
  }) async {
    if (provider is! T) {
      throw CapabilityError(
        'Provider does not support ${capabilityName ?? T.toString()}',
      );
    }
    return await action(provider);
  }

  /// Execute action with fallback if capability not supported.
  ///
  /// Executes [fallback] when the capability is not supported; useful
  /// for progressive enhancement / graceful degradation patterns.
  static Future<R> withFallback<T, R>(
    dynamic provider,
    Future<R> Function(T) action,
    Future<R> Function() fallback,
  ) async {
    if (provider is T) {
      return await action(provider);
    }
    return await fallback();
  }

  /// Execute multiple actions based on available capabilities.
  ///
  /// Selects which actions to run based on the provider's capabilities
  /// and returns a result map.
  static Future<Map<String, dynamic>> executeByCapabilities(
    dynamic provider,
    Map<LLMCapability, Future<dynamic> Function()> actions,
  ) async {
    final results = <String, dynamic>{};

    if (provider is! ProviderCapabilities) {
      return results;
    }

    for (final entry in actions.entries) {
      if (provider.supports(entry.key)) {
        try {
          results[entry.key.name] = await entry.value();
        } catch (e) {
          results[entry.key.name] = 'Error: $e';
        }
      } else {
        results[entry.key.name] = 'Not supported';
      }
    }

    return results;
  }

  // ========== Specific Capability Helpers ==========

  /// File management helper.
  static Future<R?> withFileManagement<R>(
    dynamic provider,
    Future<R> Function(FileManagementCapability) action,
  ) async {
    return await withCapability<FileManagementCapability, R>(provider, action);
  }

  /// Moderation helper.
  static Future<R?> withModeration<R>(
    dynamic provider,
    Future<R> Function(ModerationCapability) action,
  ) async {
    return await withCapability<ModerationCapability, R>(provider, action);
  }

  /// Assistant helper.
  static Future<R?> withAssistant<R>(
    dynamic provider,
    Future<R> Function(AssistantCapability) action,
  ) async {
    return await withCapability<AssistantCapability, R>(provider, action);
  }

  // ========== Capability Discovery ==========

  /// Get all supported capabilities for a provider.
  static Set<LLMCapability> getCapabilities(dynamic provider) {
    if (provider is ProviderCapabilities) {
      return provider.supportedCapabilities;
    }

    // Fallback: detect capabilities through interface checking.
    return _detectCapabilities(provider);
  }

  /// Get capability summary as human-readable map.
  static Map<String, bool> getCapabilitySummary(dynamic provider) {
    final capabilities = LLMCapability.values;
    final summary = <String, bool>{};

    if (provider is ProviderCapabilities) {
      for (final cap in capabilities) {
        summary[cap.name] = provider.supports(cap);
      }
    } else {
      final detected = _detectCapabilities(provider);
      for (final cap in capabilities) {
        summary[cap.name] = detected.contains(cap);
      }
    }

    return summary;
  }

  /// Find missing capabilities for a set of requirements.
  static Set<LLMCapability> getMissingCapabilities(
    dynamic provider,
    Set<LLMCapability> required,
  ) {
    final supported = getCapabilities(provider);
    return required.difference(supported);
  }

  // ========== Validation Helpers ==========

  /// Validate provider meets minimum requirements.
  static bool validateRequirements(
    dynamic provider,
    Set<LLMCapability> required,
  ) {
    final missing = getMissingCapabilities(provider, required);
    return missing.isEmpty;
  }

  /// Get validation report.
  static CapabilityValidationReport validateProvider(
    dynamic provider,
    Set<LLMCapability> required,
  ) {
    final supported = getCapabilities(provider);
    final missing = required.difference(supported);
    final extra = supported.difference(required);

    return CapabilityValidationReport(
      isValid: missing.isEmpty,
      supported: supported,
      required: required,
      missing: missing,
      extra: extra,
    );
  }

  // ========== Private Helpers ==========

  /// Detect capabilities through interface checking (fallback).
  static Set<LLMCapability> _detectCapabilities(dynamic provider) {
    final capabilities = <LLMCapability>{};

    if (provider is ChatCapability) {
      capabilities.add(LLMCapability.chat);
    }
    if (provider is EmbeddingCapability) {
      capabilities.add(LLMCapability.embedding);
    }
    if (provider is FileManagementCapability) {
      capabilities.add(LLMCapability.fileManagement);
    }
    if (provider is ModerationCapability) {
      capabilities.add(LLMCapability.moderation);
    }
    if (provider is AssistantCapability) {
      capabilities.add(LLMCapability.assistants);
    }
    if (provider is AudioCapability) {
      if (provider.supportedFeatures.contains(AudioFeature.textToSpeech)) {
        capabilities.add(LLMCapability.textToSpeech);
      }
      if (provider.supportedFeatures.contains(AudioFeature.speechToText)) {
        capabilities.add(LLMCapability.speechToText);
      }
    }
    if (provider is ModelListingCapability) {
      capabilities.add(LLMCapability.modelListing);
    }
    if (provider is ImageGenerationCapability) {
      capabilities.add(LLMCapability.imageGeneration);
    }

    return capabilities;
  }
}

/// Error thrown when a required capability is not supported.
class CapabilityError extends Error {
  final String message;

  CapabilityError(this.message);

  @override
  String toString() => 'CapabilityError: $message';
}

/// Validation report for provider capabilities.
class CapabilityValidationReport {
  final bool isValid;
  final Set<LLMCapability> supported;
  final Set<LLMCapability> required;
  final Set<LLMCapability> missing;
  final Set<LLMCapability> extra;

  const CapabilityValidationReport({
    required this.isValid,
    required this.supported,
    required this.required,
    required this.missing,
    required this.extra,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Capability Validation Report:');
    buffer.writeln('  Valid: $isValid');
    buffer.writeln('  Supported: ${supported.length} capabilities');
    buffer.writeln('  Required: ${required.length} capabilities');

    if (missing.isNotEmpty) {
      buffer.writeln('  Missing: ${missing.map((c) => c.name).join(', ')}');
    }

    if (extra.isNotEmpty) {
      buffer.writeln('  Extra: ${extra.map((c) => c.name).join(', ')}');
    }

    return buffer.toString();
  }
}
