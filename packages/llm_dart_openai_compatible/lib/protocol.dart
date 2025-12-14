/// OpenAI-compatible protocol/internal API for llm_dart.
///
/// This entrypoint exports lower-level building blocks (client, chat mapping,
/// embeddings implementation) that are intentionally not part of the stable
/// provider-facing API surface.
///
/// For typical usage, prefer:
/// `import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';`
library;

export 'src/client/openai_compatible_client.dart';
export 'src/chat/openai_compatible_chat.dart';
export 'src/embeddings/openai_compatible_embeddings.dart';
export 'src/utils/openai_message_mapper.dart';
