import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_metadata.dart';
import 'openai_responses_stream_state.dart';

Map<String, Object?>? openAIResponsesAsMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  return null;
}

List<Object?> openAIResponsesAsList(Object? value) {
  if (value is List<Object?>) {
    return value;
  }

  if (value is List) {
    return List<Object?>.from(value);
  }

  return const [];
}

List<Object?>? openAIResponsesJsonListOrNull(Object? value) {
  if (value is List<Object?>) {
    return value;
  }

  if (value is List) {
    return List<Object?>.from(value);
  }

  return null;
}

String? openAIResponsesAsString(Object? value) =>
    value is String ? value : null;

int? openAIResponsesAsInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return null;
}

DateTime? openAIResponsesDecodeTimestamp(Object? value) {
  final createdAt = openAIResponsesAsInt(value);
  if (createdAt == null) {
    return null;
  }

  return DateTime.fromMillisecondsSinceEpoch(
    createdAt * 1000,
    isUtc: true,
  );
}

String? openAIResponsesResponseFinishReason(Map<String, Object?> response) {
  final incompleteDetails =
      openAIResponsesAsMap(response['incomplete_details']);
  return openAIResponsesAsString(incompleteDetails?['reason']);
}

String openAIResponsesResolveTextId(
  Map<String, Object?> chunk,
  Map<String, Object?>? item,
) {
  return openAIResponsesAsString(chunk['item_id']) ??
      openAIResponsesAsString(item?['id']) ??
      'text-${openAIResponsesAsInt(chunk['output_index']) ?? 0}';
}

String openAIResponsesResolveReasoningId(Map<String, Object?> chunk) {
  return '${openAIResponsesAsString(chunk['item_id']) ?? 'reasoning'}:${openAIResponsesAsInt(chunk['summary_index']) ?? 0}';
}

final class OpenAIResponsesStreamMetadataAdapter {
  final OpenAIResponsesStreamState state;
  final Map<String, Object?> chunk;
  final ProviderMetadata? Function(Map<String, Object?> values)
      customMetadataBuilder;

  const OpenAIResponsesStreamMetadataAdapter({
    required this.state,
    required this.chunk,
    required this.customMetadataBuilder,
  });

  ProviderMetadata? item([Map<String, Object?>? item]) =>
      openAIResponsesStreamItemMetadata(
        responseId: state.responseId,
        serviceTier: state.serviceTier,
        chunk: chunk,
        item: item,
      );

  ProviderMetadata? textPart(Map<String, Object?> part) =>
      openAIResponsesStreamTextPartMetadata(
        responseId: state.responseId,
        serviceTier: state.serviceTier,
        chunk: chunk,
        part: part,
      );

  ProviderMetadata? response(
    Map<String, Object?> response, {
    List<Object?>? logprobs,
  }) =>
      openAIResponsesResponseMetadata(
        response,
        logprobs: logprobs ?? const [],
      );

  ProviderMetadata? custom(Map<String, Object?> values) =>
      customMetadataBuilder(values);
}
