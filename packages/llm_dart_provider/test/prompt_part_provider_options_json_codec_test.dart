import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider/src/serialization/prompt_part_provider_options_json_codec.dart';
import 'package:test/test.dart';

void main() {
  group('PromptPartProviderOptionsJsonCodec', () {
    test('round-trips registered provider prompt part options', () {
      const codec = PromptPartProviderOptionsJsonCodec(
        providerPromptPartOptionsCodecs: [
          _TestPromptPartOptionsJsonCodec(),
        ],
      );

      final encoded = codec.encode(
        const _TestPromptPartOptions('cache'),
        path: r'$.part.providerOptions',
      );

      expect(encoded, {
        'type': _TestPromptPartOptionsJsonCodec.typeId,
        'data': {'mode': 'cache'},
      });

      final decoded = codec.decode(
        encoded,
        path: r'$.part.providerOptions',
      );

      expect(
        decoded,
        isA<_TestPromptPartOptions>().having(
          (options) => options.mode,
          'mode',
          'cache',
        ),
      );
    });

    test('returns null for absent provider options', () {
      const codec = PromptPartProviderOptionsJsonCodec(
        providerPromptPartOptionsCodecs: [],
      );

      expect(codec.decode(null, path: r'$.part.providerOptions'), isNull);
    });

    test('fails fast when encoding unregistered provider options', () {
      const codec = PromptPartProviderOptionsJsonCodec(
        providerPromptPartOptionsCodecs: [],
      );

      expect(
        () => codec.encode(
          const _TestPromptPartOptions('cache'),
          path: r'$.part.providerOptions',
        ),
        throwsUnsupportedError,
      );
    });

    test('rejects unknown provider option type during decode', () {
      const codec = PromptPartProviderOptionsJsonCodec(
        providerPromptPartOptionsCodecs: [],
      );

      expect(
        () => codec.decode(
          {
            'type': 'provider.unknown',
            'data': <String, Object?>{},
          },
          path: r'$.part.providerOptions',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Unsupported providerOptions type "provider.unknown"'),
          ),
        ),
      );
    });
  });
}

final class _TestPromptPartOptions implements ProviderPromptPartOptions {
  final String mode;

  const _TestPromptPartOptions(this.mode);
}

final class _TestPromptPartOptionsJsonCodec
    implements ProviderPromptPartOptionsJsonCodec<_TestPromptPartOptions> {
  static const typeId = 'test.promptPartOptions';

  const _TestPromptPartOptionsJsonCodec();

  @override
  String get type => typeId;

  @override
  bool canEncode(ProviderPromptPartOptions options) =>
      options is _TestPromptPartOptions;

  @override
  JsonMap encode(ProviderPromptPartOptions options) {
    final typed = options as _TestPromptPartOptions;
    return {'mode': typed.mode};
  }

  @override
  _TestPromptPartOptions decode(JsonMap json) {
    return _TestPromptPartOptions(
      asJsonString(json['mode'], path: r'$.data.mode'),
    );
  }
}
