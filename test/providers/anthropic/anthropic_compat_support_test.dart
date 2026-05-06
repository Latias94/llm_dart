import 'package:llm_dart/models/chat_models.dart';
import 'package:llm_dart/models/tool_models.dart';
import 'package:llm_dart/providers/anthropic/models.dart';
import 'package:llm_dart/src/compatibility/providers/anthropic_compat_support.dart';
import 'package:llm_dart_core/llm_dart_core.dart' as core;
import 'package:test/test.dart';

void main() {
  group('Anthropic compatibility adapter support', () {
    const support = AnthropicCompatAdapterSupport();

    test('buildRequestPlan promotes message tools and merges cache policy', () {
      final requestPlan = support.buildRequestPlan(
        messages: [
          MessageBuilder.system()
              .text('Reusable instructions')
              .tools([
                Tool.function(
                  name: 'weather',
                  description: 'Get weather details.',
                  parameters: const ParametersSchema(
                    schemaType: 'object',
                    properties: {
                      'city': ParameterProperty(
                        propertyType: 'string',
                        description: 'City name.',
                      ),
                    },
                    required: ['city'],
                  ),
                ),
              ])
              .anthropicConfig(
                (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour),
              )
              .build(),
          ChatMessage.user('Hello'),
        ],
        tools: null,
        configTools: null,
        providerOptions: null,
      );

      expect(requestPlan.effectiveTools, hasLength(1));
      expect(requestPlan.effectiveTools.single.function.name, 'weather');
      expect(requestPlan.providerOptions.toolsCacheControl?.type, 'ephemeral');
      expect(requestPlan.providerOptions.toolsCacheControl?.ttl, '1h');
    });

    test('convertMessages keeps system prompt injection and tool replay names',
        () {
      final prompt = support.convertMessages(
        messages: [
          ChatMessage.assistant('Trailing assistant text').withExtension(
            'anthropic',
            {
              'contentBlocks': [
                {
                  'type': 'tool_use',
                  'id': 'toolu_1',
                  'name': 'weather',
                  'input': {
                    'city': 'Hong Kong',
                  },
                },
              ],
            },
          ),
          ChatMessage.user('').withExtension(
            'anthropic',
            {
              'contentBlocks': [
                {
                  'type': 'tool_result',
                  'tool_use_id': 'toolu_1',
                  'content': '{"temp":72}',
                },
              ],
            },
          ),
        ],
        systemPrompt: 'You are concise.',
        convertTrackedMessage: (_) => const <core.PromptMessage>[],
      );

      expect(prompt, hasLength(3));
      expect(prompt.first, isA<core.SystemPromptMessage>());

      final assistantMessage = prompt[1] as core.AssistantPromptMessage;
      expect(assistantMessage.parts, hasLength(2));
      final toolPart = assistantMessage.parts.first as core.ToolCallPromptPart;
      expect(toolPart.toolCallId, 'toolu_1');
      expect(toolPart.toolName, 'weather');

      final toolResultMessage = prompt[2] as core.ToolPromptMessage;
      expect(toolResultMessage.toolName, 'weather');
      final toolResultPart =
          toolResultMessage.parts.single as core.ToolResultPromptPart;
      expect(toolResultPart.toolCallId, 'toolu_1');
      expect(toolResultPart.output, '{"temp":72}');
    });
  });
}
