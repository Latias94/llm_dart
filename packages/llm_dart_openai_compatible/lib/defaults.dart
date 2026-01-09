/// Default endpoints and model names for OpenAI-compatible providers.
///
/// These are intentionally kept out of `llm_dart_core` to keep the core package
/// provider-agnostic and stable.
library;

const String openaiCompatibleFallbackModel = 'gpt-4o';

// OpenAI-compatible preset defaults.
//
// Note: Provider-specific endpoints that are also shipped as first-party
// provider packages (e.g. DeepSeek/Groq/xAI) are intentionally *not* exported
// from this protocol package to avoid confusing users about the recommended
// integration path.

// OpenAI-compatible presets:
// - Preset-only endpoints (OpenRouter/Copilot/Together) are kept internal to
//   the preset config file to avoid leaking preset constants into the public
//   protocol surface.

// OpenAI-compatible media defaults (shared by OpenAI-style endpoints).
//
// Note: These are intentionally prefixed with `openaiStyle*` to avoid symbol
// collisions with the dedicated `llm_dart_openai` provider package defaults.
const String openaiStyleDefaultTTSModel = 'tts-1';
const String openaiStyleDefaultSTTModel = 'whisper-1';
const String openaiStyleDefaultVoice = 'alloy';

// Supported voices (OpenAI-style TTS).
const List<String> openaiStyleSupportedVoices = [
  'alloy',
  'ash',
  'ballad',
  'coral',
  'echo',
  'fable',
  'nova',
  'onyx',
  'sage',
  'shimmer',
  'verse',
];

// Supported audio formats for TTS output.
const List<String> openaiStyleSupportedTTSFormats = [
  'mp3',
  'opus',
  'aac',
  'flac',
  'wav',
  'pcm',
];

// Supported audio formats for STT input.
const List<String> openaiStyleSupportedSTTFormats = [
  'flac',
  'm4a',
  'mp3',
  'mp4',
  'mpeg',
  'mpga',
  'oga',
  'ogg',
  'wav',
  'webm',
];

// Supported image sizes (OpenAI-style image generation).
const List<String> openaiStyleSupportedImageSizes = [
  '256x256',
  '512x512',
  '1024x1024',
  '1792x1024',
  '1024x1792',
];

// Supported image formats (OpenAI-style image generation).
const List<String> openaiStyleSupportedImageFormats = [
  'url',
  'b64_json',
];
