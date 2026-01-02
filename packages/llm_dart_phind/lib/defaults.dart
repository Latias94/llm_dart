/// Phind defaults (OpenAI-compatible).
///
/// Duplicated here (instead of re-exporting `llm_dart_openai_compatible`) to
/// keep provider packages from leaking protocol-layer package names.
library;

const String phindBaseUrl = 'https://api.phind.com/v1/';
const String phindDefaultModel = 'Phind-70B';
