/// Legacy OpenAI helper APIs.
///
/// These helpers were originally added as convenience functions for treating
/// other providers as OpenAI-compatible HTTP endpoints. New code should prefer:
/// - Newer builders such as `ai().openRouter()`, `ai().groq()`,
///   `ai().deepseek()`, etc.
/// - OpenAI-compatible provider configuration from the
///   `llm_dart_openai_compatible` package.
///
/// This file only re-exports the existing helpers to keep an explicit import
/// path for legacy code:
/// `import 'package:llm_dart/legacy/openai_legacy.dart';`.
library;

export '../providers/openai/openai.dart'
    show
        createOpenRouterProvider,
        createGroqProvider,
        createDeepSeekProvider,
        createCopilotProvider,
        createTogetherProvider;
