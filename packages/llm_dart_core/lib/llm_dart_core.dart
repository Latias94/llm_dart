/// Core library for llm_dart
///
/// This package provides the fundamental abstractions, configuration,
/// and shared models used by all llm_dart provider packages.
library;

// Core error and cancellation support
export 'src/core/llm_error.dart';
export 'src/core/cancellation.dart';

// Core capabilities and configuration
export 'src/core/capability.dart';
export 'src/core/config.dart';
export 'src/core/config_extensions.dart';
export 'src/core/provider_registry.dart';
export 'src/core/provider_factory_base.dart';
export 'src/core/agent.dart';

// Core models
export 'src/models/chat_models.dart';
export 'src/models/tool_models.dart';
export 'src/models/tool_builder.dart';
export 'src/models/audio_models.dart';
export 'src/models/image_models.dart';
export 'src/models/file_models.dart';
export 'src/models/moderation_models.dart';
export 'src/models/assistant_models.dart';
export 'src/models/responses_models.dart';
export 'src/models/rerank_models.dart';

// Core utilities
export 'src/utils/reasoning_utils.dart';
export 'src/utils/structured_output_utils.dart';
export 'src/utils/capability_utils.dart';
export 'src/utils/provider_registry.dart';
export 'src/utils/message_resolver.dart';
export 'src/utils/llm_logger.dart';
export 'src/utils/logger_utils.dart';

// Core tool validation
export 'src/core/tool_validator.dart';

// Core web search configuration
export 'src/core/web_search.dart';

// Additional core APIs (capabilities, config, registry, etc.) will be
// exported incrementally as we migrate them from the main llm_dart
// package into this core package.
