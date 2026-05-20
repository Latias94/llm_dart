import '../common/json_codec_common.dart';
import '../common/provider_options.dart';
import '../tool/tool_output.dart';
import 'serialization_file_json_codec.dart';

final class SerializationToolOutputPartJsonCodec {
  const SerializationToolOutputPartJsonCodec();

  JsonMap encodeToolOutputContentPart(
    ToolOutputContentPart part, {
    String path = r'$.toolOutput.parts[]',
    JsonMap Function(
      ProviderPromptPartOptions options, {
      required String path,
    })? encodeProviderOptions,
  }) {
    final JsonMap encoded = switch (part) {
      TextToolOutputContentPart(:final text) => {
          'type': 'text',
          'text': text,
        },
      JsonToolOutputContentPart(:final value) => {
          'type': 'json',
          'value': ensureJsonValue(
            value,
            path: r'$.toolOutput.parts[].value',
          ),
        },
      FileToolOutputContentPart(
        :final mediaType,
        :final filename,
        :final data,
      ) =>
        {
          'type': 'file',
          'mediaType': mediaType,
          if (filename != null) 'filename': filename,
          'data': const SerializationFileJsonCodec().encodeFileData(data),
        },
      CustomToolOutputContentPart(:final kind, :final data) => {
          'type': 'custom',
          'kind': kind,
          'data': ensureJsonValue(
            data,
            path: r'$.toolOutput.parts[].data',
          ),
        },
    };

    if (part.providerOptions case final providerOptions?) {
      encoded['providerOptions'] = _encodeProviderOptions(
        providerOptions,
        path: '$path.providerOptions',
        encodeProviderOptions: encodeProviderOptions,
      );
    }

    return encoded;
  }

  ToolOutputContentPart decodeToolOutputContentPart(
    Object? value, {
    required String path,
    ProviderPromptPartOptions? Function(
      Object? value, {
      required String path,
    })? decodeProviderOptions,
  }) {
    final map = asJsonMap(value, path: path);
    final type = asJsonString(map['type'], path: '$path.type');
    final providerOptions = _decodeProviderOptions(
      map['providerOptions'],
      path: '$path.providerOptions',
      decodeProviderOptions: decodeProviderOptions,
    );
    if (map.containsKey('providerMetadata')) {
      throw FormatException(
        'Legacy prompt replay metadata is no longer supported at $path.providerMetadata. '
        'Use ProviderReplayPromptPartOptions instead.',
      );
    }

    return switch (type) {
      'text' => TextToolOutputContentPart(
          asJsonString(map['text'], path: '$path.text'),
          providerOptions: providerOptions,
        ),
      'json' => JsonToolOutputContentPart(
          map['value'],
          providerOptions: providerOptions,
        ),
      'file' => FileToolOutputContentPart(
          mediaType: asJsonString(map['mediaType'], path: '$path.mediaType'),
          filename:
              asNullableJsonString(map['filename'], path: '$path.filename'),
          data: const SerializationFileJsonCodec()
              .decodeRequiredFileDataFromMap(map, path: path),
          providerOptions: providerOptions,
        ),
      'custom' => CustomToolOutputContentPart(
          kind: asJsonString(map['kind'], path: '$path.kind'),
          data: map['data'],
          providerOptions: providerOptions,
        ),
      _ => throw FormatException(
          'Unsupported tool output content part type "$type" at $path.',
        ),
    };
  }

  JsonMap _encodeProviderOptions(
    ProviderPromptPartOptions options, {
    required String path,
    required JsonMap Function(
      ProviderPromptPartOptions options, {
      required String path,
    })? encodeProviderOptions,
  }) {
    if (encodeProviderOptions == null) {
      throw UnsupportedError(
        'Cannot serialize providerOptions at $path without a '
        'provider prompt part options encoder.',
      );
    }

    return encodeProviderOptions(options, path: path);
  }

  ProviderPromptPartOptions? _decodeProviderOptions(
    Object? value, {
    required String path,
    required ProviderPromptPartOptions? Function(
      Object? value, {
      required String path,
    })? decodeProviderOptions,
  }) {
    if (value == null) {
      return null;
    }

    if (decodeProviderOptions == null) {
      throw FormatException(
        'Cannot decode providerOptions at $path without a provider prompt '
        'part options decoder.',
      );
    }

    return decodeProviderOptions(value, path: path);
  }
}
