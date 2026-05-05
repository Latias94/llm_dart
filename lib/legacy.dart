/// Explicit compatibility entrypoint for the legacy root surface.
///
/// New code should prefer focused entrypoints such as `ai.dart`, `core.dart`,
/// `openai.dart`, `chat.dart`, and provider-specific typed APIs. This barrel
/// exists so migration-oriented code can depend on a stable compatibility shell
/// even after the broad root `llm_dart.dart` surface starts shrinking.
library;

export 'src/facade/ai.dart' show AI;
export 'src/bootstrap/root_registry_bootstrap.dart'
    show ensureRootRegistryBootstrap;
export 'src/facade/legacy_builder_helpers.dart';
export 'src/compatibility/providers/community_provider_config_adapters.dart'
    show createLegacyDioClientOverrides;
export 'src/compatibility/providers/elevenlabs/config_adapter.dart'
    show createLegacyElevenLabsConfig;
export 'src/compatibility/providers/ollama/config_adapter.dart'
    show createLegacyOllamaConfig;

export 'core/capability.dart';
export 'core/cancellation.dart';
export 'core/llm_error.dart';
export 'core/config.dart';
export 'core/registry.dart';
export 'core/openai_compatible_configs.dart';
export 'core/tool_validator.dart';
export 'core/web_search.dart';
export 'package:llm_dart_transport/llm_dart_transport.dart'
    show
        StreamingTransportResponse,
        TransportClient,
        TransportException,
        TransportHttpException,
        TransportMethod,
        TransportNetworkException,
        TransportRequest,
        TransportResponse,
        TransportResponseFormatException,
        TransportResponseType,
        TransportTimeoutException;

export 'models/chat_models.dart';
export 'models/tool_models.dart';
export 'models/audio_models.dart';
export 'models/google_tts_models.dart';
export 'models/image_models.dart';
export 'models/file_models.dart';
export 'models/moderation_models.dart';
export 'models/assistant_models.dart';

export 'providers/openai/openai.dart';
export 'providers/openai/client.dart';
export 'providers/openai/chat.dart';
export 'providers/openai/embeddings.dart';
export 'providers/openai/audio.dart';
export 'providers/openai/images.dart';
export 'providers/openai/files.dart';
export 'providers/openai/models.dart';
export 'providers/openai/moderation.dart';
export 'providers/openai/assistants.dart';
export 'providers/openai/completion.dart';
export 'providers/anthropic/anthropic.dart';
export 'providers/anthropic/models.dart';
export 'providers/google/google.dart';
export 'providers/google/client.dart';
export 'providers/google/chat.dart';
export 'providers/google/embeddings.dart';
export 'providers/google/tts.dart';
export 'providers/deepseek/deepseek.dart';
export 'providers/ollama/ollama.dart';
export 'providers/xai/xai.dart';
export 'providers/phind/phind.dart';
export 'providers/groq/groq.dart';
export 'providers/elevenlabs/elevenlabs.dart';

export 'providers/factories/base_factory.dart';

export 'builder/llm_builder.dart';
export 'builder/http_config.dart';
export 'builder/audio_config.dart';
export 'builder/image_config.dart';
export 'builder/provider_config.dart';

export 'utils/config_utils.dart';
export 'utils/capability_utils.dart';
export 'utils/provider_registry.dart';
export 'utils/utf8_stream_decoder.dart';
export 'utils/http_config_utils.dart';
export 'utils/tool_call_aggregator.dart';
