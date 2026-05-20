import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;

import '../stream/text_stream_event.dart';

final class TextStreamLifecycleEventJsonCodec {
  const TextStreamLifecycleEventJsonCodec();

  bool canDecode(String type) {
    return switch (type) {
      'run-start' ||
      'run-finish' ||
      'run-end' ||
      'start' ||
      'response-metadata' ||
      'step-start' ||
      'step-end' ||
      'step-finish' ||
      'finish' ||
      'abort' =>
        true,
      _ => false,
    };
  }

  provider.JsonMap encode(TextStreamEvent event) {
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
      _ => throw ArgumentError.value(
          event,
          'event',
          'Unsupported lifecycle text stream event.',
        ),
    };
  }

  TextStreamEvent decode(
    provider.JsonMap map, {
    required String type,
    required String path,
  }) {
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
          'Unsupported text stream lifecycle event type "$type" at $path.',
        ),
    };
  }
}
