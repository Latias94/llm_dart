/// Internal testing entrypoint for `llm_dart_anthropic`.
///
/// This library intentionally exports implementation details that are not part
/// of the stable public API. It exists so the monorepo can test request shaping
/// and protocol-level behavior without forcing end users to import `src/*`.
library;

export 'llm_dart_anthropic.dart';
export 'protocol.dart';
