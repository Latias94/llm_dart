/// Builder entrypoint for the `llm_dart` bundle.
///
/// The provider-neutral implementation lives in `llm_dart_builder`.
///
/// Note: We intentionally re-export the neutral builder directly to avoid
/// fluent API type erosion when subclassing (chainable methods would return
/// the base type and break extension-based shortcuts such as `.openai()`).
library;

export 'package:llm_dart_builder/builder/llm_builder.dart';
