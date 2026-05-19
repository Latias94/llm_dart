import '../common/json_codec_common.dart';
import '../stream/language_model_stream_event.dart';
import 'serialization_json_support.dart';

final class LanguageModelStreamToolInputEventJsonCodec {
  static const Set<String> eventTypes = {
    'tool-input-start',
    'tool-input-delta',
    'tool-input-end',
    'tool-input-error',
  };

  const LanguageModelStreamToolInputEventJsonCodec();

  bool canDecode(String type) => eventTypes.contains(type);

  JsonMap encode(LanguageModelStreamEvent event) {
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
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
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
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      ToolInputEndEvent(:final toolCallId, :final providerMetadata) => {
          'type': 'tool-input-end',
          'toolCallId': toolCallId,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
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
          'input': ensureJsonValue(input, path: r'$.toolInputError.input'),
          'errorText': errorText,
          'providerExecuted': providerExecuted,
          'isDynamic': isDynamic,
          if (title != null) 'title': title,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      _ => throw ArgumentError.value(
          event,
          'event',
          'Expected a provider tool input stream event.',
        ),
    };
  }

  LanguageModelStreamEvent decode(
    JsonMap map, {
    required String type,
    required String path,
  }) {
    return switch (type) {
      'tool-input-start' => ToolInputStartEvent(
          toolCallId: asJsonString(
            map['toolCallId'],
            path: '$path.toolCallId',
          ),
          toolName: asJsonString(map['toolName'], path: '$path.toolName'),
          providerExecuted: asNullableJsonBool(
                map['providerExecuted'],
                path: '$path.providerExecuted',
              ) ??
              false,
          isDynamic: SerializationJsonSupport.decodeDynamicFlag(
            map,
            path: path,
          ),
          title: asNullableJsonString(map['title'], path: '$path.title'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-input-delta' => ToolInputDeltaEvent(
          toolCallId: asJsonString(
            map['toolCallId'],
            path: '$path.toolCallId',
          ),
          delta: asJsonString(map['delta'], path: '$path.delta'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-input-end' => ToolInputEndEvent(
          toolCallId: asJsonString(
            map['toolCallId'],
            path: '$path.toolCallId',
          ),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-input-error' => ToolInputErrorEvent(
          toolCallId: asJsonString(
            map['toolCallId'],
            path: '$path.toolCallId',
          ),
          toolName: asJsonString(map['toolName'], path: '$path.toolName'),
          input: map['input'],
          errorText: asJsonString(map['errorText'], path: '$path.errorText'),
          providerExecuted: asNullableJsonBool(
                map['providerExecuted'],
                path: '$path.providerExecuted',
              ) ??
              false,
          isDynamic: SerializationJsonSupport.decodeDynamicFlag(
            map,
            path: path,
          ),
          title: asNullableJsonString(map['title'], path: '$path.title'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      _ => throw FormatException(
          'Unsupported provider tool input stream event type "$type" at $path.',
        ),
    };
  }
}
