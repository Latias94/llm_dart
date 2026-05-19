import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;

import '../stream/text_stream_event.dart';
import 'text_stream_content_event_json_codec.dart';
import 'text_stream_tool_event_json_codec.dart';

/// JSON codec for AI runtime full-stream events.
///
/// The wire shape remains compatible with the previous text stream envelope,
/// but event serialization is now owned by `llm_dart_ai` instead of delegating
/// through provider stream serialization.
final class TextStreamEventJsonCodec {
  static const envelopeKind = 'text-stream-events';

  const TextStreamEventJsonCodec();

  provider.JsonMap encodeEvents(List<TextStreamEvent> events) {
    return {
      'schemaVersion': provider.llmDartJsonSchemaVersion,
      'kind': envelopeKind,
      'data': {
        'events': events.map(encodeEvent).toList(growable: false),
      },
    };
  }

  List<TextStreamEvent> decodeEvents(Object? envelope) {
    final root = provider.asJsonMap(envelope, path: r'$');
    final kind = provider.asJsonString(root['kind'], path: r'$.kind');
    if (kind != envelopeKind) {
      throw FormatException(
        'Expected envelope kind "$envelopeKind", received "$kind".',
      );
    }

    final data = provider.asJsonMap(root['data'], path: r'$.data');
    return provider
        .asJsonList(data['events'], path: r'$.data.events')
        .asMap()
        .entries
        .map(
          (entry) => decodeEvent(
            entry.value,
            path: '\$.data.events[${entry.key}]',
          ),
        )
        .toList(growable: false);
  }

  provider.JsonMap encodeEvent(TextStreamEvent event) {
    return switch (event) {
      RunStartEvent(:final runId) => {
          'type': 'run-start',
          if (runId != null) 'runId': runId,
        },
      RunFinishEvent(
        :final runId,
        :final finishReason,
        :final rawFinishReason,
        :final usage,
      ) =>
        {
          'type': 'run-finish',
          if (runId != null) 'runId': runId,
          'finishReason': finishReason.name,
          if (rawFinishReason != null) 'rawFinishReason': rawFinishReason,
          if (usage != null)
            'usage': provider.SerializationJsonSupport.encodeUsageStats(usage),
        },
      StartEvent(:final warnings) => {
          'type': 'start',
          'warnings': warnings
              .map(provider.SerializationJsonSupport.encodeModelWarning)
              .toList(growable: false),
        },
      ResponseMetadataEvent(
        :final responseMetadata,
        :final responseId,
        :final timestamp,
        :final modelId,
        :final providerMetadata,
      ) =>
        {
          'type': 'response-metadata',
          ...provider.SerializationJsonSupport.encodeModelResponseMetadata(
            provider.modelResponseMetadataFrom(
                  metadata: responseMetadata,
                  id: responseId,
                  timestamp: timestamp,
                  modelId: modelId,
                ) ??
                const provider.ModelResponseMetadata(),
          ),
          if (providerMetadata != null)
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      TextStartEvent() ||
      TextDeltaEvent() ||
      TextEndEvent() ||
      ReasoningStartEvent() ||
      ReasoningDeltaEvent() ||
      ReasoningEndEvent() ||
      ReasoningFileEvent() =>
        const TextStreamContentEventJsonCodec().encode(event),
      ToolInputStartEvent() ||
      ToolInputDeltaEvent() ||
      ToolInputEndEvent() ||
      ToolInputErrorEvent() ||
      ToolCallEvent() ||
      ToolResultEvent() ||
      ToolApprovalRequestEvent() ||
      ToolOutputDeniedEvent() =>
        const TextStreamToolEventJsonCodec().encode(event),
      SourceEvent() ||
      FileEvent() =>
        const TextStreamContentEventJsonCodec().encode(event),
      StepStartEvent(:final stepId) => {
          'type': 'step-start',
          if (stepId != null) 'stepId': stepId,
        },
      StepFinishEvent(:final stepId) => {
          'type': 'step-end',
          if (stepId != null) 'stepId': stepId,
        },
      FinishEvent(
        :final finishReason,
        :final rawFinishReason,
        :final usage,
        :final providerMetadata,
      ) =>
        {
          'type': 'finish',
          'finishReason': finishReason.name,
          if (rawFinishReason != null) 'rawFinishReason': rawFinishReason,
          if (usage != null)
            'usage': provider.SerializationJsonSupport.encodeUsageStats(usage),
          if (providerMetadata != null)
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      AbortEvent(:final reason) => {
          'type': 'abort',
          if (reason != null) 'reason': reason,
        },
      CustomEvent() ||
      RawChunkEvent() ||
      ErrorEvent() =>
        const TextStreamContentEventJsonCodec().encode(event),
    };
  }

  TextStreamEvent decodeEvent(
    Object? value, {
    String path = r'$',
  }) {
    final map = provider.asJsonMap(value, path: path);
    final type = provider.asJsonString(map['type'], path: '$path.type');
    const toolEventCodec = TextStreamToolEventJsonCodec();
    if (toolEventCodec.canDecode(type)) {
      return toolEventCodec.decode(map, type: type, path: path);
    }
    const contentEventCodec = TextStreamContentEventJsonCodec();
    if (contentEventCodec.canDecode(type)) {
      return contentEventCodec.decode(map, type: type, path: path);
    }

    return switch (type) {
      'run-start' => RunStartEvent(
          runId: provider.asNullableJsonString(
            map['runId'],
            path: '$path.runId',
          ),
        ),
      'run-finish' || 'run-end' => RunFinishEvent(
          runId: provider.asNullableJsonString(
            map['runId'],
            path: '$path.runId',
          ),
          finishReason: provider.FinishReason.values.byName(
            provider.asJsonString(
              map['finishReason'],
              path: '$path.finishReason',
            ),
          ),
          rawFinishReason: provider.asNullableJsonString(
            map['rawFinishReason'],
            path: '$path.rawFinishReason',
          ),
          usage: provider.SerializationJsonSupport.decodeUsageStats(
            map['usage'],
            path: '$path.usage',
          ),
        ),
      'start' => StartEvent(
          warnings: provider
              .asJsonList(map['warnings'], path: '$path.warnings')
              .asMap()
              .entries
              .map(
                (entry) => provider.SerializationJsonSupport.decodeModelWarning(
                  entry.value,
                  path: '$path.warnings[${entry.key}]',
                ),
              )
              .toList(growable: false),
        ),
      'response-metadata' => ResponseMetadataEvent(
          responseMetadata: provider.SerializationJsonSupport
              .decodeModelResponseMetadataFields(
            map,
            path: path,
          ),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'step-start' => StepStartEvent(
          stepId: provider.asNullableJsonString(
            map['stepId'],
            path: '$path.stepId',
          ),
        ),
      'step-end' || 'step-finish' => StepFinishEvent(
          stepId: provider.asNullableJsonString(
            map['stepId'],
            path: '$path.stepId',
          ),
        ),
      'finish' => FinishEvent(
          finishReason: provider.FinishReason.values.byName(
            provider.asJsonString(
              map['finishReason'],
              path: '$path.finishReason',
            ),
          ),
          rawFinishReason: provider.asNullableJsonString(
            map['rawFinishReason'],
            path: '$path.rawFinishReason',
          ),
          usage: provider.SerializationJsonSupport.decodeUsageStats(
            map['usage'],
            path: '$path.usage',
          ),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'abort' => AbortEvent(
          reason: provider.asNullableJsonString(
            map['reason'],
            path: '$path.reason',
          ),
        ),
      _ => throw FormatException(
          'Unsupported text stream event type "$type" at $path.',
        ),
    };
  }
}
