/// Focused Groq provider entrypoint.
///
/// Re-exports Groq-owned profile types and the short `groq(...)` factory while
/// the implementation continues to share the OpenAI-family transport adapter.
library;

export 'package:llm_dart_openai/llm_dart_openai.dart'
    show
        GroqProfile,
        OpenAI,
        OpenAIChatModelSettings,
        OpenAIGenerateTextOptions,
        OpenAILanguageModel;
export 'src/facade/ai.dart' show groq;
