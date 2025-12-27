import 'package:llm_dart_core/core/config.dart';
import 'package:llm_dart_core/core/provider_options.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_core/models/tool_models.dart';

import 'web_search_tool_options.dart';

/// Google AI harm categories
enum HarmCategory {
  harmCategoryUnspecified('HARM_CATEGORY_UNSPECIFIED'),
  harmCategoryDerogatory('HARM_CATEGORY_DEROGATORY'),
  harmCategoryToxicity('HARM_CATEGORY_TOXICITY'),
  harmCategoryViolence('HARM_CATEGORY_VIOLENCE'),
  harmCategorySexual('HARM_CATEGORY_SEXUAL'),
  harmCategoryMedical('HARM_CATEGORY_MEDICAL'),
  harmCategoryDangerous('HARM_CATEGORY_DANGEROUS'),
  harmCategoryHarassment('HARM_CATEGORY_HARASSMENT'),
  harmCategoryHateSpeech('HARM_CATEGORY_HATE_SPEECH'),
  harmCategorySexuallyExplicit('HARM_CATEGORY_SEXUALLY_EXPLICIT'),
  harmCategoryDangerousContent('HARM_CATEGORY_DANGEROUS_CONTENT');

  const HarmCategory(this.value);
  final String value;
}

/// Google AI harm block thresholds
enum HarmBlockThreshold {
  harmBlockThresholdUnspecified('HARM_BLOCK_THRESHOLD_UNSPECIFIED'),
  blockLowAndAbove('BLOCK_LOW_AND_ABOVE'),
  blockMediumAndAbove('BLOCK_MEDIUM_AND_ABOVE'),
  blockOnlyHigh('BLOCK_ONLY_HIGH'),
  blockNone('BLOCK_NONE'),
  off('OFF');

  const HarmBlockThreshold(this.value);
  final String value;
}

/// Google AI safety setting
class SafetySetting {
  final HarmCategory category;
  final HarmBlockThreshold threshold;

  const SafetySetting({
    required this.category,
    required this.threshold,
  });

  Map<String, dynamic> toJson() => {
        'category': category.value,
        'threshold': threshold.value,
      };
}

/// Google (Gemini) provider configuration
///
/// This class contains all configuration options for the Google providers.
/// It's extracted from the main provider to improve modularity and reusability.
class GoogleConfig {
  final String apiKey;
  final String baseUrl;
  final String model;
  final int? maxTokens;
  final double? temperature;
  final String? systemPrompt;
  final Duration? timeout;
  final bool stream;
  final double? topP;
  final int? topK;
  final List<Tool>? tools;
  final ToolChoice? toolChoice;
  final StructuredOutputFormat? jsonSchema;
  final ReasoningEffort? reasoningEffort;
  final int? thinkingBudgetTokens;
  final bool? includeThoughts;
  final bool? enableImageGeneration;
  final List<String>? responseModalities;
  final List<SafetySetting>? safetySettings;
  final int maxInlineDataSize;
  final int? candidateCount;
  final List<String>? stopSequences;

  /// Provider-native web search configuration (Gemini `google_search` tool).
  ///
  /// When enabled (via `providerOptions['google']['webSearchEnabled']` or
  /// `providerOptions['google']['webSearch'].enabled`), `GoogleChat` injects a
  /// Google grounding tool into the request JSON (e.g. `googleSearch` or
  /// `googleSearchRetrieval`, depending on the model).
  final bool webSearchEnabled;

  /// Provider-native tool options for `google.google_search`.
  ///
  /// This follows the Vercel-style provider tool input schema (e.g.
  /// `mode`, `dynamicThreshold`) and is only used for request shaping.
  final GoogleWebSearchToolOptions? webSearchToolOptions;

  // Embedding-specific parameters
  final String? embeddingTaskType;
  final String? embeddingTitle;
  final int? embeddingDimensions;

  /// Reference to original LLMConfig for accessing provider options.
  final LLMConfig? _originalConfig;

  const GoogleConfig({
    required this.apiKey,
    this.baseUrl = 'https://generativelanguage.googleapis.com/v1beta/',
    this.model = 'gemini-1.5-flash',
    this.maxTokens,
    this.temperature,
    this.systemPrompt,
    this.timeout,
    this.stream = false,
    this.topP,
    this.topK,
    this.tools,
    this.toolChoice,
    this.jsonSchema,
    this.reasoningEffort,
    this.thinkingBudgetTokens,
    this.includeThoughts,
    this.enableImageGeneration,
    this.responseModalities,
    this.safetySettings,
    this.maxInlineDataSize = 20 * 1024 * 1024, // 20MB default
    this.candidateCount,
    this.stopSequences,
    this.webSearchEnabled = false,
    this.webSearchToolOptions,
    this.embeddingTaskType,
    this.embeddingTitle,
    this.embeddingDimensions,
    LLMConfig? originalConfig,
  }) : _originalConfig = originalConfig;

