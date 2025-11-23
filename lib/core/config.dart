/// Backwards-compatible re-export of core configuration types.
///
/// The canonical implementations live in the `llm_dart_core` package.
/// This wrapper keeps the original import path:
/// `package:llm_dart/core/config.dart`.
library;

export 'package:llm_dart_core/llm_dart_core.dart'
    show
        LLMConfig,
        LLMConfigKeys,
        OpenAICompatibleProviderConfig,
        ModelCapabilityConfig,
        ConfigTransformer,
        RequestBodyTransformer,
        HeadersTransformer;
