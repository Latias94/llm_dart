import 'dart:convert';

import '../prompt/prompt_message.dart';
import 'json_codec_common.dart';
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
      TextPromptPart(:final text) => {
          'type': 'text',
          'text': text,
        },
      FilePromptPart(
        :final mediaType,
        :final filename,
        :final uri,
        :final bytes,
      ) =>
        {
          'type': 'file',
          'mediaType': mediaType,
          if (filename != null) 'filename': filename,
          if (uri != null) 'uri': uri.toString(),
          if (bytes != null) 'bytes': _encodeBytes(bytes),
        },
      ImagePromptPart(
        :final mediaType,
        :final uri,
        :final bytes,
      ) =>
        {
          'type': 'image',
          'mediaType': mediaType,
          if (uri != null) 'uri': uri.toString(),
          if (bytes != null) 'bytes': _encodeBytes(bytes),
        },
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
      ToolApprovalRequestPromptPart(
        :final approvalId,
        :final toolCallId,
      ) =>
        {
          'type': 'tool-approval-request',
          'approvalId': approvalId,
          'toolCallId': toolCallId,
        },
      ToolResultPromptPart(
        :final toolCallId,
        :final toolName,
        :final output,
        :final isError,
      ) =>
        {
          'type': 'tool-result',
          'toolCallId': toolCallId,
          'toolName': toolName,
          'output': ensureJsonValue(output, path: r'$.toolResult.output'),
          'isError': isError,
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
        ),
      'file' => FilePromptPart(
          mediaType: asJsonString(map['mediaType'], path: '$path.mediaType'),
          filename:
              asNullableJsonString(map['filename'], path: '$path.filename'),
          uri: _decodeUri(map['uri'], path: '$path.uri'),
          bytes: _decodeBytes(map['bytes'], path: '$path.bytes'),
        ),
      'image' => ImagePromptPart(
          mediaType: asJsonString(map['mediaType'], path: '$path.mediaType'),
          uri: _decodeUri(map['uri'], path: '$path.uri'),
          bytes: _decodeBytes(map['bytes'], path: '$path.bytes'),
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
        ),
      'tool-approval-request' => ToolApprovalRequestPromptPart(
          approvalId: asJsonString(map['approvalId'], path: '$path.approvalId'),
          toolCallId: asJsonString(map['toolCallId'], path: '$path.toolCallId'),
        ),
      'tool-result' => ToolResultPromptPart(
          toolCallId: asJsonString(map['toolCallId'], path: '$path.toolCallId'),
          toolName: asJsonString(map['toolName'], path: '$path.toolName'),
          output: map['output'],
          isError: asNullableJsonBool(map['isError'], path: '$path.isError') ??
              false,
        ),
      'tool-approval-response' => ToolApprovalResponsePromptPart(
          approvalId: asJsonString(map['approvalId'], path: '$path.approvalId'),
          toolCallId: asJsonString(map['toolCallId'], path: '$path.toolCallId'),
          approved: asJsonBool(map['approved'], path: '$path.approved'),
          reason: asNullableJsonString(map['reason'], path: '$path.reason'),
        ),
      _ =>
        throw FormatException('Unsupported prompt part type "$type" at $path.'),
    };
  }

  JsonMap _encodeBytes(List<int> bytes) {
    return {
      'encoding': 'base64',
      'data': base64Encode(bytes),
    };
  }

  List<int>? _decodeBytes(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return null;
    }

    final map = asJsonMap(value, path: path);
    final encoding = asJsonString(map['encoding'], path: '$path.encoding');
    if (encoding != 'base64') {
      throw FormatException('Unsupported byte encoding "$encoding" at $path.');
    }

    return base64Decode(asJsonString(map['data'], path: '$path.data'));
  }

  Uri? _decodeUri(
    Object? value, {
    required String path,
  }) {
    final stringValue = asNullableJsonString(value, path: path);
    return stringValue == null ? null : Uri.parse(stringValue);
  }
}
