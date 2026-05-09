/// Focused Anthropic provider entrypoint.
///
/// Exports provider-owned Anthropic types plus the short `anthropic(...)`
/// factory. Import `core.dart` / `transport.dart` for shared layers.
library;

export 'package:llm_dart_anthropic/llm_dart_anthropic.dart' hide anthropic;
export 'src/facade/ai.dart' show AI, anthropic;
