/// Backwards-compatible re-export of web search configuration types.
///
/// The canonical implementation now lives in `llm_dart_core` so that it can be
/// shared across packages and provider implementations.
library;

export 'package:llm_dart_core/llm_dart_core.dart'
    show
        WebSearchType,
        WebSearchContextSize,
        WebSearchStrategy,
        WebSearchLocation,
        WebSearchConfig;
