import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;

import '../stream/text_stream_event.dart';

final class TextStreamToolEventJsonCodec {
  static const Set<String> eventTypes = {
    'tool-input-start',
    'tool-input-delta',
    'tool-input-end',
    'tool-input-error',
    'tool-call',
    'tool-result',
    'tool-approval-request',
    'tool-output-denied',
  };

  const TextStreamToolEventJsonCodec();

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
      _ => throw ArgumentError.value(
          event,
          'event',
          'Expected a tool text stream event.',
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
      _ => throw FormatException(
          'Unsupported tool text stream event type "$type" at $path.',
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
}
