import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

@Deprecated(
  'Use OpenAIProvider from package:llm_dart_openai/llm_dart_openai.dart '
  'instead. This alias exists only for backwards compatibility and will be '
  'removed in a future release.',
)

/// Backwards-compatible alias for the OpenAI provider.
///
/// The actual implementation now lives in the `llm_dart_openai` subpackage.
typedef OpenAIProvider = openai.OpenAIProvider;
