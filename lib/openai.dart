/// Focused OpenAI-family entrypoint.
///
/// Exports provider-owned OpenAI-family types plus the short `openai(...)`
/// factory. Import `core.dart` / `transport.dart` for shared layers.
library;

export 'package:llm_dart_openai/llm_dart_openai.dart';
export 'src/facade/ai.dart' show AI, openai;
