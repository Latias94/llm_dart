import 'package:llm_dart_core/llm_dart_core.dart';

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

/// Google (Gemini) provider configuration for the sub-package.
class GoogleConfig {
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
  final double? frequencyPenalty;
  final double? presencePenalty;
  final int? seed;
  final ReasoningEffort? reasoningEffort;
  final int? thinkingBudgetTokens;
  final bool? includeThoughts;
  final bool? enableImageGeneration;
  final List<String>? responseModalities;
  final List<SafetySetting>? safetySettings;
  final int maxInlineDataSize;
  final int? candidateCount;
  final List<String>? stopSequences;

  final String? embeddingTaskType;
  final String? embeddingTitle;
  final int? embeddingDimensions;

  final LLMConfig? _originalConfig;

  static const String _defaultBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/';
  static const String _defaultModel = 'gemini-1.5-flash';

  const GoogleConfig({
    required this.apiKey,
    this.baseUrl = _defaultBaseUrl,
    this.model = _defaultModel,
    this.maxTokens,
    this.temperature,
    this.systemPrompt,
    this.timeout,
    this.topP,
    this.topK,
    this.tools,
    this.toolChoice,
    this.jsonSchema,
    this.frequencyPenalty,
    this.presencePenalty,
    this.seed,
    this.reasoningEffort,
    this.thinkingBudgetTokens,
    this.includeThoughts,
    this.enableImageGeneration,
    this.responseModalities,
    this.safetySettings,
    this.maxInlineDataSize = 20 * 1024 * 1024,
    this.candidateCount,
    this.stopSequences,
    this.embeddingTaskType,
    this.embeddingTitle,
    this.embeddingDimensions,
    LLMConfig? originalConfig,
  }) : _originalConfig = originalConfig;

  factory GoogleConfig.fromLLMConfig(LLMConfig config) {
    return GoogleConfig(
      apiKey: config.apiKey!,
      baseUrl: config.baseUrl.isNotEmpty ? config.baseUrl : _defaultBaseUrl,
      model: config.model.isNotEmpty ? config.model : _defaultModel,
      maxTokens: config.maxTokens,
      temperature: config.temperature,
      systemPrompt: config.systemPrompt,
      timeout: config.timeout,
      topP: config.topP,
      topK: config.topK,
      tools: config.tools,
      toolChoice: config.toolChoice,
      jsonSchema:
          config.getExtension<StructuredOutputFormat>(LLMConfigKeys.jsonSchema),
      frequencyPenalty:
          config.getExtension<double>(LLMConfigKeys.frequencyPenalty),
      presencePenalty:
          config.getExtension<double>(LLMConfigKeys.presencePenalty),
      seed: config.getExtension<int>(LLMConfigKeys.seed),
      reasoningEffort: ReasoningEffort.fromString(
        config.getExtension<String>(LLMConfigKeys.reasoningEffort),
      ),
      thinkingBudgetTokens:
          config.getExtension<int>(LLMConfigKeys.thinkingBudgetTokens),
      includeThoughts: config.getExtension<bool>(LLMConfigKeys.includeThoughts),
      enableImageGeneration:
          config.getExtension<bool>(LLMConfigKeys.enableImageGeneration),
      responseModalities:
          config.getExtension<List<String>>(LLMConfigKeys.responseModalities),
      safetySettings: config
          .getExtension<List<SafetySetting>>(LLMConfigKeys.safetySettings),
      maxInlineDataSize:
          config.getExtension<int>(LLMConfigKeys.maxInlineDataSize) ??
              20 * 1024 * 1024,
      candidateCount: config.getExtension<int>(LLMConfigKeys.candidateCount),
      stopSequences:
          config.getExtension<List<String>>(LLMConfigKeys.stopSequences),
      embeddingTaskType:
          config.getExtension<String>(LLMConfigKeys.embeddingTaskType),
      embeddingTitle: config.getExtension<String>(LLMConfigKeys.embeddingTitle),
      embeddingDimensions:
          config.getExtension<int>(LLMConfigKeys.embeddingDimensions),
      originalConfig: config,
    );
  }

  T? getExtension<T>(String key) => _originalConfig?.getExtension<T>(key);

  LLMConfig? get originalConfig => _originalConfig;

  bool get supportsReasoning {
    return model.contains('thinking') ||
        model.contains('gemini-2.5') ||
        model.contains('gemini-2.0') ||
        model.contains('gemini-exp');
  }

  bool get supportsVision {
    return !model.contains('text');
  }

  bool get supportsToolCalling => true;

  bool get supportsImageGeneration {
    return model.contains('imagen') || enableImageGeneration == true;
  }

  bool get supportsEmbeddings {
    return model.contains('embedding') || model.contains('text-embedding');
  }

  bool get supportsTTS {
    return model.contains('tts') ||
        model.contains('gemini-2.5-flash-preview-tts') ||
        model.contains('gemini-2.5-pro-preview-tts');
  }

  /// Get default safety settings (permissive for development).
  static List<SafetySetting> get defaultSafetySettings => const [
        SafetySetting(
          category: HarmCategory.harmCategoryHarassment,
          threshold: HarmBlockThreshold.blockOnlyHigh,
        ),
        SafetySetting(
          category: HarmCategory.harmCategoryHateSpeech,
          threshold: HarmBlockThreshold.blockOnlyHigh,
        ),
        SafetySetting(
          category: HarmCategory.harmCategorySexuallyExplicit,
          threshold: HarmBlockThreshold.blockOnlyHigh,
        ),
        SafetySetting(
          category: HarmCategory.harmCategoryDangerousContent,
          threshold: HarmBlockThreshold.blockOnlyHigh,
        ),
      ];

  /// Create a copy of this config with optional overrides.
  GoogleConfig copyWith({
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
    double? frequencyPenalty,
    double? presencePenalty,
    int? seed,
    ReasoningEffort? reasoningEffort,
    int? thinkingBudgetTokens,
    bool? includeThoughts,
    bool? enableImageGeneration,
    List<String>? responseModalities,
    List<SafetySetting>? safetySettings,
    int? maxInlineDataSize,
    int? candidateCount,
    List<String>? stopSequences,
    String? embeddingTaskType,
    String? embeddingTitle,
    int? embeddingDimensions,
  }) {
    return GoogleConfig(
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
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      seed: seed ?? this.seed,
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
      embeddingTaskType: embeddingTaskType ?? this.embeddingTaskType,
      embeddingTitle: embeddingTitle ?? this.embeddingTitle,
      embeddingDimensions: embeddingDimensions ?? this.embeddingDimensions,
      originalConfig: _originalConfig,
    );
  }
}
