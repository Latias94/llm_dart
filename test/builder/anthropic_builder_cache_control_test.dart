import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('AnthropicBuilder', () {
    test('cacheControl() writes providerOptions[anthropic][cacheControl]', () {
      final builder = ai().anthropic(
        (anthropic) => anthropic.cacheControl(
          const {'type': 'ephemeral', 'ttl': '1h'},
        ),
      );

      expect(
        builder.currentConfig.getProviderOption<Map<String, dynamic>>(
          'anthropic',
          'cacheControl',
        ),
        equals({'type': 'ephemeral', 'ttl': '1h'}),
      );
    });

    test('cacheControlEphemeral() writes an ephemeral cache control shape', () {
      final builder = ai().anthropic(
        (anthropic) => anthropic.cacheControlEphemeral(ttl: '5m'),
      );

      expect(
        builder.currentConfig.getProviderOption<Map<String, dynamic>>(
          'anthropic',
          'cacheControl',
        ),
        equals({'type': 'ephemeral', 'ttl': '5m'}),
      );
    });
  });
}

