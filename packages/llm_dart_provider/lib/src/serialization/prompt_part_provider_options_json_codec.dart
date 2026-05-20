import '../common/json_codec_common.dart';
import '../common/provider_options.dart';

final class PromptPartProviderOptionsJsonCodec {
  final Iterable<ProviderPromptPartOptionsJsonCodec>
      providerPromptPartOptionsCodecs;

  const PromptPartProviderOptionsJsonCodec({
    required this.providerPromptPartOptionsCodecs,
  });

  JsonMap encode(
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

  ProviderPromptPartOptions? decode(
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
