/// Backwards-compatible re-export of the UTF-8 stream decoder utilities.
///
/// The canonical implementation now lives in `llm_dart_provider_utils` so that
/// it can be reused across providers and tests without duplicating logic.
library;

export 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart'
    show Utf8StreamDecoder, Utf8StreamDecoderExtension;
