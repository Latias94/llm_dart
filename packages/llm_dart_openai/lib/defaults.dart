/// OpenAI provider defaults.
library;

// Core OpenAI
const String openaiBaseUrl = 'https://api.openai.com/v1/';
const String openaiDefaultModel = 'gpt-4o';

// OpenAI Audio defaults
const String openaiDefaultTTSModel = 'tts-1';
const String openaiDefaultSTTModel = 'whisper-1';
const String openaiDefaultVoice = 'alloy';

// OpenAI supported voices
// Reference: https://platform.openai.com/docs/guides/text-to-speech#voice-options
const List<String> openaiSupportedVoices = [
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

// OpenAI supported audio formats for TTS
const List<String> openaiSupportedTTSFormats = [
  'mp3',
  'opus',
  'aac',
  'flac',
  'wav',
  'pcm',
];

// OpenAI supported audio formats for STT (input)
const List<String> openaiSupportedSTTFormats = [
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

// OpenAI supported image sizes
const List<String> openaiSupportedImageSizes = [
  '256x256',
  '512x512',
  '1024x1024',
  '1792x1024',
  '1024x1792',
];

// OpenAI supported image formats
const List<String> openaiSupportedImageFormats = [
  'url',
  'b64_json',
];
