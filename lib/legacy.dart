/// Explicit compatibility entrypoint for the legacy root surface.
///
/// New code should prefer focused entrypoints such as `ai.dart`, `core.dart`,
/// `openai.dart`, `chat.dart`, and provider-specific typed APIs. This barrel
/// exists so migration-oriented code can depend on a stable compatibility shell
/// even after the broad root `llm_dart.dart` surface starts shrinking.
library;

export 'llm_dart.dart';
