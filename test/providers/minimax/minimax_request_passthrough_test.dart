import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_minimax/llm_dart_minimax.dart';
import 'package:test/test.dart';

void main() {
  group('MiniMax (Anthropic-compatible) request passthrough', () {
    test('forwards optional Anthropic fields best-effort (no stripping)', () {
      final llmConfig = LLMConfig(
        apiKey: 'k',
        baseUrl: minimaxAnthropicBaseUrl,
        model: minimaxDefaultModel,
        topK: 42,
        stopSequences: const ['STOP'],
        serviceTier: ServiceTier.priority,
        providerOptions: const {
          'minimax': {
            'reasoning': true,
            'thinkingBudgetTokens': 256,
            'container': 'container-1',
            'mcpServers': [
              {
                'name': 'mcp-1',
                'type': 'url',
                'url': 'https://mcp.example.com',
              },
            ],
            'extraBody': {
              'foo': 'bar',
            },
          },
        },
      );

      final config = AnthropicConfig.fromLLMConfig(
        llmConfig,
        providerOptionsNamespace: 'minimax',
      );

      final body = AnthropicRequestBuilder(config).buildRequestBody(
        [ChatMessage.user('hi')],
        null,
        false,
      );

      expect(body['model'], equals(minimaxDefaultModel));
      expect(body['top_k'], equals(42));
      expect(body['stop_sequences'], equals(['STOP']));
      expect(body['service_tier'], equals(ServiceTier.priority.value));

      // MiniMax docs may claim `thinking` is ignored at the API layer.
      // LLM Dart intentionally does not strip it.
      final thinking = body['thinking'];
      expect(thinking, isA<Map<String, dynamic>>());
      expect((thinking as Map<String, dynamic>)['type'], equals('enabled'));
      expect(thinking['budget_tokens'], equals(256));

      expect(body['container'], equals('container-1'));

      final mcpServers = body['mcp_servers'];
      expect(mcpServers, isA<List<dynamic>>());
      expect((mcpServers as List).length, equals(1));
      expect(mcpServers.single['name'], equals('mcp-1'));

      expect(body['foo'], equals('bar'));
    });
  });
}
