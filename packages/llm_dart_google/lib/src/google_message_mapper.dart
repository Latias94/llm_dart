import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_custom_part.dart';
import 'google_custom_part_summary.dart';
import 'google_shared.dart';

enum GoogleUiPartType {
  text,
  reasoning,
  source,
  file,
  reasoningFile,
  tool,
  custom,
}

final class GoogleUiPartDetails {
  final int index;
  final ChatUiPart part;
  final GoogleUiPartType type;
  final String label;
  final ProviderMetadata? providerMetadata;
  final String? thoughtSignature;
  final bool? thought;
  final String? functionCallId;
  final String? responsePart;
  final String? serverToolPart;
  final String? fileId;
  final String? sourceId;
  final String? chunkType;
  final String? toolCallId;
  final String? toolType;

  const GoogleUiPartDetails({
    required this.index,
    required this.part,
    required this.type,
    required this.label,
    required this.providerMetadata,
    required this.thoughtSignature,
    required this.thought,
    required this.functionCallId,
    required this.responsePart,
    required this.serverToolPart,
    required this.fileId,
    required this.sourceId,
    required this.chunkType,
    required this.toolCallId,
    required this.toolType,
  });

  bool get hasGoogleMetadata => providerMetadata != null;

  bool get hasThoughtSignature =>
      thoughtSignature != null && thoughtSignature!.isNotEmpty;
}

final class GoogleMappedMessage {
  final ChatUiMessage message;
  final List<GoogleUiPartDetails> partDetails;
  final List<GoogleCustomPart> customParts;
  final List<GoogleCustomPartSummary> customPartSummaries;
  final Map<String, Object?>? responseMetadata;
  final Map<String, Object?>? finishMetadata;

  const GoogleMappedMessage({
    required this.message,
    required this.partDetails,
    required this.customParts,
    required this.customPartSummaries,
    required this.responseMetadata,
    required this.finishMetadata,
  });

  bool get hasGoogleMetadata =>
      responseMetadata != null ||
      finishMetadata != null ||
      partDetails.any((detail) => detail.hasGoogleMetadata);

  bool get hasThoughtSignatures =>
      partDetails.any((detail) => detail.hasThoughtSignature);
}

final class GoogleComposedMappedMessage {
  final ChatMappedMessage shared;
  final GoogleMappedMessage provider;

  const GoogleComposedMappedMessage({
    required this.shared,
    required this.provider,
  });
}

/// Provider-owned companion mapper for Google-specific UI metadata.
///
/// This is intentionally separate from `llm_dart_flutter`'s shared
/// `ChatMessageMapper`. The shared mapper keeps only stable cross-provider
/// fields, while this mapper extracts Google-owned replay payloads and
/// Google-specific provider metadata for richer Flutter render paths.
final class GoogleMessageMapper {
  final ChatMessageMapper sharedMapper;

  const GoogleMessageMapper({
    this.sharedMapper = const ChatMessageMapper(),
  });

  GoogleMappedMessage map(ChatUiMessage message) {
    final partDetails = <GoogleUiPartDetails>[];
    final customParts = <GoogleCustomPart>[];
    final customPartSummaries = <GoogleCustomPartSummary>[];

    for (var index = 0; index < message.parts.length; index += 1) {
      final part = message.parts[index];
      final detail = _detailForPart(index, part);
      if (detail != null) {
        partDetails.add(detail);
      }

      final customPart = GoogleCustomPart.tryParseUiPart(part);
      if (customPart != null) {
        customParts.add(customPart);
        customPartSummaries.add(GoogleCustomPartSummary.fromPart(customPart));
      }
    }

    return GoogleMappedMessage(
      message: message,
      partDetails: List<GoogleUiPartDetails>.unmodifiable(partDetails),
      customParts: List<GoogleCustomPart>.unmodifiable(customParts),
      customPartSummaries:
          List<GoogleCustomPartSummary>.unmodifiable(customPartSummaries),
      responseMetadata: _googleMessageMetadata(
        message.metadata[ChatUiMetadataKeys.responseProviderMetadata],
      ),
      finishMetadata: _googleMessageMetadata(
        message.metadata[ChatUiMetadataKeys.finishProviderMetadata],
      ),
    );
  }

