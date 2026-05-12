import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_function_response_replay.dart';
import 'google_options.dart';
import 'google_response_format.dart';
import 'google_server_tool_replay.dart';
import 'google_shared.dart';
import 'google_tools.dart';

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
    final systemInstructionParts = <Map<String, Object?>>[];
    final contents = <Map<String, Object?>>[];
    var sawConversationMessage = false;

    for (final message in prompt) {
      if (message is SystemPromptMessage) {
        if (sawConversationMessage) {
          throw UnsupportedError(
            'Google system messages are only supported before the first conversation message.',
          );
        }

        for (final part in message.parts) {
          if (part is! TextPromptPart) {
            throw UnsupportedError(
              'Google system prompt part ${part.runtimeType} is not supported yet.',
            );
          }

          systemInstructionParts.add({
            'text': part.text,
          });
        }
        continue;
      }

      sawConversationMessage = true;
      final encodedMessage = _encodeMessage(
        message,
        modelId: modelId,
      );
      if (encodedMessage != null) {
        contents.add(encodedMessage);
      }
    }

    if (contents.isEmpty) {
      throw ArgumentError(
        'Google requests require at least one non-system prompt message.',
      );
    }

    final isGemmaModel = modelId.toLowerCase().startsWith('gemma-');
    if (systemInstructionParts.isNotEmpty && isGemmaModel) {
      final firstContent = contents.first;
      if (firstContent['role'] != 'user') {
        throw UnsupportedError(
          'Gemma system prompts require the first non-system message to be a user message.',
        );
      }

      final parts = List<Object?>.from(asList(firstContent['parts']));
      parts.insert(
        0,
        {
          'text':
              '${systemInstructionParts.map((part) => part['text']).join('\n\n')}\n\n',
        },
      );
      firstContent['parts'] = parts;
    }

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
    final includeServerSideToolInvocations =
        providerOptions.includeServerSideToolInvocations ??
            settings.includeServerSideToolInvocations;
    final promptRequiresServerToolReplay =
        _promptRequiresServerToolReplay(prompt);
    _validateServerSideToolInvocations(
      modelId: modelId,
      includeServerSideToolInvocations: includeServerSideToolInvocations,
    );
    if (promptRequiresServerToolReplay && !includeServerSideToolInvocations) {
      throw UnsupportedError(
        'Google server-side tool replay requires includeServerSideToolInvocations=true for Gemini 3 follow-up requests.',
      );
    }
    final nativeTools = providerOptions.tools ?? settings.tools;
    final encodedNativeTools = _encodeNativeTools(
      modelId: modelId,
      tools: nativeTools,
      warnings: warnings,
    );
    final useNativeTools = encodedNativeTools.isNotEmpty;
    final useMixedTools = _supportsMixedToolRequests(
      modelId: modelId,
      includeServerSideToolInvocations: includeServerSideToolInvocations,
      hasNativeTools: useNativeTools,
      hasFunctionTools: tools.isNotEmpty,
    );

    if (useNativeTools && tools.isNotEmpty && !useMixedTools) {
      warnings.add(
        ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'tools',
          message: isGemini3Model(modelId)
              ? 'Gemini 3 mixed Google native tools and common function tools require includeServerSideToolInvocations=true. The common function tools have been ignored for this call.'
              : 'Google native tools do not mix cleanly with common function tools yet. The common function tools have been ignored for this call.',
        ),
      );
    }

    if (useNativeTools && toolChoice != null && !useMixedTools) {
      warnings.add(
        ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'toolChoice',
          message: isGemini3Model(modelId)
              ? 'toolChoice is ignored when Google native tools are enabled unless includeServerSideToolInvocations=true is set for a Gemini 3 mixed-tool request.'
              : 'toolChoice is ignored when Google native tools are enabled for this call.',
        ),
      );
    }

    final encodedFunctionTools = _encodeFunctionTools(tools);
    final shouldIncludeServerSideToolInvocations =
        includeServerSideToolInvocations &&
            (useNativeTools ||
                tools.isNotEmpty ||
                promptRequiresServerToolReplay);
    final encodedToolConfig = _encodeToolConfig(
      tools: useMixedTools || !useNativeTools ? tools : const [],
      toolChoice: useMixedTools || !useNativeTools ? toolChoice : null,
      includeServerSideToolInvocations: shouldIncludeServerSideToolInvocations,
    );

    List<Object?>? encodedTools;
    if (useMixedTools) {
      encodedTools = [
        ...encodedNativeTools,
        ...?encodedFunctionTools,
      ];
    } else if (encodedNativeTools.isNotEmpty) {
      encodedTools = encodedNativeTools;
    } else {
      encodedTools = encodedFunctionTools;
    }

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
      if (encodedTools != null) 'tools': encodedTools,
      if (encodedToolConfig != null) 'toolConfig': encodedToolConfig,
    };

    return GoogleGenerateContentRequest(
      body: body,
      warnings: warnings,
    );
  }

  List<Object?>? _encodeFunctionTools(List<FunctionToolDefinition> tools) {
    if (tools.isEmpty) {
      return null;
    }

    return [
      {
        'functionDeclarations': [
          for (final tool in tools)
            {
              'name': tool.name,
              'description': tool.description ?? '',
              'parameters': tool.inputSchema.toJson(),
            },
        ],
      },
    ];
  }

  List<Object?> _encodeNativeTools({
    required String modelId,
    required List<GoogleNativeTool> tools,
    required List<ModelWarning> warnings,
  }) {
    if (tools.isEmpty) {
      return const [];
    }

    final encoded = <Object?>[];
    final supportsNativeTools = _supportsNativeTools(modelId);

    for (final tool in tools) {
      if (!supportsNativeTools) {
        warnings.add(
          ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'tools',
            message:
                'Google native tool "${tool.name}" requires Gemini 2.0 or newer compatible models.',
          ),
        );
        continue;
      }

      encoded.add(tool.toJson());
    }

    return encoded;
  }

  Map<String, Object?>? _encodeToolConfig({
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required bool includeServerSideToolInvocations,
  }) {
    if (tools.isEmpty && !includeServerSideToolInvocations) {
      return null;
    }

    Map<String, Object?>? functionCallingConfig;
    if (tools.isNotEmpty) {
      final hasStrictTools = tools.any((tool) => tool.strict == true);
      String? mode;
      List<String>? allowedFunctionNames;

      switch (toolChoice) {
        case null:
          if (hasStrictTools) {
            mode = 'VALIDATED';
          }
        case AutoToolChoice():
          mode = hasStrictTools ? 'VALIDATED' : 'AUTO';
        case NoneToolChoice():
          mode = 'NONE';
        case RequiredToolChoice():
          mode = hasStrictTools ? 'VALIDATED' : 'ANY';
        case SpecificToolChoice(toolName: final toolName):
          mode = hasStrictTools ? 'VALIDATED' : 'ANY';
          allowedFunctionNames = [toolName];
      }

      if (mode != null) {
        functionCallingConfig = {
          'mode': mode,
          if (allowedFunctionNames != null)
            'allowedFunctionNames': allowedFunctionNames,
        };
      }
    }

    return {
      if (includeServerSideToolInvocations)
        'includeServerSideToolInvocations': true,
      if (functionCallingConfig != null)
        'functionCallingConfig': functionCallingConfig,
    };
  }

  bool _supportsNativeTools(String modelId) {
    final normalized = modelId.toLowerCase();
    return normalized.contains('gemini-2') ||
        normalized.contains('gemini-3') ||
        normalized.endsWith('-latest') ||
        normalized.contains('nano-banana');
  }

  void _validateServerSideToolInvocations({
    required String modelId,
    required bool includeServerSideToolInvocations,
  }) {
    if (!includeServerSideToolInvocations) {
      return;
    }

    if (!isGemini3Model(modelId)) {
      throw UnsupportedError(
        'Google includeServerSideToolInvocations is currently only supported for Gemini 3 models.',
      );
    }
  }

  bool _supportsMixedToolRequests({
    required String modelId,
    required bool includeServerSideToolInvocations,
    required bool hasNativeTools,
    required bool hasFunctionTools,
  }) {
    return isGemini3Model(modelId) &&
        includeServerSideToolInvocations &&
        hasNativeTools &&
        hasFunctionTools;
  }

  bool _promptRequiresServerToolReplay(List<PromptMessage> prompt) {
    for (final message in prompt) {
      final parts = switch (message) {
        UserPromptMessage(:final parts) => parts,
        AssistantPromptMessage(:final parts) => parts,
        ToolPromptMessage(:final parts) => parts,
        SystemPromptMessage(:final parts) => parts,
      };

      for (final part in parts) {
        if (part is! CustomPromptPart) {
          continue;
        }

        if (part.kind == GoogleToolCallReplay.kind ||
            part.kind == GoogleToolResponseReplay.kind) {
          return true;
        }
      }
    }

    return false;
  }

  Map<String, Object?> _normalizeGoogleResponseSchema(
    GoogleJsonSchemaResponseFormat responseFormat,
  ) {
    final normalized = Map<String, Object?>.from(responseFormat.schema);
    normalized.remove('additionalProperties');
    return normalized;
  }

  Map<String, Object?>? _encodeMessage(
    PromptMessage message, {
    required String modelId,
  }) {
    if (message case UserPromptMessage(:final parts)) {
      return {
        'role': 'user',
        'parts': [
          for (final part in parts) _encodeUserPart(part),
        ],
      };
    }

    if (message case AssistantPromptMessage(:final parts)) {
      final encodedParts = [
        for (final part in parts)
          if (_encodeAssistantPart(
            part,
            modelId: modelId,
          )
              case final encodedPart?)
            encodedPart,
      ];
      if (encodedParts.isEmpty) {
        return null;
      }

      return {
        'role': 'model',
        'parts': encodedParts,
      };
    }

    if (message case ToolPromptMessage(:final toolName, :final parts)) {
      final encodedParts = [
        for (final part in parts)
          if (_encodeToolPart(
            part,
            toolName: toolName,
            modelId: modelId,
          )
              case final encodedPart?)
            encodedPart,
      ];
      if (encodedParts.isEmpty) {
        return null;
      }

      return {
        'role': 'user',
        'parts': encodedParts,
      };
    }

    throw UnsupportedError(
      'Unsupported Google prompt message type: ${message.runtimeType}.',
    );
  }

  Map<String, Object?> _encodeUserPart(PromptPart part) {
    if (part is TextPromptPart) {
      return {
        'text': part.text,
      };
    }

    if (part is ImagePromptPart) {
      return _encodeBinaryPart(
        mediaType: part.mediaType == 'image/*' ? 'image/jpeg' : part.mediaType,
        data: part.data,
      );
    }

    if (part is FilePromptPart) {
      return _encodeBinaryPart(
        mediaType: part.mediaType,
        data: part.data,
      );
    }

    throw UnsupportedError(
      'Google user prompt part ${part.runtimeType} is not supported yet.',
    );
  }

  Map<String, Object?>? _encodeAssistantPart(
    PromptPart part, {
    required String modelId,
  }) {
    final metadata = _resolveAssistantPartMetadata(part.providerMetadata);

    if (part is TextPromptPart) {
      if (part.text.isEmpty) {
        return null;
      }

      return {
        'text': part.text,
        ..._encodeThoughtFields(metadata),
      };
    }

    if (part is ReasoningPromptPart) {
      if (part.text.isEmpty) {
        return null;
      }

      return {
        'text': part.text,
        ..._encodeThoughtFields(metadata, forceThought: true),
      };
    }

    if (part is ReasoningFilePromptPart) {
      return _encodeAssistantInlineDataPart(
        mediaType: part.mediaType,
        data: part.data,
        metadata: metadata,
        forceThought: true,
      );
    }

    if (part is FilePromptPart) {
      return _encodeAssistantInlineDataPart(
        mediaType: part.mediaType,
        data: part.data,
        metadata: metadata,
      );
    }

    if (part is ToolCallPromptPart) {
      return {
        'functionCall': {
          if (_shouldReplayGoogleFunctionCallId(
              modelId, metadata.functionCallId))
            'id': metadata.functionCallId,
          'name': part.toolName,
          'args': normalizeJsonValue(part.input) ?? const <String, Object?>{},
        },
        ..._encodeThoughtFields(metadata),
      };
    }

    if (part is ToolApprovalRequestPromptPart) {
      return null;
    }

    if (part is CustomPromptPart) {
      if (part.kind == GoogleToolCallReplay.kind) {
        final replay = GoogleToolCallReplay.parseData(
          part.data,
          providerMetadata: part.providerMetadata,
        );
        return {
          'toolCall': replay.toToolCallJson(),
          ..._encodeThoughtFields(metadata),
        };
      }

      if (part.kind == GoogleToolResponseReplay.kind) {
        final replay = GoogleToolResponseReplay.parseData(
          part.data,
          providerMetadata: part.providerMetadata,
        );
        return {
          'toolResponse': replay.toToolResponseJson(),
          ..._encodeThoughtFields(metadata),
        };
      }

      return null;
    }

    throw UnsupportedError(
      'Google assistant prompt part ${part.runtimeType} is not supported yet.',
    );
  }

  Map<String, Object?>? _encodeToolPart(
    PromptPart part, {
    required String toolName,
    required String modelId,
  }) {
    if (part is ToolApprovalResponsePromptPart) {
      return null;
    }

    if (part is ToolResultPromptPart) {
      final functionCallId = _googleFunctionCallId(
        part.providerMetadata,
        part.toolOutput.providerMetadata,
      );
      final replay = GoogleFunctionResponseReplay.fromToolOutput(
        toolCallId: part.toolCallId,
        toolName: part.toolName,
        toolOutput: part.toolOutput,
        functionCallId: functionCallId,
        providerMetadata: part.providerMetadata,
      );
      final functionResponse = replay.toFunctionResponseJson();
      if (_shouldReplayGoogleFunctionCallId(modelId, functionCallId) &&
          !functionResponse.containsKey('id')) {
        functionResponse['id'] = functionCallId;
      }

      return {
        'functionResponse': {
          ...functionResponse,
        },
      };
    }

    if (part is CustomPromptPart) {
      if (part.kind == GoogleFunctionResponseReplay.kind) {
        final replay = GoogleFunctionResponseReplay.parseData(
          part.data,
          providerMetadata: part.providerMetadata,
        );
        final functionResponse = replay.toFunctionResponseJson();
        final functionCallId = replay.functionCallId ??
            _googleFunctionCallId(part.providerMetadata);
        if (_shouldReplayGoogleFunctionCallId(modelId, functionCallId) &&
            !functionResponse.containsKey('id')) {
          functionResponse['id'] = functionCallId;
        }

        return {
          'functionResponse': functionResponse,
        };
      }
    }

    throw UnsupportedError(
      'Google tool prompt part ${part.runtimeType} is not supported yet.',
    );
  }

  Map<String, Object?> _encodeBinaryPart({
    required String mediaType,
    required FileData? data,
  }) {
    final bytes = data?.bytes;
    if (bytes != null) {
      return {
        'inlineData': {
          'mimeType': mediaType,
          'data': base64Encode(bytes),
        },
      };
    }

    final uri = data?.uri;
    if (uri != null) {
      return {
        'fileData': {
          'mimeType': mediaType,
          'fileUri': uri.toString(),
        },
      };
    }

    if (_googleFileUri(data?.providerReference) case final fileUri?) {
      return {
        'fileData': {
          'mimeType': mediaType,
          'fileUri': fileUri,
        },
      };
    }

    throw UnsupportedError(
      'Google binary prompt parts require in-memory bytes or a URI.',
    );
  }

  Map<String, Object?> _encodeAssistantInlineDataPart({
    required String mediaType,
    required FileData? data,
    required _GoogleAssistantPartMetadata metadata,
    bool forceThought = false,
  }) {
    final bytes = data?.bytes;
    if (bytes == null) {
      throw UnsupportedError(
        'Google assistant file prompt parts require in-memory bytes. Assistant-side file URIs are not supported.',
      );
    }

    return {
      'inlineData': {
        'mimeType': mediaType,
        'data': base64Encode(bytes),
      },
      ..._encodeThoughtFields(metadata, forceThought: forceThought),
    };
  }

  String? _googleFileUri(ProviderReference? reference) {
    if (reference == null) {
      return null;
    }

    return reference['google'] ??
        reference['vertex'] ??
        reference.requireProvider(
          'google',
          context: 'Google file prompt part',
        );
  }

  Map<String, Object?> _encodeThoughtFields(
    _GoogleAssistantPartMetadata metadata, {
    bool forceThought = false,
  }) {
    return {
      if (forceThought || metadata.thought) 'thought': true,
      if (metadata.thoughtSignature != null)
        'thoughtSignature': metadata.thoughtSignature,
    };
  }

  _GoogleAssistantPartMetadata _resolveAssistantPartMetadata(
    ProviderMetadata? metadata,
  ) {
    final primary = _providerNamespace(metadata, 'google');
    final fallback = _providerNamespace(metadata, 'vertex');
    final resolved = primary ?? fallback;

    return _GoogleAssistantPartMetadata(
      thought: resolved?['thought'] == true,
      thoughtSignature: asString(resolved?['thoughtSignature']),
      functionCallId: asString(resolved?['functionCallId']),
    );
  }

  String? _googleFunctionCallId(
    ProviderMetadata? primaryMetadata, [
    ProviderMetadata? fallbackMetadata,
  ]) {
    final primary = _providerNamespace(primaryMetadata, 'google') ??
        _providerNamespace(primaryMetadata, 'vertex');
    final fallback = _providerNamespace(fallbackMetadata, 'google') ??
        _providerNamespace(fallbackMetadata, 'vertex');
    return asString(primary?['functionCallId']) ??
        asString(fallback?['functionCallId']);
  }

  bool _shouldReplayGoogleFunctionCallId(
      String modelId, String? functionCallId) {
    return isGemini3Model(modelId) &&
        functionCallId != null &&
        functionCallId.isNotEmpty;
  }

  Map<String, Object?>? _providerNamespace(
    ProviderMetadata? metadata,
    String namespace,
  ) {
    final value = metadata?[namespace];
    if (value is Map<String, Object?>) {
      return value;
    }

    if (value is Map) {
      return Map<String, Object?>.from(value);
    }

    return null;
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

final class _GoogleAssistantPartMetadata {
  final bool thought;
  final String? thoughtSignature;
  final String? functionCallId;

  const _GoogleAssistantPartMetadata({
    this.thought = false,
    this.thoughtSignature,
    this.functionCallId,
  });
}
