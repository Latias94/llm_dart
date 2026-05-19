import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;

import '../stream/text_stream_event.dart';

final class TextStreamToolInputEventJsonCodec {
  static const Set<String> eventTypes = {
    'tool-input-start',
    'tool-input-delta',
    'tool-input-end',
    'tool-input-error',
  };

  const TextStreamToolInputEventJsonCodec();

  bool canDecode(String type) => eventTypes.contains(type);

  provider.JsonMap encode(TextStreamEvent event) {
    return switch (event) {
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
      _ => throw ArgumentError.value(
          event,
          'event',
          'Expected a tool input text stream event.',
        ),
    };
  }

  TextStreamEvent decode(
    provider.JsonMap map, {
    required String type,
    required String path,
  }) {
    return switch (type) {
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
      _ => throw FormatException(
          'Unsupported tool input text stream event type "$type" at $path.',
        ),
    };
  }
}
