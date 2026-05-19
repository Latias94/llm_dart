import '../common/json_codec_common.dart';
import '../content/content_part.dart';
import '../stream/language_model_stream_event.dart';
import 'serialization_json_support.dart';

final class LanguageModelStreamToolEventJsonCodec {
  static const Set<String> eventTypes = {
    'tool-input-start',
    'tool-input-delta',
    'tool-input-end',
    'tool-input-error',
    'tool-call',
    'tool-result',
    'tool-approval-request',
  };

  const LanguageModelStreamToolEventJsonCodec();

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
      ToolCallEvent(:final toolCall, :final providerMetadata) => {
          'type': 'tool-call',
          'toolCall': _encodeToolCallContent(toolCall),
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      ToolResultEvent(:final toolResult, :final providerMetadata) => {
          'type': 'tool-result',
          'toolResult': _encodeToolResultContent(toolResult),
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
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
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      _ => throw ArgumentError.value(
          event,
          'event',
          'Expected a provider tool stream event.',
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
          toolCallId: asJsonString(
            map['toolCallId'],
            path: '$path.toolCallId',
          ),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      _ => throw FormatException(
          'Unsupported provider tool stream event type "$type" at $path.',
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
      isDynamic: SerializationJsonSupport.decodeDynamicFlag(
        map,
        path: path,
      ),
      title: asNullableJsonString(map['title'], path: '$path.title'),
    );
  }

  JsonMap _encodeToolResultContent(ToolResultContent toolResult) {
    return {
      'toolCallId': toolResult.toolCallId,
      'toolName': toolResult.toolName,
      'toolOutput':
          SerializationJsonSupport.encodeToolOutput(toolResult.toolOutput),
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
      toolOutput: map.containsKey('toolOutput')
          ? SerializationJsonSupport.decodeToolOutput(
              map['toolOutput'],
              path: '$path.toolOutput',
            )
          : null,
      output: map.containsKey('toolOutput') ? null : map['output'],
      isError: map.containsKey('toolOutput')
          ? false
          : asNullableJsonBool(map['isError'], path: '$path.isError') ?? false,
      preliminary: asNullableJsonBool(
            map['preliminary'],
            path: '$path.preliminary',
          ) ??
          false,
      isDynamic: SerializationJsonSupport.decodeDynamicFlag(
        map,
        path: path,
      ),
    );
  }
}
