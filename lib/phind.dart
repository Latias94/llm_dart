/// Focused Phind provider entrypoint.
///
/// Re-exports Phind-owned profile types and the short `phind(...)` factory
/// while the implementation continues to share the OpenAI-family transport
/// adapter.
library;

export 'package:llm_dart_openai/llm_dart_openai.dart'
    show
        OpenAI,
        OpenAIChatModelSettings,
        OpenAIGenerateTextOptions,
        OpenAILanguageModel,
        PhindProfile;
export 'src/facade/ai.dart' show phind;
