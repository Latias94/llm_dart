/// Protocol/internal API for llm_dart_ollama.
///
/// This entrypoint exports lower-level building blocks that are intentionally
/// not part of the stable public API surface.
///
/// For typical usage, prefer:
/// `import 'package:llm_dart_ollama/llm_dart_ollama.dart';`
library;

export 'src/client/ollama_client.dart';
export 'src/chat/ollama_chat.dart';
export 'src/completion/ollama_completion.dart';
export 'src/embeddings/ollama_embeddings.dart';
export 'src/models/ollama_models.dart';
