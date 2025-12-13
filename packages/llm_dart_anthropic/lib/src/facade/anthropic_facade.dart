import 'package:llm_dart_core/llm_dart_core.dart';

import '../chat/anthropic_chat.dart';
import '../client/anthropic_client.dart';
import '../config/anthropic_config.dart';

const _defaultBaseUrl = 'https://api.anthropic.com/v1/';

/// Anthropic provider settings (Vercel AI-style).
///
/// Mirrors the core fields from `AnthropicProviderSettings` in the
/// Vercel AI SDK while adopting Dart conventions:
/// - [apiKey] is required instead of being read from environment variables.
/// - [baseUrl] and [headers] allow proxying and custom HTTP configuration.
class AnthropicProviderSettings {
  /// API key used for authenticating requests.
  final String apiKey;

  /// Base URL for the Anthropic API.
  ///
  /// Defaults to `https://api.anthropic.com/v1/` when not provided.
  final String? baseUrl;

  /// Additional custom headers to send with each request.
  final Map<String, String>? headers;

  /// Logical provider name used for metadata (e.g. `anthropic.messages`).
  final String? name;

  /// Optional default timeout applied via [LLMConfig.timeout].
  final Duration? timeout;

  const AnthropicProviderSettings({
    required this.apiKey,
    this.baseUrl,
    this.headers,
    this.name,
    this.timeout,
  });
}

/// Anthropic model factory (Vercel AI-style).
///
/// Provides a model-centric API similar to `createAnthropic` in the
/// Vercel AI SDK. It returns [LanguageModel] instances that can be
/// passed into helpers like `generateTextWithModel` or `runAgentPromptText`.
class Anthropic implements LanguageModelProviderFactory {
  final AnthropicProviderSettings _settings;
  final String _baseUrl;
  final String _providerName;

  Anthropic(AnthropicProviderSettings settings)
      : _settings = settings,
        _baseUrl = _normalizeBaseUrl(
          settings.baseUrl ?? _defaultBaseUrl,
        ),
        _providerName = settings.name ?? 'anthropic';

  /// Create a language model for text generation.
  ///
  /// Alias for [chat].
  @override
  LanguageModel languageModel(String modelId) => chat(modelId);

  /// Create a chat model for text generation.
  ///
  /// Wraps the Anthropic Messages API via [AnthropicChat].
  LanguageModel chat(String modelId) {
    final llmConfig = _createLLMConfig(modelId);
    final config = AnthropicConfig.fromLLMConfig(llmConfig);
    final client = AnthropicClient(config);
    final chat = AnthropicChat(client, config);

    return DefaultLanguageModel(
      providerId: _providerName,
      modelId: modelId,
      config: llmConfig,
      chat: chat,
    );
  }

  LLMConfig _createLLMConfig(String modelId) {
    final headers = <String, String>{};

    if (_settings.headers != null && _settings.headers!.isNotEmpty) {
      headers.addAll(_settings.headers!);
    }

    final extensions = <String, dynamic>{};
    if (headers.isNotEmpty) {
      extensions[LLMConfigKeys.customHeaders] = headers;
    }

    return LLMConfig(
      apiKey: _settings.apiKey,
      baseUrl: _baseUrl,
      model: modelId,
      timeout: _settings.timeout,
      extensions: extensions,
    );
  }

  static String _normalizeBaseUrl(String value) {
    if (value.isEmpty) return _defaultBaseUrl;
    return value.endsWith('/') ? value : '$value/';
  }

  /// Anthropic provider-defined tools (web search, MCP, etc.).
  ///
  /// This mirrors the `anthropic.tools` namespace in the Vercel AI SDK
  /// for the tools that are implemented in this Dart package. For now
  /// we expose the web search tool used by the `web_search_20250305`
  /// server-side integration.
  AnthropicTools get tools => const AnthropicTools();
}

/// Create an Anthropic model factory (Vercel AI-style).
///
/// Example:
/// ```dart
/// final anthropic = createAnthropic(
///   apiKey: 'sk-ant-...',
/// );
///
/// final model = anthropic.chat('claude-sonnet-4-20250514');
/// ```
Anthropic createAnthropic({
  required String apiKey,
  String? baseUrl,
  Map<String, String>? headers,
  String? name,
  Duration? timeout,
}) {
  return Anthropic(
    AnthropicProviderSettings(
      apiKey: apiKey,
      baseUrl: baseUrl,
      headers: headers,
      name: name,
      timeout: timeout,
    ),
  );
}

/// Alias for [createAnthropic] to mirror the default `anthropic` export
/// from the Vercel AI SDK.
Anthropic anthropic({
  required String apiKey,
  String? baseUrl,
  Map<String, String>? headers,
  String? name,
  Duration? timeout,
}) {
  return createAnthropic(
    apiKey: apiKey,
    baseUrl: baseUrl,
    headers: headers,
    name: name,
    timeout: timeout,
  );
}

/// Lightweight facade for Anthropic provider-defined tools.
///
/// This mirrors the `anthropic.tools` namespace from the Vercel AI SDK
/// for the subset of tools that are supported in this Dart port.
class AnthropicTools {
  const AnthropicTools();

  /// Web search tool (`web_search_20250305`).
  ///
  /// Returns a [Tool] with:
  /// - name: `web_search`
  /// - single `query` string parameter describing the search query
  ///
  /// The underlying Anthropic request builder recognizes this tool name
  /// and maps it to Anthropic's official `web_search_20250305` tool type,
  /// augmenting it with configuration from [WebSearchConfig] when present.
  Tool webSearch20250305() {
    return Tool.function(
      name: 'web_search',
      description: 'Search the web for current information',
      parameters: ParametersSchema(
        schemaType: 'object',
        properties: {
          'query': ParameterProperty(
            propertyType: 'string',
            description: 'The search query to execute',
          ),
        },
        required: const ['query'],
      ),
    );
  }
}
