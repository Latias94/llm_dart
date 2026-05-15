import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_function_response_replay.dart';
import 'google_server_tool_replay.dart';
import 'google_shared.dart';

final class GooglePromptProjection {
  final List<Map<String, Object?>> systemInstructionParts;
  final List<Map<String, Object?>> contents;

  const GooglePromptProjection({
    required this.systemInstructionParts,
    required this.contents,
  });
}

final class GoogleContentProjectionCodec {
  const GoogleContentProjectionCodec();

  GooglePromptProjection encodePrompt({
    required String modelId,
    required List<PromptMessage> prompt,
  }) {
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

    return GooglePromptProjection(
      systemInstructionParts: systemInstructionParts,
      contents: contents,
    );
  }

  bool promptRequiresServerToolReplay(List<PromptMessage> prompt) {
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
    final providerMetadata = _promptPartProviderMetadata(part);
    final metadata = _resolveAssistantPartMetadata(providerMetadata);

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
          providerMetadata: providerMetadata,
        );
        return {
          'toolCall': replay.toToolCallJson(),
          ..._encodeThoughtFields(metadata),
        };
      }

      if (part.kind == GoogleToolResponseReplay.kind) {
        final replay = GoogleToolResponseReplay.parseData(
          part.data,
          providerMetadata: providerMetadata,
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
      final providerMetadata = _promptPartProviderMetadata(part);
      final functionCallId = _googleFunctionCallId(
        providerMetadata,
        part.toolOutput.providerMetadata,
      );
      final replay = GoogleFunctionResponseReplay.fromToolOutput(
        toolCallId: part.toolCallId,
        toolName: part.toolName,
        toolOutput: part.toolOutput,
        functionCallId: functionCallId,
        providerMetadata: providerMetadata,
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
        final providerMetadata = _promptPartProviderMetadata(part);
        final replay = GoogleFunctionResponseReplay.parseData(
          part.data,
          providerMetadata: providerMetadata,
        );
        final functionResponse = replay.toFunctionResponseJson();
        final functionCallId =
            replay.functionCallId ?? _googleFunctionCallId(providerMetadata);
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

  ProviderMetadata? _promptPartProviderMetadata(PromptPart part) {
    return mergeProviderReplayMetadata(
      providerOptions: part.providerOptions,
    );
  }

  _GoogleAssistantPartMetadata _resolveAssistantPartMetadata(
    ProviderMetadata? metadata,
  ) {
    final primary = metadata?.namespace('google');
    final fallback = metadata?.namespace('vertex');
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
    final primary = primaryMetadata?.namespace('google') ??
        primaryMetadata?.namespace('vertex');
    final fallback = fallbackMetadata?.namespace('google') ??
        fallbackMetadata?.namespace('vertex');
    return asString(primary?['functionCallId']) ??
        asString(fallback?['functionCallId']);
  }

  bool _shouldReplayGoogleFunctionCallId(
    String modelId,
    String? functionCallId,
  ) {
    return isGemini3Model(modelId) &&
        functionCallId != null &&
        functionCallId.isNotEmpty;
  }
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
