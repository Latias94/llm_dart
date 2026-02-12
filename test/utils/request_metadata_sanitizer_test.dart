library;

import 'package:llm_dart_provider_utils/utils/request_metadata_sanitizer.dart';
import 'package:test/test.dart';

void main() {
  group('sanitizeRequestBodyForMetadata', () {
    test('truncates long strings', () {
      final input = {
        'prompt': 'a' * 50,
      };

      final sanitized = sanitizeRequestBodyForMetadata(
        input,
        maxStringLength: 10,
      );

      expect(sanitized, isA<Map>());
      final map = sanitized as Map;
      expect(map['prompt'], startsWith('aaaaaaaaaa'));
      expect(map['prompt'], contains('truncated'));
    });

    test('omits binary-like long strings by key', () {
      final input = {
        'image_base64': 'b' * 200,
      };

      final sanitized = sanitizeRequestBodyForMetadata(input);
      final map = sanitized as Map;
      expect(map['image_base64'], contains('omitted'));
    });

    test('truncates long lists', () {
      final input = {
        'items': List.generate(10, (i) => i),
      };

      final sanitized = sanitizeRequestBodyForMetadata(
        input,
        maxListLength: 3,
      );

      final map = sanitized as Map;
      final items = map['items'] as List;
      expect(items, hasLength(4));
      expect(items.last, contains('truncated'));
    });
  });
}
