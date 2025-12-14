/// Backwards-compatible alias for the UTF-8 stream decoder used by OpenAI.
///
/// The canonical implementation now lives in `llm_dart_provider_utils` so it
/// can be shared across providers without introducing circular dependencies.
library;

export 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart'
    show Utf8StreamDecoder;
