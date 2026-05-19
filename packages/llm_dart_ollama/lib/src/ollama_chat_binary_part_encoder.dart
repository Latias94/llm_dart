import 'dart:convert';

import 'ollama_binary_resolver.dart';
import 'ollama_chat_limitations.dart';

final class OllamaChatBinaryPartEncoder {
  final OllamaBinaryResolver? binaryResolver;

  const OllamaChatBinaryPartEncoder({
    this.binaryResolver,
  });

  Future<String> encodeBase64({
    required String mediaType,
    required Uri? uri,
    required List<int>? bytes,
    required String promptPartKind,
    String? filename,
  }) async {
    return base64Encode(
      await resolveBytes(
        mediaType: mediaType,
        uri: uri,
        bytes: bytes,
        promptPartKind: promptPartKind,
        filename: filename,
      ),
    );
  }

  Future<List<int>> resolveBytes({
    required String mediaType,
    required Uri? uri,
    required List<int>? bytes,
    required String promptPartKind,
    String? filename,
  }) async {
    if (bytes != null && bytes.isNotEmpty) {
      return bytes;
    }

    if (uri == null) {
      throw missingOllamaPromptPartBytes(
        promptPartKind: promptPartKind,
      );
    }

    final uriData = uri.data;
    if (uriData != null) {
      final resolved = uriData.contentAsBytes();
      if (resolved.isNotEmpty) {
        return resolved;
      }
    }

    final resolver = binaryResolver;
    if (resolver != null) {
      final resolved = await resolver(
        uri,
        mediaType: mediaType,
        filename: filename,
      );
      if (resolved != null && resolved.isNotEmpty) {
        return resolved;
      }
    }

    throw unresolvedOllamaPromptPartUri(
      promptPartKind: promptPartKind,
      uri: uri,
    );
  }
}
