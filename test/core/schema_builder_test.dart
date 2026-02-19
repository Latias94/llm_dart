import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('Schema builders', () {
    test('builds JSON Schema', () {
      final schema = Schema.params(
        properties: {
          'location': Schema.string('City name'),
          'units': Schema.string(
            'Temperature units',
            enumValues: const ['c', 'f'],
          ),
          'days': Schema.integer('Number of days'),
          'includeHumidity': Schema.boolean('Whether to include humidity'),
          'tags': Schema.array('Tags', items: Schema.string('Tag')),
          'options': Schema.object(
            'Advanced options',
            properties: {
              'mode': Schema.string('Mode', enumValues: const ['fast', 'full']),
            },
            required: const ['mode'],
          ),
        },
        required: const ['location'],
      );

      expect(schema, {
        'type': 'object',
        'properties': {
          'location': {'type': 'string', 'description': 'City name'},
          'units': {
            'type': 'string',
            'description': 'Temperature units',
            'enum': ['c', 'f'],
          },
          'days': {'type': 'integer', 'description': 'Number of days'},
          'includeHumidity': {
            'type': 'boolean',
            'description': 'Whether to include humidity',
          },
          'tags': {
            'type': 'array',
            'description': 'Tags',
            'items': {'type': 'string', 'description': 'Tag'},
          },
          'options': {
            'type': 'object',
            'description': 'Advanced options',
            'properties': {
              'mode': {
                'type': 'string',
                'description': 'Mode',
                'enum': ['fast', 'full'],
              },
            },
            'required': ['mode'],
          },
        },
        'required': ['location'],
      });
    });

    test('works with ToolValidator', () {
      final schema = Schema.params(
        properties: {
          'location': Schema.string('City name'),
          'units': Schema.string(
            'Temperature units',
            enumValues: const ['c', 'f'],
          ),
        },
        required: const ['location'],
      );

      expect(
        ToolValidator.validateParameters(
          {'location': 'San Francisco', 'units': 'c'},
          schema,
        ),
        isEmpty,
      );

      expect(
        ToolValidator.validateParameters(
          {'units': 'x'},
          schema,
        ),
        containsAll([
          'Object \$ missing required property: location',
          'Value \$.units must be one of [c, f], got x',
        ]),
      );
    });
  });
}
