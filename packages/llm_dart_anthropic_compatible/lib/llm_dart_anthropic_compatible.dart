/// llm_dart_anthropic_compatible
///
/// Reusable implementation for providers that speak Anthropic's Messages API
/// wire format.
library;

export 'defaults.dart';
export 'base_url.dart';
export 'chat.dart';
export 'config.dart';
export 'mcp_models.dart';
export 'provider.dart';
export 'provider_tools.dart';
export 'request_builder.dart';
export 'web_fetch_tool_options.dart';
export 'web_search_tool_options.dart';

// Low-level HTTP utilities are opt-in:
// - `package:llm_dart_anthropic_compatible/client.dart`
// - `package:llm_dart_anthropic_compatible/dio_strategy.dart`
