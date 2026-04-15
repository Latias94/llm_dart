import '../common/model_error.dart';
import '../common/model_warning.dart';
import '../common/provider_metadata.dart';
import '../common/usage_stats.dart';
import '../model/language_model.dart';
import '../ui/chat_ui_message.dart';
import 'json_codec_common.dart';
import 'serialization_json_support.dart';
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
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
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
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
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
                SerializationJsonSupport.encodeProviderMetadata(
                    callProviderMetadata),
          if (resultProviderMetadata != null)
            'resultProviderMetadata':
                SerializationJsonSupport.encodeProviderMetadata(
                    resultProviderMetadata),
        },
      SourceUiPart(:final source) => {
          'type': 'source',
          'source': SerializationJsonSupport.encodeSourceReference(source),
        },
      FileUiPart(
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
      ReasoningFileUiPart(
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
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
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
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning' => ReasoningUiPart(
          text: asJsonString(map['text'], path: '$path.text'),
          isStreaming: asNullableJsonBool(map['isStreaming'],
                  path: '$path.isStreaming') ??
              false,
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
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
          callProviderMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['callProviderMetadata'],
            path: '$path.callProviderMetadata',
          ),
          resultProviderMetadata:
              SerializationJsonSupport.decodeProviderMetadata(
            map['resultProviderMetadata'],
            path: '$path.resultProviderMetadata',
          ),
        ),
      'source' => SourceUiPart(
          SerializationJsonSupport.decodeSourceReference(map['source'],
              path: '$path.source'),
        ),
      'file' => FileUiPart(
          SerializationJsonSupport.decodeGeneratedFile(map['file'],
              path: '$path.file'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-file' => ReasoningFileUiPart(
          SerializationJsonSupport.decodeGeneratedFile(map['file'],
              path: '$path.file'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'custom' => CustomUiPart(
          kind: asJsonString(map['kind'], path: '$path.kind'),
          data: map['data'],
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
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
            : SerializationJsonSupport.encodeProviderMetadata(
                value as ProviderMetadata),
      ChatUiMetadataKeys.errors => _encodeModelErrors(
          value,
          path: r'$.metadata.errors',
        ),
      ChatUiMetadataKeys.finishReason => (value as FinishReason?)?.name,
      ChatUiMetadataKeys.usage => value == null
          ? null
          : SerializationJsonSupport.encodeUsageStats(value as UsageStats),
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

      return SerializationJsonSupport.encodeModelWarning(warning);
    }).toList(growable: false);
  }

  List<JsonMap> _encodeModelErrors(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return const [];
    }

    if (value is! List) {
      throw FormatException('Expected errors list at $path.');
    }

    return value
        .map((entry) => SerializationJsonSupport.encodeModelError(
            ModelError.fromUnknown(entry)))
        .toList(growable: false);
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
            (entry) => SerializationJsonSupport.decodeModelWarning(
              entry.value,
              path: '$path[${entry.key}]',
            ),
          )
          .toList(growable: false),
      ChatUiMetadataKeys.responseTimestamp =>
        value == null ? null : DateTime.parse(asJsonString(value, path: path)),
      ChatUiMetadataKeys.responseProviderMetadata ||
      ChatUiMetadataKeys.finishProviderMetadata =>
        SerializationJsonSupport.decodeProviderMetadata(value, path: path),
      ChatUiMetadataKeys.errors => asJsonList(value, path: path)
          .asMap()
          .entries
          .map(
            (entry) => SerializationJsonSupport.decodeModelError(
              entry.value,
              path: '$path[${entry.key}]',
            ),
          )
          .toList(growable: false),
      ChatUiMetadataKeys.finishReason => value == null
          ? null
          : FinishReason.values.byName(asJsonString(value, path: path)),
      ChatUiMetadataKeys.usage =>
        SerializationJsonSupport.decodeUsageStats(value, path: path),
      _ => value,
    };
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
}
