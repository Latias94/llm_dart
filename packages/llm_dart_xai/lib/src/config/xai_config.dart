import 'package:llm_dart_core/llm_dart_core.dart';

import 'search_parameters.dart';

/// xAI provider configuration for the sub-package.
class XAIConfig implements ProviderHttpConfig {
  final String apiKey;
  final String baseUrl;
  final String model;
  final int? maxTokens;
  final double? temperature;
  final String? systemPrompt;
  final Duration? timeout;

  final double? topP;
  final int? topK;
  final List<Tool>? tools;
  final ToolChoice? toolChoice;
  final StructuredOutputFormat? jsonSchema;

  final String? embeddingEncodingFormat;
  final int? embeddingDimensions;

  final SearchParameters? searchParameters;
  final bool? liveSearch;

  final LLMConfig? _originalConfig;

  const XAIConfig({
    required this.apiKey,
    this.baseUrl = 'https://api.x.ai/v1/',
    this.model = 'grok-3',
    this.maxTokens,
    this.temperature,
    this.systemPrompt,
    this.timeout,
    this.topP,
    this.topK,
    this.tools,
    this.toolChoice,
    this.jsonSchema,
    this.embeddingEncodingFormat,
    this.embeddingDimensions,
    this.searchParameters,
    this.liveSearch,
    LLMConfig? originalConfig,
  }) : _originalConfig = originalConfig;

  factory XAIConfig.fromLLMConfig(LLMConfig config) {
    SearchParameters? searchParams = config.getExtension<SearchParameters>(
      LLMConfigKeys.searchParameters,
    );
    bool? liveSearchEnabled =
        config.getExtension<bool>(LLMConfigKeys.liveSearch);

    final webSearchEnabled =
        config.getExtension<bool>(LLMConfigKeys.webSearchEnabled);
    if (webSearchEnabled == true &&
        searchParams == null &&
        liveSearchEnabled != true) {
      liveSearchEnabled = true;
      searchParams = SearchParameters.webSearch();
    }

    final dynamic webSearchConfig =
        config.getExtension<dynamic>(LLMConfigKeys.webSearchConfig);
    if (webSearchConfig != null && searchParams == null) {
      try {
        final sourceType =
            webSearchConfig.searchType.toString().contains('news')
                ? 'news'
                : 'web';
        searchParams = SearchParameters(
          mode: webSearchConfig.mode ?? 'auto',
          sources: [
            SearchSource(
              sourceType: sourceType,
              excludedWebsites:
                  (webSearchConfig.blockedDomains as List?)?.cast<String>(),
            ),
          ],
          maxSearchResults: webSearchConfig.maxResults as int?,
          fromDate: webSearchConfig.fromDate as String?,
          toDate: webSearchConfig.toDate as String?,
        );
        liveSearchEnabled = true;
      } catch (_) {
        // If structure doesn't match, ignore and fall back to other config.
      }
    }

    return XAIConfig(
      apiKey: config.apiKey!,
      baseUrl:
          config.baseUrl.isNotEmpty ? config.baseUrl : 'https://api.x.ai/v1/',
      model: config.model,
      maxTokens: config.maxTokens,
      temperature: config.temperature,
      systemPrompt: config.systemPrompt,
      timeout: config.timeout,
      topP: config.topP,
      topK: config.topK,
      tools: config.tools,
      toolChoice: config.toolChoice,
      jsonSchema: config.getExtension<StructuredOutputFormat>(
        LLMConfigKeys.jsonSchema,
      ),
      embeddingEncodingFormat: config.getExtension<String>(
        LLMConfigKeys.embeddingEncodingFormat,
      ),
      embeddingDimensions: config.getExtension<int>(
        LLMConfigKeys.embeddingDimensions,
      ),
      searchParameters: searchParams,
      liveSearch: liveSearchEnabled,
      originalConfig: config,
    );
  }

  T? getExtension<T>(String key) => _originalConfig?.getExtension<T>(key);

  @override
  LLMConfig? get originalConfig => _originalConfig;

  bool get supportsReasoning => model.contains('grok');

  bool get supportsVision =>
      model.contains('vision') || model.contains('grok-vision');

  bool get supportsToolCalling => true;

  bool get supportsSearch => model.contains('grok');

  bool get isLiveSearchEnabled =>
      liveSearch == true || searchParameters != null;

  bool get supportsEmbeddings =>
      model.contains('embed') || model == 'text-embedding-ada-002';

  String get modelFamily {
    if (model.contains('grok')) return 'Grok';
    if (model.contains('embed')) return 'Embedding';
    return 'Unknown';
  }

  XAIConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    int? maxTokens,
    double? temperature,
    String? systemPrompt,
    Duration? timeout,
    double? topP,
    int? topK,
    List<Tool>? tools,
    ToolChoice? toolChoice,
    StructuredOutputFormat? jsonSchema,
    String? embeddingEncodingFormat,
    int? embeddingDimensions,
    SearchParameters? searchParameters,
    bool? liveSearch,
  }) {
    return XAIConfig(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      maxTokens: maxTokens ?? this.maxTokens,
      temperature: temperature ?? this.temperature,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      timeout: timeout ?? this.timeout,
      topP: topP ?? this.topP,
      topK: topK ?? this.topK,
      tools: tools ?? this.tools,
      toolChoice: toolChoice ?? this.toolChoice,
      jsonSchema: jsonSchema ?? this.jsonSchema,
      embeddingEncodingFormat:
          embeddingEncodingFormat ?? this.embeddingEncodingFormat,
      embeddingDimensions: embeddingDimensions ?? this.embeddingDimensions,
      searchParameters: searchParameters ?? this.searchParameters,
      liveSearch: liveSearch ?? this.liveSearch,
      originalConfig: _originalConfig,
    );
  }
}
