import '../prompt/prompt_message.dart';
import 'json_codec_common.dart';
import 'serialization_json_support.dart';
import 'serialization_protocol.dart';

final class PromptJsonCodec {
  static const envelopeKind = 'prompt-messages';

  const PromptJsonCodec();

  JsonMap encodeMessages(List<PromptMessage> messages) {
    return {
      'schemaVersion': llmDartJsonSchemaVersion,
      'kind': envelopeKind,
      'data': {
        'messages': messages.map(encodeMessage).toList(growable: false),
      },
    };
  }

  List<PromptMessage> decodeMessages(Object? envelope) {
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

  JsonMap encodeMessage(PromptMessage message) {
    return {
      'role': message.role.name,
      'parts': message.parts.map(encodePart).toList(growable: false),
      if (message case ToolPromptMessage(:final toolName)) 'toolName': toolName,
    };
  }

  PromptMessage decodeMessage(
    Object? value, {
    String path = r'$',
  }) {
    final map = asJsonMap(value, path: path);
    final role = PromptRole.values.byName(
      asJsonString(map['role'], path: '$path.role'),
    );
    final parts = asJsonList(map['parts'], path: '$path.parts')
        .asMap()
        .entries
        .map((entry) =>
            decodePart(entry.value, path: '$path.parts[${entry.key}]'))
        .toList(growable: false);

    return switch (role) {
      PromptRole.system => SystemPromptMessage(parts: parts),
      PromptRole.user => UserPromptMessage(parts: parts),
      PromptRole.assistant => AssistantPromptMessage(parts: parts),
      PromptRole.tool => ToolPromptMessage(
          toolName: asJsonString(map['toolName'], path: '$path.toolName'),
          parts: parts,
        ),
    };
  }

  JsonMap encodePart(PromptPart part) {
    return switch (part) {
      TextPromptPart(
        :final text,
        :final providerMetadata,
      ) =>
        {
          'type': 'text',
          'text': text,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      FilePromptPart(
        :final mediaType,
        :final filename,
        :final uri,
        :final bytes,
        :final providerMetadata,
      ) =>
        {
          'type': 'file',
          'mediaType': mediaType,
          if (filename != null) 'filename': filename,
          if (uri != null) 'uri': uri.toString(),
          if (bytes != null)
            'bytes': SerializationJsonSupport.encodeBytes(bytes),
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      ImagePromptPart(
        :final mediaType,
        :final uri,
        :final bytes,
        :final providerMetadata,
      ) =>
        {
          'type': 'image',
          'mediaType': mediaType,
          if (uri != null) 'uri': uri.toString(),
          if (bytes != null)
            'bytes': SerializationJsonSupport.encodeBytes(bytes),
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      ReasoningPromptPart(
        :final text,
        :final providerMetadata,
      ) =>
        {
          'type': 'reasoning',
          'text': text,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      ReasoningFilePromptPart(
        :final mediaType,
        :final filename,
        :final uri,
        :final bytes,
        :final providerMetadata,
      ) =>
        {
          'type': 'reasoning-file',
          'mediaType': mediaType,
          if (filename != null) 'filename': filename,
          if (uri != null) 'uri': uri.toString(),
          if (bytes != null)
            'bytes': SerializationJsonSupport.encodeBytes(bytes),
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      CustomPromptPart(
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
      ToolCallPromptPart(
        :final toolCallId,
        :final toolName,
        :final input,
        :final providerExecuted,
        :final isDynamic,
        :final title,
        :final providerMetadata,
      ) =>
        {
          'type': 'tool-call',
          'toolCallId': toolCallId,
          'toolName': toolName,
          'input': ensureJsonValue(input, path: r'$.toolCall.input'),
          'providerExecuted': providerExecuted,
          'isDynamic': isDynamic,
          if (title != null) 'title': title,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      ToolApprovalRequestPromptPart(
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
                providerMetadata),
        },
      ToolResultPromptPart(
        :final toolCallId,
        :final toolName,
        :final output,
        :final isError,
        :final providerMetadata,
      ) =>
        {
          'type': 'tool-result',
          'toolCallId': toolCallId,
          'toolName': toolName,
          'output': ensureJsonValue(output, path: r'$.toolResult.output'),
          'isError': isError,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
      ToolApprovalResponsePromptPart(
        :final approvalId,
        :final toolCallId,
        :final approved,
        :final reason,
        :final providerMetadata,
      ) =>
        {
          'type': 'tool-approval-response',
          'approvalId': approvalId,
          'toolCallId': toolCallId,
          'approved': approved,
          if (reason != null) 'reason': reason,
          if (providerMetadata != null)
            'providerMetadata': SerializationJsonSupport.encodeProviderMetadata(
                providerMetadata),
        },
    };
  }

  PromptPart decodePart(
    Object? value, {
    String path = r'$',
  }) {
    final map = asJsonMap(value, path: path);
    final type = asJsonString(map['type'], path: '$path.type');

    return switch (type) {
      'text' => TextPromptPart(
          asJsonString(map['text'], path: '$path.text'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'file' => FilePromptPart(
          mediaType: asJsonString(map['mediaType'], path: '$path.mediaType'),
          filename:
              asNullableJsonString(map['filename'], path: '$path.filename'),
          uri:
              SerializationJsonSupport.decodeUri(map['uri'], path: '$path.uri'),
          bytes: SerializationJsonSupport.decodeBytes(map['bytes'],
              path: '$path.bytes'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'image' => ImagePromptPart(
          mediaType: asJsonString(map['mediaType'], path: '$path.mediaType'),
          uri:
              SerializationJsonSupport.decodeUri(map['uri'], path: '$path.uri'),
          bytes: SerializationJsonSupport.decodeBytes(map['bytes'],
              path: '$path.bytes'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning' => ReasoningPromptPart(
          asJsonString(map['text'], path: '$path.text'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'reasoning-file' => ReasoningFilePromptPart(
          mediaType: asJsonString(map['mediaType'], path: '$path.mediaType'),
          filename:
              asNullableJsonString(map['filename'], path: '$path.filename'),
          uri:
              SerializationJsonSupport.decodeUri(map['uri'], path: '$path.uri'),
          bytes: SerializationJsonSupport.decodeBytes(map['bytes'],
              path: '$path.bytes'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'custom' => CustomPromptPart(
          kind: asJsonString(map['kind'], path: '$path.kind'),
          data: map['data'],
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-call' => ToolCallPromptPart(
          toolCallId: asJsonString(map['toolCallId'], path: '$path.toolCallId'),
          toolName: asJsonString(map['toolName'], path: '$path.toolName'),
          input: map['input'],
          providerExecuted: asNullableJsonBool(
                map['providerExecuted'],
                path: '$path.providerExecuted',
              ) ??
              false,
          isDynamic: asNullableJsonBool(
                map['isDynamic'],
                path: '$path.isDynamic',
              ) ??
              false,
          title: asNullableJsonString(map['title'], path: '$path.title'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-approval-request' => ToolApprovalRequestPromptPart(
          approvalId: asJsonString(map['approvalId'], path: '$path.approvalId'),
          toolCallId: asJsonString(map['toolCallId'], path: '$path.toolCallId'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-result' => ToolResultPromptPart(
          toolCallId: asJsonString(map['toolCallId'], path: '$path.toolCallId'),
          toolName: asJsonString(map['toolName'], path: '$path.toolName'),
          output: map['output'],
          isError: asNullableJsonBool(map['isError'], path: '$path.isError') ??
              false,
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'tool-approval-response' => ToolApprovalResponsePromptPart(
          approvalId: asJsonString(map['approvalId'], path: '$path.approvalId'),
          toolCallId: asJsonString(map['toolCallId'], path: '$path.toolCallId'),
          approved: asJsonBool(map['approved'], path: '$path.approved'),
          reason: asNullableJsonString(map['reason'], path: '$path.reason'),
          providerMetadata: SerializationJsonSupport.decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      _ =>
        throw FormatException('Unsupported prompt part type "$type" at $path.'),
    };
  }
}
