/// OpenAI-specific Responses API capability interface.
///
/// This file now provides a backwards-compatible alias to the
/// implementation in the `llm_dart_openai` subpackage so that
/// existing imports continue to work.
library;

import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

/// Re-export extension methods defined in the subpackage.
export 'package:llm_dart_openai/llm_dart_openai.dart'
    show OpenAIResponsesCapabilityExtensions;

/// Backwards-compatible alias for the OpenAI Responses capability interface.
typedef OpenAIResponsesCapability = openai.OpenAIResponsesCapability;
