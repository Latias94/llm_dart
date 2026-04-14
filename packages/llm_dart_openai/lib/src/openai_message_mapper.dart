import 'package:llm_dart_core/llm_dart_core.dart';

import 'openai_custom_part.dart';
import 'openai_custom_part_summary.dart';

enum OpenAIUiPartType {
  text,
  reasoning,
  tool,
  source,
  file,
  reasoningFile,
  custom,
}

final class OpenAIUiPartDetails {
  final int index;
  final ChatUiPart part;
  final OpenAIUiPartType type;
  final String label;
  final ProviderMetadata? providerMetadata;
  final String? responseId;
  final String? itemId;
  final String? itemType;
  final int? outputIndex;
  final int? contentIndex;
  final int? summaryIndex;
  final int? toolIndex;
  final String? serviceTier;
  final String? systemFingerprint;
  final String? approvalRequestId;
  final String? serverLabel;
  final String? fileId;
  final String? annotationType;
  final String? toolCallId;
  final String? sourceId;
  final List<Object?> logprobs;

  const OpenAIUiPartDetails({
    required this.index,
    required this.part,
    required this.type,
    required this.label,
    required this.providerMetadata,
    required this.responseId,
    required this.itemId,
    required this.itemType,
    required this.outputIndex,
    required this.contentIndex,
    required this.summaryIndex,
    required this.toolIndex,
    required this.serviceTier,
    required this.systemFingerprint,
    required this.approvalRequestId,
    required this.serverLabel,
    required this.fileId,
    required this.annotationType,
    required this.toolCallId,
    required this.sourceId,
    required this.logprobs,
  });

  bool get hasOpenAIMetadata => providerMetadata != null;

  bool get hasLogprobs => logprobs.isNotEmpty;
}

final class OpenAIMappedMessage {
  final ChatUiMessage message;
  final List<OpenAIUiPartDetails> partDetails;
  final List<OpenAICustomPart> customParts;
  final List<OpenAICustomPartSummary> customPartSummaries;
  final Map<String, Object?>? responseMetadata;
  final Map<String, Object?>? finishMetadata;

  const OpenAIMappedMessage({
    required this.message,
    required this.partDetails,
    required this.customParts,
    required this.customPartSummaries,
    required this.responseMetadata,
    required this.finishMetadata,
  });

  bool get hasOpenAIMetadata =>
      responseMetadata != null ||
      finishMetadata != null ||
      partDetails.any((detail) => detail.hasOpenAIMetadata) ||
      customParts.isNotEmpty;

  bool get hasLogprobs => partDetails.any((detail) => detail.hasLogprobs);
}

final class OpenAIComposedMappedMessage {
  final ChatMappedMessage shared;
  final OpenAIMappedMessage provider;

  const OpenAIComposedMappedMessage({
    required this.shared,
    required this.provider,
  });
}

final class OpenAIMessageMapper {
  final ChatMessageMapper sharedMapper;

  const OpenAIMessageMapper({
    this.sharedMapper = const ChatMessageMapper(),
  });

  OpenAIMappedMessage map(ChatUiMessage message) {
    final partDetails = <OpenAIUiPartDetails>[];
    final customParts = <OpenAICustomPart>[];
    final customPartSummaries = <OpenAICustomPartSummary>[];

    for (var index = 0; index < message.parts.length; index += 1) {
      final part = message.parts[index];
      final detail = _detailForPart(index, part);
      if (detail != null) {
        partDetails.add(detail);
      }

      final customPart = OpenAICustomPart.tryParseUiPart(part);
      if (customPart == null) {
        continue;
      }

      customParts.add(customPart);
      customPartSummaries.add(OpenAICustomPartSummary.fromPart(customPart));
    }

    return OpenAIMappedMessage(
      message: message,
      partDetails: List<OpenAIUiPartDetails>.unmodifiable(partDetails),
      customParts: List<OpenAICustomPart>.unmodifiable(customParts),
      customPartSummaries:
          List<OpenAICustomPartSummary>.unmodifiable(customPartSummaries),
      responseMetadata: _openaiMessageMetadata(
        message.metadata[ChatUiMetadataKeys.responseProviderMetadata],
      ),
      finishMetadata: _openaiMessageMetadata(
        message.metadata[ChatUiMetadataKeys.finishProviderMetadata],
      ),
    );
  }

  List<OpenAIMappedMessage> mapMessages(Iterable<ChatUiMessage> messages) {
    return messages.map(map).toList(growable: false);
  }

  OpenAIComposedMappedMessage mapComposed(ChatUiMessage message) {
    return OpenAIComposedMappedMessage(
      shared: sharedMapper.map(message),
      provider: map(message),
    );
  }

