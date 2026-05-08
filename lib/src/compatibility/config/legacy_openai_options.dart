import '../../../models/chat_models.dart';
import '../../../models/tool_models.dart';
import '../../../providers/openai/builtin_tools.dart';
import 'legacy_config_keys.dart';
import 'legacy_provider_options.dart';

final class LegacyOpenAIFamilyOptions {
  final StructuredOutputFormat? jsonSchema;
  final bool useResponsesAPI;
  final String? previousResponseId;
  final List<OpenAIBuiltInTool>? builtInTools;
  final double? frequencyPenalty;
  final double? presencePenalty;
  final Map<String, double>? logitBias;
  final int? seed;
  final bool? parallelToolCalls;
  final bool? logprobs;
  final int? topLogprobs;
  final String? verbosity;

  const LegacyOpenAIFamilyOptions({
    required this.jsonSchema,
    required this.useResponsesAPI,
    required this.previousResponseId,
    required this.builtInTools,
    required this.frequencyPenalty,
    required this.presencePenalty,
    required this.logitBias,
    required this.seed,
    required this.parallelToolCalls,
    required this.logprobs,
    required this.topLogprobs,
    required this.verbosity,
  });
}

final class LegacyOpenAIHostedOptions {
  final Object? reasoningEffortValue;
  final String? voice;
  final String? embeddingEncodingFormat;
  final int? embeddingDimensions;

  const LegacyOpenAIHostedOptions({
    required this.reasoningEffortValue,
    required this.voice,
    required this.embeddingEncodingFormat,
    required this.embeddingDimensions,
  });

  ReasoningEffort? get reasoningEffort =>
      ReasoningEffort.fromString(_legacyStringValue(reasoningEffortValue));
}

LegacyOpenAIFamilyOptions legacyOpenAIFamilyOptions(
  LegacyProviderOptionView options,
) {
  return LegacyOpenAIFamilyOptions(
    jsonSchema: options.getWithFlatFallback<StructuredOutputFormat>(
      LegacyExtensionKeys.jsonSchema,
    ),
    useResponsesAPI: options
            .getWithFlatFallback<bool>(LegacyExtensionKeys.useResponsesApi) ??
        false,
    previousResponseId: options.getWithFlatFallback<String>(
      LegacyExtensionKeys.previousResponseId,
    ),
    builtInTools: options.getWithFlatFallback<List<OpenAIBuiltInTool>>(
      LegacyExtensionKeys.builtInTools,
    ),
    frequencyPenalty: options.getWithFlatFallback<double>(
      LegacyExtensionKeys.frequencyPenalty,
    ),
    presencePenalty: options.getWithFlatFallback<double>(
      LegacyExtensionKeys.presencePenalty,
    ),
    logitBias: options.getWithFlatFallback<Map<String, double>>(
      LegacyExtensionKeys.logitBias,
    ),
    seed: options.getWithFlatFallback<int>(LegacyExtensionKeys.seed),
    parallelToolCalls: options.getWithFlatFallback<bool>(
      LegacyExtensionKeys.parallelToolCalls,
    ),
    logprobs: options.getWithFlatFallback<bool>(LegacyExtensionKeys.logprobs),
    topLogprobs:
        options.getWithFlatFallback<int>(LegacyExtensionKeys.topLogprobs),
    verbosity:
        options.getWithFlatFallback<String>(LegacyExtensionKeys.verbosity),
  );
}

LegacyOpenAIHostedOptions legacyOpenAIHostedOptions(
  LegacyProviderOptionView options,
) {
  return LegacyOpenAIHostedOptions(
    reasoningEffortValue: options.getWithFlatFallback<dynamic>(
      LegacyExtensionKeys.reasoningEffort,
    ),
    voice: options.getWithFlatFallback<String>(LegacyExtensionKeys.voice),
    embeddingEncodingFormat: options.getWithFlatFallback<String>(
      LegacyExtensionKeys.embeddingEncodingFormat,
    ),
    embeddingDimensions: options.getWithFlatFallback<int>(
      LegacyExtensionKeys.embeddingDimensions,
    ),
  );
}

String? _legacyStringValue(Object? value) {
  return switch (value) {
    null => null,
    String() => value,
    ReasoningEffort() => value.value,
    _ => value.toString(),
  };
}
