import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;

import '../stream/text_stream_event.dart';

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
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      TextStartEvent(:final id, :final providerMetadata) => {
          'type': 'text-start',
          'id': id,
          if (providerMetadata != null)
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      TextDeltaEvent(:final id, :final delta, :final providerMetadata) => {
          'type': 'text-delta',
          'id': id,
          'delta': delta,
          if (providerMetadata != null)
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      TextEndEvent(:final id, :final providerMetadata) => {
          'type': 'text-end',
          'id': id,
          if (providerMetadata != null)
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      ReasoningStartEvent(:final id, :final providerMetadata) => {
          'type': 'reasoning-start',
          'id': id,
          if (providerMetadata != null)
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
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
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      ReasoningEndEvent(:final id, :final providerMetadata) => {
          'type': 'reasoning-end',
          'id': id,
          if (providerMetadata != null)
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      ReasoningFileEvent(:final file, :final providerMetadata) => {
          'type': 'reasoning-file',
          'file': provider.SerializationJsonSupport.encodeGeneratedFile(file),
          if (providerMetadata != null)
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
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
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
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
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      ToolInputEndEvent(:final toolCallId, :final providerMetadata) => {
          'type': 'tool-input-end',
          'toolCallId': toolCallId,
          if (providerMetadata != null)
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
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
          'input': provider.ensureJsonValue(
            input,
            path: r'$.toolInputError.input',
          ),
          'errorText': errorText,
          'providerExecuted': providerExecuted,
          'isDynamic': isDynamic,
          if (title != null) 'title': title,
          if (providerMetadata != null)
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      ToolCallEvent(:final toolCall, :final providerMetadata) => {
          'type': 'tool-call',
          'toolCall': _encodeToolCallContent(toolCall),
          if (providerMetadata != null)
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      ToolResultEvent(:final toolResult, :final providerMetadata) => {
          'type': 'tool-result',
          'toolResult': _encodeToolResultContent(toolResult),
          if (providerMetadata != null)
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
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
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      ToolOutputDeniedEvent(
        :final toolCallId,
        :final reason,
        :final providerMetadata,
      ) =>
        {
          'type': 'tool-output-denied',
          'toolCallId': toolCallId,
          if (reason != null) 'reason': reason,
          if (providerMetadata != null)
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      SourceEvent(:final source) => {
          'type': 'source',
          'source': provider.SerializationJsonSupport.encodeSourceReference(
            source,
          ),
        },
      FileEvent(:final file, :final providerMetadata) => {
          'type': 'file',
          'file': provider.SerializationJsonSupport.encodeGeneratedFile(file),
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
      CustomEvent(:final kind, :final data, :final providerMetadata) => {
          'type': 'custom',
          'kind': kind,
          'data': provider.ensureJsonValue(data, path: r'$.custom.data'),
          if (providerMetadata != null)
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      RawChunkEvent(:final raw) => {
          'type': 'raw-chunk',
          'raw': provider.ensureJsonValue(raw, path: r'$.rawChunk.raw'),
        },
      ErrorEvent(:final error) => {
          'type': 'error',
          'error': provider.SerializationJsonSupport.encodeModelError(error),
        },
    };
  }

  TextStreamEvent decodeEvent(
    Object? value, {
    String path = r'$',
  }) {
    final map = provider.asJsonMap(value, path: path);
    final type = provider.asJsonString(map['type'], path: '$path.type');

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
          responseId: provider.asNullableJsonString(
            map['responseId'],
            path: '$path.responseId',
          ),
          timestamp: _decodeDateTime(map['timestamp'], path: '$path.timestamp'),
          modelId: provider.asNullableJsonString(
            map['modelId'],
            path: '$path.modelId',
          ),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'text-start' => TextStartEvent(
          id: provider.asJsonString(map['id'], path: '$path.id'),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'text-delta' => TextDeltaEvent(
          id: provider.asJsonString(map['id'], path: '$path.id'),
          delta: provider.asJsonString(map['delta'], path: '$path.delta'),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'text-end' => TextEndEvent(
          id: provider.asJsonString(map['id'], path: '$path.id'),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-start' => ReasoningStartEvent(
          id: provider.asJsonString(map['id'], path: '$path.id'),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-delta' => ReasoningDeltaEvent(
          id: provider.asJsonString(map['id'], path: '$path.id'),
          delta: provider.asJsonString(map['delta'], path: '$path.delta'),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-end' => ReasoningEndEvent(
          id: provider.asJsonString(map['id'], path: '$path.id'),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-file' => ReasoningFileEvent(
          provider.SerializationJsonSupport.decodeGeneratedFile(
            map['file'],
            path: '$path.file',
          ),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-input-start' => ToolInputStartEvent(
          toolCallId: provider.asJsonString(
            map['toolCallId'],
            path: '$path.toolCallId',
          ),
          toolName: provider.asJsonString(
            map['toolName'],
            path: '$path.toolName',
          ),
          providerExecuted: provider.asNullableJsonBool(
                map['providerExecuted'],
                path: '$path.providerExecuted',
              ) ??
              false,
          isDynamic: provider.SerializationJsonSupport.decodeDynamicFlag(
            map,
            path: path,
          ),
          title: provider.asNullableJsonString(
            map['title'],
            path: '$path.title',
          ),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-input-delta' => ToolInputDeltaEvent(
          toolCallId: provider.asJsonString(
            map['toolCallId'],
            path: '$path.toolCallId',
          ),
          delta: provider.asJsonString(map['delta'], path: '$path.delta'),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-input-end' => ToolInputEndEvent(
          toolCallId: provider.asJsonString(
            map['toolCallId'],
            path: '$path.toolCallId',
          ),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-input-error' => ToolInputErrorEvent(
          toolCallId: provider.asJsonString(
            map['toolCallId'],
            path: '$path.toolCallId',
          ),
          toolName: provider.asJsonString(
            map['toolName'],
            path: '$path.toolName',
          ),
          input: map['input'],
          errorText: provider.asJsonString(
            map['errorText'],
            path: '$path.errorText',
          ),
          providerExecuted: provider.asNullableJsonBool(
                map['providerExecuted'],
                path: '$path.providerExecuted',
              ) ??
              false,
          isDynamic: provider.SerializationJsonSupport.decodeDynamicFlag(
            map,
            path: path,
          ),
          title: provider.asNullableJsonString(
            map['title'],
            path: '$path.title',
          ),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-call' => ToolCallEvent(
          toolCall: _decodeToolCallContent(
            map['toolCall'],
            path: '$path.toolCall',
          ),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-result' => ToolResultEvent(
          toolResult: _decodeToolResultContent(
            map['toolResult'],
            path: '$path.toolResult',
          ),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-approval-request' => ToolApprovalRequestEvent(
          approvalId: provider.asJsonString(
            map['approvalId'],
            path: '$path.approvalId',
          ),
          toolCallId: provider.asJsonString(
            map['toolCallId'],
            path: '$path.toolCallId',
          ),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-output-denied' => ToolOutputDeniedEvent(
          toolCallId: provider.asJsonString(
            map['toolCallId'],
            path: '$path.toolCallId',
          ),
          reason: provider.asNullableJsonString(
            map['reason'],
            path: '$path.reason',
          ),
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'source' => SourceEvent(
          provider.SerializationJsonSupport.decodeSourceReference(
            map['source'],
            path: '$path.source',
          ),
        ),
      'file' => FileEvent(
          provider.SerializationJsonSupport.decodeGeneratedFile(
            map['file'],
            path: '$path.file',
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
      'custom' => CustomEvent(
          kind: provider.asJsonString(map['kind'], path: '$path.kind'),
          data: map['data'],
          providerMetadata:
              provider.SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'raw-chunk' => RawChunkEvent(map['raw']),
      'error' => ErrorEvent(
          provider.SerializationJsonSupport.decodeModelError(
            _requireValue(map['error'], path: '$path.error'),
            path: '$path.error',
          ),
        ),
      _ => throw FormatException(
          'Unsupported text stream event type "$type" at $path.',
        ),
    };
  }

  provider.JsonMap _encodeToolCallContent(provider.ToolCallContent toolCall) {
    return {
      'toolCallId': toolCall.toolCallId,
      'toolName': toolCall.toolName,
      'input': provider.ensureJsonValue(
        toolCall.input,
        path: r'$.toolCall.input',
      ),
      'providerExecuted': toolCall.providerExecuted,
      'isDynamic': toolCall.isDynamic,
      if (toolCall.title != null) 'title': toolCall.title,
    };
  }

  provider.ToolCallContent _decodeToolCallContent(
    Object? value, {
    required String path,
  }) {
    final map = provider.asJsonMap(value, path: path);
    return provider.ToolCallContent(
      toolCallId: provider.asJsonString(
        map['toolCallId'],
        path: '$path.toolCallId',
      ),
      toolName: provider.asJsonString(
        map['toolName'],
        path: '$path.toolName',
      ),
      input: map['input'],
      providerExecuted: provider.asNullableJsonBool(
            map['providerExecuted'],
            path: '$path.providerExecuted',
          ) ??
          false,
      isDynamic: provider.SerializationJsonSupport.decodeDynamicFlag(
        map,
        path: path,
      ),
      title: provider.asNullableJsonString(
        map['title'],
        path: '$path.title',
      ),
    );
  }

  provider.JsonMap _encodeToolResultContent(
    provider.ToolResultContent toolResult,
  ) {
    return {
      'toolCallId': toolResult.toolCallId,
      'toolName': toolResult.toolName,
      'toolOutput': provider.SerializationJsonSupport.encodeToolOutput(
        toolResult.toolOutput,
      ),
      'preliminary': toolResult.preliminary,
      'isDynamic': toolResult.isDynamic,
    };
  }

  provider.ToolResultContent _decodeToolResultContent(
    Object? value, {
    required String path,
  }) {
    final map = provider.asJsonMap(value, path: path);
    return provider.ToolResultContent(
      toolCallId: provider.asJsonString(
        map['toolCallId'],
        path: '$path.toolCallId',
      ),
      toolName: provider.asJsonString(
        map['toolName'],
        path: '$path.toolName',
      ),
      toolOutput: map.containsKey('toolOutput')
          ? provider.SerializationJsonSupport.decodeToolOutput(
              map['toolOutput'],
              path: '$path.toolOutput',
            )
          : null,
      output: map.containsKey('toolOutput') ? null : map['output'],
      isError: map.containsKey('toolOutput')
          ? false
          : provider.asNullableJsonBool(
                map['isError'],
                path: '$path.isError',
              ) ??
              false,
      preliminary: provider.asNullableJsonBool(
            map['preliminary'],
            path: '$path.preliminary',
          ) ??
          false,
      isDynamic: provider.SerializationJsonSupport.decodeDynamicFlag(
        map,
        path: path,
      ),
    );
  }

  DateTime? _decodeDateTime(
    Object? value, {
    required String path,
  }) {
    final stringValue = provider.asNullableJsonString(value, path: path);
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
