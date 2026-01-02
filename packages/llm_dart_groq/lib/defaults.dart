/// Groq defaults (OpenAI-compatible).
///
/// Duplicated here (instead of re-exporting `llm_dart_openai_compatible`) to
/// keep provider packages from leaking protocol-layer package names.
library;

const String groqBaseUrl = 'https://api.groq.com/openai/v1/';
const String groqDefaultModel = 'llama-3.3-70b-versatile';
