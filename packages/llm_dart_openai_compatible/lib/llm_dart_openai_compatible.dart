/// OpenAI-compatible protocol package for llm_dart
///
/// This package contains a reusable implementation of the OpenAI REST API
/// shape (chat/completions/embeddings/images/files/moderation, etc.) that
/// can be shared by providers exposing an OpenAI-compatible interface.
library;

export 'src/config/openai_compatible_config.dart'
    show OpenAICompatibleConfig, OpenAICompatibleConfigs;
export 'src/client/openai_compatible_client.dart';
export 'src/chat/openai_compatible_chat.dart';
export 'src/provider/openai_compatible_provider.dart';
