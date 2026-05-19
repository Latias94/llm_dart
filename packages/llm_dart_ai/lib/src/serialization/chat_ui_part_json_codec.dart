import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../ui/chat_ui_message.dart';
import 'chat_ui_tool_part_json_codec.dart';

final class ChatUiPartJsonCodec {
  const ChatUiPartJsonCodec();

  JsonMap encode(ChatUiPart part) {
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

  ChatUiPart decode(
    Object? value, {
    String path = r'$',
  }) {
    final map = asJsonMap(value, path: path);
    final type = asJsonString(map['type'], path: '$path.type');

    return switch (type) {
      'text' => TextUiPart(
          text: asJsonString(map['text'], path: '$path.text'),
          isStreaming: asNullableJsonBool(
                map['isStreaming'],
                path: '$path.isStreaming',
              ) ??
              false,
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning' => ReasoningUiPart(
          text: asJsonString(map['text'], path: '$path.text'),
          isStreaming: asNullableJsonBool(
                map['isStreaming'],
                path: '$path.isStreaming',
              ) ??
              false,
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool' => const ChatUiToolPartJsonCodec().decode(map, path: path),
      'source' => SourceUiPart(
          SerializationJsonSupport.decodeSourceReference(
            map['source'],
            path: '$path.source',
          ),
        ),
      'file' => FileUiPart(
          SerializationJsonSupport.decodeGeneratedFile(
            map['file'],
            path: '$path.file',
          ),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-file' => ReasoningFileUiPart(
          SerializationJsonSupport.decodeGeneratedFile(
            map['file'],
            path: '$path.file',
          ),
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
}
