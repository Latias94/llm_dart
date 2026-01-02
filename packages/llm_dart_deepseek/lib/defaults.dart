/// DeepSeek defaults (OpenAI-compatible).
///
/// Duplicated here (instead of re-exporting `llm_dart_openai_compatible`) to
/// keep provider packages from leaking protocol-layer package names.
library;

const String deepseekBaseUrl = 'https://api.deepseek.com/v1/';
const String deepseekDefaultModel = 'deepseek-chat';
