import 'package:llm_dart_core/llm_dart_core.dart';

/// Helper to emit typed source parts with deduplication.
///
/// This mirrors the AI SDK approach of tracking emitted sources across chunks to
/// avoid duplicates during streaming.
class SourcePartEmitter {
  final String providerMetadataNamespace;
  final Map<String, dynamic>? providerMetadataPayload;
  final String sourceIdPrefix;

  final Set<String> _emittedKeys = <String>{};
  var _seq = 0;

  SourcePartEmitter({
    required this.providerMetadataNamespace,
    this.providerMetadataPayload,
    this.sourceIdPrefix = 'source_',
  });

  Map<String, dynamic>? _providerMetadata() {
    final payload = providerMetadataPayload;
    if (payload == null) return null;
    return {providerMetadataNamespace: payload};
  }

  /// Emits a URL source part if it has not been emitted yet.
  ///
  /// Returns `null` when the source was already emitted.
  LLMSourceUrlPart? url(
    String url, {
    String? title,
    String? dedupeKey,
  }) {
    final key = dedupeKey ?? 'url:$url';
    if (!_emittedKeys.add(key)) return null;
    return LLMSourceUrlPart(
      sourceId: '$sourceIdPrefix${_seq++}',
      url: url,
      title: title,
      providerMetadata: _providerMetadata(),
    );
  }

  /// Emits a document source part if it has not been emitted yet.
  ///
  /// Returns `null` when the source was already emitted.
  LLMSourceDocumentPart? document(
    String title, {
    required String mediaType,
    String? filename,
    String? dedupeKey,
  }) {
    final key = dedupeKey ?? 'doc:$title:$mediaType:${filename ?? ''}';
    if (!_emittedKeys.add(key)) return null;
    return LLMSourceDocumentPart(
      sourceId: '$sourceIdPrefix${_seq++}',
      mediaType: mediaType,
      title: title,
      filename: filename,
      providerMetadata: _providerMetadata(),
    );
  }
}

