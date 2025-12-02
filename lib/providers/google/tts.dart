/// Backwards-compatible aliases for the Google TTS capability and models.
///
/// The actual implementation now lives in the `llm_dart_google` subpackage.
library;

export 'package:llm_dart_google/llm_dart_google.dart'
    show
        GoogleTTSCapability,
        GoogleTTSRequest,
        GoogleVoiceConfig,
        GooglePrebuiltVoiceConfig,
        GoogleMultiSpeakerVoiceConfig,
        GoogleSpeakerVoiceConfig,
        GoogleTTSResponse,
        GoogleVoiceInfo,
        GoogleTTSStreamEvent,
        GoogleTTSAudioDataEvent,
        GoogleTTSMetadataEvent,
        GoogleTTSErrorEvent,
        GoogleTTSCompletionEvent,
        GoogleTTS;