  List<GoogleMappedMessage> mapMessages(Iterable<ChatUiMessage> messages) {
    return messages.map(map).toList(growable: false);
  }

  GoogleComposedMappedMessage mapComposed(ChatUiMessage message) {
    return GoogleComposedMappedMessage(
      shared: sharedMapper.map(message),
      provider: map(message),
    );
  }

  List<GoogleComposedMappedMessage> mapMessagesComposed(
    Iterable<ChatUiMessage> messages,
  ) {
    return messages.map(mapComposed).toList(growable: false);
  }
}

GoogleUiPartDetails? _detailForPart(int index, ChatUiPart part) {
  return switch (part) {
    TextUiPart(:final text, :final providerMetadata) => _buildPartDetails(
        index: index,
        part: part,
        type: GoogleUiPartType.text,
        label: _labelOrFallback(text, fallback: 'Text'),
        providerMetadata: providerMetadata,
      ),
    ReasoningUiPart(:final text, :final providerMetadata) => _buildPartDetails(
        index: index,
        part: part,
        type: GoogleUiPartType.reasoning,
        label: _labelOrFallback(text, fallback: 'Reasoning'),
        providerMetadata: providerMetadata,
      ),
    SourceUiPart(:final source) => _buildPartDetails(
        index: index,
        part: part,
        type: GoogleUiPartType.source,
        label: source.title ?? source.filename ?? source.sourceId,
        providerMetadata: source.providerMetadata,
        fallbackSourceId: source.sourceId,
      ),
    FileUiPart(:final file, :final providerMetadata) => _buildPartDetails(
        index: index,
        part: part,
        type: GoogleUiPartType.file,
        label: file.filename ?? file.mediaType,
        providerMetadata: providerMetadata,
      ),
    ReasoningFileUiPart(:final file, :final providerMetadata) =>
      _buildPartDetails(
        index: index,
        part: part,
        type: GoogleUiPartType.reasoningFile,
        label: file.filename ?? file.mediaType,
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
        type: GoogleUiPartType.tool,
        label: toolName,
        providerMetadata: providerMetadata,
        fallbackToolCallId: toolCallId,
      ),
    CustomUiPart(
      :final kind,
      :final providerMetadata,
    ) =>
      _buildPartDetails(
        index: index,
        part: part,
        type: GoogleUiPartType.custom,
        label: kind,
        providerMetadata: providerMetadata,
      ),
    StepBoundaryUiPart() || DataUiPart() => null,
  };
}

GoogleUiPartDetails? _buildPartDetails({
  required int index,
  required ChatUiPart part,
  required GoogleUiPartType type,
  required String label,
  required ProviderMetadata? providerMetadata,
  String? fallbackToolCallId,
  String? fallbackSourceId,
}) {
  final google = providerMetadata?.namespace('google');
  if (google == null) {
    return null;
  }

  return GoogleUiPartDetails(
    index: index,
    part: part,
    type: type,
    label: label,
    providerMetadata: providerMetadata,
    thoughtSignature: asString(google['thoughtSignature']),
    thought: google['thought'] as bool?,
    functionCallId: asString(google['functionCallId']),
    responsePart: asString(google['responsePart']),
    serverToolPart: asString(google['serverToolPart']),
    fileId: asString(google['fileId']),
    sourceId: asString(google['sourceId']) ?? fallbackSourceId,
    chunkType: asString(google['chunkType']),
    toolCallId: asString(google['toolCallId']) ?? fallbackToolCallId,
    toolType: asString(google['toolType']),
  );
}

Map<String, Object?>? _googleMessageMetadata(Object? metadata) {
  return switch (metadata) {
    ProviderMetadata() => metadata.namespace('google'),
    _ => null,
  };
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
