library;

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('tool builders providerOptions/strict/inputExamples', () {
    test('functionTool forwards strict/inputExamples/providerOptions', () {
      final local = functionTool(
        name: 't',
        description: 'test',
        parameters: const ParametersSchema(
          schemaType: 'object',
          properties: {},
          required: [],
        ),
        strict: true,
        inputExamples: const [
          {'a': 1},
        ],
        providerOptions: const {
          'anthropic': {'foo': 'bar'},
        },
        handler: (input, options) => null,
      );

      expect(local.tool.strict, isTrue);
      expect(local.tool.inputExamples, isNotNull);
      expect(local.tool.inputExamples, hasLength(1));
      expect(local.tool.inputExamples!.first['a'], equals(1));
      expect(local.tool.providerOptions, contains('anthropic'));
      expect(local.tool.providerOptions['anthropic']!['foo'], equals('bar'));
    });

    test('tool() forwards strict/inputExamples/providerOptions', () {
      final local = tool(
        name: 't',
        description: 'test',
        parameters: const ParametersSchema(
          schemaType: 'object',
          properties: {},
          required: [],
        ),
        strict: true,
        inputExamples: const [
          {'a': 1},
        ],
        providerOptions: const {
          'openai': {'x': 1},
        },
        execute: (input, options) => null,
      );

      expect(local.tool.strict, isTrue);
      expect(local.tool.inputExamples, isNotNull);
      expect(local.tool.providerOptions, contains('openai'));
      expect(local.tool.providerOptions['openai']!['x'], equals(1));
    });
  });
}
