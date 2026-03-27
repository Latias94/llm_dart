import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'google_options.dart';
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
      final encodedMessage = _encodeMessage(message);
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

    final safetySettings =
        providerOptions.safetySettings ?? settings.safetySettings;
    final nativeTools = providerOptions.tools ?? settings.tools;
    final encodedNativeTools = _encodeNativeTools(
      modelId: modelId,
      tools: nativeTools,
      warnings: warnings,
    );
    final useNativeTools = encodedNativeTools.isNotEmpty;

    if (useNativeTools && tools.isNotEmpty) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'tools',
          message:
              'Google native tools do not mix cleanly with common function tools yet. The common function tools have been ignored for this call.',
        ),
      );
    }

    if (useNativeTools && toolChoice != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'toolChoice',
          message:
              'toolChoice is ignored when Google native tools are enabled for this call.',
        ),
      );
    }

    final encodedFunctionTools =
        useNativeTools ? null : _encodeFunctionTools(tools);
    final encodedToolConfig = useNativeTools
        ? null
        : _encodeToolConfig(
            tools: tools,
            toolChoice: toolChoice,
          );
    final encodedTools =
        encodedNativeTools.isNotEmpty ? encodedNativeTools : encodedFunctionTools;

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
  }) {
    if (tools.isEmpty) {
      return null;
    }

    final hasStrictTools = tools.any((tool) => tool.strict == true);
    String? mode;
    List<String>? allowedFunctionNames;

    switch (toolChoice) {
      case null:
        if (!hasStrictTools) {
          return null;
        }
        mode = 'VALIDATED';
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

    return {
      'functionCallingConfig': {
        'mode': mode,
        if (allowedFunctionNames != null)
          'allowedFunctionNames': allowedFunctionNames,
      },
    };
  }

  bool _supportsNativeTools(String modelId) {
    final normalized = modelId.toLowerCase();
    return normalized.contains('gemini-2') ||
        normalized.contains('gemini-3') ||
        normalized.endsWith('-latest') ||
        normalized.contains('nano-banana');
  }

  Map<String, Object?>? _encodeMessage(PromptMessage message) {
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
          if (_encodeAssistantPart(part) case final encodedPart?) encodedPart,
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
          if (_encodeToolPart(part, toolName: toolName)
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
        uri: part.uri,
        bytes: part.bytes,
      );
    }

    if (part is FilePromptPart) {
      return _encodeBinaryPart(
        mediaType: part.mediaType,
        uri: part.uri,
        bytes: part.bytes,
      );
    }

    throw UnsupportedError(
      'Google user prompt part ${part.runtimeType} is not supported yet.',
    );
  }

  Map<String, Object?>? _encodeAssistantPart(PromptPart part) {
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
        uri: part.uri,
        bytes: part.bytes,
        metadata: metadata,
        forceThought: true,
      );
    }

    if (part is FilePromptPart) {
      return _encodeAssistantInlineDataPart(
        mediaType: part.mediaType,
        uri: part.uri,
        bytes: part.bytes,
        metadata: metadata,
      );
    }

    if (part is ToolCallPromptPart) {
      return {
        'functionCall': {
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
      return null;
    }

    throw UnsupportedError(
      'Google assistant prompt part ${part.runtimeType} is not supported yet.',
    );
  }

  Map<String, Object?>? _encodeToolPart(
    PromptPart part, {
    required String toolName,
  }) {
    if (part is ToolApprovalResponsePromptPart) {
      return null;
    }

    if (part is ToolResultPromptPart) {
      return {
        'functionResponse': {
          'name': part.toolName,
          'response': {
            'name': part.toolName,
            'content': normalizeJsonValue(part.output) ?? 'null',
          },
        },
      };
    }

    throw UnsupportedError(
      'Google tool prompt part ${part.runtimeType} is not supported yet.',
    );
  }

  Map<String, Object?> _encodeBinaryPart({
    required String mediaType,
    required Uri? uri,
    required List<int>? bytes,
  }) {
    if (bytes != null) {
      return {
        'inlineData': {
          'mimeType': mediaType,
          'data': base64Encode(bytes),
        },
      };
    }

    if (uri != null) {
      return {
        'fileData': {
          'mimeType': mediaType,
          'fileUri': uri.toString(),
        },
      };
    }

    throw UnsupportedError(
      'Google binary prompt parts require in-memory bytes or a URI.',
    );
  }

  Map<String, Object?> _encodeAssistantInlineDataPart({
    required String mediaType,
    required Uri? uri,
    required List<int>? bytes,
    required _GoogleAssistantPartMetadata metadata,
    bool forceThought = false,
  }) {
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
    );
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
    required GoogleGenerateTextOptions providerOptions,
    required List<ModelWarning> warnings,
  }) {
    final config = <String, Object?>{};

    if (providerOptions.includeThoughts != null) {
      config['includeThoughts'] = providerOptions.includeThoughts;
    }

    if (isGemini3Model(modelId)) {
      if (providerOptions.thinkingLevel != null) {
        config['thinkingLevel'] = providerOptions.thinkingLevel!.value;
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
    } else {
      if (providerOptions.thinkingBudgetTokens != null) {
        config['thinkingBudget'] = providerOptions.thinkingBudgetTokens;
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
    }

    return config.isEmpty ? null : config;
  }
}

final class _GoogleAssistantPartMetadata {
  final bool thought;
  final String? thoughtSignature;

  const _GoogleAssistantPartMetadata({
    this.thought = false,
    this.thoughtSignature,
  });
}
