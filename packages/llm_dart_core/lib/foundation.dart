/// Narrow foundation contracts for `llm_dart_core`.
///
/// This entrypoint exposes the low-level data structures used by providers,
/// model calls, UI projection, and serialization without importing the higher
/// runner or UI helper layers.
library;

export 'src/common/call_options.dart';
export 'src/common/json_schema.dart';
export 'src/common/model_error.dart';
export 'src/common/model_warning.dart';
export 'src/common/provider_metadata.dart';
export 'src/common/provider_options.dart';
export 'src/common/transport_cancellation.dart';
export 'src/common/usage_stats.dart';
export 'src/content/content_part.dart';
export 'src/prompt/prompt_message.dart';
export 'src/tool/tool_definition.dart';
