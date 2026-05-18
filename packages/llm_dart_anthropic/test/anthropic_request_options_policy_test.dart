import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_anthropic/src/anthropic_beta_feature_inference.dart';
import 'package:llm_dart_anthropic/src/anthropic_prompt_blocks.dart';
import 'package:llm_dart_anthropic/src/anthropic_thinking_policy.dart';
import 'package:llm_dart_anthropic/src/anthropic_token_count_request_projection.dart';
import 'package:llm_dart_anthropic/src/anthropic_tool_configuration.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic request option policies', () {
    test('projects shared reasoning and provider thinking into sampling fields',
        () {
      final warnings = <ModelWarning>[];

      final projection = const AnthropicThinkingPolicy().project(
        options: const GenerateTextOptions(
          maxOutputTokens: 200,
          temperature: 1.2,
          topP: 0.8,
          topK: 40,
          reasoning: GenerateTextReasoningOptions.enabled(
            effort: ReasoningEffort.low,
            budgetTokens: 512,
          ),
        ),
        providerOptions: const AnthropicGenerateTextOptions(
          extendedThinking: true,
        ),
        warnings: warnings,
      );

      expect(projection.extendedThinking, isTrue);
      expect(projection.maxTokens, 1224);
      expect(projection.temperature, 1);
      expect(projection.topP, isNull);
      expect(projection.topK, isNull);
      expect(
        projection.thinking,
        {
          'type': 'enabled',
          'budget_tokens': 1024,
        },
      );
      expect(
        warnings.map((warning) => warning.field),
        containsAll([
          'temperature',
          'options.reasoning.effort',
          'thinkingBudgetTokens',
          'topP',
          'topK',
        ]),
      );
    });

    test('adds only applicable beta features and keeps them sorted', () {
      final warnings = <ModelWarning>[];
      final betaFeatures = <String>{};
      const inference = AnthropicBetaFeatureInference();

      inference.collectThinkingFeatures(
        providerOptions: const AnthropicGenerateTextOptions(
          interleavedThinking: true,
        ),
        extendedThinking: false,
        betaFeatures: betaFeatures,
        warnings: warnings,
      );

      expect(betaFeatures, isEmpty);
      expect(warnings.map((warning) => warning.field),
          contains('interleavedThinking'));

      inference.collectThinkingFeatures(
        providerOptions: const AnthropicGenerateTextOptions(
          extendedThinking: true,
          interleavedThinking: true,
        ),
        extendedThinking: true,
        betaFeatures: betaFeatures,
        warnings: warnings,
      );
      final prompt = const AnthropicPromptBlockEncoder().encode(
        [
          UserPromptMessage(
            parts: [
              TextPromptPart(
                'Cached prompt',
                providerOptions: AnthropicPromptPartOptions(
                  cacheControl: AnthropicCacheControl.ephemeral(),
                ),
              ),
              FilePromptPart(
                mediaType: 'application/pdf',
                data: FileProviderReferenceData(
                  ProviderReference({'anthropic': 'file_123'}),
                ),
              ),
            ],
          ),
        ],
        warnings: warnings,
      );
      final toolConfiguration = resolveAnthropicToolConfiguration(
        tools: [
          FunctionToolDefinition(
            name: 'weather',
            inputSchema: ToolJsonSchema.object(),
          ),
        ],
        nativeTools: const [],
        toolChoice: null,
        deferredToolNames: const [],
        toolsCacheControl: const AnthropicCacheControl.ephemeral(),
        warnings: warnings,
      );

      betaFeatures.addAll(prompt.betaFeatures);
      betaFeatures.addAll(toolConfiguration.betaFeatures);
      inference.collectProviderOptionFeatures(
        providerOptions: const AnthropicGenerateTextOptions(
          mcpServers: [
            AnthropicMcpServer.url(
              name: 'workspace',
              url: 'https://mcp.example.com',
            ),
          ],
        ),
        betaFeatures: betaFeatures,
      );

      expect(
        inference.sorted(betaFeatures),
        [
          'extended-cache-ttl-2025-04-11',
          'files-api-2025-04-14',
          'interleaved-thinking-2025-05-14',
          'mcp-client-2025-04-04',
        ],
      );
    });

    test('projects token count requests to the Anthropic-supported subset', () {
      final projection = const AnthropicTokenCountRequestProjector().project(
        baseBody: const {
          'model': 'claude-sonnet-4-5',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Count me.',
                },
              ],
            },
          ],
          'max_tokens': 2048,
          'stream': false,
          'system': [
            {
              'type': 'text',
              'text': 'System.',
            },
          ],
          'thinking': {
            'type': 'enabled',
            'budget_tokens': 1024,
          },
          'temperature': 0.4,
          'service_tier': 'auto',
          'metadata': {
            'session': 'abc',
          },
          'container': 'container_123',
          'mcp_servers': [
            {
              'name': 'workspace',
              'type': 'url',
              'url': 'https://mcp.example.com',
            },
          ],
          'tools': [
            {
              'name': 'weather',
              'input_schema': {
                'type': 'object',
              },
            },
          ],
          'tool_choice': {
            'type': 'auto',
          },
        },
        baseBetaFeatures: const [
          'mcp-client-2025-04-04',
        ],
        baseWarnings: const [
          ModelWarning(
            type: ModelWarningType.compatibility,
            field: 'thinkingBudgetTokens',
            message: 'defaulted',
          ),
        ],
        providerOptions: const AnthropicGenerateTextOptions(
          serviceTier: 'auto',
          metadata: {
            'session': 'abc',
          },
          container: 'container_123',
        ),
      );

      expect(
        projection.body,
        {
          'model': 'claude-sonnet-4-5',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Count me.',
                },
              ],
            },
          ],
          'system': [
            {
              'type': 'text',
              'text': 'System.',
            },
          ],
          'thinking': {
            'type': 'enabled',
            'budget_tokens': 1024,
          },
          'mcp_servers': [
            {
              'name': 'workspace',
              'type': 'url',
              'url': 'https://mcp.example.com',
            },
          ],
          'tools': [
            {
              'name': 'weather',
              'input_schema': {
                'type': 'object',
              },
            },
          ],
          'tool_choice': {
            'type': 'auto',
          },
        },
      );
      expect(projection.betaFeatures, ['mcp-client-2025-04-04']);
      expect(
        projection.warnings.map((warning) => warning.field),
        [
          'thinkingBudgetTokens',
          'serviceTier',
          'metadata',
          'container',
        ],
      );
    });
  });
}
