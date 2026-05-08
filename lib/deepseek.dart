/// Focused DeepSeek provider entrypoint.
///
/// Re-exports DeepSeek-owned options and the short `deepSeek(...)` factory
/// while the implementation continues to share the OpenAI-family transport
/// adapter.
library;

export 'package:llm_dart_openai/llm_dart_openai.dart'
    show
        DeepSeekGenerateTextOptions,
        DeepSeekProfile,
        OpenAI,
        OpenAIChatModelSettings,
        OpenAIGenerateTextOptions,
        OpenAILanguageModel;
export 'src/facade/ai.dart' show AI, deepSeek;
