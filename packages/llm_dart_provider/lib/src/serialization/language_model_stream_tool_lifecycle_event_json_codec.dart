import '../common/json_codec_common.dart';
import '../stream/language_model_stream_event.dart';
import 'serialization_json_support.dart';

final class LanguageModelStreamToolLifecycleEventJsonCodec {
  static const Set<String> eventTypes = {
    'tool-call',
    'tool-result',
    'tool-approval-request',
  };

  const LanguageModelStreamToolLifecycleEventJsonCodec();

  bool canDecode(String type) => eventTypes.contains(type);

  JsonMap encode(LanguageModelStreamEvent event) {
    return switch (event) {
      ToolCallEvent(:final toolCall, :final providerMetadata) => {
          'type': 'tool-call',
          'toolCall': SerializationJsonSupport.encodeToolCallContent(toolCall),
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
              providerMetadata,
            ),
        },
      ToolResultEvent(:final toolResult, :final providerMetadata) => {
          'type': 'tool-result',
          'toolResult':
              SerializationJsonSupport.encodeToolResultContent(toolResult),
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
          'Expected a provider tool lifecycle stream event.',
        ),
    };
  }

  LanguageModelStreamEvent decode(
    JsonMap map, {
    required String type,
    required String path,
  }) {
    return switch (type) {
      'tool-call' => ToolCallEvent(
          toolCall: SerializationJsonSupport.decodeToolCallContent(
            map['toolCall'],
            path: '$path.toolCall',
          ),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-result' => ToolResultEvent(
          toolResult: SerializationJsonSupport.decodeToolResultContent(
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
          'Unsupported provider tool lifecycle stream event type "$type" at $path.',
        ),
    };
  }
}
