import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('Configuration Tests', () {
    group('LLMConfig', () {
      test('should create with required parameters', () {
        final config = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.test.com',
          model: 'test-model',
        );

        expect(config.apiKey, equals('test-key'));
        expect(config.baseUrl, equals('https://api.test.com'));
        expect(config.model, equals('test-model'));
        expect(config.maxTokens, isNull);
        expect(config.temperature, isNull);
        expect(config.transportOptions, isEmpty);
        expect(config.providerOptions, isEmpty);
      });

      test('should create with all parameters', () {
        final tools = [
          Tool.function(
            name: 'test_tool',
            description: 'A test tool',
            parameters: ParametersSchema(
              schemaType: 'object',
              properties: {},
              required: [],
            ),
          ),
        ];

        final config = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.test.com',
          model: 'test-model',
          maxTokens: 1000,
          temperature: 0.7,
          systemPrompt: 'You are a helpful assistant',
          timeout: Duration(seconds: 30),
          topP: 0.9,
          topK: 50,
          tools: tools,
          toolChoice: AutoToolChoice(),
          stopSequences: ['STOP'],
          user: 'test-user',
          serviceTier: ServiceTier.auto,
          providerOptions: {
            'openai': {'reasoningEffort': 'medium'},
          },
        );

        expect(config.apiKey, equals('test-key'));
        expect(config.baseUrl, equals('https://api.test.com'));
        expect(config.model, equals('test-model'));
        expect(config.maxTokens, equals(1000));
        expect(config.temperature, equals(0.7));
        expect(config.systemPrompt, equals('You are a helpful assistant'));
        expect(config.timeout, equals(Duration(seconds: 30)));
        expect(config.topP, equals(0.9));
        expect(config.topK, equals(50));
        expect(config.tools, equals(tools));
        expect(config.toolChoice, isA<AutoToolChoice>());
        expect(config.stopSequences, equals(['STOP']));
        expect(config.user, equals('test-user'));
        expect(config.serviceTier, equals(ServiceTier.auto));
        expect(config.transportOptions, isEmpty);
        expect(
            config.providerOptions,
            equals({
              'openai': {'reasoningEffort': 'medium'}
            }));
      });

      test('should copy with modifications', () {
        final original = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.test.com',
          model: 'test-model',
          temperature: 0.5,
        );

        final modified = original.copyWith(
          temperature: 0.8,
          maxTokens: 2000,
        );

        expect(modified.apiKey, equals('test-key'));
        expect(modified.baseUrl, equals('https://api.test.com'));
        expect(modified.model, equals('test-model'));
        expect(modified.temperature, equals(0.8));
        expect(modified.maxTokens, equals(2000));
      });

      test('should serialize to JSON correctly', () {
        final config = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.test.com',
          model: 'test-model',
          maxTokens: 1000,
          temperature: 0.7,
          systemPrompt: 'You are helpful',
          timeout: Duration(seconds: 30),
          topP: 0.9,
          topK: 50,
          stopSequences: ['STOP'],
          user: 'test-user',
          serviceTier: ServiceTier.auto,
          providerOptions: {
            'openai': {'reasoningEffort': 'medium'},
          },
        );

        final json = config.toJson();
        expect(json['apiKey'], equals('test-key'));
        expect(json['baseUrl'], equals('https://api.test.com'));
        expect(json['model'], equals('test-model'));
        expect(json['maxTokens'], equals(1000));
        expect(json['temperature'], equals(0.7));
        expect(json['systemPrompt'], equals('You are helpful'));
        expect(json['timeout'], equals(30000));
        expect(json['topP'], equals(0.9));
        expect(json['topK'], equals(50));
        expect(json['stopSequences'], equals(['STOP']));
        expect(json['user'], equals('test-user'));
        expect(json['serviceTier'], equals('auto'));
        expect(
            json['providerOptions'],
            equals({
              'openai': {'reasoningEffort': 'medium'}
            }));
      });

      test('should handle null values in JSON serialization', () {
        final config = LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.test.com',
          model: 'test-model',
        );

        final json = config.toJson();
        expect(json.containsKey('maxTokens'), isFalse);
        expect(json.containsKey('temperature'), isFalse);
        expect(json.containsKey('systemPrompt'), isFalse);
        expect(json['transportOptions'], isEmpty);
        expect(json['providerOptions'], isEmpty);
      });

      test('should parse providerOptions from JSON', () {
        final config = LLMConfig.fromJson({
          'apiKey': 'test-key',
          'baseUrl': 'https://api.test.com',
          'model': 'test-model',
          'providerOptions': {
            'anthropic': {
              'cacheControl': {'type': 'ephemeral'}
            },
          },
        });

        expect(
            config.getProviderOption<Map<String, dynamic>>(
                'anthropic', 'cacheControl'),
            equals({'type': 'ephemeral'}));
      });

      test('should serialize and parse providerTools', () {
        final config = LLMConfig(
          baseUrl: 'https://api.test.com',
          model: 'test-model',
          providerTools: const [
            ProviderTool(
              id: 'openai.web_search_preview',
              options: {'searchContextSize': 'medium'},
            ),
          ],
        );

        final json = config.toJson();
        expect(json['providerTools'], isA<List>());
        expect((json['providerTools'] as List).length, equals(1));

        final roundTrip = LLMConfig.fromJson(json);
        expect(roundTrip.providerTools, isNotNull);
        expect(roundTrip.providerTools!.single.id,
            equals('openai.web_search_preview'));
        expect(
          roundTrip.providerTools!.single.options,
          equals({'searchContextSize': 'medium'}),
        );
      });
    });
  });
}
