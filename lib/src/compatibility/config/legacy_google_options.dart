import '../../../models/tool_models.dart';
import '../../../providers/google/config.dart';
import 'legacy_config_keys.dart';
import 'legacy_provider_options.dart';

const legacyGoogleDefaultMaxInlineDataSize = 20 * 1024 * 1024;

final class LegacyGoogleOptions {
  final StructuredOutputFormat? jsonSchema;
  final bool? enableImageGeneration;
  final List<dynamic>? _rawResponseModalities;
  final List<SafetySetting>? safetySettings;
  final int maxInlineDataSize;
  final int? candidateCount;
  final String? embeddingTaskType;
  final String? embeddingTitle;
  final int? embeddingDimensions;

  const LegacyGoogleOptions({
    required this.jsonSchema,
    required this.enableImageGeneration,
    required List<dynamic>? rawResponseModalities,
    required this.safetySettings,
    required this.maxInlineDataSize,
    required this.candidateCount,
    required this.embeddingTaskType,
    required this.embeddingTitle,
    required this.embeddingDimensions,
  }) : _rawResponseModalities = rawResponseModalities;

  List<String>? get responseModalities =>
      _stringListOrNull(_rawResponseModalities);

  bool get hasChatBridgeSupportedResponseModalities {
    final responseModalities = _rawResponseModalities;
    if (responseModalities == null) {
      return true;
    }

    return responseModalities.every(
      (value) => value == 'TEXT' || value == 'IMAGE',
    );
  }

  bool get hasStructuredOutputChatBridgeConflict {
    if (jsonSchema == null) {
      return false;
    }

    if (enableImageGeneration == true) {
      return true;
    }

    final responseModalities = _rawResponseModalities;
    if (responseModalities == null) {
      return false;
    }

    return responseModalities.any(
      (value) => value.toString().toUpperCase() != 'TEXT',
    );
  }
}

LegacyGoogleOptions legacyGoogleOptions(
  LegacyProviderOptionView options,
) {
  final responseModalities = options.getWithFlatFallback<List<dynamic>>(
    LegacyExtensionKeys.responseModalities,
  );

  return LegacyGoogleOptions(
    jsonSchema: options.getWithFlatFallback<StructuredOutputFormat>(
      LegacyExtensionKeys.jsonSchema,
    ),
    enableImageGeneration: options.getWithFlatFallback<bool>(
      LegacyExtensionKeys.enableImageGeneration,
    ),
    rawResponseModalities: responseModalities,
    safetySettings: options.getWithFlatFallback<List<SafetySetting>>(
      LegacyExtensionKeys.safetySettings,
    ),
    maxInlineDataSize: options.getWithFlatFallback<int>(
          LegacyExtensionKeys.maxInlineDataSize,
        ) ??
        legacyGoogleDefaultMaxInlineDataSize,
    candidateCount: options.getWithFlatFallback<int>(
      LegacyExtensionKeys.candidateCount,
    ),
    embeddingTaskType: options.getWithFlatFallback<String>(
      LegacyExtensionKeys.embeddingTaskType,
    ),
    embeddingTitle: options.getWithFlatFallback<String>(
      LegacyExtensionKeys.embeddingTitle,
    ),
    embeddingDimensions: options.getWithFlatFallback<int>(
      LegacyExtensionKeys.embeddingDimensions,
    ),
  );
}

List<String>? _stringListOrNull(List<dynamic>? values) {
  if (values == null) {
    return null;
  }

  return values.map((value) => value as String).toList(growable: false);
}
