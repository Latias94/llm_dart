/// Protocol/internal API for llm_dart_xai.
///
/// This entrypoint exports lower-level building blocks that are intentionally
/// not part of the stable public API surface.
///
/// For typical usage, prefer:
/// `import 'package:llm_dart_xai/llm_dart_xai.dart';`
library;

export 'src/client/xai_client.dart';
export 'src/chat/xai_chat.dart';
export 'src/embeddings/xai_embeddings.dart';
export 'src/http/xai_dio_strategy.dart';
