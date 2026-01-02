/// (Tier 3 / opt-in) OpenAI Responses API wrapper + built-in tools.
///
/// This mirrors upstream OpenAI endpoints and provider-native tools (web search,
/// file search, computer use). Prefer the standard surface unless you
/// explicitly need Responses API behavior.
library;

export 'src/responses.dart';
export 'src/models/responses_models.dart';
export 'responses_capability.dart';
export 'responses_message_converter.dart';
export 'builtin_tools.dart';
export 'provider_tools.dart';
export 'web_search_context_size.dart';
