import 'dart:convert';

import '../common/model_warning.dart';
import '../common/provider_metadata.dart';
import '../common/usage_stats.dart';
import '../content/content_part.dart';
import '../model/language_model.dart';
import '../ui/chat_ui_message.dart';
import 'json_codec_common.dart';
import 'serialization_protocol.dart';

final class ChatUiJsonCodec {
  static const envelopeKind = 'chat-ui-messages';

  const ChatUiJsonCodec();

  JsonMap encodeMessages(List<ChatUiMessage> messages) {
    return {
      'schemaVersion': llmDartJsonSchemaVersion,
      'kind': envelopeKind,
      'data': {
        'messages': messages.map(encodeMessage).toList(growable: false),
      },
    };
  }

  List<ChatUiMessage> decodeMessages(Object? envelope) {
    final root = asJsonMap(envelope, path: r'$');
    final kind = asJsonString(root['kind'], path: r'$.kind');
    if (kind != envelopeKind) {
      throw FormatException(
        'Expected envelope kind "$envelopeKind", received "$kind".',
      );
    }

    final data = asJsonMap(root['data'], path: r'$.data');
    return asJsonList(data['messages'], path: r'$.data.messages')
        .asMap()
        .entries
        .map(
          (entry) => decodeMessage(
            entry.value,
            path: '\$.data.messages[${entry.key}]',
          ),
        )
        .toList(growable: false);
  }

  JsonMap encodeMessage(ChatUiMessage message) {
    return {
      'id': message.id,
      'role': message.role.name,
      'parts': message.parts.map(encodePart).toList(growable: false),
      'metadata': _encodeMetadataMap(message.metadata),
    };
  }

  ChatUiMessage decodeMessage(
    Object? value, {
    String path = r'$',
  }) {
    final map = asJsonMap(value, path: path);
    final role = ChatUiRole.values.byName(
      asJsonString(map['role'], path: '$path.role'),
    );
    final parts = asJsonList(map['parts'], path: '$path.parts')
        .asMap()
        .entries
        .map((entry) =>
            decodePart(entry.value, path: '$path.parts[${entry.key}]'))
        .toList(growable: false);

    return ChatUiMessage(
      id: asJsonString(map['id'], path: '$path.id'),
      role: role,
      parts: parts,
      metadata: _decodeMetadataMap(map['metadata'], path: '$path.metadata'),
    );
  }

