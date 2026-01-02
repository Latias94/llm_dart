/// Anthropic defaults (Messages API).
///
/// Duplicated here (instead of re-exporting `llm_dart_anthropic_compatible`) to
/// keep provider packages from leaking protocol-layer package names.
library;

const String anthropicBaseUrl = 'https://api.anthropic.com/v1/';
const String anthropicDefaultModel = 'claude-sonnet-4-20250514';
