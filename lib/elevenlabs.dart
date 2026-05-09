/// Focused ElevenLabs provider entrypoint.
///
/// Exports provider-owned ElevenLabs types plus the short `elevenLabs(...)`
/// factory. Import `core.dart` / `transport.dart` for shared layers.
library;

export 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart' hide elevenLabs;
export 'src/facade/ai.dart' show elevenLabs;
