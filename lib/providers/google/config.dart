import 'package:llm_dart_transport/llm_dart_transport.dart'
    show DioClientOverrides, HasDioClientOverrides;

import '../../core/web_search.dart';
import '../../models/tool_models.dart';
import '../../models/chat_models.dart';

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
class GoogleConfig implements HasDioClientOverrides {
  final String apiKey;
  final String baseUrl;
  final String model;
  final int? maxTokens;
  final double? temperature;
  final String? systemPrompt;
  final Duration? timeout;
  @override
  final DioClientOverrides? dioOverrides;
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
  final WebSearchConfig? webSearchConfig;
  final List<SafetySetting>? safetySettings;
  final int maxInlineDataSize;
  final int? candidateCount;
  final List<String>? stopSequences;

  // Embedding-specific parameters
  final String? embeddingTaskType;
  final String? embeddingTitle;
  final int? embeddingDimensions;

  const GoogleConfig({
    required this.apiKey,
    this.baseUrl = 'https://generativelanguage.googleapis.com/v1beta/',
    this.model = 'gemini-1.5-flash',
    this.maxTokens,
    this.temperature,
    this.systemPrompt,
    this.timeout,
    this.dioOverrides,
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
    this.webSearchConfig,
    this.safetySettings,
    this.maxInlineDataSize = 20 * 1024 * 1024, // 20MB default
    this.candidateCount,
    this.stopSequences,
    this.embeddingTaskType,
    this.embeddingTitle,
    this.embeddingDimensions,
  });

  /// Check if this model supports reasoning/thinking
  bool get supportsReasoning {
    // According to Google API docs, Gemini 2.5 series models support thinking
    return model.contains('thinking') ||
        model.contains('gemini-2.5') ||
        model.contains('gemini-2.0') ||
        model.contains('gemini-exp');
  }

  /// Check if this model supports vision
  bool get supportsVision {
    // Most Gemini models support vision except text-only variants
    return !model.contains('text');
  }

  /// Check if this model supports tool calling
  bool get supportsToolCalling {
    // All modern Gemini models support tool calling
    return true;
  }

  /// Check if this model supports image generation
  bool get supportsImageGeneration {
    // Imagen models and some Gemini models support image generation
    return model.contains('imagen') || enableImageGeneration == true;
  }

  /// Check if Google native web search is configured.
  bool get webSearchEnabled => webSearchConfig?.enabled == true;

  /// Check if this model supports embeddings
  bool get supportsEmbeddings {
    // Google embedding models
    return model.contains('embedding') || model.contains('text-embedding');
  }

  /// Check if this model supports text-to-speech
  bool get supportsTTS {
    // Google TTS models
    return model.contains('tts') ||
        model.contains('gemini-2.5-flash-preview-tts') ||
        model.contains('gemini-2.5-pro-preview-tts');
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
    DioClientOverrides? dioOverrides,
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
    WebSearchConfig? webSearchConfig,
    List<SafetySetting>? safetySettings,
    int? maxInlineDataSize,
    int? candidateCount,
    List<String>? stopSequences,
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
        dioOverrides: dioOverrides ?? this.dioOverrides,
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
        webSearchConfig: webSearchConfig ?? this.webSearchConfig,
        safetySettings: safetySettings ?? this.safetySettings,
        maxInlineDataSize: maxInlineDataSize ?? this.maxInlineDataSize,
        candidateCount: candidateCount ?? this.candidateCount,
        stopSequences: stopSequences ?? this.stopSequences,
        embeddingTaskType: embeddingTaskType ?? this.embeddingTaskType,
        embeddingTitle: embeddingTitle ?? this.embeddingTitle,
        embeddingDimensions: embeddingDimensions ?? this.embeddingDimensions,
      );
}
