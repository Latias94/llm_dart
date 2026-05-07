import '../../../builder/llm_builder.dart';
import '../../../models/chat_models.dart';
import '../../../models/tool_models.dart';
import '../config/legacy_config_keys.dart';

/// Legacy extension-key convenience methods layered on top of [LLMBuilder].
extension LLMBuilderLegacyExtensionConfig on LLMBuilder {
  /// Sets the reasoning effort for models that support it.
  LLMBuilder reasoningEffort(ReasoningEffort? effort) =>
      extension(LegacyExtensionKeys.reasoningEffort, effort?.value);

  /// Sets structured output schema for JSON responses.
  LLMBuilder jsonSchema(StructuredOutputFormat schema) =>
      extension(LegacyExtensionKeys.jsonSchema, schema);

  /// Sets voice for text-to-speech providers.
  LLMBuilder voice(String voiceName) =>
      extension(LegacyExtensionKeys.voice, voiceName);

  /// Enables reasoning/thinking for legacy compatibility providers.
  LLMBuilder reasoning(bool enable) =>
      extension(LegacyExtensionKeys.reasoning, enable);

  /// Sets thinking budget tokens for providers that expose that knob.
  LLMBuilder thinkingBudgetTokens(int tokens) =>
      extension(LegacyExtensionKeys.thinkingBudgetTokens, tokens);

  /// Enables interleaved thinking for providers that expose that knob.
  LLMBuilder interleavedThinking(bool enable) =>
      extension(LegacyExtensionKeys.interleavedThinking, enable);

  /// Sets embedding encoding format for compatibility providers.
  LLMBuilder embeddingEncodingFormat(String format) =>
      extension(LegacyExtensionKeys.embeddingEncodingFormat, format);

  /// Sets embedding dimensions for compatibility providers.
  LLMBuilder embeddingDimensions(int dimensions) =>
      extension(LegacyExtensionKeys.embeddingDimensions, dimensions);
}
