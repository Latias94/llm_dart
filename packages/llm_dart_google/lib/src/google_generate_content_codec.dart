import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'google_options.dart';
import 'google_shared.dart';

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
      contents.add(_encodeMessage(message));
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
    };

    return GoogleGenerateContentRequest(
      body: body,
      warnings: warnings,
    );
  }

  Map<String, Object?> _encodeMessage(PromptMessage message) {
    if (message case UserPromptMessage(:final parts)) {
      return {
        'role': 'user',
        'parts': [
          for (final part in parts) _encodeUserPart(part),
        ],
      };
    }

    if (message case AssistantPromptMessage(:final parts)) {
      return {
        'role': 'model',
        'parts': [
          for (final part in parts)
            if (_encodeAssistantPart(part) case final encodedPart?) encodedPart,
        ],
      };
    }

    if (message case ToolPromptMessage(:final toolName, :final parts)) {
      return {
        'role': 'user',
        'parts': [
          for (final part in parts)
            if (_encodeToolPart(part, toolName: toolName)
                case final encodedPart?)
              encodedPart,
        ],
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
    if (part is TextPromptPart) {
      return {
        'text': part.text,
      };
    }

    if (part is ToolCallPromptPart) {
      return {
        'functionCall': {
          'name': part.toolName,
          'args': normalizeJsonValue(part.input) ?? const <String, Object?>{},
        },
      };
    }

    if (part is ToolApprovalRequestPromptPart) {
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
