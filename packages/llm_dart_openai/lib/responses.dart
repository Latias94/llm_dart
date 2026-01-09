/// (Tier 3 / opt-in) OpenAI Responses API wrapper + built-in tools.
///
/// This mirrors upstream OpenAI endpoints and provider-native tools (web search,
/// file search, computer use). Prefer the standard surface unless you
/// explicitly need Responses API behavior.
library;

export 'package:llm_dart_openai_compatible/responses.dart';
export 'provider_tools.dart';
