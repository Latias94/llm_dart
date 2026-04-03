/// LLM Dart Library - A modular Dart library for AI provider interactions
///
/// This library provides a unified interface for interacting with different
/// AI providers, starting with OpenAI. It's designed to be modular and
/// extensible
library;

export 'src/facade/ai.dart' show AI;
export 'src/bootstrap/root_registry_bootstrap.dart'
    show ensureRootRegistryBootstrap;
export 'src/facade/legacy_builder_helpers.dart';

// Core exports
export 'core/capability.dart';
export 'core/cancellation.dart';
export 'core/llm_error.dart';
export 'core/config.dart';
export 'core/registry.dart';
export 'core/base_http_provider.dart';
export 'core/openai_compatible_configs.dart';
export 'core/tool_validator.dart';
export 'core/web_search.dart';
export 'package:llm_dart_transport/llm_dart_transport.dart'
    show
        StreamingTransportResponse,
        TransportCancellation,
        TransportCancelledException,
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

// Model exports
export 'models/chat_models.dart';
export 'models/tool_models.dart';
export 'models/audio_models.dart';
export 'models/google_tts_models.dart';
export 'models/image_models.dart';
export 'models/file_models.dart';
export 'models/moderation_models.dart';
export 'models/assistant_models.dart';

// Provider exports
export 'providers/openai/openai.dart'
    hide createDeepSeekProvider, createGroqProvider;
export 'providers/anthropic/anthropic.dart';
export 'providers/anthropic/models.dart';
export 'providers/google/google.dart';
export 'providers/google/tts.dart';
export 'providers/deepseek/deepseek.dart';
export 'providers/ollama/ollama.dart';
export 'providers/xai/xai.dart';
export 'providers/phind/phind.dart';
export 'providers/groq/groq.dart';
export 'providers/elevenlabs/elevenlabs.dart';

// Factory exports
export 'providers/factories/base_factory.dart';

// Builder exports
export 'builder/llm_builder.dart';
export 'builder/http_config.dart';
export 'builder/audio_config.dart';
export 'builder/image_config.dart';
export 'builder/provider_config.dart';

// Utility exports
export 'utils/config_utils.dart';
export 'utils/capability_utils.dart';
export 'utils/provider_registry.dart';
export 'utils/utf8_stream_decoder.dart';
export 'utils/http_config_utils.dart';
export 'utils/tool_call_aggregator.dart';

