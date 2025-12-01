@Deprecated(
  'ProviderRegistry and related helper types have moved to llm_dart_core. '
  'Import them from package:llm_dart_core/llm_dart_core.dart instead. '
  'This shim will be removed in a future release.',
)
library;

export 'package:llm_dart_core/llm_dart_core.dart'
    show
        ProviderRegistry,
        RegistryProviderInfo,
        RegistryStats,
        ProviderRegistryClient,
        createProviderRegistry,
        LanguageModelProviderFactory,
        EmbeddingModelProviderFactory,
        ImageModelProviderFactory,
        SpeechModelProviderFactory;
