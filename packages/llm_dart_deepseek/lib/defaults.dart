/// DeepSeek defaults (OpenAI-compatible).
///
/// Duplicated here (instead of re-exporting `llm_dart_openai_compatible`) to
/// keep provider packages from leaking protocol-layer package names.
library;

// Vercel AI SDK parity: DeepSeek API base URL uses `/chat/completions` without
// a `/v1` prefix.
const String deepseekBaseUrl = 'https://api.deepseek.com/';
const String deepseekDefaultModel = 'deepseek-chat';