  /// Create GoogleConfig from unified LLMConfig
  factory GoogleConfig.fromLLMConfig(LLMConfig config) {
    const providerId = 'google';
    final providerOptions = config.providerOptions;

    final webSearchEnabledFromProviderOptions = readProviderOption<bool>(
        providerOptions, providerId, 'webSearchEnabled');

    final rawWebSearch = readProviderOptionMap(
            providerOptions, providerId, 'webSearch') ??
        readProviderOption<dynamic>(providerOptions, providerId, 'webSearch');
    final webSearchEnabledFromWebSearch =
        _parseWebSearchEnabledFromLegacyConfig(rawWebSearch);

    final webSearchToolOptionsFromProviderOptions =
        _parseWebSearchToolOptions(rawWebSearch);

    final webSearchEnabledFromOptions =
        webSearchEnabledFromProviderOptions ?? webSearchEnabledFromWebSearch;

    final providerTools = config.providerTools;
    ProviderTool? providerToolWebSearch;
    if (providerTools != null) {
      for (final tool in providerTools) {
        if (tool.id == 'google.google_search') {
          providerToolWebSearch = tool;
          break;
        }
      }
    }

    final providerToolEnabled = providerToolWebSearch == null
        ? false
        : _isProviderToolEnabled(providerToolWebSearch);

    final mergedWebSearchEnabled =
        webSearchEnabledFromOptions == true || providerToolEnabled;

    final webSearchToolOptionsFromProviderTools =
        providerToolWebSearch != null &&
                providerToolWebSearch.options.isNotEmpty
            ? _parseWebSearchToolOptions(providerToolWebSearch.options)
            : null;

    final mergedWebSearchToolOptions = webSearchToolOptionsFromProviderTools ??
        webSearchToolOptionsFromProviderOptions;

    final safetySettings = _parseSafetySettings(
      readProviderOptionList(
        providerOptions,
        providerId,
        'safetySettings',
      ),
    );

    return GoogleConfig(
      apiKey: config.apiKey!,
      baseUrl: config.baseUrl,
      model: config.model,
      maxTokens: config.maxTokens,
      temperature: config.temperature,
      systemPrompt: config.systemPrompt,
      timeout: config.timeout,

      topP: config.topP,
      topK: config.topK,
      tools: config.tools,
      toolChoice: config.toolChoice,
      // Google-specific provider options (namespaced)
      reasoningEffort: ReasoningEffort.fromString(
        readProviderOption<String>(
            providerOptions, providerId, 'reasoningEffort'),
      ),
      thinkingBudgetTokens: readProviderOption<int>(
          providerOptions, providerId, 'thinkingBudgetTokens'),
      includeThoughts: readProviderOption<bool>(
        providerOptions,
        providerId,
        'includeThoughts',
      ),
      enableImageGeneration: readProviderOption<bool>(
        providerOptions,
        providerId,
        'enableImageGeneration',
      ),
      responseModalities: readProviderOptionList(
        providerOptions,
        providerId,
        'responseModalities',
      )?.whereType<String>().toList(growable: false),
      safetySettings: safetySettings,
      maxInlineDataSize: readProviderOption<int>(
            providerOptions,
            providerId,
            'maxInlineDataSize',
          ) ??
          20 * 1024 * 1024,
      candidateCount: readProviderOption<int>(
          providerOptions, providerId, 'candidateCount'),
      stopSequences: config.stopSequences,
      webSearchEnabled: mergedWebSearchEnabled,
      webSearchToolOptions: mergedWebSearchToolOptions,
      // Embedding-specific provider options
      embeddingTaskType: readProviderOption<String>(
          providerOptions, providerId, 'embeddingTaskType'),
      embeddingTitle: readProviderOption<String>(
          providerOptions, providerId, 'embeddingTitle'),
      embeddingDimensions: readProviderOption<int>(
          providerOptions, providerId, 'embeddingDimensions'),
      originalConfig: config,
    );
  }

  static List<SafetySetting>? _parseSafetySettings(List<dynamic>? raw) {
    if (raw == null || raw.isEmpty) return null;

    HarmCategory? parseCategory(dynamic value) {
      if (value is HarmCategory) return value;
      if (value is! String) return null;
      for (final c in HarmCategory.values) {
        if (c.value == value || c.name == value) return c;
      }
      return null;
    }

    HarmBlockThreshold? parseThreshold(dynamic value) {
      if (value is HarmBlockThreshold) return value;
      if (value is! String) return null;
      for (final t in HarmBlockThreshold.values) {
        if (t.value == value || t.name == value) return t;
      }
      return null;
    }

    final result = <SafetySetting>[];

    for (final item in raw) {
      if (item is SafetySetting) {
        result.add(item);
        continue;
      }

      if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        final category = parseCategory(map['category']);
        final threshold = parseThreshold(map['threshold']);
        if (category != null && threshold != null) {
          result.add(SafetySetting(category: category, threshold: threshold));
        }
      }
    }

