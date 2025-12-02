import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _Element {
  final String content;

  const _Element(this.content);

  static _Element fromJson(Map<String, dynamic> json) {
    return _Element(json['content'] as String);
  }
}

void main() {
  group('OutputSpec convenience factories', () {
    test('stringValue creates correct schema and parses value', () {
      final spec = OutputSpec.stringValue(
        name: 'TestString',
        description: 'Test string output',
        fieldName: 'value',
      );

      expect(spec.format.name, 'TestString');
      expect(spec.format.description, 'Test string output');

      final schema = spec.format.schema;
      expect(schema, isNotNull);
      expect(schema!['type'], 'object');
      expect(schema['required'], contains('value'));

      final properties = (schema['properties'] as Map).cast<String, dynamic>();
      final valueSchema = (properties['value'] as Map).cast<String, dynamic>();
      expect(valueSchema['type'], 'string');

      final parsed = spec.fromJson({'value': 'hello'});
      expect(parsed, 'hello');
    });

    test('intValue creates correct schema and parses value', () {
      final spec = OutputSpec.intValue(
        name: 'TestInt',
        description: 'Test int output',
        fieldName: 'value',
      );

      final schema = spec.format.schema!;
      expect(schema['type'], 'object');

      final properties = (schema['properties'] as Map).cast<String, dynamic>();
      final valueSchema = (properties['value'] as Map).cast<String, dynamic>();
      expect(valueSchema['type'], 'integer');

      final parsed = spec.fromJson({'value': 42});
      expect(parsed, 42);
    });

    test('doubleValue creates correct schema and parses value', () {
      final spec = OutputSpec.doubleValue(
        name: 'TestDouble',
        description: 'Test double output',
        fieldName: 'value',
      );

      final schema = spec.format.schema!;
      final properties = (schema['properties'] as Map).cast<String, dynamic>();
      final valueSchema = (properties['value'] as Map).cast<String, dynamic>();
      expect(valueSchema['type'], 'number');

      final parsed = spec.fromJson({'value': 3.14});
      expect(parsed, closeTo(3.14, 1e-9));
    });

    test('boolValue creates correct schema and parses value', () {
      final spec = OutputSpec.boolValue(
        name: 'TestBool',
        description: 'Test bool output',
        fieldName: 'value',
      );

      final schema = spec.format.schema!;
      final properties = (schema['properties'] as Map).cast<String, dynamic>();
      final valueSchema = (properties['value'] as Map).cast<String, dynamic>();
      expect(valueSchema['type'], 'boolean');

      final parsedTrue = spec.fromJson({'value': true});
      final parsedFalse = spec.fromJson({'value': false});
      expect(parsedTrue, isTrue);
      expect(parsedFalse, isFalse);
    });

    test('listOf builds nested schema and parses element list', () {
      final elementSpec = OutputSpec<_Element>.object(
        name: 'Element',
        properties: {
          'content': ParameterProperty(
            propertyType: 'string',
            description: 'Element content',
          ),
        },
        fromJson: _Element.fromJson,
      );

      final listSpec = OutputSpec.listOf<_Element>(
        itemOutput: elementSpec,
        name: 'ElementList',
        description: 'List of elements',
        fieldName: 'items',
      );

      expect(listSpec.format.name, 'ElementList');
      expect(listSpec.format.description, 'List of elements');

      final schema = listSpec.format.schema!;
      expect(schema['type'], 'object');

      final properties = (schema['properties'] as Map).cast<String, dynamic>();
      final itemsSchema = (properties['items'] as Map).cast<String, dynamic>();

      expect(itemsSchema['type'], 'array');
      expect(
        (itemsSchema['items'] as Map).cast<String, dynamic>(),
        equals(elementSpec.format.schema),
      );

      // Validate that the structured output format passes validation.
      expect(
        ToolValidator.validateStructuredOutput(listSpec.format),
        isTrue,
      );

      // Parse a list of elements.
      final parsed = listSpec.fromJson({
        'items': [
          {'content': 'a'},
          {'content': 'b'},
        ],
      });

      expect(parsed, hasLength(2));
      expect(parsed[0].content, 'a');
      expect(parsed[1].content, 'b');
    });
  });
}
