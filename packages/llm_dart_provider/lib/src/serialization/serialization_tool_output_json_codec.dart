import '../common/json_codec_common.dart';
import '../common/provider_metadata.dart';
import '../common/provider_options.dart';
import '../tool/tool_output.dart';
import 'serialization_metadata_json_codec.dart';
import 'serialization_tool_output_part_json_codec.dart';

final class SerializationToolOutputJsonCodec {
  const SerializationToolOutputJsonCodec();

  JsonMap encodeToolOutput(
    ToolOutput output, {
    JsonMap Function(
      ProviderPromptPartOptions options, {
      required String path,
    })? encodeProviderOptions,
  }) {
    return switch (output) {
      TextToolOutput(:final value, :final providerMetadata) => {
          'type': 'text',
          'value': value,
          if (providerMetadata != null)
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
        },
      JsonToolOutput(:final value, :final providerMetadata) => {
          'type': 'json',
          'value': ensureJsonValue(value, path: r'$.toolOutput.value'),
          if (providerMetadata != null)
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
        },
      ErrorTextToolOutput(:final value, :final providerMetadata) => {
          'type': 'error-text',
          'value': value,
          if (providerMetadata != null)
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
        },
      ErrorJsonToolOutput(:final value, :final providerMetadata) => {
          'type': 'error-json',
          'value': ensureJsonValue(value, path: r'$.toolOutput.value'),
          if (providerMetadata != null)
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
        },
      ExecutionDeniedToolOutput(:final reason, :final providerMetadata) => {
          'type': 'execution-denied',
          if (reason != null) 'reason': reason,
          if (providerMetadata != null)
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
        },
      ContentToolOutput(:final parts, :final providerMetadata) => {
          'type': 'content',
          'parts': [
            for (final entry in parts.asMap().entries)
              encodeToolOutputContentPart(
                entry.value,
                path: '\$.toolOutput.parts[${entry.key}]',
                encodeProviderOptions: encodeProviderOptions,
              ),
          ],
          if (providerMetadata != null)
            'providerMetadata': _encodeProviderMetadata(providerMetadata),
        },
    };
  }

  ToolOutput decodeToolOutput(
    Object? value, {
    required String path,
    ProviderPromptPartOptions? Function(
      Object? value, {
      required String path,
    })? decodeProviderOptions,
  }) {
    final map = asJsonMap(value, path: path);
    final type = asJsonString(map['type'], path: '$path.type');

    return switch (type) {
      'text' => TextToolOutput(
          asJsonString(map['value'], path: '$path.value'),
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'json' => JsonToolOutput(
          map['value'],
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'error-text' => ErrorTextToolOutput(
          asJsonString(map['value'], path: '$path.value'),
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'error-json' => ErrorJsonToolOutput(
          map['value'],
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'execution-denied' => ExecutionDeniedToolOutput.withMetadata(
          reason: asNullableJsonString(map['reason'], path: '$path.reason'),
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      'content' => ContentToolOutput(
          parts: [
            for (final entry in asJsonList(map['parts'], path: '$path.parts')
                .asMap()
                .entries)
              decodeToolOutputContentPart(
                entry.value,
                path: '$path.parts[${entry.key}]',
                decodeProviderOptions: decodeProviderOptions,
              ),
          ],
          providerMetadata: _decodeProviderMetadata(
            map['providerMetadata'],
            path: '$path.providerMetadata',
          ),
        ),
      _ =>
        throw FormatException('Unsupported tool output type "$type" at $path.'),
    };
  }

  JsonMap encodeToolOutputContentPart(
    ToolOutputContentPart part, {
    String path = r'$.toolOutput.parts[]',
    JsonMap Function(
      ProviderPromptPartOptions options, {
      required String path,
    })? encodeProviderOptions,
  }) =>
      const SerializationToolOutputPartJsonCodec().encodeToolOutputContentPart(
        part,
        path: path,
        encodeProviderOptions: encodeProviderOptions,
      );

  ToolOutputContentPart decodeToolOutputContentPart(
    Object? value, {
    required String path,
    ProviderPromptPartOptions? Function(
      Object? value, {
      required String path,
    })? decodeProviderOptions,
  }) =>
      const SerializationToolOutputPartJsonCodec().decodeToolOutputContentPart(
        value,
        path: path,
        decodeProviderOptions: decodeProviderOptions,
      );

  JsonMap _encodeProviderMetadata(ProviderMetadata metadata) {
    return const SerializationMetadataJsonCodec()
        .encodeProviderMetadata(metadata);
  }

  ProviderMetadata? _decodeProviderMetadata(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return null;
    }

    return const SerializationMetadataJsonCodec().decodeProviderMetadata(
      value,
      path: path,
    );
  }
}
