import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_content_projection.dart';
import 'google_options.dart';
import 'google_response_format.dart';
import 'google_shared.dart';
import 'google_tool_configuration.dart';

final class GoogleGenerateContentRequest {
  final Map<String, Object?> body;
  final List<ModelWarning> warnings;

  GoogleGenerateContentRequest({
    required Map<String, Object?> body,
    List<ModelWarning> warnings = const [],
  })  : body = Map.unmodifiable(body),
        warnings = List.unmodifiable(warnings);
}

final class GoogleGenerateContentCodec {
  const GoogleGenerateContentCodec();

  GoogleGenerateContentRequest encodeRequest({
    required String modelId,
    required List<PromptMessage> prompt,
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required GenerateTextOptions options,
    required GoogleChatModelSettings settings,
    required GoogleGenerateTextOptions providerOptions,
  }) {
    final warnings = <ModelWarning>[];
    const contentProjectionCodec = GoogleContentProjectionCodec();
    final promptProjection = contentProjectionCodec.encodePrompt(
      modelId: modelId,
      prompt: prompt,
    );
    final systemInstructionParts = promptProjection.systemInstructionParts;
    final contents = promptProjection.contents;
    final isGemmaModel = modelId.toLowerCase().startsWith('gemma-');

    final includeServerSideToolInvocations =
        providerOptions.includeServerSideToolInvocations ??
            settings.includeServerSideToolInvocations;
    final promptRequiresServerToolReplay =
        contentProjectionCodec.promptRequiresServerToolReplay(prompt);

    final nativeTools = providerOptions.tools ?? settings.tools;
    final toolConfiguration = const GoogleToolConfigurationCodec().encode(
      modelId: modelId,
      tools: tools,
      toolChoice: toolChoice,
      nativeTools: nativeTools,
      includeServerSideToolInvocations: includeServerSideToolInvocations,
      promptRequiresServerToolReplay: promptRequiresServerToolReplay,
      warnings: warnings,
    );

    final generationConfig = <String, Object?>{
      if (options.maxOutputTokens != null)
        'maxOutputTokens': options.maxOutputTokens,
      if (options.temperature != null) 'temperature': options.temperature,
      if (options.topP != null) 'topP': options.topP,
      if (options.topK != null) 'topK': options.topK,
      if (options.stopSequences != null && options.stopSequences!.isNotEmpty)
        'stopSequences': options.stopSequences,
      if (options.presencePenalty != null)
        'presencePenalty': options.presencePenalty,
      if (options.frequencyPenalty != null)
        'frequencyPenalty': options.frequencyPenalty,
      if (options.seed != null) 'seed': options.seed,
    };

    final resolvedCandidateCount = _resolveCandidateCount(
      providerOptions.candidateCount,
      warnings: warnings,
    );
    if (resolvedCandidateCount != null) {
      generationConfig['candidateCount'] = resolvedCandidateCount;
    }

    final thinkingConfig = _buildThinkingConfig(
      modelId: modelId,
      options: options,
      providerOptions: providerOptions,
      warnings: warnings,
    );
    if (thinkingConfig != null) {
      generationConfig['thinkingConfig'] = thinkingConfig;
    }

    if (providerOptions.responseModalities case final modalities?
        when modalities.isNotEmpty) {
      generationConfig['responseModalities'] = [
        for (final modality in modalities) modality.value,
      ];
    }

    if (providerOptions.responseFormat case final responseFormat?) {
      generationConfig['responseMimeType'] = 'application/json';
      generationConfig['responseSchema'] =
          _normalizeGoogleResponseSchema(responseFormat);
    }

    final safetySettings =
        providerOptions.safetySettings ?? settings.safetySettings;

    final body = <String, Object?>{
      'contents': contents,
      if (systemInstructionParts.isNotEmpty && !isGemmaModel)
        'systemInstruction': {
          'parts': systemInstructionParts,
        },
      if (generationConfig.isNotEmpty) 'generationConfig': generationConfig,
      if (safetySettings.isNotEmpty)
        'safetySettings': [
          for (final setting in safetySettings) setting.toJson(),
        ],
      if (providerOptions.cachedContent != null)
        'cachedContent': providerOptions.cachedContent,
      if (toolConfiguration.tools != null) 'tools': toolConfiguration.tools,
      if (toolConfiguration.toolConfig != null)
        'toolConfig': toolConfiguration.toolConfig,
    };

    return GoogleGenerateContentRequest(
      body: body,
      warnings: warnings,
    );
  }

