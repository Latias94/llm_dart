import 'package:llm_dart_openai/src/provider/deepseek_options.dart';
import 'package:llm_dart_openai/src/provider/openai_family_option_resolver.dart';
import 'package:llm_dart_openai/src/provider/openai_family_profile.dart';
import 'package:llm_dart_openai/src/language/openai_generate_text_options.dart';
import 'package:llm_dart_openai/src/provider/openai_model_settings.dart';
import 'package:llm_dart_openai/src/tools/openai_native_tools.dart';
import 'package:llm_dart_openai/src/language/openai_response_format.dart';
import 'package:llm_dart_openai/src/provider/openrouter_options.dart';
import 'package:llm_dart_openai/src/provider/resolved_openai_chat_settings.dart';
import 'package:llm_dart_openai/src/provider/xai_options.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIFamilyOptionResolver', () {
    test('merges shared response format into common OpenAI options', () {
      final resolved = openAIFamilyOptionResolverFor(
        const OpenAIProfile(),
      ).resolveInvocationOptions(
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

      final resolved = openAIFamilyOptionResolverFor(
        const OpenAIProfile(),
      ).resolveInvocationOptions(
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

    test('OpenRouter resolver applies settings and invocation search shaping',
        () {
      final resolver = openAIFamilyOptionResolverFor(
        const OpenRouterProfile(),
      );
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
    });

    test('profile-specific provider options are rejected on the wrong profile',
        () {
      expect(
        () => openAIFamilyOptionResolverFor(
          const OpenAIProfile(),
        ).resolveInvocationOptions(
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
        () => openAIFamilyOptionResolverFor(
          const OpenAIProfile(),
        ).resolveInvocationOptions(
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
        () => openAIFamilyOptionResolverFor(
          const DeepSeekProfile(),
        ).resolveInvocationOptions(
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
