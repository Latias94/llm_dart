/// Protocol/internal API for llm_dart_google.
///
/// This entrypoint exports lower-level building blocks that are intentionally
/// not part of the stable public API surface.
///
/// For typical usage, prefer:
/// `import 'package:llm_dart_google/llm_dart_google.dart';`
library;

export 'src/client/google_client.dart';
export 'src/chat/google_chat.dart';
export 'src/embeddings/google_embeddings.dart';
export 'src/http/google_dio_strategy.dart';
export 'src/images/google_images.dart';
export 'src/tts/google_tts.dart' show GoogleTTS;
export 'src/files/google_files.dart';
