/// llm_dart_provider
///
/// This package mirrors the AI SDK package split where the `provider` package
/// hosts transport-agnostic interfaces and shared types.
///
/// In llm_dart, those types live in `llm_dart_core`. This package is a thin
/// compatibility layer that re-exports the core surface.
library;

export 'package:llm_dart_core/llm_dart_core.dart';

export 'src/errors/no_such_model_error.dart';
export 'src/provider_v3.dart';
