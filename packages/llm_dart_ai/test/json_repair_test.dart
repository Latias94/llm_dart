import 'dart:convert';

import 'package:llm_dart_ai/internal.dart';
import 'package:test/test.dart';

void main() {
  group('fixJson', () {
    test('closes nested objects and arrays', () {
      final repaired = fixJson('{"items":[{"name":"alpha"');

      expect(jsonDecode(repaired), {
        'items': [
          {'name': 'alpha'},
        ],
      });
    });

    test('completes partial literals', () {
      expect(jsonDecode(fixJson('{"ok":tru')), {'ok': true});
      expect(jsonDecode(fixJson('{"ok":fal')), {'ok': false});
      expect(jsonDecode(fixJson('{"value":nul')), {'value': null});
    });

    test('trims incomplete trailing object keys', () {
      expect(jsonDecode(fixJson('{"ready":true,"dangling"')), {
        'ready': true,
      });
    });
  });
}
