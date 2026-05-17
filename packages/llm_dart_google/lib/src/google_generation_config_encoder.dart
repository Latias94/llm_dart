import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_language_model_policy.dart';
import 'google_options.dart';
import 'google_response_format.dart';

final class GoogleGenerationConfigEncoder {
  const GoogleGenerationConfigEncoder();

  Map<String, Object?> encode({
    required String modelId,
    required GenerateTextOptions options,
    required GoogleGenerateTextOptions providerOptions,
    required List<ModelWarning> warnings,
  }) {
    final policy = GoogleLanguageModelPolicy(modelId);
    final generationConfig = <String, Object?>{
      if (options.maxOutputTokens != null)
        'maxOutputTokens': options.maxOutputTokens,
      if (options.temperature != null) 'temperature': options.temperature,
      if (options.topP != null) 'topP': options.topP,
      if (options.topK != null) 'topK': options.topK,
      if (options.stopSequences != null && options.stopSequences!.isNotEmpty)
        'stopSequences': options.stopSequences,
      if (options.presencePenalty != null)
        'presencePenalty': options.presencePenalty,
      if (options.frequencyPenalty != null)
        'frequencyPenalty': options.frequencyPenalty,
      if (options.seed != null) 'seed': options.seed,
    };

    final resolvedCandidateCount = _resolveCandidateCount(
      providerOptions.candidateCount,
      warnings: warnings,
    );
    if (resolvedCandidateCount != null) {
      generationConfig['candidateCount'] = resolvedCandidateCount;
    }

    final thinkingConfig = policy.encodeThinkingConfig(
      options: options,
      providerOptions: providerOptions,
      warnings: warnings,
    );
    if (thinkingConfig != null) {
      generationConfig['thinkingConfig'] = thinkingConfig;
    }

    if (providerOptions.responseModalities case final modalities?
        when modalities.isNotEmpty) {
      generationConfig['responseModalities'] = [
        for (final modality in modalities) modality.value,
      ];
    }

    if (providerOptions.responseFormat case final responseFormat?) {
      generationConfig['responseMimeType'] = 'application/json';
      generationConfig['responseSchema'] =
          _normalizeGoogleResponseSchema(responseFormat);
    }

    return generationConfig;
  }

  Map<String, Object?> _normalizeGoogleResponseSchema(
    GoogleJsonSchemaResponseFormat responseFormat,
  ) {
    final normalized = Map<String, Object?>.from(responseFormat.schema);
    normalized.remove('additionalProperties');
    return normalized;
  }

  int? _resolveCandidateCount(
    int? value, {
    required List<ModelWarning> warnings,
  }) {
    if (value == null) {
      return null;
    }

    if (value <= 0) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'candidateCount',
          message: 'candidateCount must be greater than 0 for Google.',
        ),
      );
      return null;
    }

    if (value > 1) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'candidateCount',
          message:
              'The unified LanguageModel interface currently exposes a single result. candidateCount has been clamped to 1 for Google.',
        ),
      );
      return 1;
    }

    return value;
  }
}
