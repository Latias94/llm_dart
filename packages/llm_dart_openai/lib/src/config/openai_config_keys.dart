/// OpenAI-specific extension keys used in `LLMConfig.extensions`.
///
/// These keys are intentionally defined in the OpenAI package (not `llm_dart_core`)
/// because they are specific to OpenAI behavior and APIs (e.g. Responses API).
abstract final class OpenAIConfigKeys {
  /// Whether to use the OpenAI Responses API instead of Chat Completions.
  static const String useResponsesAPI = 'useResponsesAPI';

  /// Previous response ID for chaining responses (Responses API only).
  static const String previousResponseId = 'previousResponseId';

  /// Built-in tools list for the Responses API.
  static const String builtInTools = 'builtInTools';

  /// GPT-5 style verbosity control.
  static const String verbosity = 'verbosity';
}
