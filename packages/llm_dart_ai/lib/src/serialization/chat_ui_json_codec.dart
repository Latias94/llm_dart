import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../ui/chat_ui_message.dart';
import 'chat_ui_tool_part_json_codec.dart';

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
      ToolUiPart() => const ChatUiToolPartJsonCodec().encode(part),
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
      'tool' => const ChatUiToolPartJsonCodec().decode(map, path: path),
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
      ChatUiMetadataKeys.finishReason ||
      ChatUiMetadataKeys.runFinishReason =>
        (value as FinishReason?)?.name,
      ChatUiMetadataKeys.usage || ChatUiMetadataKeys.runUsage => value == null
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
      ChatUiMetadataKeys.finishReason ||
      ChatUiMetadataKeys.runFinishReason =>
        value == null
            ? null
            : FinishReason.values.byName(asJsonString(value, path: path)),
      ChatUiMetadataKeys.usage ||
      ChatUiMetadataKeys.runUsage =>
        SerializationJsonSupport.decodeUsageStats(value, path: path),
      _ => value,
    };
  }
}
