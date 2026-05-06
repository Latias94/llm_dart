import '../content/content_part.dart';
import '../model/finish_reason.dart';
import '../stream/text_stream_event.dart';
import '../common/json_codec_common.dart';
import 'serialization_json_support.dart';
import 'serialization_protocol.dart';

final class TextStreamEventJsonCodec {
  static const envelopeKind = 'text-stream-events';

  const TextStreamEventJsonCodec();

  JsonMap encodeEvents(List<TextStreamEvent> events) {
    return {
      'schemaVersion': llmDartJsonSchemaVersion,
      'kind': envelopeKind,
      'data': {
        'events': events.map(encodeEvent).toList(growable: false),
      },
    };
  }

  List<TextStreamEvent> decodeEvents(Object? envelope) {
    final root = asJsonMap(envelope, path: r'$');
    final kind = asJsonString(root['kind'], path: r'$.kind');
    if (kind != envelopeKind) {
      throw FormatException(
        'Expected envelope kind "$envelopeKind", received "$kind".',
      );
    }

    final data = asJsonMap(root['data'], path: r'$.data');
    return asJsonList(data['events'], path: r'$.data.events')
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

  JsonMap encodeEvent(TextStreamEvent event) {
    return switch (event) {
      StartEvent(:final warnings) => {
          'type': 'start',
          'warnings': warnings
              .map(SerializationJsonSupport.encodeModelWarning)
              .toList(growable: false),
        },
      ResponseMetadataEvent(
        :final responseId,
        :final timestamp,
        :final modelId,
        :final providerMetadata,
      ) =>
        {
          'type': 'response-metadata',
          if (responseId != null) 'responseId': responseId,
          if (timestamp != null) 'timestamp': timestamp.toIso8601String(),
          if (modelId != null) 'modelId': modelId,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      TextStartEvent(
        :final id,
        :final providerMetadata,
      ) =>
        {
          'type': 'text-start',
          'id': id,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      TextDeltaEvent(
        :final id,
        :final delta,
        :final providerMetadata,
      ) =>
        {
          'type': 'text-delta',
          'id': id,
          'delta': delta,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      TextEndEvent(
        :final id,
        :final providerMetadata,
      ) =>
        {
          'type': 'text-end',
          'id': id,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      ReasoningStartEvent(
        :final id,
        :final providerMetadata,
      ) =>
        {
          'type': 'reasoning-start',
          'id': id,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      ReasoningDeltaEvent(
        :final id,
        :final delta,
        :final providerMetadata,
      ) =>
        {
          'type': 'reasoning-delta',
          'id': id,
          'delta': delta,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      ReasoningEndEvent(
        :final id,
        :final providerMetadata,
      ) =>
        {
          'type': 'reasoning-end',
          'id': id,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      ReasoningFileEvent(
        :final file,
        :final providerMetadata,
      ) =>
        {
          'type': 'reasoning-file',
          'file': SerializationJsonSupport.encodeGeneratedFile(file),
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      ToolInputStartEvent(
        :final toolCallId,
        :final toolName,
        :final providerExecuted,
        :final isDynamic,
        :final title,
        :final providerMetadata,
      ) =>
        {
          'type': 'tool-input-start',
          'toolCallId': toolCallId,
          'toolName': toolName,
          'providerExecuted': providerExecuted,
          'isDynamic': isDynamic,
          if (title != null) 'title': title,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      ToolInputDeltaEvent(
        :final toolCallId,
        :final delta,
        :final providerMetadata,
      ) =>
        {
          'type': 'tool-input-delta',
          'toolCallId': toolCallId,
          'delta': delta,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      ToolInputEndEvent(
        :final toolCallId,
        :final providerMetadata,
      ) =>
        {
          'type': 'tool-input-end',
          'toolCallId': toolCallId,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      ToolInputErrorEvent(
        :final toolCallId,
        :final toolName,
        :final input,
        :final errorText,
        :final providerExecuted,
        :final isDynamic,
        :final title,
        :final providerMetadata,
      ) =>
        {
          'type': 'tool-input-error',
          'toolCallId': toolCallId,
          'toolName': toolName,
          'input': ensureJsonValue(input, path: r'$.toolInputError.input'),
          'errorText': errorText,
          'providerExecuted': providerExecuted,
          'isDynamic': isDynamic,
          if (title != null) 'title': title,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      ToolCallEvent(
        :final toolCall,
        :final providerMetadata,
      ) =>
        {
          'type': 'tool-call',
          'toolCall': _encodeToolCallContent(toolCall),
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      ToolResultEvent(
        :final toolResult,
        :final providerMetadata,
      ) =>
        {
          'type': 'tool-result',
          'toolResult': _encodeToolResultContent(toolResult),
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      ToolApprovalRequestEvent(
        :final approvalId,
        :final toolCallId,
        :final providerMetadata,
      ) =>
        {
          'type': 'tool-approval-request',
          'approvalId': approvalId,
          'toolCallId': toolCallId,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      ToolOutputDeniedEvent(
        :final toolCallId,
        :final providerMetadata,
      ) =>
        {
          'type': 'tool-output-denied',
          'toolCallId': toolCallId,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      SourceEvent(:final source) => {
          'type': 'source',
          'source': SerializationJsonSupport.encodeSourceReference(source),
        },
      FileEvent(
        :final file,
        :final providerMetadata,
      ) =>
        {
          'type': 'file',
          'file': SerializationJsonSupport.encodeGeneratedFile(file),
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
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
            'usage': SerializationJsonSupport.encodeUsageStats(usage),
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      AbortEvent(:final reason) => {
          'type': 'abort',
          if (reason != null) 'reason': reason,
        },
      CustomEvent(
        :final kind,
        :final data,
        :final providerMetadata,
      ) =>
        {
          'type': 'custom',
          'kind': kind,
          'data': ensureJsonValue(data, path: r'$.custom.data'),
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      RawChunkEvent(:final raw) => {
          'type': 'raw-chunk',
          'raw': ensureJsonValue(raw, path: r'$.rawChunk.raw'),
        },
      ErrorEvent(:final error) => {
          'type': 'error',
          'error': SerializationJsonSupport.encodeModelError(error),
        },
    };
  }

  TextStreamEvent decodeEvent(
    Object? value, {
    String path = r'$',
  }) {
    final map = asJsonMap(value, path: path);
    final type = asJsonString(map['type'], path: '$path.type');

    return switch (type) {
      'start' => StartEvent(
          warnings: asJsonList(map['warnings'], path: '$path.warnings')
              .asMap()
              .entries
              .map(
                (entry) => SerializationJsonSupport.decodeModelWarning(
                  entry.value,
                  path: '$path.warnings[${entry.key}]',
                ),
              )
              .toList(growable: false),
        ),
      'response-metadata' => ResponseMetadataEvent(
          responseId:
              asNullableJsonString(map['responseId'], path: '$path.responseId'),
          timestamp: _decodeDateTime(map['timestamp'], path: '$path.timestamp'),
          modelId: asNullableJsonString(map['modelId'], path: '$path.modelId'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'text-start' => TextStartEvent(
          id: asJsonString(map['id'], path: '$path.id'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'text-delta' => TextDeltaEvent(
          id: asJsonString(map['id'], path: '$path.id'),
          delta: asJsonString(map['delta'], path: '$path.delta'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'text-end' => TextEndEvent(
          id: asJsonString(map['id'], path: '$path.id'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-start' => ReasoningStartEvent(
          id: asJsonString(map['id'], path: '$path.id'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-delta' => ReasoningDeltaEvent(
          id: asJsonString(map['id'], path: '$path.id'),
          delta: asJsonString(map['delta'], path: '$path.delta'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-end' => ReasoningEndEvent(
          id: asJsonString(map['id'], path: '$path.id'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-file' => ReasoningFileEvent(
          SerializationJsonSupport.decodeGeneratedFile(map['file'],
              path: '$path.file'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-input-start' => ToolInputStartEvent(
          toolCallId: asJsonString(map['toolCallId'], path: '$path.toolCallId'),
          toolName: asJsonString(map['toolName'], path: '$path.toolName'),
          providerExecuted: asNullableJsonBool(
                map['providerExecuted'],
                path: '$path.providerExecuted',
              ) ??
              false,
          isDynamic: asNullableJsonBool(
                map['isDynamic'],
                path: '$path.isDynamic',
              ) ??
              false,
          title: asNullableJsonString(map['title'], path: '$path.title'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-input-delta' => ToolInputDeltaEvent(
          toolCallId: asJsonString(map['toolCallId'], path: '$path.toolCallId'),
          delta: asJsonString(map['delta'], path: '$path.delta'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-input-end' => ToolInputEndEvent(
          toolCallId: asJsonString(map['toolCallId'], path: '$path.toolCallId'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-input-error' => ToolInputErrorEvent(
          toolCallId: asJsonString(map['toolCallId'], path: '$path.toolCallId'),
          toolName: asJsonString(map['toolName'], path: '$path.toolName'),
          input: map['input'],
          errorText: asJsonString(map['errorText'], path: '$path.errorText'),
          providerExecuted: asNullableJsonBool(
                map['providerExecuted'],
                path: '$path.providerExecuted',
              ) ??
              false,
          isDynamic: asNullableJsonBool(
                map['isDynamic'],
                path: '$path.isDynamic',
              ) ??
              false,
          title: asNullableJsonString(map['title'], path: '$path.title'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-call' => ToolCallEvent(
          toolCall: _decodeToolCallContent(
            map['toolCall'],
            path: '$path.toolCall',
          ),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-result' => ToolResultEvent(
          toolResult: _decodeToolResultContent(
            map['toolResult'],
            path: '$path.toolResult',
          ),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-approval-request' => ToolApprovalRequestEvent(
          approvalId: asJsonString(map['approvalId'], path: '$path.approvalId'),
          toolCallId: asJsonString(map['toolCallId'], path: '$path.toolCallId'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-output-denied' => ToolOutputDeniedEvent(
          toolCallId: asJsonString(map['toolCallId'], path: '$path.toolCallId'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'source' => SourceEvent(
          SerializationJsonSupport.decodeSourceReference(map['source'],
              path: '$path.source'),
        ),
      'file' => FileEvent(
          SerializationJsonSupport.decodeGeneratedFile(map['file'],
              path: '$path.file'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'step-start' => StepStartEvent(
          stepId: asNullableJsonString(map['stepId'], path: '$path.stepId'),
        ),
      'step-end' || 'step-finish' => StepFinishEvent(
          stepId: asNullableJsonString(map['stepId'], path: '$path.stepId'),
        ),
      'finish' => FinishEvent(
          finishReason: FinishReason.values.byName(
            asJsonString(map['finishReason'], path: '$path.finishReason'),
          ),
          rawFinishReason: asNullableJsonString(
            map['rawFinishReason'],
            path: '$path.rawFinishReason',
          ),
          usage: SerializationJsonSupport.decodeUsageStats(map['usage'],
              path: '$path.usage'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'abort' => AbortEvent(
          reason: asNullableJsonString(map['reason'], path: '$path.reason'),
        ),
      'custom' => CustomEvent(
          kind: asJsonString(map['kind'], path: '$path.kind'),
          data: map['data'],
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'raw-chunk' => RawChunkEvent(map['raw']),
      'error' => ErrorEvent(
          SerializationJsonSupport.decodeModelError(
            _requireValue(map['error'], path: '$path.error'),
            path: '$path.error',
          ),
        ),
      _ => throw FormatException(
          'Unsupported text stream event type "$type" at $path.',
        ),
    };
  }

  JsonMap _encodeToolCallContent(ToolCallContent toolCall) {
    return {
      'toolCallId': toolCall.toolCallId,
      'toolName': toolCall.toolName,
      'input': ensureJsonValue(toolCall.input, path: r'$.toolCall.input'),
      'providerExecuted': toolCall.providerExecuted,
      'isDynamic': toolCall.isDynamic,
      if (toolCall.title != null) 'title': toolCall.title,
    };
  }

  ToolCallContent _decodeToolCallContent(
    Object? value, {
    required String path,
  }) {
    final map = asJsonMap(value, path: path);
    return ToolCallContent(
      toolCallId: asJsonString(map['toolCallId'], path: '$path.toolCallId'),
      toolName: asJsonString(map['toolName'], path: '$path.toolName'),
      input: map['input'],
      providerExecuted: asNullableJsonBool(
            map['providerExecuted'],
            path: '$path.providerExecuted',
          ) ??
          false,
      isDynamic:
          asNullableJsonBool(map['isDynamic'], path: '$path.isDynamic') ??
              false,
      title: asNullableJsonString(map['title'], path: '$path.title'),
    );
  }

  JsonMap _encodeToolResultContent(ToolResultContent toolResult) {
    return {
      'toolCallId': toolResult.toolCallId,
      'toolName': toolResult.toolName,
      'output':
          ensureJsonValue(toolResult.output, path: r'$.toolResult.output'),
      'isError': toolResult.isError,
      'preliminary': toolResult.preliminary,
      'isDynamic': toolResult.isDynamic,
    };
  }

  ToolResultContent _decodeToolResultContent(
    Object? value, {
    required String path,
  }) {
    final map = asJsonMap(value, path: path);
    return ToolResultContent(
      toolCallId: asJsonString(map['toolCallId'], path: '$path.toolCallId'),
      toolName: asJsonString(map['toolName'], path: '$path.toolName'),
      output: map['output'],
      isError:
          asNullableJsonBool(map['isError'], path: '$path.isError') ?? false,
      preliminary: asNullableJsonBool(
            map['preliminary'],
            path: '$path.preliminary',
          ) ??
          false,
      isDynamic:
          asNullableJsonBool(map['isDynamic'], path: '$path.isDynamic') ??
              false,
    );
  }

  DateTime? _decodeDateTime(
    Object? value, {
    required String path,
  }) {
    final stringValue = asNullableJsonString(value, path: path);
    return stringValue == null ? null : DateTime.parse(stringValue);
  }

  Object _requireValue(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      throw FormatException('Expected non-null value at $path.');
    }

    return value;
  }
}
