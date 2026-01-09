/// Default endpoints and model names for ElevenLabs.
library;

/// Provider id used for `providerMetadata` namespacing and registry wiring.
const String elevenLabsProviderId = 'elevenlabs';

const String elevenLabsBaseUrl = 'https://api.elevenlabs.io/v1/';

// Defaults commonly used by the provider.
const String elevenLabsDefaultVoiceId = 'JBFqnCBsd6RMkjVDRZzb';
const String elevenLabsDefaultTTSModel = 'eleven_multilingual_v2';
const String elevenLabsDefaultSTTModel = 'scribe_v1';

const List<String> elevenLabsSupportedAudioFormats = [
  'mp3_44100_128',
  'mp3_44100_192',
  'pcm_16000',
  'pcm_22050',
  'pcm_24000',
  'pcm_44100',
  'ulaw_8000',
];
