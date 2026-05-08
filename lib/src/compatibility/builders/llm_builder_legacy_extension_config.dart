import '../../../builder/llm_builder.dart';
import '../../../models/chat_models.dart';
import '../../../models/tool_models.dart';
import '../config/legacy_config_keys.dart';

/// Legacy extension-key convenience methods layered on top of [LLMBuilder].
extension LLMBuilderLegacyExtensionConfig on LLMBuilder {
  /// Sets the reasoning effort for models that support it.
  LLMBuilder reasoningEffort(ReasoningEffort? effort) =>
      legacyExtension(LegacyExtensionKeys.reasoningEffort, effort?.value);

  /// Sets structured output schema for JSON responses.
  LLMBuilder jsonSchema(StructuredOutputFormat schema) =>
      legacyExtension(LegacyExtensionKeys.jsonSchema, schema);

  /// Sets voice for text-to-speech providers.
  LLMBuilder voice(String voiceName) =>
      legacyExtension(LegacyExtensionKeys.voice, voiceName);

  /// Enables reasoning/thinking for legacy compatibility providers.
  LLMBuilder reasoning(bool enable) =>
      legacyExtension(LegacyExtensionKeys.reasoning, enable);

  /// Sets thinking budget tokens for providers that expose that knob.
  LLMBuilder thinkingBudgetTokens(int tokens) =>
      legacyExtension(LegacyExtensionKeys.thinkingBudgetTokens, tokens);

  /// Enables interleaved thinking for providers that expose that knob.
  LLMBuilder interleavedThinking(bool enable) =>
      legacyExtension(LegacyExtensionKeys.interleavedThinking, enable);

  /// Sets embedding encoding format for compatibility providers.
  LLMBuilder embeddingEncodingFormat(String format) =>
      legacyExtension(LegacyExtensionKeys.embeddingEncodingFormat, format);

  /// Sets embedding dimensions for compatibility providers.
  LLMBuilder embeddingDimensions(int dimensions) =>
      legacyExtension(LegacyExtensionKeys.embeddingDimensions, dimensions);
}
