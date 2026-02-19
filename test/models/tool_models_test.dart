import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('Tool Models', () {
    group('FunctionTool', () {
      test('creates with name + inputSchema', () {
        final tool = FunctionTool(
          name: 'test_function',
          inputSchema: Schema.params(properties: const {}),
        );

        expect(tool.name, equals('test_function'));
        expect(tool.description, isNull);
        expect(tool.inputSchema, isA<Map<String, dynamic>>());
      });

      test('serializes with inputSchema key', () {
        final tool = FunctionTool(
          name: 'test_function',
          description: 'A test function',
          inputSchema: Schema.params(
            properties: {'q': Schema.string('query')},
            required: const ['q'],
          ),
        );

        final json = tool.toJson();
        expect(json['name'], equals('test_function'));
        expect(json['description'], equals('A test function'));
        expect(json['inputSchema'], isA<Map>());
      });
    });

    group('Tool', () {
      test('creates function tool', () {
        final tool = Tool.function(
          name: 'get_weather',
          description: 'Get weather information',
          inputSchema: Schema.params(
            properties: {'location': Schema.string('City name')},
            required: const ['location'],
          ),
        );

        expect(tool.toolType, equals('function'));
        expect(tool.function.name, equals('get_weather'));
        expect(tool.function.description, equals('Get weather information'));
        expect(tool.function.inputSchema['type'], equals('object'));
      });

      test('serializes function tool with inputSchema', () {
        final tool = Tool.function(
          name: 'get_weather',
          description: 'Get weather information',
          inputSchema: Schema.params(properties: const {}),
        );

        final json = tool.toJson();
        expect(json['type'], equals('function'));
        expect(json['name'], equals('get_weather'));
        expect(json['inputSchema'], isA<Map>());
      });
    });

    group('ProviderTool', () {
      test('infers provider id from stable id', () {
        const tool = ProviderTool(id: 'openai.web_search_preview');
        expect(tool.inferredProviderId, equals('openai'));
      });

      test('serializes args', () {
        const tool = ProviderTool(
          id: 'openai.file_search',
          args: {
            'vectorStoreIds': ['vs_123']
          },
        );

        final json = tool.toJson();
        expect(json['id'], equals('openai.file_search'));
        expect(json['args'], equals({'vectorStoreIds': ['vs_123']}));
      });

      test('fromJson supports legacy options key', () {
        final tool = ProviderTool.fromJson({
          'id': 'anthropic.web_search_20250305',
          'options': {'maxUses': 3},
        });

        expect(tool.id, equals('anthropic.web_search_20250305'));
        expect(tool.args, equals({'maxUses': 3}));
      });
    });

    group('ToolChoice', () {
      test('AutoToolChoice serializes', () {
        const choice = AutoToolChoice();
        expect(choice.toJson(), equals({'type': 'auto'}));
      });

      test('SpecificToolChoice serializes', () {
        const choice = SpecificToolChoice('get_weather');
        expect(
          choice.toJson(),
          equals({
            'type': 'function',
            'function': {'name': 'get_weather'},
          }),
        );
      });
    });
  });
}
