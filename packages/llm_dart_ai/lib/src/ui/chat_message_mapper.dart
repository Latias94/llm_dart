import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'chat_ui_message.dart';

final class ChatMappedDataPart {
  final String? id;
  final String key;
  final Object? data;

  const ChatMappedDataPart({
    this.id,
    required this.key,
    required this.data,
  });
}

final class ChatMappedMessage {
  final ChatUiMessage message;
  final List<TextUiPart> textParts;
  final String text;
  final bool hasStreamingText;
  final List<ReasoningUiPart> reasoningParts;
  final String reasoningText;
  final bool hasStreamingReasoning;
  final List<ToolUiPart> toolParts;
  final List<SourceReference> sources;
  final List<FileUiPart> fileParts;
  final List<ReasoningFileUiPart> reasoningFileParts;
  final List<CustomUiPart> customParts;
  final List<ChatMappedDataPart> dataParts;
  final List<String> stepIds;
  final List<ModelWarning> warnings;
  final String? responseId;
  final DateTime? responseTimestamp;
  final String? modelId;
  final ProviderMetadata? responseProviderMetadata;
  final FinishReason? finishReason;
  final String? rawFinishReason;
  final bool isAborted;
  final String? abortReason;
  final UsageStats? usage;
  final ProviderMetadata? finishProviderMetadata;
  final List<ModelError> errors;
  final List<Object?> rawChunks;

  const ChatMappedMessage({
    required this.message,
    required this.textParts,
    required this.text,
    required this.hasStreamingText,
    required this.reasoningParts,
    required this.reasoningText,
    required this.hasStreamingReasoning,
    required this.toolParts,
    required this.sources,
    required this.fileParts,
    required this.reasoningFileParts,
    required this.customParts,
    required this.dataParts,
    required this.stepIds,
    required this.warnings,
    required this.responseId,
    required this.responseTimestamp,
    required this.modelId,
    required this.responseProviderMetadata,
    required this.finishReason,
    required this.rawFinishReason,
    required this.isAborted,
    required this.abortReason,
    required this.usage,
    required this.finishProviderMetadata,
    required this.errors,
    required this.rawChunks,
  });

  bool get hasWarnings => warnings.isNotEmpty;

  bool get hasErrors => errors.isNotEmpty;

  bool get hasToolParts => toolParts.isNotEmpty;

  bool get hasSources => sources.isNotEmpty;

  bool get hasFiles => fileParts.isNotEmpty || reasoningFileParts.isNotEmpty;
}

/// Convenience mapper from [ChatUiMessage] into common render summaries.
///
/// This stays provider-neutral and only projects stable, high-frequency fields
/// out of `parts` and reserved metadata keys.
final class ChatMessageMapper {
  final String textSeparator;
  final String reasoningSeparator;

  const ChatMessageMapper({
    this.textSeparator = '',
    this.reasoningSeparator = '',
  });

  ChatMappedMessage map(ChatUiMessage message) {
    final textParts = <TextUiPart>[];
    final reasoningParts = <ReasoningUiPart>[];
    final toolParts = <ToolUiPart>[];
    final sources = <SourceReference>[];
    final fileParts = <FileUiPart>[];
    final reasoningFileParts = <ReasoningFileUiPart>[];
    final customParts = <CustomUiPart>[];
    final dataParts = <ChatMappedDataPart>[];
    final stepIds = <String>[];

    for (final part in message.parts) {
      switch (part) {
        case TextUiPart():
          textParts.add(part);
        case ReasoningUiPart():
          reasoningParts.add(part);
        case ToolUiPart():
          toolParts.add(part);
        case SourceUiPart():
          sources.add(part.source);
        case FileUiPart():
          fileParts.add(part);
        case ReasoningFileUiPart():
          reasoningFileParts.add(part);
        case CustomUiPart():
          customParts.add(part);
        case StepBoundaryUiPart():
          stepIds.add(part.stepId);
        case DataUiPart(:final id, :final key, :final data):
          dataParts.add(
            ChatMappedDataPart(
              id: id,
              key: key,
              data: data,
            ),
          );
      }
    }

    final metadata = message.metadata;
    final isAborted = _asBool(metadata[ChatUiMetadataKeys.isAborted]) ??
        metadata[ChatUiMetadataKeys.finishReason] == FinishReason.aborted;

    return ChatMappedMessage(
      message: message,
      textParts: List.unmodifiable(textParts),
      text: textParts.map((part) => part.text).join(textSeparator),
      hasStreamingText: textParts.any((part) => part.isStreaming),
      reasoningParts: List.unmodifiable(reasoningParts),
      reasoningText:
          reasoningParts.map((part) => part.text).join(reasoningSeparator),
      hasStreamingReasoning: reasoningParts.any((part) => part.isStreaming),
      toolParts: List.unmodifiable(toolParts),
      sources: List.unmodifiable(sources),
      fileParts: List.unmodifiable(fileParts),
      reasoningFileParts: List.unmodifiable(reasoningFileParts),
      customParts: List.unmodifiable(customParts),
      dataParts: List.unmodifiable(dataParts),
      stepIds: List.unmodifiable(stepIds),
      warnings: _warnings(metadata[ChatUiMetadataKeys.warnings]),
      responseId: _asString(metadata[ChatUiMetadataKeys.responseId]),
      responseTimestamp:
          metadata[ChatUiMetadataKeys.responseTimestamp] as DateTime?,
      modelId: _asString(metadata[ChatUiMetadataKeys.modelId]),
      responseProviderMetadata:
          metadata[ChatUiMetadataKeys.responseProviderMetadata]
              as ProviderMetadata?,
      finishReason: metadata[ChatUiMetadataKeys.finishReason] as FinishReason?,
      rawFinishReason: _asString(metadata[ChatUiMetadataKeys.rawFinishReason]),
      isAborted: isAborted,
      abortReason: isAborted
          ? (_asString(metadata[ChatUiMetadataKeys.abortReason]) ??
              _asString(metadata[ChatUiMetadataKeys.rawFinishReason]))
          : null,
      usage: metadata[ChatUiMetadataKeys.usage] as UsageStats?,
      finishProviderMetadata:
          metadata[ChatUiMetadataKeys.finishProviderMetadata]
              as ProviderMetadata?,
      errors: _errors(metadata[ChatUiMetadataKeys.errors]),
      rawChunks: _objectList(metadata[ChatUiMetadataKeys.rawChunks]),
    );
  }

  List<ChatMappedMessage> mapMessages(Iterable<ChatUiMessage> messages) {
    return messages.map(map).toList(growable: false);
  }

  static String? _asString(Object? value) => value is String ? value : null;

  static bool? _asBool(Object? value) => value is bool ? value : null;

  static List<ModelWarning> _warnings(Object? value) {
    if (value is! List) {
      return const <ModelWarning>[];
    }

    return List<ModelWarning>.unmodifiable(value.whereType<ModelWarning>());
  }

  static List<ModelError> _errors(Object? value) {
    if (value is! List) {
      return const <ModelError>[];
    }

    return List<ModelError>.unmodifiable(
      value.map(ModelError.fromUnknown),
    );
  }

  static List<Object?> _objectList(Object? value) {
    if (value is! List) {
      return const <Object?>[];
    }

    return List<Object?>.unmodifiable(value.cast<Object?>());
  }
}