  JsonMap encodePart(ChatUiPart part) {
    return switch (part) {
      TextUiPart(
        :final text,
        :final isStreaming,
        :final providerMetadata,
      ) =>
        {
          'type': 'text',
          'text': text,
          'isStreaming': isStreaming,
          if (providerMetadata != null)
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
        },
      ReasoningUiPart(
        :final text,
        :final isStreaming,
        :final providerMetadata,
      ) =>
        {
          'type': 'reasoning',
          'text': text,
          'isStreaming': isStreaming,
          if (providerMetadata != null)
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
        },
      ToolUiPart(
        :final toolCallId,
        :final toolName,
        :final state,
        :final input,
        :final inputText,
        :final output,
        :final errorText,
        :final providerExecuted,
        :final isDynamic,
        :final preliminary,
        :final title,
        :final approval,
        :final callProviderMetadata,
        :final resultProviderMetadata,
      ) =>
        {
          'type': 'tool',
          'toolCallId': toolCallId,
          'toolName': toolName,
          'state': state.name,
          'input': ensureJsonValue(input, path: r'$.tool.input'),
          if (inputText != null) 'inputText': inputText,
          'output': ensureJsonValue(output, path: r'$.tool.output'),
          if (errorText != null) 'errorText': errorText,
          'providerExecuted': providerExecuted,
          'isDynamic': isDynamic,
          'preliminary': preliminary,
          if (title != null) 'title': title,
          if (approval != null) 'approval': _encodeApprovalState(approval),
          if (callProviderMetadata != null)
            'callProviderMetadata':
                _encodeProviderMetadata(callProviderMetadata),
          if (resultProviderMetadata != null)
            'resultProviderMetadata':
                _encodeProviderMetadata(resultProviderMetadata),
        },
      SourceUiPart(:final source) => {
          'type': 'source',
          'source': _encodeSourceReference(source),
        },
      FileUiPart(
        :final file,
        :final providerMetadata,
      ) =>
        {
          'type': 'file',
          'file': _encodeGeneratedFile(file),
          if (providerMetadata != null)
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
        },
      ReasoningFileUiPart(
        :final file,
        :final providerMetadata,
      ) =>
        {
          'type': 'reasoning-file',
          'file': _encodeGeneratedFile(file),
          if (providerMetadata != null)
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
        },
      CustomUiPart(
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
      StepBoundaryUiPart(:final stepId) => {
          'type': 'step-boundary',
          'stepId': stepId,
        },
      DataUiPart(:final id, :final key, :final data) => {
          'type': 'data',
          if (id != null) 'id': id,
          'key': key,
          'data': ensureJsonValue(data, path: r'$.dataPart.data'),
        },
    };
  }

  ChatUiPart decodePart(
    Object? value, {
    String path = r'$',
  }) {
    final map = asJsonMap(value, path: path);
    final type = asJsonString(map['type'], path: '$path.type');

    return switch (type) {
      'text' => TextUiPart(
          text: asJsonString(map['text'], path: '$path.text'),
          isStreaming: asNullableJsonBool(map['isStreaming'],
                  path: '$path.isStreaming') ??
              false,
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning' => ReasoningUiPart(
          text: asJsonString(map['text'], path: '$path.text'),
          isStreaming: asNullableJsonBool(map['isStreaming'],
                  path: '$path.isStreaming') ??
              false,
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool' => ToolUiPart(
          toolCallId: asJsonString(map['toolCallId'], path: '$path.toolCallId'),
          toolName: asJsonString(map['toolName'], path: '$path.toolName'),
          state: ToolUiPartState.values.byName(
            asJsonString(map['state'], path: '$path.state'),
          ),
          input: map['input'],
          inputText:
              asNullableJsonString(map['inputText'], path: '$path.inputText'),
          output: map['output'],
          errorText:
              asNullableJsonString(map['errorText'], path: '$path.errorText'),
          providerExecuted: asNullableJsonBool(
                map['providerExecuted'],
                path: '$path.providerExecuted',
              ) ??
              false,
          isDynamic:
              asNullableJsonBool(map['isDynamic'], path: '$path.isDynamic') ??
                  false,
          preliminary: asNullableJsonBool(map['preliminary'],
                  path: '$path.preliminary') ??
              false,
          title: asNullableJsonString(map['title'], path: '$path.title'),
          approval:
              _decodeApprovalState(map['approval'], path: '$path.approval'),
          callProviderMetadata: _decodeProviderMetadata(
            map['callProviderMetadata'],
            path: '$path.callProviderMetadata',
          ),
          resultProviderMetadata: _decodeProviderMetadata(
            map['resultProviderMetadata'],
            path: '$path.resultProviderMetadata',
          ),
        ),
      'source' => SourceUiPart(
          _decodeSourceReference(map['source'], path: '$path.source'),
        ),
      'file' => FileUiPart(
          _decodeGeneratedFile(map['file'], path: '$path.file'),
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-file' => ReasoningFileUiPart(
          _decodeGeneratedFile(map['file'], path: '$path.file'),
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'custom' => CustomUiPart(
          kind: asJsonString(map['kind'], path: '$path.kind'),
          data: map['data'],
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'step-boundary' => StepBoundaryUiPart(
          asJsonString(map['stepId'], path: '$path.stepId'),
        ),
      'data' => DataUiPart<Object?>(
          id: asNullableJsonString(map['id'], path: '$path.id'),
          key: asJsonString(map['key'], path: '$path.key'),
          data: map['data'],
        ),
      _ => throw FormatException(
          'Unsupported chat UI part type "$type" at $path.'),
    };
  }

  JsonMap _encodeMetadataMap(Map<String, Object?> metadata) {
    final result = <String, Object?>{};

    for (final entry in metadata.entries) {
      result[entry.key] = _encodeMetadataValue(entry.key, entry.value);
    }

    return result;
  }

  Map<String, Object?> _decodeMetadataMap(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return const {};
    }

    final map = asJsonMap(value, path: path);
    final result = <String, Object?>{};

    for (final entry in map.entries) {
      result[entry.key] = _decodeMetadataValue(entry.key, entry.value,
          path: '$path.${entry.key}');
    }

    return result;
  }

  Object? _encodeMetadataValue(String key, Object? value) {
    return switch (key) {
      ChatUiMetadataKeys.warnings => _encodeModelWarnings(
          value,
          path: r'$.metadata.warnings',
        ),
      ChatUiMetadataKeys.responseTimestamp =>
        (value as DateTime?)?.toIso8601String(),
      ChatUiMetadataKeys.responseProviderMetadata ||
      ChatUiMetadataKeys.finishProviderMetadata =>
        value == null
            ? null
            : _encodeProviderMetadata(value as ProviderMetadata),
      ChatUiMetadataKeys.finishReason => (value as FinishReason?)?.name,
      ChatUiMetadataKeys.usage =>
        value == null ? null : _encodeUsageStats(value as UsageStats),
      _ => ensureJsonValue(value, path: r'$.metadata'),
    };
  }

  List<JsonMap> _encodeModelWarnings(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return const [];
    }

    if (value is! List) {
      throw FormatException('Expected warnings list at $path.');
    }

    return value.asMap().entries.map((entry) {
      final warning = entry.value;
      if (warning is! ModelWarning) {
        throw FormatException(
          'Expected ModelWarning at $path[${entry.key}], received ${warning.runtimeType}.',
        );
      }

      return _encodeModelWarning(warning);
    }).toList(growable: false);
  }

  Object? _decodeMetadataValue(
    String key,
    Object? value, {
    required String path,
  }) {
    return switch (key) {
      ChatUiMetadataKeys.warnings => asJsonList(value, path: path)
          .asMap()
          .entries
          .map(
            (entry) => _decodeModelWarning(
              entry.value,
              path: '$path[${entry.key}]',
            ),
          )
          .toList(growable: false),
      ChatUiMetadataKeys.responseTimestamp =>
        value == null ? null : DateTime.parse(asJsonString(value, path: path)),
      ChatUiMetadataKeys.responseProviderMetadata ||
      ChatUiMetadataKeys.finishProviderMetadata =>
        _decodeProviderMetadata(value, path: path),
      ChatUiMetadataKeys.finishReason => value == null
          ? null
          : FinishReason.values.byName(asJsonString(value, path: path)),
      ChatUiMetadataKeys.usage => _decodeUsageStats(value, path: path),
      _ => value,
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

  JsonMap _encodeApprovalState(ToolApprovalUiState state) {
    return {
      'approvalId': state.approvalId,
      if (state.approved != null) 'approved': state.approved,
      if (state.reason != null) 'reason': state.reason,
    };
  }

  ToolApprovalUiState? _decodeApprovalState(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return null;
    }

    final map = asJsonMap(value, path: path);
    return ToolApprovalUiState(
      approvalId: asJsonString(map['approvalId'], path: '$path.approvalId'),
      approved: asNullableJsonBool(map['approved'], path: '$path.approved'),
      reason: asNullableJsonString(map['reason'], path: '$path.reason'),
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
      null =>
        uri == null ? SourceReferenceKind.document : SourceReferenceKind.url,
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

  Uri? _decodeUri(
    Object? value, {
    required String path,
  }) {
    final stringValue = asNullableJsonString(value, path: path);
    return stringValue == null ? null : Uri.parse(stringValue);
  }
}
