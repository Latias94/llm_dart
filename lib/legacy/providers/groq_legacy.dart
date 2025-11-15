/// Legacy Groq types.
///
/// These re-export the legacy Groq chat and client implementations
/// under `lib/legacy/providers/groq`. New code should prefer the
/// `llm_dart_groq` package, which uses the shared OpenAI-compatible
/// protocol layer.
library;

export 'groq/chat.dart';
export 'groq/client.dart';
