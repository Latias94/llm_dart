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
export 'src/core/agent.dart';

// Core models
export 'src/models/chat_models.dart';
export 'src/models/tool_models.dart';
export 'src/models/audio_models.dart';
export 'src/models/image_models.dart';
export 'src/models/file_models.dart';
export 'src/models/moderation_models.dart';
export 'src/models/assistant_models.dart';
export 'src/models/responses_models.dart';

// Core utilities
export 'src/utils/reasoning_utils.dart';

// Additional core APIs (capabilities, config, registry, etc.) will be
// exported incrementally as we migrate them from the main llm_dart
// package into this core package.
