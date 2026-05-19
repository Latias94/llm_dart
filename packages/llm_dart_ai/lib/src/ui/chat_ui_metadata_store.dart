import 'package:llm_dart_provider/llm_dart_provider.dart'
    hide
        ErrorEvent,
        FinishEvent,
        RawChunkEvent,
        ResponseMetadataEvent,
        StartEvent;

import '../stream/text_stream_event.dart';
import 'chat_ui_message.dart';

final class ChatUiMetadataStore {
  final Map<String, Object?> metadata;
  final bool includeRawChunks;

  const ChatUiMetadataStore({
    required this.metadata,
    required this.includeRawChunks,
  });

  void applyStart(StartEvent event) {
    metadata[ChatUiMetadataKeys.warnings] = List.unmodifiable(event.warnings);
  }

  void applyRunStart(RunStartEvent event) {
    _setIfNotNull(ChatUiMetadataKeys.runId, event.runId);
  }

  void applyRunFinish(RunFinishEvent event) {
    _setIfNotNull(ChatUiMetadataKeys.runId, event.runId);
    metadata[ChatUiMetadataKeys.runFinishReason] = event.finishReason;
    _setIfNotNull(
      ChatUiMetadataKeys.runRawFinishReason,
      event.rawFinishReason,
    );
    if (event.usage != null) {
      metadata[ChatUiMetadataKeys.runUsage] = event.usage;
    }
    if (event.finishReason == FinishReason.aborted) {
      metadata[ChatUiMetadataKeys.isAborted] = true;
      _setIfNotNull(
        ChatUiMetadataKeys.abortReason,
        event.rawFinishReason,
      );
    }
  }

  void applyResponseMetadata(ResponseMetadataEvent event) {
    _setIfNotNull(ChatUiMetadataKeys.responseId, event.responseId);
    _setIfNotNull(
      ChatUiMetadataKeys.responseTimestamp,
      event.timestamp,
    );
    _setIfNotNull(ChatUiMetadataKeys.modelId, event.modelId);
    if (event.providerMetadata != null) {
      metadata[ChatUiMetadataKeys.responseProviderMetadata] =
          ProviderMetadata.mergeNullable(
        metadata[ChatUiMetadataKeys.responseProviderMetadata]
            as ProviderMetadata?,
        event.providerMetadata,
      );
    }
  }

  void applyAbort(String? reason) {
    metadata[ChatUiMetadataKeys.isAborted] = true;
    if (reason != null) {
      metadata[ChatUiMetadataKeys.abortReason] = reason;
    }
  }

  void applyFinish(FinishEvent event) {
    metadata[ChatUiMetadataKeys.finishReason] = event.finishReason;
    _setIfNotNull(
      ChatUiMetadataKeys.rawFinishReason,
      event.rawFinishReason,
    );
    if (event.finishReason == FinishReason.aborted) {
      metadata[ChatUiMetadataKeys.isAborted] = true;
      _setIfNotNull(
        ChatUiMetadataKeys.abortReason,
        event.rawFinishReason,
      );
    }
    if (event.usage != null) {
      metadata[ChatUiMetadataKeys.usage] = event.usage;
    }
    if (event.providerMetadata != null) {
      metadata[ChatUiMetadataKeys.finishProviderMetadata] =
          ProviderMetadata.mergeNullable(
        metadata[ChatUiMetadataKeys.finishProviderMetadata]
            as ProviderMetadata?,
        event.providerMetadata,
      );
    }
  }

  void applyRawChunk(RawChunkEvent event) {
    if (!includeRawChunks) {
      return;
    }

    final current = metadata[ChatUiMetadataKeys.rawChunks] as List<Object?>? ??
        const <Object?>[];
    metadata[ChatUiMetadataKeys.rawChunks] =
        List<Object?>.unmodifiable([...current, event.raw]);
  }

  void applyError(ErrorEvent event) {
    final current = metadata[ChatUiMetadataKeys.errors] as List<ModelError>? ??
        const <ModelError>[];
    metadata[ChatUiMetadataKeys.errors] =
        List<ModelError>.unmodifiable([...current, event.error]);
  }

  void _setIfNotNull(String key, Object? value) {
    if (value != null) {
      metadata[key] = value;
    }
  }
}
