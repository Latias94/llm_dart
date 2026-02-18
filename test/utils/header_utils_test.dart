import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:test/test.dart';

void main() {
  group('header utils', () {
    test('setHeaderCaseInsensitive replaces existing keys', () {
      final headers = <String, String>{
        'authorization': 'a',
        'Authorization': 'b',
      };

      setHeaderCaseInsensitive(headers, 'Authorization', 'c');

      final keys = headers.keys
          .where((k) => k.toLowerCase() == 'authorization')
          .toList(growable: false);
      expect(keys, hasLength(1));
      expect(headers[keys.single], 'c');
    });

    test('mergeHeadersCaseInsensitive overrides keys ignoring case', () {
      final out = mergeHeadersCaseInsensitive(
        {'Authorization': 'a', 'X': '1'},
        {'authorization': 'b'},
      );

      final keys = out.keys
          .where((k) => k.toLowerCase() == 'authorization')
          .toList(growable: false);
      expect(keys, hasLength(1));
      expect(out[keys.single], 'b');
      expect(out['X'], '1');
    });

    test('mergeHeadersCaseInsensitive concatenates User-Agent', () {
      final out = mergeHeadersCaseInsensitive(
        {'User-Agent': 'default/1.0'},
        {'user-agent': 'custom/1.0'},
      );

      final keys = out.keys
          .where((k) => k.toLowerCase() == 'user-agent')
          .toList(growable: false);
      expect(keys, hasLength(1));
      expect(out[keys.single], 'custom/1.0 default/1.0');
    });
  });
}
