import '../common/json_codec_common.dart';
import '../common/provider_options.dart';
import '../prompt/prompt_message.dart';
import 'serialization_json_support.dart';

final class PromptToolPartJsonCodec {
  const PromptToolPartJsonCodec();

  JsonMap encode(
    PromptPart part, {
    required JsonMap Function(
      ProviderPromptPartOptions options, {
      required String path,
    }) encodeProviderOptions,
  }) {
    return switch (part) {
      ToolCallPromptPart(
        :final toolCallId,
        :final toolName,
        :final input,
        :final providerExecuted,
        :final isDynamic,
        :final title,
      ) =>
        {
          'type': 'tool-call',
          'toolCallId': toolCallId,
          'toolName': toolName,
          'input': ensureJsonValue(input, path: r'$.toolCall.input'),
          'providerExecuted': providerExecuted,
          'isDynamic': isDynamic,
          if (title != null) 'title': title,
        },
      ToolApprovalRequestPromptPart(:final approvalId, :final toolCallId) => {
          'type': 'tool-approval-request',
          'approvalId': approvalId,
          'toolCallId': toolCallId,
        },
      ToolResultPromptPart(
        :final toolCallId,
        :final toolName,
        :final toolOutput,
      ) =>
        {
          'type': 'tool-result',
          'toolCallId': toolCallId,
          'toolName': toolName,
          'toolOutput': SerializationJsonSupport.encodeToolOutput(
            toolOutput,
            encodeProviderOptions: encodeProviderOptions,
          ),
        },
      ToolApprovalResponsePromptPart(
        :final approvalId,
        :final toolCallId,
        :final approved,
        :final reason,
      ) =>
        {
          'type': 'tool-approval-response',
          'approvalId': approvalId,
          'toolCallId': toolCallId,
          'approved': approved,
          if (reason != null) 'reason': reason,
        },
      _ => throw ArgumentError.value(
          part,
          'part',
          'Expected a tool prompt part.',
        ),
    };
  }

  PromptPart decode(
    JsonMap map, {
    required String type,
    required String path,
    required ProviderPromptPartOptions? providerOptions,
    required ProviderPromptPartOptions? Function(
      Object? value, {
      required String path,
    }) decodeProviderOptions,
  }) {
    return switch (type) {
      'tool-call' => ToolCallPromptPart(
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
          providerOptions: providerOptions,
        ),
      'tool-approval-request' => ToolApprovalRequestPromptPart(
          approvalId: asJsonString(map['approvalId'], path: '$path.approvalId'),
          toolCallId: asJsonString(map['toolCallId'], path: '$path.toolCallId'),
          providerOptions: providerOptions,
        ),
      'tool-result' => ToolResultPromptPart(
          toolCallId: asJsonString(map['toolCallId'], path: '$path.toolCallId'),
          toolName: asJsonString(map['toolName'], path: '$path.toolName'),
          toolOutput: map.containsKey('toolOutput')
              ? SerializationJsonSupport.decodeToolOutput(
                  map['toolOutput'],
                  path: '$path.toolOutput',
                  decodeProviderOptions: decodeProviderOptions,
                )
              : null,
          output: map.containsKey('toolOutput') ? null : map['output'],
          isError: map.containsKey('toolOutput')
              ? false
              : asNullableJsonBool(map['isError'], path: '$path.isError') ??
                  false,
          providerOptions: providerOptions,
        ),
      'tool-approval-response' => ToolApprovalResponsePromptPart(
          approvalId: asJsonString(map['approvalId'], path: '$path.approvalId'),
          toolCallId: asJsonString(map['toolCallId'], path: '$path.toolCallId'),
          approved: asJsonBool(map['approved'], path: '$path.approved'),
          reason: asNullableJsonString(map['reason'], path: '$path.reason'),
          providerOptions: providerOptions,
        ),
      _ => throw FormatException(
          'Unsupported prompt tool part type "$type" at $path.',
        ),
    };
  }
}
