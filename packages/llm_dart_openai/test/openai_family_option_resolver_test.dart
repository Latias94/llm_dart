import 'package:llm_dart_openai/src/provider/deepseek_options.dart';
import 'package:llm_dart_openai/src/provider/openai_family_profile.dart';
import 'package:llm_dart_openai/src/language/openai_generate_text_options.dart';
import 'package:llm_dart_openai/src/provider/openai_model_settings.dart';
import 'package:llm_dart_openai/src/tools/openai_native_tools.dart';
import 'package:llm_dart_openai/src/language/openai_response_format.dart';
import 'package:llm_dart_openai/src/provider/openrouter_options.dart';
import 'package:llm_dart_openai/src/provider/openai_provider_options_bag.dart';
import 'package:llm_dart_openai/src/provider/resolved_openai_chat_settings.dart';
import 'package:llm_dart_openai/src/speech/openai_speech_options.dart';
import 'package:llm_dart_openai/src/provider/xai_options.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIFamilyOptionResolver', () {
    test('merges shared response format into common OpenAI options', () {
      final resolved =
          const OpenAIProfile().optionResolver.resolveInvocationOptions(
                options: const OpenAIGenerateTextOptions(
                  serviceTier: 'flex',
                ),
                sharedResponseFormat: JsonResponseFormat(
                  name: 'answer',
                  description: 'Structured answer',
                  strict: true,
                  schema: JsonSchema.object(
                    properties: {
                      'answer': {'type': 'string'},
                    },
                    required: ['answer'],
                  ),
                ),
                modelSettings: const ResolvedOpenAIChatModelSettings(),
              );

      expect(resolved.common.serviceTier, 'flex');
      expect(
        resolved.common.responseFormat,
        isA<OpenAIJsonSchemaResponseFormat>()
            .having((format) => format.name, 'name', 'answer')
            .having((format) => format.description, 'description',
                'Structured answer')
            .having((format) => format.strict, 'strict', isTrue)
            .having(
              (format) => format.schema,
              'schema',
              containsPair('type', 'object'),
            ),
      );
    });

    test('model settings built-in tools are used when call options omit them',
        () {
      const fileSearchTool = OpenAIFileSearchTool(vectorStoreIds: ['vs_1']);

      final resolved =
          const OpenAIProfile().optionResolver.resolveInvocationOptions(
                options: const OpenAIGenerateTextOptions(),
                sharedResponseFormat: null,
                modelSettings: const ResolvedOpenAIChatModelSettings(
                  common: OpenAIChatModelSettings(
                    builtInTools: [fileSearchTool],
                  ),
                ),
              );

      expect(resolved.common.builtInTools, [fileSearchTool]);
    });

    test('parses OpenAI provider options bag and merges typed overrides', () {
      final resolved =
          const OpenAIProfile().optionResolver.resolveInvocationOptions(
                options: providerInvocationOptions(
                  typedOptions: const OpenAIGenerateTextOptions(
                    user: 'typed-user',
                  ),
                  bag: ProviderOptionsBag.forProvider('openai', {
                    'user': 'bag-user',
                    'store': true,
                    'reasoning_effort': 'high',
                    'include': ['message.output_text.logprobs'],
                    'metadata': {'traceId': 'trace_1'},
                  }),
                ),
                sharedResponseFormat: null,
                modelSettings: const ResolvedOpenAIChatModelSettings(),
              );

      expect(resolved.common.user, 'typed-user');
      expect(resolved.common.store, isTrue);
      expect(resolved.common.reasoningEffort, OpenAIReasoningEffort.high);
      expect(resolved.common.include, [
        OpenAIResponsesInclude.messageOutputTextLogprobs,
      ]);
      expect(resolved.common.metadata, {'traceId': 'trace_1'});
    });

    test('projects typed OpenAI options into provider options bag', () {
      final bag = openAIGenerateTextOptionsToProviderOptionsBag(
        const OpenAIGenerateTextOptions(
          store: true,
          reasoningEffort: OpenAIReasoningEffort.high,
          include: [
            OpenAIResponsesInclude.reasoningEncryptedContent,
          ],
        ),
      )!;

      expect(bag.toJsonMap(), {
        'openai': {
          'store': true,
          'reasoning_effort': 'high',
          'include': ['reasoning.encrypted_content'],
        },
      });
    });

    test('projects typed profile options into provider option namespaces', () {
      final deepseekBag = providerOptionsBagFromInvocationOptions(
        const DeepSeekGenerateTextOptions(
          common: OpenAIGenerateTextOptions(
            user: 'user_123',
            logprobs: OpenAILogProbs.top(3),
          ),
          logprobs: true,
          topLogprobs: 5,
          frequencyPenalty: 0.2,
        ),
      )!;

      expect(deepseekBag.toJsonMap(), {
        'openai': {
          'user': 'user_123',
          'logprobs': {'top_logprobs': 3},
        },
        'deepseek': {
          'logprobs': true,
          'top_logprobs': 5,
          'frequency_penalty': 0.2,
        },
      });

      final openRouterBag = providerOptionsBagFromInvocationOptions(
        const OpenRouterGenerateTextOptions(
          common: OpenAIGenerateTextOptions(serviceTier: 'flex'),
          search: OpenRouterSearchOptions.onlineModel(),
        ),
      )!;

      expect(openRouterBag.toJsonMap(), {
        'openai': {
          'service_tier': 'flex',
        },
        'openrouter': {
          'search': {'mode': 'online_model'},
        },
      });
    });

    test('projects typed non-text options into the OpenAI namespace', () {
      final bag = providerOptionsBagFromInvocationOptions(
        const OpenAISpeechOptions(
          outputFormat: 'wav',
          instructions: 'Speak calmly.',
          speed: 1.2,
        ),
      )!;

      expect(bag.toJsonMap(), {
        'openai': {
          'output_format': 'wav',
          'instructions': 'Speak calmly.',
          'speed': 1.2,
        },
      });
    });

    test('OpenRouter resolver applies settings and invocation search shaping',
        () {
      final resolver = const OpenRouterProfile().optionResolver;
      final modelSettings = resolver.resolveModelSettings(
        const OpenRouterChatModelSettings(
          search: OpenRouterSearchOptions.onlineModel(),
        ),
      );
      final invocationOptions = resolver.resolveInvocationOptions(
        options: const OpenRouterGenerateTextOptions(),
        sharedResponseFormat: null,
        modelSettings: modelSettings,
      );

      expect(modelSettings.openRouterSearch, isNotNull);
      expect(
        resolver.resolveRequestModelId(
          modelId: 'openai/gpt-4o-mini',
          modelSettings: modelSettings,
          invocationOptions: invocationOptions,
        ),
        'openai/gpt-4o-mini:online',
      );

      final callLevelOptions = resolver.resolveInvocationOptions(
        options: const OpenRouterGenerateTextOptions(
          search: OpenRouterSearchOptions.onlineModel(),
        ),
        sharedResponseFormat: null,
        modelSettings: const ResolvedOpenAIChatModelSettings(),
      );
      expect(
        resolver.resolveRequestModelId(
          modelId: 'anthropic/claude-3.5-sonnet',
          modelSettings: const ResolvedOpenAIChatModelSettings(),
          invocationOptions: callLevelOptions,
        ),
        'anthropic/claude-3.5-sonnet:online',
      );

      final bagLevelOptions = resolver.resolveInvocationOptions(
        options: ProviderOptionsBag.fromJsonMap({
          'openai': {
            'service_tier': 'flex',
          },
          'openrouter': {
            'search': {'mode': 'online_model'},
          },
        }),
        sharedResponseFormat: null,
        modelSettings: const ResolvedOpenAIChatModelSettings(),
      );
      expect(bagLevelOptions.common.serviceTier, 'flex');
      expect(
        resolver.resolveRequestModelId(
          modelId: 'google/gemini-2.5-pro',
          modelSettings: const ResolvedOpenAIChatModelSettings(),
          invocationOptions: bagLevelOptions,
        ),
        'google/gemini-2.5-pro:online',
      );
    });

    test('parses DeepSeek and xAI provider option namespaces', () {
      final deepseek =
          const DeepSeekProfile().optionResolver.resolveInvocationOptions(
                options: ProviderOptionsBag.fromJsonMap({
                  'openai': {
                    'user': 'bag-user',
                  },
                  'deepseek': {
                    'logprobs': true,
                    'top_logprobs': 3,
                    'frequency_penalty': 0.2,
                    'response_format': {'type': 'json_object'},
                  },
                }),
                sharedResponseFormat: null,
                modelSettings: const ResolvedOpenAIChatModelSettings(),
              );

      expect(deepseek.common.user, 'bag-user');
      expect(deepseek.deepseek!.logprobs, isTrue);
      expect(deepseek.deepseek!.topLogprobs, 3);
      expect(deepseek.deepseek!.frequencyPenalty, 0.2);
      expect(deepseek.deepseek!.responseFormat, {'type': 'json_object'});

      final xai = const XAIProfile().optionResolver.resolveInvocationOptions(
            options: ProviderOptionsBag.fromJsonMap({
              'xai': {
                'search': {
                  'mode': 'on',
                  'return_citations': false,
                  'max_search_results': 5,
                },
              },
            }),
            sharedResponseFormat: null,
            modelSettings: const ResolvedOpenAIChatModelSettings(),
          );

      expect(xai.xaiSearch!.mode, XAISearchMode.on);
      expect(xai.xaiSearch!.returnCitations, isFalse);
      expect(xai.xaiSearch!.maxSearchResults, 5);
    });

    test('profile-specific provider options are rejected on the wrong profile',
        () {
      expect(
        () => const OpenAIProfile().optionResolver.resolveInvocationOptions(
              options: const XAIGenerateTextOptions(
                search: XAILiveSearchOptions.autoWeb(),
              ),
              sharedResponseFormat: null,
              modelSettings: const ResolvedOpenAIChatModelSettings(),
            ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('only valid for xAI'),
          ),
        ),
      );

      expect(
        () => const OpenAIProfile().optionResolver.resolveInvocationOptions(
              options: const DeepSeekGenerateTextOptions(),
              sharedResponseFormat: null,
              modelSettings: const ResolvedOpenAIChatModelSettings(),
            ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('only valid for DeepSeek'),
          ),
        ),
      );
    });

    test('DeepSeek response format rejects shared OpenAI response format', () {
      expect(
        () => const DeepSeekProfile().optionResolver.resolveInvocationOptions(
              options: const DeepSeekGenerateTextOptions(
                responseFormat: {'type': 'json_object'},
              ),
              sharedResponseFormat: JsonResponseFormat(
                schema: JsonSchema.object(),
              ),
              modelSettings: const ResolvedOpenAIChatModelSettings(),
            ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('DeepSeekGenerateTextOptions.responseFormat'),
          ),
        ),
      );
    });
  });
}
