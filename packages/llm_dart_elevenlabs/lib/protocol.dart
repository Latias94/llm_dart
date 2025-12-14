/// Protocol/internal API for llm_dart_elevenlabs.
///
/// This entrypoint exports lower-level building blocks that are intentionally
/// not part of the stable public API surface.
///
/// For typical usage, prefer:
/// `import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart';`
library;

export 'src/client/elevenlabs_client.dart';
export 'src/audio/elevenlabs_audio.dart';
export 'src/http/elevenlabs_dio_strategy.dart';
