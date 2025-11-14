/// Backwards-compatible re-export of HTTP configuration utilities.
///
/// The actual implementation now lives in the `llm_dart_provider_utils`
/// package to avoid layering inversions. Existing imports from the
/// main `llm_dart` package can continue to use this path.
library;

export 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart'
    show HttpConfigUtils;
