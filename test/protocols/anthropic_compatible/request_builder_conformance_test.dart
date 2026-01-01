import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

Tool _noopTool(String name) {
  return Tool.function(
    name: name,
    description: 'noop',
    parameters: const ParametersSchema(
      schemaType: 'object',
      properties: {
        'q': ParameterProperty(
          propertyType: 'string',
          description: 'q',
        ),
      },
      required: ['q'],
    ),
  );
}

void main() {
  group('Anthropic-compatible request builder conformance', () {
    test('injects web_search tool when enabled via providerOptions', () {
      final llmConfig = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'test-model',
        providerOptions: const {
          'anthropic': {
            'webSearchEnabled': true,
            'webSearch': {
              'maxUses': 2,
              'allowedDomains': ['example.com'],
              'blockedDomains': ['bad.com'],
              'location': {
                'type': 'approximate',
                'city': 'London',
                'region': 'England',
                'country': 'GB',
                'timezone': 'Europe/London',
              },
            },
          },
        },
      );

      final config = AnthropicConfig.fromLLMConfig(llmConfig);
      final builder = AnthropicRequestBuilder(config);
      final built =
          builder.buildRequest([ChatMessage.user('hi')], const [], false);

      final tools = built.body['tools'] as List<dynamic>?;
      expect(tools, isNotNull);

      final webSearch = tools!
          .whereType<Map>()
          .cast<Map<String, dynamic>>()
          .firstWhere((t) => t['name'] == 'web_search');

      expect(webSearch['type'], equals('web_search_20250305'));
      expect(webSearch['max_uses'], equals(2));
      expect(webSearch['allowed_domains'], equals(['example.com']));
      expect(webSearch['blocked_domains'], equals(['bad.com']));
      expect(webSearch['user_location'], isA<Map>());
      expect(
        (webSearch['user_location'] as Map)['city'],
        equals('London'),
      );

      expect(
        built.toolNameMapping.requestNameForProviderToolId(
          'anthropic.web_search_20250305',
        ),
        equals('web_search'),
      );
      expect(
        built.toolNameMapping.providerToolIdForRequestName('web_search'),
        equals('anthropic.web_search_20250305'),
      );
    });

    test('bridges providerTools to web search tool (type + options)', () {
      final llmConfig = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'test-model',
        providerTools: [
          AnthropicProviderTools.webSearch(
            toolType: 'web_search_20250305',
            options: const AnthropicWebSearchToolOptions(
              maxUses: 3,
              allowedDomains: ['example.com'],
            ),
          ),
        ],
      );

      final config = AnthropicConfig.fromLLMConfig(llmConfig);
      final builder = AnthropicRequestBuilder(config);
      final built =
          builder.buildRequest([ChatMessage.user('hi')], const [], false);

      final tools = built.body['tools'] as List<dynamic>;
      final webSearch = tools
          .whereType<Map>()
          .cast<Map<String, dynamic>>()
          .firstWhere((t) => t['name'] == 'web_search');

      expect(webSearch['type'], equals('web_search_20250305'));
      expect(webSearch['max_uses'], equals(3));
      expect(webSearch['allowed_domains'], equals(['example.com']));
    });

    test('renames local tool that collides with provider-native web_search',
        () {
      final llmConfig = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'test-model',
        toolChoice: const SpecificToolChoice('web_search'),
        providerOptions: const {
          'anthropic': {'webSearchEnabled': true},
        },
      );

      final config = AnthropicConfig.fromLLMConfig(llmConfig);
      final builder = AnthropicRequestBuilder(config);

      final built = builder.buildRequest(
        [ChatMessage.user('hi')],
        [
          _noopTool('web_search'),
        ],
        false,
      );

      expect(
        built.toolNameMapping.requestNameForFunction('web_search'),
        isNot(equals('web_search')),
      );

      final tools = built.body['tools'] as List<dynamic>;
      final toolNames = tools
          .whereType<Map>()
          .map((t) => (t['name'] as String?) ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

      expect(toolNames, contains('web_search'));
      expect(
        toolNames,
        contains(built.toolNameMapping.requestNameForFunction('web_search')),
      );

      final toolChoice = built.body['tool_choice'];
      expect(toolChoice, isA<Map>());
      expect(
        (toolChoice as Map)['name'],
        equals(built.toolNameMapping.requestNameForFunction('web_search')),
      );
    });

    test('applies default cacheControl to system blocks and last tool', () {
      const config = AnthropicConfig(
        apiKey: 'k',
        model: 'test-model',
        providerId: 'anthropic',
        systemPrompt: 'sys',
        cacheControl: {'type': 'ephemeral'},
      );

      final builder = AnthropicRequestBuilder(config);
      final body = builder.buildRequestBody(
        [
          ChatMessage.system('sys2'),
          ChatMessage.user('hi'),
        ],
        [
          _noopTool('t1'),
          _noopTool('t2'),
        ],
        false,
      );

      final system = body['system'] as List<dynamic>;
      expect(system, isNotEmpty);
      for (final block in system.whereType<Map>()) {
        if (block['type'] == 'text') {
          expect(block['cache_control'], equals({'type': 'ephemeral'}));
        }
      }

      final tools = body['tools'] as List<dynamic>;
      expect(tools, hasLength(2));
      expect((tools.first as Map).containsKey('cache_control'), isFalse);
      expect(
          (tools.last as Map)['cache_control'], equals({'type': 'ephemeral'}));
    });

    test(
        'does not apply cacheControl to provider-native server tools (web_search/web_fetch)',
        () {
      final llmConfig = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'test-model',
        providerOptions: const {
          'anthropic': {
            'cacheControl': {'type': 'ephemeral'},
            'webSearchEnabled': true,
          },
        },
      );

      final config = AnthropicConfig.fromLLMConfig(llmConfig);
      final builder = AnthropicRequestBuilder(config);

      final body = builder.buildRequestBody(
        [
          ChatMessage.user('hi'),
        ],
        [
          _noopTool('t1'),
          _noopTool('t2'),
        ],
        false,
      );

      final tools = (body['tools'] as List<dynamic>)
          .whereType<Map>()
          .cast<Map<String, dynamic>>()
          .toList();

      final webSearch = tools.firstWhere((t) => t['name'] == 'web_search');
      expect(webSearch.containsKey('cache_control'), isFalse);

      final functionTools =
          tools.where((t) => t['name'] == 't1' || t['name'] == 't2').toList();
      expect(functionTools, hasLength(2));
      expect(
        functionTools.last['cache_control'],
        equals({'type': 'ephemeral'}),
      );
    });
  });
}
