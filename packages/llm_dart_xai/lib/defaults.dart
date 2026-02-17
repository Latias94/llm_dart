/// xAI defaults (OpenAI-compatible).
///
/// Duplicated here (instead of re-exporting `llm_dart_openai_compatible`) to
/// keep provider packages from leaking protocol-layer package names.
library;

const String xaiBaseUrl = 'https://api.x.ai/v1/';
const String xaiDefaultModel = 'grok-3';

/// Default image model id (Vercel AI SDK xai.image).
const String xaiDefaultImageModel = 'grok-2-image';

/// Default video model id (Vercel AI SDK xai.video).
const String xaiDefaultVideoModel = 'grok-imagine-video';
