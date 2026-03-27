import 'dart:convert';

import '../common/model_warning.dart';
import '../common/provider_metadata.dart';
import '../common/usage_stats.dart';
import '../content/content_part.dart';
import '../model/language_model.dart';
import '../stream/text_stream_event.dart';
import 'json_codec_common.dart';
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
          'warnings': warnings.map(_encodeModelWarning).toList(growable: false),
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
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
        },
      TextStartEvent(
        :final id,
        :final providerMetadata,
      ) =>
        {
          'type': 'text-start',
          'id': id,
          if (providerMetadata != null)
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
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
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
        },
      TextEndEvent(
        :final id,
        :final providerMetadata,
      ) =>
        {
          'type': 'text-end',
          'id': id,
          if (providerMetadata != null)
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
        },
      ReasoningStartEvent(
        :final id,
        :final providerMetadata,
      ) =>
        {
          'type': 'reasoning-start',
          'id': id,
          if (providerMetadata != null)
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
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
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
        },
      ReasoningEndEvent(
        :final id,
        :final providerMetadata,
      ) =>
        {
          'type': 'reasoning-end',
          'id': id,
          if (providerMetadata != null)
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
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
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
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
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
        },
      ToolInputEndEvent(
        :final toolCallId,
        :final providerMetadata,
      ) =>
        {
          'type': 'tool-input-end',
          'toolCallId': toolCallId,
          if (providerMetadata != null)
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
        },
      ToolCallEvent(
        :final toolCall,
        :final providerMetadata,
      ) =>
        {
          'type': 'tool-call',
          'toolCall': _encodeToolCallContent(toolCall),
          if (providerMetadata != null)
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
        },
      ToolResultEvent(
        :final toolResult,
        :final providerMetadata,
      ) =>
        {
          'type': 'tool-result',
          'toolResult': _encodeToolResultContent(toolResult),
          if (providerMetadata != null)
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
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
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
        },
      ToolOutputDeniedEvent(
        :final toolCallId,
        :final providerMetadata,
      ) =>
        {
          'type': 'tool-output-denied',
          'toolCallId': toolCallId,
          if (providerMetadata != null)
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
        },
      SourceEvent(:final source) => {
          'type': 'source',
          'source': _encodeSourceReference(source),
        },
      FileEvent(
        :final file,
        :final providerMetadata,
      ) =>
        {
          'type': 'file',
          'file': _encodeGeneratedFile(file),
          if (providerMetadata != null)
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
        },
      StepStartEvent(:final stepId) => {
          'type': 'step-start',
          if (stepId != null) 'stepId': stepId,
        },
      StepFinishEvent(:final stepId) => {
          'type': 'step-finish',
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
          if (usage != null) 'usage': _encodeUsageStats(usage),
          if (providerMetadata != null)
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
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
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
        },
      RawChunkEvent(:final raw) => {
          'type': 'raw-chunk',
          'raw': ensureJsonValue(raw, path: r'$.rawChunk.raw'),
        },
      ErrorEvent(:final error) => {
          'type': 'error',
          'error': ensureJsonValue(error, path: r'$.error.error'),
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
                (entry) => _decodeModelWarning(
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
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'text-start' => TextStartEvent(
          id: asJsonString(map['id'], path: '$path.id'),
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'text-delta' => TextDeltaEvent(
          id: asJsonString(map['id'], path: '$path.id'),
          delta: asJsonString(map['delta'], path: '$path.delta'),
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'text-end' => TextEndEvent(
          id: asJsonString(map['id'], path: '$path.id'),
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-start' => ReasoningStartEvent(
          id: asJsonString(map['id'], path: '$path.id'),
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-delta' => ReasoningDeltaEvent(
          id: asJsonString(map['id'], path: '$path.id'),
          delta: asJsonString(map['delta'], path: '$path.delta'),
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-end' => ReasoningEndEvent(
          id: asJsonString(map['id'], path: '$path.id'),
          providerMetadata: _decodeProviderMetadata(
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
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-input-delta' => ToolInputDeltaEvent(
          toolCallId: asJsonString(map['toolCallId'], path: '$path.toolCallId'),
          delta: asJsonString(map['delta'], path: '$path.delta'),
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-input-end' => ToolInputEndEvent(
          toolCallId: asJsonString(map['toolCallId'], path: '$path.toolCallId'),
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-call' => ToolCallEvent(
          toolCall: _decodeToolCallContent(
            map['toolCall'],
            path: '$path.toolCall',
          ),
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-result' => ToolResultEvent(
          toolResult: _decodeToolResultContent(
            map['toolResult'],
            path: '$path.toolResult',
          ),
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-approval-request' => ToolApprovalRequestEvent(
          approvalId: asJsonString(map['approvalId'], path: '$path.approvalId'),
          toolCallId: asJsonString(map['toolCallId'], path: '$path.toolCallId'),
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-output-denied' => ToolOutputDeniedEvent(
          toolCallId: asJsonString(map['toolCallId'], path: '$path.toolCallId'),
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'source' => SourceEvent(
          _decodeSourceReference(map['source'], path: '$path.source'),
        ),
      'file' => FileEvent(
          _decodeGeneratedFile(map['file'], path: '$path.file'),
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'step-start' => StepStartEvent(
          stepId: asNullableJsonString(map['stepId'], path: '$path.stepId'),
        ),
      'step-finish' => StepFinishEvent(
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
          usage: _decodeUsageStats(map['usage'], path: '$path.usage'),
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'custom' => CustomEvent(
          kind: asJsonString(map['kind'], path: '$path.kind'),
          data: map['data'],
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'raw-chunk' => RawChunkEvent(map['raw']),
      'error' => ErrorEvent(
          _requireValue(map['error'], path: '$path.error'),
        ),
      _ => throw FormatException(
          'Unsupported text stream event type "$type" at $path.',
        ),
    };
  }

  JsonMap _encodeProviderMetadata(ProviderMetadata metadata) {
    return ensureJsonValue(metadata.values, path: r'$.providerMetadata')
        as JsonMap;
  }

  ProviderMetadata? _decodeProviderMetadata(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return null;
    }

    return ProviderMetadata(asJsonMap(value, path: path));
  }

  JsonMap _encodeUsageStats(UsageStats stats) {
    return {
      'inputTokens': stats.inputTokens,
      'outputTokens': stats.outputTokens,
      'totalTokens': stats.totalTokens,
      'reasoningTokens': stats.reasoningTokens,
    };
  }

  UsageStats? _decodeUsageStats(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return null;
    }

    final map = asJsonMap(value, path: path);
    return UsageStats(
      inputTokens:
          asNullableJsonInt(map['inputTokens'], path: '$path.inputTokens'),
      outputTokens:
          asNullableJsonInt(map['outputTokens'], path: '$path.outputTokens'),
      totalTokens:
          asNullableJsonInt(map['totalTokens'], path: '$path.totalTokens'),
      reasoningTokens: asNullableJsonInt(
        map['reasoningTokens'],
        path: '$path.reasoningTokens',
      ),
    );
  }

  JsonMap _encodeModelWarning(ModelWarning warning) {
    return {
      'type': warning.type.name,
      'message': warning.message,
      if (warning.field != null) 'field': warning.field,
    };
  }

  ModelWarning _decodeModelWarning(
    Object? value, {
    required String path,
  }) {
    final map = asJsonMap(value, path: path);
    return ModelWarning(
      type: ModelWarningType.values.byName(
        asJsonString(map['type'], path: '$path.type'),
      ),
      message: asJsonString(map['message'], path: '$path.message'),
      field: asNullableJsonString(map['field'], path: '$path.field'),
    );
  }

  JsonMap _encodeSourceReference(SourceReference source) {
    return {
      'kind': _encodeSourceReferenceKind(source.kind),
      'sourceId': source.sourceId,
      if (source.uri != null) 'uri': source.uri.toString(),
      if (source.title != null) 'title': source.title,
      if (source.filename != null) 'filename': source.filename,
      if (source.mediaType != null) 'mediaType': source.mediaType,
      if (source.providerMetadata != null)
        'providerMetadata': _encodeProviderMetadata(source.providerMetadata!),
    };
  }

  SourceReference _decodeSourceReference(
    Object? value, {
    required String path,
  }) {
    final map = asJsonMap(value, path: path);
    return SourceReference(
      kind: _decodeSourceReferenceKind(
        map['kind'],
        path: '$path.kind',
        uri: map['uri'],
      ),
      sourceId: asJsonString(map['sourceId'], path: '$path.sourceId'),
      uri: _decodeUri(map['uri'], path: '$path.uri'),
      title: asNullableJsonString(map['title'], path: '$path.title'),
      filename: asNullableJsonString(map['filename'], path: '$path.filename'),
      mediaType:
          asNullableJsonString(map['mediaType'], path: '$path.mediaType'),
      providerMetadata: _decodeProviderMetadata(
        map['providerMetadata'],
        path: '$path.providerMetadata',
      ),
    );
  }

  String _encodeSourceReferenceKind(SourceReferenceKind kind) {
    switch (kind) {
      case SourceReferenceKind.url:
        return 'url';
      case SourceReferenceKind.document:
        return 'document';
      case SourceReferenceKind.other:
        return 'other';
    }
  }

  SourceReferenceKind _decodeSourceReferenceKind(
    Object? value, {
    required String path,
    required Object? uri,
  }) {
    final kind = asNullableJsonString(value, path: path);
    return switch (kind) {
      'url' => SourceReferenceKind.url,
      'document' => SourceReferenceKind.document,
      'other' => SourceReferenceKind.other,
      null => uri == null
          ? SourceReferenceKind.document
          : SourceReferenceKind.url,
      _ => throw FormatException('Invalid source kind at $path: $kind'),
    };
  }

  JsonMap _encodeGeneratedFile(GeneratedFile file) {
    return {
      'mediaType': file.mediaType,
      if (file.filename != null) 'filename': file.filename,
      if (file.uri != null) 'uri': file.uri.toString(),
      if (file.bytes != null) 'bytes': _encodeBytes(file.bytes!),
    };
  }

  GeneratedFile _decodeGeneratedFile(
    Object? value, {
    required String path,
  }) {
    final map = asJsonMap(value, path: path);
    return GeneratedFile(
      mediaType: asJsonString(map['mediaType'], path: '$path.mediaType'),
      filename: asNullableJsonString(map['filename'], path: '$path.filename'),
      uri: _decodeUri(map['uri'], path: '$path.uri'),
      bytes: _decodeBytes(map['bytes'], path: '$path.bytes'),
    );
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

  JsonMap _encodeBytes(List<int> bytes) {
    return {
      'encoding': 'base64',
      'data': base64Encode(bytes),
    };
  }

  List<int>? _decodeBytes(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return null;
    }

    final map = asJsonMap(value, path: path);
    final encoding = asJsonString(map['encoding'], path: '$path.encoding');
    if (encoding != 'base64') {
      throw FormatException('Unsupported byte encoding "$encoding" at $path.');
    }

    return base64Decode(asJsonString(map['data'], path: '$path.data'));
  }

  DateTime? _decodeDateTime(
    Object? value, {
    required String path,
  }) {
    final stringValue = asNullableJsonString(value, path: path);
    return stringValue == null ? null : DateTime.parse(stringValue);
  }

  Uri? _decodeUri(
    Object? value, {
    required String path,
  }) {
    final stringValue = asNullableJsonString(value, path: path);
    return stringValue == null ? null : Uri.parse(stringValue);
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
