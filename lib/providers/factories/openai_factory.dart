library;

/// Backwards-compatible re-export for the OpenAI provider factory and
/// registration helper. The canonical implementation lives in the
/// `llm_dart_openai` package so that it can be used without depending on
/// the root `llm_dart` package.
export 'package:llm_dart_openai/llm_dart_openai.dart'
    show OpenAIProviderFactory, registerOpenAIProvider;
