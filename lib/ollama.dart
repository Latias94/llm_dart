/// Focused Ollama provider entrypoint.
///
/// Exports provider-owned Ollama types plus the short `ollama(...)` factory.
/// Import `core.dart` / `transport.dart` for shared layers.
library;

export 'package:llm_dart_ollama/llm_dart_ollama.dart' hide ollama;
export 'src/facade/ai.dart' show ollama;
