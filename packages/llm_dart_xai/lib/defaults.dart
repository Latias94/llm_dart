/// xAI defaults (OpenAI-compatible).
///
/// Duplicated here (instead of re-exporting `llm_dart_openai_compatible`) to
/// keep provider packages from leaking protocol-layer package names.
library;

const String xaiBaseUrl = 'https://api.x.ai/v1/';
const String xaiDefaultModel = 'grok-3';