    return result.isEmpty ? null : result;
  }

  static GoogleWebSearchToolOptions? _parseWebSearchToolOptions(dynamic raw) {
    if (raw == null) return null;
    if (raw is GoogleWebSearchToolOptions) return raw;
    if (raw is Map<String, dynamic>) {
      return GoogleWebSearchToolOptions.fromJson(raw);
    }
    if (raw is Map) {
      return GoogleWebSearchToolOptions.fromJson(
          Map<String, dynamic>.from(raw));
    }
    return null;
  }

  static bool? _parseWebSearchEnabledFromLegacyConfig(dynamic raw) {
    if (raw == null) return null;

    if (raw is bool) return raw;

    if (raw is Map<String, dynamic>) {
      final enabled = raw['enabled'];
      if (enabled is bool) return enabled;
      return true; // presence implies enable (legacy behavior)
    }

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final enabled = map['enabled'];
      if (enabled is bool) return enabled;
      return true; // presence implies enable (legacy behavior)
    }

    return true;
  }

  static bool _isProviderToolEnabled(ProviderTool tool) {
    final enabled = tool.options['enabled'];
    if (enabled is bool) return enabled;
    return true;
  }

  /// Get the original LLMConfig for HTTP configuration
  LLMConfig? get originalConfig => _originalConfig;

  /// Check if this model supports reasoning/thinking
  bool get supportsReasoning {
    // Intentionally optimistic: do not maintain a model capability matrix.
    return true;
  }

  /// Check if this model supports vision
  bool get supportsVision {
    // Intentionally optimistic: do not maintain a model capability matrix.
    return true;
  }

  /// Check if this model supports tool calling
  bool get supportsToolCalling {
    // All modern Gemini models support tool calling
    return true;
  }

  /// Check if this model supports image generation
  bool get supportsImageGeneration {
    // Intentionally optimistic: do not maintain a model capability matrix.
    return true;
  }

  /// Check if this model supports embeddings
  bool get supportsEmbeddings {
    // Intentionally optimistic: do not maintain a model capability matrix.
    return true;
  }

  /// Check if this model supports text-to-speech
  bool get supportsTTS {
    // Intentionally optimistic: do not maintain a model capability matrix.
    return true;
  }

  /// Get default safety settings (permissive for development)
  static List<SafetySetting> get defaultSafetySettings => [
        const SafetySetting(
          category: HarmCategory.harmCategoryHarassment,
          threshold: HarmBlockThreshold.blockOnlyHigh,
        ),
        const SafetySetting(
          category: HarmCategory.harmCategoryHateSpeech,
          threshold: HarmBlockThreshold.blockOnlyHigh,
        ),
        const SafetySetting(
          category: HarmCategory.harmCategorySexuallyExplicit,
          threshold: HarmBlockThreshold.blockOnlyHigh,
        ),
        const SafetySetting(
          category: HarmCategory.harmCategoryDangerousContent,
          threshold: HarmBlockThreshold.blockOnlyHigh,
        ),
      ];

  GoogleConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    int? maxTokens,
    double? temperature,
    String? systemPrompt,
    Duration? timeout,
    bool? stream,
    double? topP,
    int? topK,
    List<Tool>? tools,
    ToolChoice? toolChoice,
    StructuredOutputFormat? jsonSchema,
    ReasoningEffort? reasoningEffort,
    int? thinkingBudgetTokens,
    bool? includeThoughts,
    bool? enableImageGeneration,
    List<String>? responseModalities,
    List<SafetySetting>? safetySettings,
    int? maxInlineDataSize,
    int? candidateCount,
    List<String>? stopSequences,
    bool? webSearchEnabled,
    GoogleWebSearchToolOptions? webSearchToolOptions,
    String? embeddingTaskType,
    String? embeddingTitle,
    int? embeddingDimensions,
  }) =>
      GoogleConfig(
        apiKey: apiKey ?? this.apiKey,
        baseUrl: baseUrl ?? this.baseUrl,
        model: model ?? this.model,
        maxTokens: maxTokens ?? this.maxTokens,
        temperature: temperature ?? this.temperature,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        timeout: timeout ?? this.timeout,
        stream: stream ?? this.stream,
        topP: topP ?? this.topP,
        topK: topK ?? this.topK,
        tools: tools ?? this.tools,
        toolChoice: toolChoice ?? this.toolChoice,
        jsonSchema: jsonSchema ?? this.jsonSchema,
        reasoningEffort: reasoningEffort ?? this.reasoningEffort,
        thinkingBudgetTokens: thinkingBudgetTokens ?? this.thinkingBudgetTokens,
        includeThoughts: includeThoughts ?? this.includeThoughts,
        enableImageGeneration:
            enableImageGeneration ?? this.enableImageGeneration,
        responseModalities: responseModalities ?? this.responseModalities,
        safetySettings: safetySettings ?? this.safetySettings,
        maxInlineDataSize: maxInlineDataSize ?? this.maxInlineDataSize,
        candidateCount: candidateCount ?? this.candidateCount,
        stopSequences: stopSequences ?? this.stopSequences,
        webSearchEnabled: webSearchEnabled ?? this.webSearchEnabled,
        webSearchToolOptions: webSearchToolOptions ?? this.webSearchToolOptions,
        embeddingTaskType: embeddingTaskType ?? this.embeddingTaskType,
        embeddingTitle: embeddingTitle ?? this.embeddingTitle,
        embeddingDimensions: embeddingDimensions ?? this.embeddingDimensions,
        originalConfig: _originalConfig,
      );
}
