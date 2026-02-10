import 'package:llm_dart_core/llm_dart_core.dart';

/// Helper to emit typed source parts with deduplication.
///
/// This mirrors the AI SDK approach of tracking emitted sources across chunks to
/// avoid duplicates during streaming.
class SourcePartEmitter {
  final String providerMetadataNamespace;
  final Map<String, dynamic>? defaultProviderMetadataPayload;
  final String sourceIdPrefix;

  final Set<String> _emittedKeys = <String>{};
  var _seq = 0;

  SourcePartEmitter({
    required this.providerMetadataNamespace,
    this.defaultProviderMetadataPayload,
    this.sourceIdPrefix = 'source_',
  });

  void reset() {
    _emittedKeys.clear();
    _seq = 0;
  }

  Map<String, dynamic>? _providerMetadataForPayload(
    Map<String, dynamic>? payload,
  ) {
    final effective = payload ?? defaultProviderMetadataPayload;
    if (effective == null) return null;
    if (effective.isEmpty) return null;
    return {providerMetadataNamespace: effective};
  }

  /// Emits a URL source part if it has not been emitted yet.
  ///
  /// Returns `null` when the source was already emitted.
  LLMSourceUrlPart? url(
    String url, {
    String? title,
    String? dedupeKey,
    Map<String, dynamic>? providerMetadataPayload,
  }) {
    final key = dedupeKey ?? 'url:$url';
    if (!_emittedKeys.add(key)) return null;
    return LLMSourceUrlPart(
      sourceId: '$sourceIdPrefix${_seq++}',
      url: url,
      title: title,
      providerMetadata: _providerMetadataForPayload(providerMetadataPayload),
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
    Map<String, dynamic>? providerMetadataPayload,
  }) {
    final key = dedupeKey ?? 'doc:$title:$mediaType:${filename ?? ''}';
    if (!_emittedKeys.add(key)) return null;
    return LLMSourceDocumentPart(
      sourceId: '$sourceIdPrefix${_seq++}',
      mediaType: mediaType,
      title: title,
      filename: filename,
      providerMetadata: _providerMetadataForPayload(providerMetadataPayload),
    );
  }
}
