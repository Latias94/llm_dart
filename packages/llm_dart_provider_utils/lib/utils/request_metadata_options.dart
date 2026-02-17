import 'package:llm_dart_core/llm_dart_core.dart';

/// Whether to emit [LLMRequestMetadataPart] from provider streaming code.
///
/// This is an opt-in debug/observability feature, aligned with the AI SDK's
/// `LanguageModelRequestMetadata` concept.
///
/// Supported keys:
/// - `emitRequestMetadata` (preferred)
bool emitRequestMetadataEnabled(
  ProviderOptions providerOptions,
  String providerId, {
  String? fallbackProviderId,
}) {
  return readProviderOption<bool>(
        providerOptions,
        providerId,
        'emitRequestMetadata',
        fallbackProviderId: fallbackProviderId,
      ) ??
      false;
}
