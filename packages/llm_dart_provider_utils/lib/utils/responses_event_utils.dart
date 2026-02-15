import 'package:llm_dart_core/llm_dart_core.dart';

import 'provider_tool_name_resolver.dart';

/// Parsed info for Responses API tool delta events.
///
/// Matches events shaped like:
/// `response.<tool>_call.<status>` with an `item_id`.
typedef ResponsesToolDeltaEvent = ({
  String toolCallId,
  String rawToolType,
  String toolType,
  String status,
});

ResponsesToolDeltaEvent? parseResponsesToolDeltaEvent({
  required String eventType,
  required Map<String, dynamic> json,
}) {
  if (!eventType.startsWith('response.')) return null;
  final segments = eventType.split('.');
  if (segments.length != 3) return null;

  final rawToolType = segments[1];
  final status = segments[2];
  if (!rawToolType.endsWith('_call')) return null;

  final toolCallId = json['item_id']?.toString();
  if (toolCallId == null || toolCallId.isEmpty) return null;

  final toolType = rawToolType.substring(0, rawToolType.length - 5);
  return (
    toolCallId: toolCallId,
    rawToolType: rawToolType,
    toolType: toolType,
    status: status,
  );
}

LLMProviderToolDeltaPart providerToolDeltaPartFromResponsesEvent({
  required String providerId,
  required ResponsesToolDeltaEvent event,
  required List<ProviderTool>? providerTools,
  Object? data,
  Map<String, dynamic>? providerMetadataPayload,
}) {
  final toolName = resolveProviderToolName(
    providerId: providerId,
    rawToolName: event.toolType,
    providerTools: providerTools,
  );

  return LLMProviderToolDeltaPart(
    toolCallId: event.toolCallId,
    toolName: toolName,
    status: event.status,
    data: data,
    providerMetadata:
        (providerMetadataPayload == null || providerMetadataPayload.isEmpty)
            ? null
            : {providerId: providerMetadataPayload},
  );
}
