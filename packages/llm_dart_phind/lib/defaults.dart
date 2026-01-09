/// Phind defaults (OpenAI-compatible).
///
/// These defaults intentionally live in the provider package (instead of the
/// protocol layer) to avoid confusing "OpenAI-compatible presets" with
/// first-party provider packages.
library;

const String phindBaseUrl = 'https://api.phind.com/v1/';
const String phindDefaultModel = 'Phind-70B';