  List<OpenAIComposedMappedMessage> mapMessagesComposed(
    Iterable<ChatUiMessage> messages,
  ) {
    return messages.map(mapComposed).toList(growable: false);
  }
}

OpenAIUiPartDetails? _detailForPart(int index, ChatUiPart part) {
  return switch (part) {
    TextUiPart(:final text, :final providerMetadata) => _buildPartDetails(
        index: index,
        part: part,
        type: OpenAIUiPartType.text,
        label: _labelOrFallback(text, fallback: 'Text'),
        providerMetadata: providerMetadata,
      ),
    ReasoningUiPart(:final text, :final providerMetadata) => _buildPartDetails(
        index: index,
        part: part,
        type: OpenAIUiPartType.reasoning,
        label: _labelOrFallback(text, fallback: 'Reasoning'),
        providerMetadata: providerMetadata,
      ),
    ToolUiPart(
      :final toolName,
      :final providerMetadata,
      :final toolCallId,
    ) =>
      _buildPartDetails(
        index: index,
        part: part,
        type: OpenAIUiPartType.tool,
        label: toolName,
        providerMetadata: providerMetadata,
        fallbackToolCallId: toolCallId,
      ),
    SourceUiPart(:final source) => _buildPartDetails(
        index: index,
        part: part,
        type: OpenAIUiPartType.source,
        label: source.title ?? source.filename ?? source.sourceId,
        providerMetadata: source.providerMetadata,
        fallbackSourceId: source.sourceId,
      ),
    FileUiPart(:final file, :final providerMetadata) => _buildPartDetails(
        index: index,
        part: part,
        type: OpenAIUiPartType.file,
        label: file.filename ?? file.mediaType,
        providerMetadata: providerMetadata,
      ),
    ReasoningFileUiPart(:final file, :final providerMetadata) =>
      _buildPartDetails(
        index: index,
        part: part,
        type: OpenAIUiPartType.reasoningFile,
        label: file.filename ?? file.mediaType,
        providerMetadata: providerMetadata,
      ),
    CustomUiPart(
      :final kind,
      :final providerMetadata,
    ) =>
      _buildPartDetails(
        index: index,
        part: part,
        type: OpenAIUiPartType.custom,
        label: kind,
        providerMetadata: providerMetadata,
      ),
    StepBoundaryUiPart() || DataUiPart() => null,
  };
}

OpenAIUiPartDetails? _buildPartDetails({
  required int index,
  required ChatUiPart part,
  required OpenAIUiPartType type,
  required String label,
  required ProviderMetadata? providerMetadata,
  String? fallbackToolCallId,
  String? fallbackSourceId,
}) {
  final openai = providerMetadata?.namespace('openai');
  if (openai == null) {
    return null;
  }

  return OpenAIUiPartDetails(
    index: index,
    part: part,
    type: type,
    label: label,
    providerMetadata: providerMetadata,
    responseId: _asString(openai['responseId']),
    itemId: _asString(openai['itemId']),
    itemType: _asString(openai['itemType']),
    outputIndex: _asInt(openai['outputIndex']),
    contentIndex: _asInt(openai['contentIndex']),
    summaryIndex: _asInt(openai['summaryIndex']),
    toolIndex: _asInt(openai['toolIndex']),
    serviceTier: _asString(openai['serviceTier']),
    systemFingerprint: _asString(openai['systemFingerprint']),
    approvalRequestId: _asString(openai['approvalRequestId']),
    serverLabel: _asString(openai['serverLabel']),
    fileId: _asString(openai['fileId']),
    annotationType: _asString(openai['annotationType']),
    toolCallId: _asString(openai['toolCallId']) ?? fallbackToolCallId,
    sourceId: _asString(openai['sourceId']) ?? fallbackSourceId,
    logprobs: _objectList(openai['logprobs']),
  );
}

Map<String, Object?>? _openaiMessageMetadata(Object? metadata) {
  return switch (metadata) {
    ProviderMetadata() => metadata.namespace('openai'),
    _ => null,
  };
}

String? _asString(Object? value) => value is String ? value : null;

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return null;
}

List<Object?> _objectList(Object? value) {
  if (value is List<Object?>) {
    return List<Object?>.unmodifiable(value);
  }

  if (value is List) {
    return List<Object?>.unmodifiable(value.cast<Object?>());
  }

  return const <Object?>[];
}

String _labelOrFallback(
  String value, {
  required String fallback,
}) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return fallback;
  }

  if (normalized.length <= 80) {
    return normalized;
  }

  return '${normalized.substring(0, 79)}…';
}