  Map<String, Object?> _normalizeGoogleResponseSchema(
    GoogleJsonSchemaResponseFormat responseFormat,
  ) {
    final normalized = Map<String, Object?>.from(responseFormat.schema);
    normalized.remove('additionalProperties');
    return normalized;
  }

  int? _resolveCandidateCount(
    int? value, {
    required List<ModelWarning> warnings,
  }) {
    if (value == null) {
      return null;
    }

    if (value <= 0) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'candidateCount',
          message: 'candidateCount must be greater than 0 for Google.',
        ),
      );
      return null;
    }

    if (value > 1) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'candidateCount',
          message:
              'The unified LanguageModel interface currently exposes a single result. candidateCount has been clamped to 1 for Google.',
        ),
      );
      return 1;
    }

    return value;
  }

  Map<String, Object?>? _buildThinkingConfig({
    required String modelId,
    required GenerateTextOptions options,
    required GoogleGenerateTextOptions providerOptions,
    required List<ModelWarning> warnings,
  }) {
    final config = <String, Object?>{};
    final sharedReasoning = options.reasoning;

    if (providerOptions.includeThoughts != null) {
      config['includeThoughts'] = providerOptions.includeThoughts;
    } else if (sharedReasoning?.enabled == true) {
      config['includeThoughts'] = true;
    }

    if (isGemini3Model(modelId)) {
      final sharedThinkingLevel = _mapGoogleThinkingLevel(
        sharedReasoning?.effort,
      );
      if (providerOptions.thinkingLevel != null) {
        config['thinkingLevel'] = providerOptions.thinkingLevel!.value;
        if (sharedThinkingLevel != null) {
          warnings.add(
            const ModelWarning(
              type: ModelWarningType.compatibility,
              field: 'options.reasoning.effort',
              message:
                  'Google providerOptions.thinkingLevel overrides shared options.reasoning.effort.',
            ),
          );
        }
      } else if (sharedThinkingLevel != null) {
        config['thinkingLevel'] = sharedThinkingLevel.value;
      }

      if (providerOptions.thinkingBudgetTokens != null) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.compatibility,
            field: 'thinkingBudgetTokens',
            message:
                'thinkingBudgetTokens is ignored for Gemini 3 style Google models. Use thinkingLevel instead.',
          ),
        );
      }
      if (sharedReasoning?.budgetTokens != null) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.compatibility,
            field: 'options.reasoning.budgetTokens',
            message:
                'options.reasoning.budgetTokens is ignored for Gemini 3 style Google models. Use reasoning.effort instead.',
          ),
        );
      }
    } else {
      if (providerOptions.thinkingBudgetTokens != null) {
        config['thinkingBudget'] = providerOptions.thinkingBudgetTokens;
        if (sharedReasoning?.budgetTokens != null) {
          warnings.add(
            const ModelWarning(
              type: ModelWarningType.compatibility,
              field: 'options.reasoning.budgetTokens',
              message:
                  'Google providerOptions.thinkingBudgetTokens overrides shared options.reasoning.budgetTokens.',
            ),
          );
        }
      } else if (sharedReasoning?.budgetTokens != null) {
        config['thinkingBudget'] = sharedReasoning!.budgetTokens;
      }

      if (providerOptions.thinkingLevel != null) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.compatibility,
            field: 'thinkingLevel',
            message:
                'thinkingLevel is only supported for Gemini 3 style Google models. Use thinkingBudgetTokens instead.',
          ),
        );
      }
      if (sharedReasoning?.effort != null) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.compatibility,
            field: 'options.reasoning.effort',
            message:
                'options.reasoning.effort is only mapped for Gemini 3 style Google models. Use reasoning.budgetTokens for other Google models.',
          ),
        );
      }
    }

    if (sharedReasoning?.enabled == false &&
        (providerOptions.includeThoughts == null &&
            providerOptions.thinkingBudgetTokens == null &&
            providerOptions.thinkingLevel == null)) {
      if (isGemini3Model(modelId)) {
        config['thinkingLevel'] = GoogleThinkingLevel.minimal.value;
      } else {
        config['thinkingBudget'] = 0;
      }
    }

    return config.isEmpty ? null : config;
  }
}

GoogleThinkingLevel? _mapGoogleThinkingLevel(ReasoningEffort? effort) {
  return switch (effort) {
    null => null,
    ReasoningEffort.minimal => GoogleThinkingLevel.minimal,
    ReasoningEffort.low => GoogleThinkingLevel.low,
    ReasoningEffort.medium => GoogleThinkingLevel.medium,
    ReasoningEffort.high => GoogleThinkingLevel.high,
  };
}
