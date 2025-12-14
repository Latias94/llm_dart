import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('injectJsonInstruction', () {
    test('handles basic case with prompt and schema', () {
      final schema = <String, dynamic>{
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
          'age': {'type': 'number'},
        },
        'required': ['name', 'age'],
      };

      final result = injectJsonInstruction(
        prompt: 'Generate a person',
        schema: schema,
      );

      expect(
        result,
        equals(
          'Generate a person\n\n'
          'JSON schema:\n'
          '${jsonEncode(schema)}\n'
          'You MUST answer with a JSON object that matches the JSON schema above.',
        ),
      );
    });

    test('handles prompt without schema', () {
      final result = injectJsonInstruction(
        prompt: 'Generate a person',
      );

      expect(
        result,
        equals(
          'Generate a person\n\n'
          'You MUST answer with JSON.',
        ),
      );
    });

    test('handles schema without prompt', () {
      final schema = <String, dynamic>{
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
          'age': {'type': 'number'},
        },
        'required': ['name', 'age'],
      };

      final result = injectJsonInstruction(schema: schema);

      expect(
        result,
        equals(
          'JSON schema:\n'
          '${jsonEncode(schema)}\n'
          'You MUST answer with a JSON object that matches the JSON schema above.',
        ),
      );
    });

    test('handles no prompt and no schema', () {
      final result = injectJsonInstruction();

      expect(result, equals('You MUST answer with JSON.'));
    });

    test('supports custom schemaPrefix and schemaSuffix', () {
      final schema = <String, dynamic>{
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
        },
      };

      final result = injectJsonInstruction(
        prompt: 'Generate a person',
        schema: schema,
        schemaPrefix: 'Custom prefix:',
        schemaSuffix: 'Custom suffix',
      );

      expect(
        result,
        equals(
          'Generate a person\n\n'
          'Custom prefix:\n'
          '${jsonEncode(schema)}\n'
          'Custom suffix',
        ),
      );
    });

    test('handles empty string prompt with schema', () {
      final schema = <String, dynamic>{
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
        },
      };

      final result = injectJsonInstruction(
        prompt: '',
        schema: schema,
      );

      // No leading blank line when prompt is empty.
      expect(
        result,
        equals(
          'JSON schema:\n'
          '${jsonEncode(schema)}\n'
          'You MUST answer with a JSON object that matches the JSON schema above.',
        ),
      );
    });

    test('handles empty object schema', () {
      final schema = <String, dynamic>{};

      final result = injectJsonInstruction(
        prompt: 'Generate something',
        schema: schema,
      );

      expect(
        result,
        equals(
          'Generate something\n\n'
          'JSON schema:\n'
          '${jsonEncode(schema)}\n'
          'You MUST answer with a JSON object that matches the JSON schema above.',
        ),
      );
    });

    test('handles complex nested schema', () {
      final schema = <String, dynamic>{
        'type': 'object',
        'properties': {
          'person': {
            'type': 'object',
            'properties': {
              'name': {'type': 'string'},
              'age': {'type': 'number'},
              'address': {
                'type': 'object',
                'properties': {
                  'street': {'type': 'string'},
                  'city': {'type': 'string'},
                },
              },
            },
          },
        },
      };

      final result = injectJsonInstruction(
        prompt: 'Generate a complex person',
        schema: schema,
      );

      expect(
        result,
        equals(
          'Generate a complex person\n\n'
          'JSON schema:\n'
          '${jsonEncode(schema)}\n'
          'You MUST answer with a JSON object that matches the JSON schema above.',
        ),
      );
    });
  });
}
