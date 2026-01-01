import 'package:test/test.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

void main() {
  group('LogRedactor', () {
    test('redacts common auth headers case-insensitively', () {
      final headers = <String, dynamic>{
        'Authorization': 'Bearer sk-secret',
        'x-api-key': 'secret',
        'Xi-Api-Key': 'secret',
        'X-Goog-Api-Key': 'secret',
        'Content-Type': 'application/json',
        'User-Agent': 'test',
      };

      final redacted = LogRedactor.redactHeaders(headers);

      expect(redacted['Authorization'], LogRedactor.redacted);
      expect(redacted['x-api-key'], LogRedactor.redacted);
      expect(redacted['Xi-Api-Key'], LogRedactor.redacted);
      expect(redacted['X-Goog-Api-Key'], LogRedactor.redacted);
      expect(redacted['Content-Type'], 'application/json');
      expect(redacted['User-Agent'], 'test');
    });

    test('redacts token-like header names', () {
      final headers = <String, dynamic>{
        'X-Access-Token': 'secret',
        'refresh-token': 'secret',
        'X-Not-Sensitive': 'ok',
      };

      final redacted = LogRedactor.redactHeaders(headers);

      expect(redacted['X-Access-Token'], LogRedactor.redacted);
      expect(redacted['refresh-token'], LogRedactor.redacted);
      expect(redacted['X-Not-Sensitive'], 'ok');
    });

    test('returns empty map for empty input', () {
      expect(LogRedactor.redactHeaders(const {}), const {});
    });
  });
}
