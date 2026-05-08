import '../../../builder/llm_builder.dart';
import '../config/legacy_provider_options.dart';

/// Small writer for provider-scoped legacy builder options.
///
/// Provider builders keep their fluent public APIs, while the compatibility
/// storage shape stays centralized under the transitional `providerOptions`
/// bag.
final class LegacyBuilderProviderOptionWriter {
  final LLMBuilder _builder;
  final String _namespace;

  const LegacyBuilderProviderOptionWriter._(this._builder, this._namespace);

  factory LegacyBuilderProviderOptionWriter.openAI(LLMBuilder builder) =>
      LegacyBuilderProviderOptionWriter._(
        builder,
        LegacyProviderOptionNamespaces.openai,
      );

  factory LegacyBuilderProviderOptionWriter.anthropic(LLMBuilder builder) =>
      LegacyBuilderProviderOptionWriter._(
        builder,
        LegacyProviderOptionNamespaces.anthropic,
      );

  factory LegacyBuilderProviderOptionWriter.google(LLMBuilder builder) =>
      LegacyBuilderProviderOptionWriter._(
        builder,
        LegacyProviderOptionNamespaces.google,
      );

  factory LegacyBuilderProviderOptionWriter.ollama(LLMBuilder builder) =>
      LegacyBuilderProviderOptionWriter._(
        builder,
        LegacyProviderOptionNamespaces.ollama,
      );

  factory LegacyBuilderProviderOptionWriter.elevenLabs(LLMBuilder builder) =>
      LegacyBuilderProviderOptionWriter._(
        builder,
        LegacyProviderOptionNamespaces.elevenlabs,
      );

  factory LegacyBuilderProviderOptionWriter.xai(LLMBuilder builder) =>
      LegacyBuilderProviderOptionWriter._(
        builder,
        LegacyProviderOptionNamespaces.xai,
      );

  factory LegacyBuilderProviderOptionWriter.deepSeek(LLMBuilder builder) =>
      LegacyBuilderProviderOptionWriter._(
        builder,
        LegacyProviderOptionNamespaces.deepseek,
      );

  void set(String key, dynamic value) {
    setLegacyBuilderProviderOption(_builder, _namespace, key, value);
  }

  T? get<T>(String key) {
    return legacyProviderOptionView(
      _builder.currentConfig,
      _namespace,
    ).get<T>(key);
  }
}
