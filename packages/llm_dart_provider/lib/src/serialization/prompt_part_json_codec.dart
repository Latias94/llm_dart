import '../common/json_codec_common.dart';
import '../common/provider_options.dart';
import '../content/file_data.dart';
import '../prompt/prompt_message.dart';
import 'serialization_json_support.dart';

final class PromptPartJsonCodec {
  final Iterable<ProviderPromptPartOptionsJsonCodec>
      providerPromptPartOptionsCodecs;

  const PromptPartJsonCodec({
    required this.providerPromptPartOptionsCodecs,
  });

  JsonMap encode(PromptPart part) {
    final JsonMap encoded = switch (part) {
      TextPromptPart(:final text) => {
          'type': 'text',
          'text': text,
        },
      FilePromptPart(
        :final mediaType,
        :final filename,
        :final data,
      ) =>
        {
          'type': 'file',
          'mediaType': mediaType,
          if (filename != null) 'filename': filename,
          'data': SerializationJsonSupport.encodeFileData(data),
        },
      ImagePromptPart(
        :final mediaType,
        :final data,
      ) =>
        {
          'type': 'image',
          'mediaType': mediaType,
          'data': SerializationJsonSupport.encodeFileData(data),
        },
      ReasoningPromptPart(:final text) => {
          'type': 'reasoning',
          'text': text,
        },
      ReasoningFilePromptPart(
        :final mediaType,
        :final filename,
        :final data,
      ) =>
        {
          'type': 'reasoning-file',
          'mediaType': mediaType,
          if (filename != null) 'filename': filename,
          'data': SerializationJsonSupport.encodeFileData(data),
        },
      CustomPromptPart(:final kind, :final data) => {
          'type': 'custom',
          'kind': kind,
          'data': ensureJsonValue(data, path: r'$.custom.data'),
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
            encodeProviderOptions: _encodeProviderPromptPartOptions,
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
    };

    if (part.providerOptions case final providerOptions?) {
      encoded['providerOptions'] = _encodeProviderPromptPartOptions(
        providerOptions,
        path: r'$.part.providerOptions',
      );
    }

    return encoded;
  }

  PromptPart decode(
    Object? value, {
    String path = r'$',
  }) {
    final map = asJsonMap(value, path: path);
    final type = asJsonString(map['type'], path: '$path.type');
    final providerOptions = _decodeProviderPromptPartOptions(
      map['providerOptions'],
      path: '$path.providerOptions',
    );
    _rejectLegacyPromptMetadata(map, path: path);

    return switch (type) {
      'text' => TextPromptPart(
          asJsonString(map['text'], path: '$path.text'),
          providerOptions: providerOptions,
        ),
      'file' => FilePromptPart(
          mediaType: asJsonString(map['mediaType'], path: '$path.mediaType'),
          filename:
              asNullableJsonString(map['filename'], path: '$path.filename'),
          data: _decodeRequiredFileData(map, path: path),
          providerOptions: providerOptions,
        ),
      'image' => ImagePromptPart(
          mediaType: asJsonString(map['mediaType'], path: '$path.mediaType'),
          data: _decodeRequiredFileData(map, path: path),
          providerOptions: providerOptions,
        ),
      'reasoning' => ReasoningPromptPart(
          asJsonString(map['text'], path: '$path.text'),
          providerOptions: providerOptions,
        ),
      'reasoning-file' => ReasoningFilePromptPart(
          mediaType: asJsonString(map['mediaType'], path: '$path.mediaType'),
          filename:
              asNullableJsonString(map['filename'], path: '$path.filename'),
          data: _decodeRequiredFileData(map, path: path),
          providerOptions: providerOptions,
        ),
      'custom' => CustomPromptPart(
          kind: asJsonString(map['kind'], path: '$path.kind'),
          data: map['data'],
          providerOptions: providerOptions,
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
                  decodeProviderOptions: _decodeProviderPromptPartOptions,
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
      _ =>
        throw FormatException('Unsupported prompt part type "$type" at $path.'),
    };
  }

  void _rejectLegacyPromptMetadata(
    JsonMap map, {
    required String path,
  }) {
    if (!map.containsKey('providerMetadata')) {
      return;
    }

    throw FormatException(
      'Legacy prompt replay metadata is no longer supported at $path.providerMetadata. '
      'Use ProviderReplayPromptPartOptions instead.',
    );
  }

  FileData _decodeRequiredFileData(
    JsonMap map, {
    required String path,
  }) {
    return SerializationJsonSupport.decodeFileData(
          map['data'],
          path: '$path.data',
        ) ??
        fileDataFromLegacy(
          uri: SerializationJsonSupport.decodeUri(
            map['uri'],
            path: '$path.uri',
          ),
          bytes: map.containsKey('data')
              ? null
              : SerializationJsonSupport.decodeBytes(
                  map['bytes'],
                  path: '$path.bytes',
                ),
        ) ??
        (throw FormatException('Expected file data, uri, or bytes at $path.'));
  }

  JsonMap _encodeProviderPromptPartOptions(
    ProviderPromptPartOptions options, {
    required String path,
  }) {
    for (final codec in providerPromptPartOptionsCodecs) {
      if (codec.canEncode(options)) {
        return {
          'type': codec.type,
          'data': ensureJsonValue(
            codec.encode(options),
            path: '$path.data',
          ),
        };
      }
    }

    throw UnsupportedError(
      'Cannot serialize providerOptions at $path because no '
      'ProviderPromptPartOptionsJsonCodec was registered for '
      '${options.runtimeType}. Pass the provider codec to PromptJsonCodec.',
    );
  }

  ProviderPromptPartOptions? _decodeProviderPromptPartOptions(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return null;
    }

    final map = asJsonMap(value, path: path);
    final type = asJsonString(map['type'], path: '$path.type');
    final data = asJsonMap(map['data'], path: '$path.data');

    for (final codec in providerPromptPartOptionsCodecs) {
      if (codec.type == type) {
        return codec.decode(data);
      }
    }

    throw FormatException(
      'Unsupported providerOptions type "$type" at $path. Register a '
      'ProviderPromptPartOptionsJsonCodec for this type.',
    );
  }
}
