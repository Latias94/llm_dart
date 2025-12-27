import '../core/capability.dart';

/// Utility class for capability checking and safe execution.
///
/// This stays out of provider packages and focuses on capability interfaces
/// and `LLMCapability` enums (standard surface).
class CapabilityUtils {
  // ========== Basic Capability Checking ==========

  /// Simple capability check using interface type.
  static bool hasCapability<T>(dynamic provider) {
    return provider is T;
  }

  /// Check capability using enum (requires ProviderCapabilities).
  static bool supportsCapability(dynamic provider, LLMCapability capability) {
    if (provider is ProviderCapabilities) {
      return provider.supports(capability);
    }
    return false;
  }

  /// Check multiple capabilities at once.
  static bool supportsAllCapabilities(
    dynamic provider,
    Set<LLMCapability> capabilities,
  ) {
    if (provider is! ProviderCapabilities) return false;
    return capabilities.every((cap) => provider.supports(cap));
  }

  /// Check if provider supports any of the given capabilities.
  static bool supportsAnyCapability(
    dynamic provider,
    Set<LLMCapability> capabilities,
  ) {
    if (provider is! ProviderCapabilities) return false;
    return capabilities.any((cap) => provider.supports(cap));
  }

  // ========== Safe Execution Patterns ==========

  /// Execute action safely with capability check.
  /// Returns null if capability not supported.
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
  /// Throws CapabilityError if not supported.
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

  static Future<R?> withFileManagement<R>(
    dynamic provider,
    Future<R> Function(FileManagementCapability) action,
  ) async {
    return await withCapability<FileManagementCapability, R>(provider, action);
  }

  static Future<R?> withModeration<R>(
    dynamic provider,
    Future<R> Function(ModerationCapability) action,
  ) async {
    return await withCapability<ModerationCapability, R>(provider, action);
  }

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

    // Fallback: detect capabilities through interface checking
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

  static Set<LLMCapability> getMissingCapabilities(
    dynamic provider,
    Set<LLMCapability> required,
  ) {
    final supported = getCapabilities(provider);
    return required.difference(supported);
  }

  // ========== Validation Helpers ==========

  static bool validateRequirements(
    dynamic provider,
    Set<LLMCapability> required,
  ) {
    final missing = getMissingCapabilities(provider, required);
    return missing.isEmpty;
  }

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

  static Set<LLMCapability> _detectCapabilities(dynamic provider) {
    final detected = <LLMCapability>{};
    if (provider is ChatCapability) {
      detected.add(LLMCapability.chat);
      detected.add(LLMCapability.streaming);
    }

    if (provider is EmbeddingCapability) {
      detected.add(LLMCapability.embedding);
    }
    if (provider is CompletionCapability) {
      detected.add(LLMCapability.completion);
    }

    if (provider is ImageGenerationCapability) {
      detected.add(LLMCapability.imageGeneration);
    }

    if (provider is AudioCapability) {
      try {
        final features = provider.supportedFeatures;
        if (features.contains(AudioFeature.textToSpeech)) {
          detected.add(LLMCapability.textToSpeech);
        }
        if (features.contains(AudioFeature.streamingTTS)) {
          detected.add(LLMCapability.streamingTextToSpeech);
        }
        if (features.contains(AudioFeature.speechToText)) {
          detected.add(LLMCapability.speechToText);
        }
        if (features.contains(AudioFeature.audioTranslation)) {
          detected.add(LLMCapability.audioTranslation);
        }
        if (features.contains(AudioFeature.realtimeProcessing)) {
          detected.add(LLMCapability.realtimeAudio);
        }
      } catch (_) {
        // If feature discovery fails, don't infer audio capabilities.
      }
    }

    if (provider is FileManagementCapability) {
      detected.add(LLMCapability.fileManagement);
    }
    if (provider is ModerationCapability) {
      detected.add(LLMCapability.moderation);
    }
    if (provider is AssistantCapability) {
      detected.add(LLMCapability.assistants);
    }
    if (provider is ModelListingCapability) {
      detected.add(LLMCapability.modelListing);
    }
    return detected;
  }
}

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
    return 'CapabilityValidationReport(isValid: $isValid, missing: $missing, extra: $extra)';
  }
}

class CapabilityError implements Exception {
  final String message;
  const CapabilityError(this.message);

  @override
  String toString() => 'CapabilityError: $message';
}
