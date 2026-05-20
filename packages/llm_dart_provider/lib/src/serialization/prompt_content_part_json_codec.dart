import '../common/json_codec_common.dart';
import '../common/provider_options.dart';
import '../content/file_data.dart';
import '../prompt/prompt_message.dart';
import 'serialization_json_support.dart';

final class PromptContentPartJsonCodec {
  const PromptContentPartJsonCodec();

  JsonMap encode(PromptPart part) {
    return switch (part) {
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
      _ => throw ArgumentError.value(
          part,
          'part',
          'Expected a content prompt part.',
        ),
    };
  }

  PromptPart decode(
    JsonMap map, {
    required String type,
    required String path,
    required ProviderPromptPartOptions? providerOptions,
  }) {
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
      _ => throw FormatException(
          'Unsupported prompt content part type "$type" at $path.',
        ),
    };
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
}
