import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;

import '../stream/text_stream_event.dart';

final class TextStreamToolLifecycleEventJsonCodec {
  static const Set<String> eventTypes = {
    'tool-call',
    'tool-result',
    'tool-approval-request',
    'tool-output-denied',
  };

  const TextStreamToolLifecycleEventJsonCodec();

  bool canDecode(String type) => eventTypes.contains(type);

  provider.JsonMap encode(TextStreamEvent event) {
    return switch (event) {
      ToolCallEvent(:final toolCall, :final providerMetadata) => {
          'type': 'tool-call',
          'toolCall':
              provider.SerializationJsonSupport.encodeToolCallContent(toolCall),
          if (providerMetadata != null)
            'providerMetadata':
                provider.SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      ToolResultEvent(:final toolResult, :final providerMetadata) => {
          'type': 'tool-result',
          'toolResult':
              provider.SerializationJsonSupport.encodeToolResultContent(
                  toolResult),
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
          'Expected a tool lifecycle text stream event.',
        ),
    };
  }

  TextStreamEvent decode(
    provider.JsonMap map, {
    required String type,
    required String path,
  }) {
    return switch (type) {
      'tool-call' => ToolCallEvent(
          toolCall: provider.SerializationJsonSupport.decodeToolCallContent(
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
          toolResult: provider.SerializationJsonSupport.decodeToolResultContent(
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
          'Unsupported tool lifecycle text stream event type "$type" at $path.',
        ),
    };
  }
}
