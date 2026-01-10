import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('OpenRouterBuilder headers', () {
    test('appInfo writes HTTP-Referer and X-Title headers', () {
      final builder = ai().openRouter(
        (openrouter) => openrouter.appInfo(
          referer: 'https://example.com',
          title: 'my-app',
        ),
      );

      final headers =
          builder.currentConfig.getProviderOption<Map<String, dynamic>>(
        'openrouter',
        'headers',
      );
      expect(headers, isNotNull);
      expect(headers!['HTTP-Referer'], equals('https://example.com'));
      expect(headers['X-Title'], equals('my-app'));
    });
  });
}
