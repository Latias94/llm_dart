/// Legacy Groq client entrypoint.
///
/// This file is kept only so that existing imports from
/// `providers/groq/client.dart` continue to compile. The modern Groq
/// implementation lives in the `llm_dart_groq` subpackage and is
/// exposed via `providers/groq/groq.dart`.
library;

// Intentionally left without exports. The modern Groq implementation lives in
// the `llm_dart_groq` subpackage and is surfaced via:
//   - package:llm_dart/providers/groq/groq.dart
//   - package:llm_dart/providers/groq/provider.dart
//
// This file only exists to keep legacy import paths compiling.
