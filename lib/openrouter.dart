/// Focused OpenRouter provider entrypoint.
///
/// Re-exports OpenRouter-owned options and the short `openRouter(...)` factory
/// while the implementation continues to share the OpenAI-family transport
/// adapter.
library;

export 'package:llm_dart_openai/llm_dart_openai.dart'
    show
        OpenAI,
        OpenAIChatModelSettings,
        OpenAIGenerateTextOptions,
        OpenAILanguageModel,
        OpenRouterChatModelSettings,
        OpenRouterGenerateTextOptions,
        OpenRouterProfile,
        OpenRouterSearchMode,
        OpenRouterSearchOptions;
export 'src/facade/ai.dart' show AI, openRouter;
