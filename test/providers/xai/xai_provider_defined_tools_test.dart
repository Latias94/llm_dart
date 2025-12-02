import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('XAI provider-defined tools', () {
    test('webSearch() creates xai.web_search spec with args', () {
      final factory = createXAI(apiKey: 'test-key');

      final spec = factory.providerTools.webSearch(
        allowedDomains: const ['example.com'],
        excludedDomains: const ['blocked.com'],
        enableImageUnderstanding: true,
      );

      expect(spec.id, equals('xai.web_search'));
      expect(spec.args['allowedDomains'], equals(['example.com']));
      expect(spec.args['excludedDomains'], equals(['blocked.com']));
      expect(spec.args['enableImageUnderstanding'], isTrue);
    });

    test('xSearch() creates xai.x_search spec with args', () {
      final factory = createXAI(apiKey: 'test-key');

      final spec = factory.providerTools.xSearch(
        allowedXHandles: const ['@foo'],
        excludedXHandles: const ['@bar'],
        fromDate: '2024-01-01',
        toDate: '2024-01-31',
        enableImageUnderstanding: true,
        enableVideoUnderstanding: false,
      );

      expect(spec.id, equals('xai.x_search'));
      expect(spec.args['allowedXHandles'], equals(['@foo']));
      expect(spec.args['excludedXHandles'], equals(['@bar']));
      expect(spec.args['fromDate'], equals('2024-01-01'));
      expect(spec.args['toDate'], equals('2024-01-31'));
      expect(spec.args['enableImageUnderstanding'], isTrue);
      expect(spec.args['enableVideoUnderstanding'], isFalse);
    });
  });
}

