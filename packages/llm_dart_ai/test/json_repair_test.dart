import 'dart:convert';

import 'package:llm_dart_ai/internal.dart';
import 'package:test/test.dart';

void main() {
  group('fixJson', () {
    test('handles empty input', () {
      expect(fixJson(''), '');
    });

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

    group('Vercel fix-json parity', () {
      test('repairs partial root literals', () {
        expect(fixJson('nul'), 'null');
        expect(fixJson('t'), 'true');
        expect(fixJson('fals'), 'false');
      });

      test('repairs incomplete root numbers', () {
        expect(fixJson('12.'), '12');
        expect(fixJson('12.2'), '12.2');
        expect(fixJson('-12'), '-12');
        expect(fixJson('-'), '');
        expect(fixJson('2.5e'), '2.5');
        expect(fixJson('2.5e-'), '2.5');
        expect(fixJson('2.5e3'), '2.5e3');
        expect(fixJson('-2.5e3'), '-2.5e3');
        expect(fixJson('2.5E'), '2.5');
        expect(fixJson('2.5E-'), '2.5');
        expect(fixJson('2.5E3'), '2.5E3');
        expect(fixJson('-2.5E3'), '-2.5E3');
        expect(fixJson('12.e'), '12');
        expect(fixJson('12.34e'), '12.34');
        expect(fixJson('5e'), '5');
      });

      test('repairs incomplete strings and escapes', () {
        expect(fixJson('"abc'), '"abc"');
        expect(
          fixJson(r'"value with \"quoted\" text and \\ escape'),
          r'"value with \"quoted\" text and \\ escape"',
        );
        expect(fixJson(r'"value with \'), '"value with "');
        expect(fixJson('"value with unicode <"'), '"value with unicode <"');
      });

      test('repairs arrays', () {
        expect(fixJson('['), '[]');
        expect(fixJson('[[1], [2'), '[[1], [2]]');
        expect(fixJson('[["1"], ["2'), '[["1"], ["2"]]');
        expect(fixJson('[[false], [nu'), '[[false], [null]]');
        expect(fixJson('[[[]], [[]'), '[[[]], [[]]]');
        expect(fixJson('[[{}], [{'), '[[{}], [{}]]');
        expect(fixJson('[1, '), '[1]');
        expect(fixJson('[[], 123'), '[[], 123]');
      });

      test('repairs objects', () {
        expect(fixJson('{"key":'), '{}');
        expect(
          fixJson('{"a": {"b": 1}, "c": {"d": 2'),
          '{"a": {"b": 1}, "c": {"d": 2}}',
        );
        expect(
          fixJson('{"a": {"b": "1"}, "c": {"d": 2'),
          '{"a": {"b": "1"}, "c": {"d": 2}}',
        );
        expect(
          fixJson('{"a": {"b": false}, "c": {"d": 2'),
          '{"a": {"b": false}, "c": {"d": 2}}',
        );
        expect(
          fixJson('{"a": {"b": []}, "c": {"d": 2'),
          '{"a": {"b": []}, "c": {"d": 2}}',
        );
        expect(
          fixJson('{"a": {"b": {}}, "c": {"d": 2'),
          '{"a": {"b": {}}, "c": {"d": 2}}',
        );
        expect(fixJson('{"ke'), '{}');
        expect(fixJson('{"k1": 1, "k2'), '{"k1": 1}');
        expect(fixJson('{"k1": 1, "k2":'), '{"k1": 1}');
        expect(fixJson('{"key": "value"  '), '{"key": "value"}');
        expect(fixJson('{"a": {"b": {}'), '{"a": {"b": {}}}');
      });

      test('repairs nested arrays and objects', () {
        expect(fixJson('[1, [2, 3, ['), '[1, [2, 3, []]]');
        expect(fixJson('[false, [true, ['), '[false, [true, []]]');
        expect(fixJson('{"key": {"subKey":'), '{"key": {}}');
        expect(
          fixJson('{"key": 123, "key2": {"subKey":'),
          '{"key": 123, "key2": {}}',
        );
        expect(
          fixJson('{"key": null, "key2": {"subKey":'),
          '{"key": null, "key2": {}}',
        );
        expect(fixJson('{"key": [1, 2, {'), '{"key": [1, 2, {}]}');
        expect(
          fixJson('[1, 2, {"key": "value",'),
          '[1, 2, {"key": "value"}]',
        );
        expect(
          fixJson('{"a": {"b": ["c", {"d": "e",'),
          '{"a": {"b": ["c", {"d": "e"}]}}',
        );
        expect(
          fixJson('{"a": {"b": {"c": {"d":'),
          '{"a": {"b": {"c": {}}}}',
        );
        expect(fixJson('{"a": 1, "b": ['), '{"a": 1, "b": []}');
        expect(fixJson('{"a": 1, "b": {'), '{"a": 1, "b": {}}');
        expect(fixJson('{"a": 1, "b": "'), '{"a": 1, "b": ""}');
      });

      test('repairs regression cases', () {
        expect(
          fixJson(
            [
              '{',
              '  "a": [',
              '    {',
              '      "a1": "v1",',
              '      "a2": "v2",',
              '      "a3": "v3"',
              '    }',
              '  ],',
              '  "b": [',
              '    {',
              '      "b1": "n',
            ].join('\n'),
          ),
          [
            '{',
            '  "a": [',
            '    {',
            '      "a1": "v1",',
            '      "a2": "v2",',
            '      "a3": "v3"',
            '    }',
            '  ],',
            '  "b": [',
            '    {',
            '      "b1": "n"}]}',
          ].join('\n'),
        );
        expect(
          fixJson('{"type":"div","children":[{"type":"Card","props":{}'),
          '{"type":"div","children":[{"type":"Card","props":{}}]}',
        );
      });
    });
  });
}
