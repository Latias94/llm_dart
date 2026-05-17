import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

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

  Map<String, Object?> encodeAssistantInlineDataPart({
    required String mediaType,
    required FileData? data,
    required GooglePromptPartMetadata metadata,
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
