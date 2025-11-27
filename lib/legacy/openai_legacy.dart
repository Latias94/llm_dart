@Deprecated(
  'Legacy OpenAI helper APIs. '
  'Use the new multi-package architecture instead:\n'
  '- High-level helpers and builders from package:llm_dart/llm_dart.dart.\n'
  '- OpenAI-specific features from package:llm_dart_openai/llm_dart_openai.dart.\n'
  'This shim will be removed in a future release.',
)

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
/// `import 'package:llm_dart/legacy/openai_legacy.dart';`. New code should not
/// depend on this path.
library;

export '../providers/openai/openai.dart'
    show
        createOpenRouterProvider,
        createGroqProvider,
        createDeepSeekProvider,
        createCopilotProvider,
        createTogetherProvider;
