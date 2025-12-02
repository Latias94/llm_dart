library;

/// Backwards-compatible re-export of provider factory base classes.
///
/// The canonical implementations now live in `llm_dart_core` so that provider
/// subpackages can reuse them without depending on the root `llm_dart`
/// package. This shim keeps existing imports working:
///
///   import 'package:llm_dart/providers/factories/base_factory.dart';
///
export 'package:llm_dart_core/llm_dart_core.dart'
    show
        BaseProviderFactory,
        OpenAICompatibleBaseFactory,
        LocalProviderFactory,
        AudioProviderFactory;
