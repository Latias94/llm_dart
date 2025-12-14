/// Protocol/internal API for llm_dart_phind.
///
/// This entrypoint exports lower-level building blocks that are intentionally
/// not part of the stable public API surface.
///
/// For typical usage, prefer:
/// `import 'package:llm_dart_phind/llm_dart_phind.dart';`
library;

export 'src/client/phind_client.dart';
export 'src/chat/phind_chat.dart';
