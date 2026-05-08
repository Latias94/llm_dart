import '../../../models/tool_models.dart';
import '../../../providers/google/config.dart';
import 'legacy_config_keys.dart';
import 'legacy_provider_options.dart';

const legacyGoogleDefaultMaxInlineDataSize = 20 * 1024 * 1024;

final class LegacyGoogleOptions {
  final StructuredOutputFormat? jsonSchema;
  final bool? enableImageGeneration;
  final List<String>? responseModalities;
  final List<SafetySetting>? safetySettings;
  final int maxInlineDataSize;
  final int? candidateCount;
  final String? embeddingTaskType;
  final String? embeddingTitle;
  final int? embeddingDimensions;

  const LegacyGoogleOptions({
    required this.jsonSchema,
    required this.enableImageGeneration,
    required this.responseModalities,
    required this.safetySettings,
    required this.maxInlineDataSize,
    required this.candidateCount,
    required this.embeddingTaskType,
    required this.embeddingTitle,
    required this.embeddingDimensions,
  });
}

LegacyGoogleOptions legacyGoogleOptions(
  LegacyProviderOptionView options,
) {
  return LegacyGoogleOptions(
    jsonSchema: options.getWithFlatFallback<StructuredOutputFormat>(
      LegacyExtensionKeys.jsonSchema,
    ),
    enableImageGeneration: options.getWithFlatFallback<bool>(
      LegacyExtensionKeys.enableImageGeneration,
    ),
    responseModalities: options.getWithFlatFallback<List<String>>(
      LegacyExtensionKeys.responseModalities,
    ),
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
