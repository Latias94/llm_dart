/// ID generator helpers.
///
/// In the upstream AI SDK, these live in `@ai-sdk/provider-utils`.
/// In llm_dart, the implementation lives in `llm_dart_core` so that
/// `llm_dart_ai` (core-only) can depend on it without pulling in HTTP utilities.
library;

export 'package:llm_dart_core/utils/id_generator.dart';
