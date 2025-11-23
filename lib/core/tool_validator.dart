/// Backwards-compatible re-export of the tool validation utilities.
///
/// The canonical implementation now lives in `llm_dart_core` so that it can be
/// reused across provider packages and tests without duplicating logic.
library;

export 'package:llm_dart_core/llm_dart_core.dart' show ToolValidator;
