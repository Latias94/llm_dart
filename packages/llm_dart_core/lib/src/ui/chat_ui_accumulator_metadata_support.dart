part of 'chat_ui_accumulator.dart';

extension _ChatUiAccumulatorMetadataSupport on ChatUiAccumulator {
  void _applyStartEvent(StartEvent event) {
    _metadata[ChatUiMetadataKeys.warnings] = List.unmodifiable(event.warnings);
  }

  void _applyResponseMetadataEvent(ResponseMetadataEvent event) {
    _setMetadataIfNotNull(ChatUiMetadataKeys.responseId, event.responseId);
    _setMetadataIfNotNull(
      ChatUiMetadataKeys.responseTimestamp,
      event.timestamp,
    );
    _setMetadataIfNotNull(ChatUiMetadataKeys.modelId, event.modelId);
    if (event.providerMetadata != null) {
      _metadata[ChatUiMetadataKeys.responseProviderMetadata] =
          ProviderMetadata.mergeNullable(
        _metadata[ChatUiMetadataKeys.responseProviderMetadata]
            as ProviderMetadata?,
        event.providerMetadata,
      );
    }
  }

  void _applyAbortEvent(String? reason) {
    _metadata[ChatUiMetadataKeys.isAborted] = true;
    if (reason != null) {
      _metadata[ChatUiMetadataKeys.abortReason] = reason;
    }
  }

  void _applyFinishEvent(FinishEvent event) {
    _metadata[ChatUiMetadataKeys.finishReason] = event.finishReason;
    _setMetadataIfNotNull(
      ChatUiMetadataKeys.rawFinishReason,
      event.rawFinishReason,
    );
    if (event.finishReason == FinishReason.aborted) {
      _metadata[ChatUiMetadataKeys.isAborted] = true;
      _setMetadataIfNotNull(
        ChatUiMetadataKeys.abortReason,
        event.rawFinishReason,
      );
    }
    if (event.usage != null) {
      _metadata[ChatUiMetadataKeys.usage] = event.usage;
    }
    if (event.providerMetadata != null) {
      _metadata[ChatUiMetadataKeys.finishProviderMetadata] =
          ProviderMetadata.mergeNullable(
        _metadata[ChatUiMetadataKeys.finishProviderMetadata]
            as ProviderMetadata?,
        event.providerMetadata,
      );
    }
  }

  void _applyRawChunkEvent(RawChunkEvent event) {
    if (options.includeRawChunksInMetadata) {
      final current =
          _metadata[ChatUiMetadataKeys.rawChunks] as List<Object?>? ??
              const <Object?>[];
      _metadata[ChatUiMetadataKeys.rawChunks] =
          List<Object?>.unmodifiable([...current, event.raw]);
    }
  }

  void _applyErrorEvent(ErrorEvent event) {
    final current = _metadata[ChatUiMetadataKeys.errors] as List<ModelError>? ??
        const <ModelError>[];
    _metadata[ChatUiMetadataKeys.errors] =
        List<ModelError>.unmodifiable([...current, event.error]);
  }
}
