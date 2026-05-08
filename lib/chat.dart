/// Focused pure Dart chat runtime entrypoint.
///
/// Re-exports the reusable chat runtime, shared core and transport surfaces,
/// plus stable model factories. Flutter-specific adapters stay in
/// `package:llm_dart_flutter/llm_dart_flutter.dart`.
library;

export 'core.dart';
export 'transport.dart';
export 'package:llm_dart_chat/llm_dart_chat.dart';
export 'src/facade/ai.dart'
    show AI, anthropic, deepSeek, google, groq, openRouter, openai, phind, xai;
