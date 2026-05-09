/// Focused xAI provider entrypoint.
///
/// Re-exports xAI-owned options and the short `xai(...)` factory while the
/// implementation continues to share the OpenAI-family transport adapter.
library;

export 'package:llm_dart_openai/llm_dart_openai.dart'
    show
        OpenAI,
        OpenAIChatModelSettings,
        OpenAIGenerateTextOptions,
        OpenAILanguageModel,
        XAIProfile,
        XAIGenerateTextOptions,
        XAILiveSearchOptions,
        XAINewsSearchSource,
        XAIRssSearchSource,
        XAISearchMode,
        XAISearchSource,
        XAIWebSearchSource,
        XAIXSearchSource;
export 'src/facade/ai.dart' show xai;
