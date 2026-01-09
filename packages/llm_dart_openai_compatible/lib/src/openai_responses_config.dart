import 'builtin_tools.dart';
import 'openai_request_config.dart';

/// Shared config surface required to talk to the OpenAI Responses API.
///
/// This intentionally lives in the OpenAI-compatible protocol package so that
/// multiple provider packages (e.g. OpenAI, Azure OpenAI) can reuse the same
/// Responses implementation without provider-to-provider dependencies.
abstract class OpenAIResponsesConfig implements OpenAIRequestConfig {
  /// Previous response ID for chaining responses.
  String? get previousResponseId;

  /// Provider-native tools to include in Responses requests.
  List<OpenAIBuiltInTool>? get builtInTools;
}
