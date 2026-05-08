import '../../../models/tool_models.dart';
import 'legacy_config_keys.dart';
import 'legacy_provider_options.dart';

final class LegacyOllamaOptions {
  final StructuredOutputFormat? jsonSchema;
  final int? numCtx;
  final int? numGpu;
  final int? numThread;
  final bool? numa;
  final int? numBatch;
  final String? keepAlive;
  final bool? raw;
  final bool? reasoning;

  const LegacyOllamaOptions({
    required this.jsonSchema,
    required this.numCtx,
    required this.numGpu,
    required this.numThread,
    required this.numa,
    required this.numBatch,
    required this.keepAlive,
    required this.raw,
    required this.reasoning,
  });
}

LegacyOllamaOptions legacyOllamaOptions(
  LegacyProviderOptionView options,
) {
  return LegacyOllamaOptions(
    jsonSchema: options.getWithFlatFallback<StructuredOutputFormat>(
      LegacyExtensionKeys.jsonSchema,
    ),
    numCtx: options.getWithFlatFallback<int>(LegacyExtensionKeys.numCtx),
    numGpu: options.getWithFlatFallback<int>(LegacyExtensionKeys.numGpu),
    numThread: options.getWithFlatFallback<int>(
      LegacyExtensionKeys.numThread,
    ),
    numa: options.getWithFlatFallback<bool>(LegacyExtensionKeys.numa),
    numBatch: options.getWithFlatFallback<int>(
      LegacyExtensionKeys.numBatch,
    ),
    keepAlive:
        options.getWithFlatFallback<String>(LegacyExtensionKeys.keepAlive),
    raw: options.getWithFlatFallback<bool>(LegacyExtensionKeys.raw),
    reasoning: options.getWithFlatFallback<bool>(LegacyExtensionKeys.reasoning),
  );
}
