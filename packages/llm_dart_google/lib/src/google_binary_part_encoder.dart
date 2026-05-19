import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_prompt_limitations.dart';
import 'google_prompt_replay_metadata.dart';

final class GoogleBinaryPartEncoder {
  const GoogleBinaryPartEncoder();

  Map<String, Object?> encodeUserBinaryPart({
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

    final text = data?.text;
    if (text != null) {
      return {
        'inlineData': {
          'mimeType': mediaType,
          'data': base64Encode(utf8.encode(text)),
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

    throw missingGoogleUserBinaryData();
  }

  Map<String, Object?> encodeAssistantInlineDataPart({
    required String mediaType,
    required FileData? data,
    required GooglePromptPartMetadata metadata,
    bool forceThought = false,
  }) {
    final bytes = data?.bytes;
    if (bytes == null) {
      throw unsupportedGoogleAssistantFileData();
    }

    return {
      'inlineData': {
        'mimeType': mediaType,
        'data': base64Encode(bytes),
      },
      ...metadata.encodeThoughtFields(forceThought: forceThought),
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
}
