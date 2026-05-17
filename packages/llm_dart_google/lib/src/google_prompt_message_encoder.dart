import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_function_response_replay.dart';
import 'google_language_model_policy.dart';
import 'google_server_tool_replay.dart';
import 'google_shared.dart';

final class GooglePromptMessageEncoder {
  const GooglePromptMessageEncoder();

  Map<String, Object?>? encodeMessage(
    PromptMessage message, {
    required String modelId,
  }) {
    final policy = GoogleLanguageModelPolicy(modelId);
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
            policy: policy,
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
            policy: policy,
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
    required GoogleLanguageModelPolicy policy,
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
            policy,
            metadata.functionCallId,
          ))
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
    required GoogleLanguageModelPolicy policy,
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
      if (_shouldReplayGoogleFunctionCallId(policy, functionCallId) &&
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
        if (_shouldReplayGoogleFunctionCallId(policy, functionCallId) &&
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
    GoogleLanguageModelPolicy policy,
    String? functionCallId,
  ) {
    return policy.supportsFunctionCallIdReplay &&
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
