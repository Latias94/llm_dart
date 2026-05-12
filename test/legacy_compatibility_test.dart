import 'package:llm_dart/legacy.dart' as legacy;
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as modern_anthropic;
import 'package:llm_dart/src/compatibility/compat_providers.dart';
import 'package:llm_dart/src/compatibility/legacy_chat_adapter.dart';
import 'package:llm_dart/src/compatibility/config/legacy_anthropic_options.dart';
import 'package:llm_dart/src/compatibility/config/legacy_config_keys.dart';
import 'package:llm_dart/src/compatibility/config/legacy_deepseek_options.dart';
import 'package:llm_dart/src/compatibility/config/legacy_elevenlabs_options.dart';
import 'package:llm_dart/src/compatibility/config/legacy_google_options.dart';
import 'package:llm_dart/src/compatibility/config/legacy_google_thinking_options.dart';
import 'package:llm_dart/src/compatibility/config/legacy_ollama_options.dart';
import 'package:llm_dart/src/compatibility/config/legacy_openai_options.dart';
import 'package:llm_dart/src/compatibility/config/legacy_provider_options.dart';
import 'package:llm_dart/src/compatibility/config/legacy_web_search_options.dart';
import 'package:llm_dart/src/compatibility/config/legacy_xai_options.dart';
import 'package:llm_dart_core/llm_dart_core.dart' as core;
import 'package:llm_dart_openai/llm_dart_openai.dart' as modern_openai;
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('Legacy Compatibility', () {
    test('LegacyProviderOptionView makes flat fallback explicit', () {
      const config = legacy.LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-4o',
        extensions: {
          LegacyExtensionKeys.verbosity: 'flat',
          legacyProviderOptionsBagKey: {
            LegacyProviderOptionNamespaces.openai: {
              LegacyExtensionKeys.verbosity: 'namespaced',
              LegacyExtensionKeys.previousResponseId: null,
            },
          },
        },
      );
      final options = legacyProviderOptionView(
        config,
        LegacyProviderOptionNamespaces.openai,
      );

      expect(
        options.get<String>(LegacyExtensionKeys.verbosity),
        'namespaced',
      );
      expect(
        options.get<String>(LegacyExtensionKeys.voice),
        isNull,
      );
      expect(
        options.getWithFlatFallback<String>(
          LegacyExtensionKeys.voice,
          fallbackKey: LegacyExtensionKeys.verbosity,
        ),
        'flat',
      );
      expect(
        options.getWithFlatFallback<String>(
          LegacyExtensionKeys.previousResponseId,
          fallbackKey: LegacyExtensionKeys.verbosity,
        ),
        isNull,
      );
    });

    test('LegacyWebSearchOptions centralizes migrated search intent', () {
      const config = legacy.LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://openrouter.ai/api/v1',
        model: 'openai/gpt-4o-mini',
        extensions: {
          LegacyExtensionKeys.webSearchEnabled: true,
          LegacyExtensionKeys.webSearchConfig: legacy.WebSearchConfig(
            maxResults: 3,
          ),
          legacyProviderOptionsBagKey: {
            LegacyProviderOptionNamespaces.openrouter: {
              LegacyExtensionKeys.webSearchConfig: legacy.WebSearchConfig(
                maxResults: 7,
              ),
            },
          },
        },
      );

      final search = legacyWebSearchOptions(
        legacyProviderOptionView(
          config,
          LegacyProviderOptionNamespaces.openrouter,
        ),
      );

      expect(search.enabled, isTrue);
      expect(search.hasSearchIntent, isTrue);
      expect(search.config?.maxResults, 7);
      expect(search.configOrEnabledDefault?.maxResults, 7);
    });

    test('LegacyWebSearchOptions preserves explicit null namespace overrides',
        () {
      const config = legacy.LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        model: 'gemini-2.0-flash',
        extensions: {
          LegacyExtensionKeys.webSearchEnabled: true,
          LegacyExtensionKeys.webSearchConfig: legacy.WebSearchConfig(
            maxResults: 3,
          ),
          legacyProviderOptionsBagKey: {
            LegacyProviderOptionNamespaces.google: {
              LegacyExtensionKeys.webSearchEnabled: false,
              LegacyExtensionKeys.webSearchConfig: null,
            },
          },
        },
      );

      final search = legacyWebSearchOptions(
        legacyProviderOptionView(
          config,
          LegacyProviderOptionNamespaces.google,
        ),
      );

      expect(search.enabled, isFalse);
      expect(search.config, isNull);
      expect(search.hasSearchIntent, isFalse);
      expect(search.configOrEnabledDefault, isNull);
    });

    test('LegacyGoogleThinkingOptions centralizes thinking reads', () {
      const config = legacy.LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        model: 'gemini-2.0-flash',
        extensions: {
          LegacyExtensionKeys.reasoning: true,
          legacyProviderOptionsBagKey: {
            LegacyProviderOptionNamespaces.google: {
              LegacyExtensionKeys.includeThoughts: false,
              LegacyExtensionKeys.thinkingBudgetTokens: 64,
              LegacyExtensionKeys.reasoningEffort: 'high',
            },
          },
        },
      );

      final thinking = legacyGoogleThinkingOptions(
        legacyProviderOptionView(
          config,
          LegacyProviderOptionNamespaces.google,
        ),
      );

      expect(thinking.reasoning, isTrue);
      expect(thinking.includeThoughts, isFalse);
      expect(thinking.thinkingBudgetTokens, 64);
      expect(thinking.reasoningEffort, legacy.ReasoningEffort.high);
      expect(thinking.hasThinkingConfig, isTrue);
      expect(thinking.includeThoughtsHeader, isTrue);
      expect(thinking.toThinkingConfig(), {
        'includeThoughts': false,
        'thinkingBudget': 64,
      });
    });

    test('LegacyGoogleOptions centralizes Google option reads', () {
      const schema = legacy.StructuredOutputFormat(
        name: 'answer',
        schema: {'type': 'object'},
      );
      const safety = legacy.SafetySetting(
        category: legacy.HarmCategory.harmCategoryHarassment,
        threshold: legacy.HarmBlockThreshold.blockOnlyHigh,
      );
      final responseModalities = <dynamic>['TEXT', 'IMAGE'];
      final config = legacy.LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        model: 'gemini-2.0-flash',
        extensions: {
          LegacyExtensionKeys.maxInlineDataSize: 1024,
          legacyProviderOptionsBagKey: {
            LegacyProviderOptionNamespaces.google: {
              LegacyExtensionKeys.jsonSchema: schema,
              LegacyExtensionKeys.enableImageGeneration: true,
              LegacyExtensionKeys.responseModalities: responseModalities,
              LegacyExtensionKeys.safetySettings: [safety],
              LegacyExtensionKeys.maxInlineDataSize: null,
              LegacyExtensionKeys.candidateCount: 2,
              LegacyExtensionKeys.embeddingTaskType: 'retrieval_document',
              LegacyExtensionKeys.embeddingTitle: 'Docs',
              LegacyExtensionKeys.embeddingDimensions: 768,
            },
          },
        },
      );

      final google = legacyGoogleOptions(
        legacyProviderOptionView(
          config,
          LegacyProviderOptionNamespaces.google,
        ),
      );

      expect(google.jsonSchema, schema);
      expect(google.enableImageGeneration, isTrue);
      expect(google.responseModalities, ['TEXT', 'IMAGE']);
      expect(google.hasChatBridgeSupportedResponseModalities, isTrue);
      expect(google.hasStructuredOutputChatBridgeConflict, isTrue);
      expect(google.safetySettings, [safety]);
      expect(google.maxInlineDataSize, legacyGoogleDefaultMaxInlineDataSize);
      expect(google.candidateCount, 2);
      expect(google.embeddingTaskType, 'retrieval_document');
      expect(google.embeddingTitle, 'Docs');
      expect(google.embeddingDimensions, 768);
    });

    test('LegacyOpenAIOptions centralizes OpenAI-family option reads', () {
      final webSearch = legacy.OpenAIBuiltInTools.webSearch();
      final config = legacy.LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-4o',
        extensions: {
          LegacyExtensionKeys.reasoningEffort: legacy.ReasoningEffort.low,
          LegacyExtensionKeys.useResponsesApi: true,
          LegacyExtensionKeys.previousResponseId: 'flat-response',
          LegacyExtensionKeys.verbosity: 'flat',
          legacyProviderOptionsBagKey: {
            LegacyProviderOptionNamespaces.openai: {
              LegacyExtensionKeys.reasoningEffort: 'high',
              LegacyExtensionKeys.useResponsesApi: null,
              LegacyExtensionKeys.previousResponseId: null,
              LegacyExtensionKeys.builtInTools: [webSearch],
              LegacyExtensionKeys.frequencyPenalty: 0.2,
              LegacyExtensionKeys.presencePenalty: 0.3,
              LegacyExtensionKeys.logitBias: {'42': 1.5},
              LegacyExtensionKeys.seed: 7,
              LegacyExtensionKeys.parallelToolCalls: true,
              LegacyExtensionKeys.logprobs: true,
              LegacyExtensionKeys.topLogprobs: 3,
              LegacyExtensionKeys.verbosity: 'high',
              LegacyExtensionKeys.voice: 'alloy',
              LegacyExtensionKeys.embeddingEncodingFormat: 'float',
              LegacyExtensionKeys.embeddingDimensions: 1024,
            },
          },
        },
      );
      final options = legacyProviderOptionView(
        config,
        LegacyProviderOptionNamespaces.openai,
      );

      final family = legacyOpenAIFamilyOptions(options);
      final hosted = legacyOpenAIHostedOptions(options);

      expect(family.useResponsesAPI, isFalse);
      expect(family.previousResponseId, isNull);
      expect(family.builtInTools, [webSearch]);
      expect(family.frequencyPenalty, 0.2);
      expect(family.presencePenalty, 0.3);
      expect(family.logitBias, {'42': 1.5});
      expect(family.seed, 7);
      expect(family.parallelToolCalls, isTrue);
      expect(family.logprobs, isTrue);
      expect(family.topLogprobs, 3);
      expect(family.verbosity, 'high');
      expect(hosted.reasoningEffort, legacy.ReasoningEffort.high);
      expect(hosted.voice, 'alloy');
      expect(hosted.embeddingEncodingFormat, 'float');
      expect(hosted.embeddingDimensions, 1024);
    });

    test('LegacyAnthropicOptions centralizes Anthropic option reads', () {
      const server = legacy.AnthropicMCPServer.url(
        name: 'docs',
        url: 'https://example.com/mcp',
      );
      const config = legacy.LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1',
        model: 'claude-3-5-sonnet-latest',
        extensions: {
          LegacyExtensionKeys.reasoning: true,
          LegacyExtensionKeys.metadata: {'source': 'flat'},
          LegacyExtensionKeys.container: 'flat-container',
          legacyProviderOptionsBagKey: {
            LegacyProviderOptionNamespaces.anthropic: {
              LegacyExtensionKeys.reasoning: null,
              LegacyExtensionKeys.thinkingBudgetTokens: 1024,
              LegacyExtensionKeys.interleavedThinking: true,
              LegacyExtensionKeys.metadata: {'source': 'namespaced'},
              LegacyExtensionKeys.container: null,
              LegacyExtensionKeys.mcpServers: [server],
            },
          },
        },
      );

      final anthropic = legacyAnthropicOptions(
        legacyProviderOptionView(
          config,
          LegacyProviderOptionNamespaces.anthropic,
        ),
      );

      expect(anthropic.reasoning, isFalse);
      expect(anthropic.thinkingBudgetTokens, 1024);
      expect(anthropic.interleavedThinking, isTrue);
      expect(anthropic.metadata, {'source': 'namespaced'});
      expect(anthropic.container, isNull);
      expect(anthropic.mcpServers, [server]);
    });

    test('LegacyElevenLabsOptions centralizes ElevenLabs option reads', () {
      const config = legacy.LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.elevenlabs.io/v1',
        model: 'eleven_multilingual_v2',
        extensions: {
          LegacyExtensionKeys.voiceId: 'flat-voice',
          LegacyExtensionKeys.stability: 0.2,
          legacyProviderOptionsBagKey: {
            LegacyProviderOptionNamespaces.elevenlabs: {
              LegacyExtensionKeys.voiceId: 'voice-123',
              LegacyExtensionKeys.stability: null,
              LegacyExtensionKeys.similarityBoost: 0.8,
              LegacyExtensionKeys.style: 0.4,
              LegacyExtensionKeys.useSpeakerBoost: true,
            },
          },
        },
      );

      final elevenLabs = legacyElevenLabsOptions(
        legacyProviderOptionView(
          config,
          LegacyProviderOptionNamespaces.elevenlabs,
        ),
      );

      expect(elevenLabs.voiceId, 'voice-123');
      expect(elevenLabs.stability, isNull);
      expect(elevenLabs.similarityBoost, 0.8);
      expect(elevenLabs.style, 0.4);
      expect(elevenLabs.useSpeakerBoost, isTrue);
    });

    test('LegacyOllamaOptions centralizes Ollama option reads', () {
      const schema = legacy.StructuredOutputFormat(
        name: 'answer',
        schema: {'type': 'object'},
      );
      const config = legacy.LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'http://localhost:11434',
        model: 'llama3.2',
        extensions: {
          LegacyExtensionKeys.numCtx: 1024,
          LegacyExtensionKeys.keepAlive: 'flat',
          legacyProviderOptionsBagKey: {
            LegacyProviderOptionNamespaces.ollama: {
              LegacyExtensionKeys.jsonSchema: schema,
              LegacyExtensionKeys.numCtx: null,
              LegacyExtensionKeys.numGpu: 2,
              LegacyExtensionKeys.numThread: 8,
              LegacyExtensionKeys.numa: true,
              LegacyExtensionKeys.numBatch: 256,
              LegacyExtensionKeys.keepAlive: '10m',
              LegacyExtensionKeys.raw: false,
              LegacyExtensionKeys.reasoning: true,
            },
          },
        },
      );

      final ollama = legacyOllamaOptions(
        legacyProviderOptionView(
          config,
          LegacyProviderOptionNamespaces.ollama,
        ),
      );

      expect(ollama.jsonSchema, schema);
      expect(ollama.numCtx, isNull);
      expect(ollama.numGpu, 2);
      expect(ollama.numThread, 8);
      expect(ollama.numa, isTrue);
      expect(ollama.numBatch, 256);
      expect(ollama.keepAlive, '10m');
      expect(ollama.raw, isFalse);
      expect(ollama.reasoning, isTrue);
    });

    test('LegacyDeepSeekOptions centralizes DeepSeek option reads', () {
      const config = legacy.LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.deepseek.com',
        model: 'deepseek-chat',
        extensions: {
          LegacyExtensionKeys.logprobs: true,
          LegacyExtensionKeys.deepSeekTopLogprobs: 1,
          legacyProviderOptionsBagKey: {
            LegacyProviderOptionNamespaces.deepseek: {
              LegacyExtensionKeys.logprobs: null,
              LegacyExtensionKeys.deepSeekTopLogprobs: 3,
              LegacyExtensionKeys.deepSeekFrequencyPenalty: 0.2,
              LegacyExtensionKeys.deepSeekPresencePenalty: 0.4,
              LegacyExtensionKeys.deepSeekResponseFormat: {
                'type': 'json_object',
              },
            },
          },
        },
      );

      final deepSeek = legacyDeepSeekOptions(
        legacyProviderOptionView(
          config,
          LegacyProviderOptionNamespaces.deepseek,
        ),
      );

      expect(deepSeek.logprobs, isNull);
      expect(deepSeek.topLogprobs, 3);
      expect(deepSeek.frequencyPenalty, 0.2);
      expect(deepSeek.presencePenalty, 0.4);
      expect(deepSeek.responseFormat, {'type': 'json_object'});
    });

    test('LegacyXAIOptions centralizes xAI option reads', () {
      const schema = legacy.StructuredOutputFormat(
        name: 'answer',
        schema: {'type': 'object'},
      );
      const config = legacy.LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1',
        model: 'grok-3',
        extensions: {
          LegacyExtensionKeys.xaiLiveSearch: true,
          LegacyExtensionKeys.webSearchConfig: legacy.WebSearchConfig(
            enabled: true,
            searchType: legacy.WebSearchType.news,
            maxResults: 4,
            blockedDomains: ['example.com'],
            fromDate: '2025-01-01',
            toDate: '2025-01-31',
            mode: 'always',
          ),
          legacyProviderOptionsBagKey: {
            LegacyProviderOptionNamespaces.xai: {
              LegacyExtensionKeys.jsonSchema: schema,
              LegacyExtensionKeys.embeddingEncodingFormat: 'float',
              LegacyExtensionKeys.embeddingDimensions: 1024,
              LegacyExtensionKeys.xaiLiveSearch: null,
            },
          },
        },
      );

      final xai = legacyXAIOptions(
        legacyProviderOptionView(
          config,
          LegacyProviderOptionNamespaces.xai,
        ),
      );

      expect(xai.jsonSchema, schema);
      expect(xai.embeddingEncodingFormat, 'float');
      expect(xai.embeddingDimensions, 1024);
      expect(xai.liveSearchEnabled, isNull);
      expect(xai.liveSearch, isTrue);
      expect(xai.searchParameters?.mode, 'always');
      expect(xai.searchParameters?.maxSearchResults, 4);
      expect(xai.searchParameters?.fromDate, '2025-01-01');
      expect(xai.searchParameters?.toDate, '2025-01-31');
      expect(xai.searchParameters?.sources?.single.sourceType, 'news');
      expect(xai.searchParameters?.sources?.single.excludedWebsites, [
        'example.com',
      ]);
    });

    test(
        'LLMBuilder.build returns compat provider subclasses for migrated providers',
        () async {
      final openaiProvider = await legacy.LLMBuilder()
          .openai()
          .apiKey('test-key')
          .model('gpt-4o')
          .build();
      final openRouterProvider = await legacy.LLMBuilder()
          .openRouter()
          .apiKey('test-key')
          .model('openai/gpt-4o-mini')
          .build();
      final googleProvider = await legacy.LLMBuilder()
          .google()
          .apiKey('test-key')
          .model('gemini-2.5-flash')
          .build();
      final anthropicProvider = await legacy.LLMBuilder()
          .anthropic()
          .apiKey('test-key')
          .model('claude-sonnet-4-5')
          .build();
      final deepSeekProvider = await legacy.LLMBuilder()
          .deepseek()
          .apiKey('test-key')
          .model('deepseek-chat')
          .build();
      final groqProvider = await legacy.LLMBuilder()
          .groq()
          .apiKey('test-key')
          .model('llama-3.3-70b-versatile')
          .build();
      final xaiProvider = await legacy.LLMBuilder()
          .xai()
          .apiKey('test-key')
          .model('grok-3')
          .build();
      final phindProvider = await legacy.LLMBuilder()
          .phind()
          .apiKey('test-key')
          .model('Phind-70B')
          .build();

      expect(openaiProvider, isA<CompatOpenAIProvider>());
      expect(openaiProvider, isA<legacy.OpenAIProvider>());
      expect(openRouterProvider, isA<CompatOpenRouterProvider>());
      expect(openRouterProvider, isA<legacy.OpenAIProvider>());
      expect(googleProvider, isA<CompatGoogleProvider>());
      expect(googleProvider, isA<legacy.GoogleProvider>());
      expect(anthropicProvider, isA<CompatAnthropicProvider>());
      expect(anthropicProvider, isA<legacy.AnthropicProvider>());
      expect(deepSeekProvider, isA<CompatDeepSeekProvider>());
      expect(deepSeekProvider, isA<legacy.DeepSeekProvider>());
      expect(groqProvider, isA<CompatGroqProvider>());
      expect(groqProvider, isA<legacy.GroqProvider>());
      expect(xaiProvider, isA<CompatXAIProvider>());
      expect(xaiProvider, isA<legacy.XAIProvider>());
      expect(phindProvider, isA<CompatPhindProvider>());
      expect(phindProvider, isA<legacy.PhindProvider>());
    });

    test('legacy chat adapter maps messages, tools, results, and usage',
        () async {
      final fakeModel = _FakeLanguageModel(
        onGenerate: (request) async {
          return core.GenerateTextResult(
            content: [
              const core.ReasoningContentPart('Plan first.'),
              const core.TextContentPart('Hello from the refactored core.'),
              const core.ToolCallContentPart(
                core.ToolCallContent(
                  toolCallId: 'call_1',
                  toolName: 'weather',
                  input: {'city': 'Hong Kong'},
                ),
              ),
            ],
            finishReason: core.FinishReason.toolCalls,
            usage: const core.UsageStats(
              inputTokens: 11,
              outputTokens: 7,
              totalTokens: 18,
              reasoningTokens: 3,
            ),
          );
        },
      );

      final adapter = LegacyChatCapabilityAdapter(
        model: fakeModel,
        config: legacy.LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://example.com',
          model: 'test-model',
          systemPrompt: 'You are concise.',
          maxTokens: 256,
          temperature: 0.2,
          topP: 0.9,
          topK: 20,
          toolChoice: const legacy.AnyToolChoice(),
        ),
      );

      final response = await adapter.chatWithTools(
        [
          legacy.ChatMessage.user('Say hello.'),
        ],
        [
          legacy.Tool.function(
            name: 'weather',
            description: 'Get weather details.',
            parameters: const legacy.ParametersSchema(
              schemaType: 'object',
              properties: {
                'city': legacy.ParameterProperty(
                  propertyType: 'string',
                  description: 'City name.',
                ),
              },
              required: ['city'],
            ),
          ),
        ],
      );

      expect(fakeModel.lastRequest, isNotNull);
      expect(fakeModel.lastRequest!.prompt, hasLength(2));
      expect(
          fakeModel.lastRequest!.prompt.first, isA<core.SystemPromptMessage>());
      expect(fakeModel.lastRequest!.tools, hasLength(1));
      expect(fakeModel.lastRequest!.toolChoice, isA<core.RequiredToolChoice>());
      expect(fakeModel.lastRequest!.options.maxOutputTokens, 256);
      expect(fakeModel.lastRequest!.options.temperature, 0.2);
      expect(fakeModel.lastRequest!.options.topP, 0.9);
      expect(fakeModel.lastRequest!.options.topK, 20);

      expect(response.text, 'Hello from the refactored core.');
      expect(response.thinking, 'Plan first.');
      expect(response.toolCalls, hasLength(1));
      expect(response.toolCalls!.single.function.name, 'weather');
      expect(response.toolCalls!.single.function.arguments,
          '{"city":"Hong Kong"}');
      expect(response.usage?.promptTokens, 11);
      expect(response.usage?.completionTokens, 7);
      expect(response.usage?.totalTokens, 18);
      expect(response.usage?.reasoningTokens, 3);
    });

    test(
        'legacy chat adapter routes legacy jsonSchema through shared responseFormat',
        () {
      final adapter = LegacyChatCapabilityAdapter(
        model: _FakeLanguageModel(),
        config: legacy.LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://example.com',
          model: 'test-model',
        ).withExtension(
          'jsonSchema',
          const legacy.StructuredOutputFormat(
            name: 'answer',
            description: 'Structured answer payload.',
            strict: true,
            schema: {
              'type': 'object',
              'properties': {
                'value': {'type': 'string'},
              },
              'required': ['value'],
            },
          ),
        ),
        providerOptions: const modern_openai.OpenAIGenerateTextOptions(
          verbosity: 'high',
        ),
      );

      final request = adapter.buildRequest([
        legacy.ChatMessage.user('Return JSON.'),
      ], null);

      final responseFormat =
          request.options.responseFormat as core.JsonResponseFormat?;
      expect(responseFormat, isNotNull);
      expect(responseFormat!.name, 'answer');
      expect(responseFormat.description, 'Structured answer payload.');
      expect(responseFormat.strict, isTrue);
      expect(
        responseFormat.schema.toJson(),
        const {
          'type': 'object',
          'properties': {
            'value': {'type': 'string'},
          },
          'required': ['value'],
        },
      );

      final providerOptions = request.callOptions.providerOptions
          as modern_openai.OpenAIGenerateTextOptions?;
      expect(providerOptions, isNotNull);
      expect(providerOptions!.verbosity, 'high');
      expect(providerOptions.responseFormat, isNull);
    });

    test(
        'legacy chat adapter lets namespaced jsonSchema null block flat fallback',
        () {
      const flatSchema = legacy.StructuredOutputFormat(
        name: 'flat',
        schema: {'type': 'object'},
      );
      const config = legacy.LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://example.com',
        model: 'test-model',
        extensions: {
          LegacyExtensionKeys.jsonSchema: flatSchema,
          legacyProviderOptionsBagKey: {
            LegacyProviderOptionNamespaces.openrouter: {
              LegacyExtensionKeys.jsonSchema: null,
            },
          },
        },
      );
      final adapter = LegacyChatCapabilityAdapter(
        model: _FakeLanguageModel(),
        config: config,
        providerOptionsNamespace: LegacyProviderOptionNamespaces.openrouter,
      );

      final request = adapter.buildRequest([
        legacy.ChatMessage.user('Return JSON.'),
      ], null);

      expect(request.options.responseFormat, isNull);
    });

    test('legacy chat adapter maps streaming deltas and completion events',
        () async {
      final fakeModel = _FakeLanguageModel(
        onStream: (request) {
          return Stream<core.TextStreamEvent>.fromIterable([
            const core.TextDeltaEvent(
              id: 'text_1',
              delta: 'Hello',
            ),
            const core.ReasoningDeltaEvent(
              id: 'reasoning_1',
              delta: 'Thinking...',
            ),
            const core.ToolInputStartEvent(
              toolCallId: 'call_1',
              toolName: 'weather',
            ),
            const core.ToolInputDeltaEvent(
              toolCallId: 'call_1',
              delta: '{"city":"Hong Kong"}',
            ),
            const core.ToolCallEvent(
              toolCall: core.ToolCallContent(
                toolCallId: 'call_1',
                toolName: 'weather',
                input: {'city': 'Hong Kong'},
              ),
            ),
            const core.FinishEvent(
              finishReason: core.FinishReason.toolCalls,
              usage: core.UsageStats(
                inputTokens: 5,
                outputTokens: 2,
                totalTokens: 7,
              ),
            ),
          ]);
        },
      );

      final adapter = LegacyChatCapabilityAdapter(
        model: fakeModel,
        config: legacy.LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://example.com',
          model: 'test-model',
        ),
      );

      final events = await adapter.chatStream([
        legacy.ChatMessage.user('Call the weather tool.'),
      ]).toList();

      expect(events[0], isA<legacy.TextDeltaEvent>());
      expect((events[0] as legacy.TextDeltaEvent).delta, 'Hello');
      expect(events[1], isA<legacy.ThinkingDeltaEvent>());
      expect((events[1] as legacy.ThinkingDeltaEvent).delta, 'Thinking...');
      expect(events[2], isA<legacy.ToolCallDeltaEvent>());
      expect(
        (events[2] as legacy.ToolCallDeltaEvent).toolCall.function.arguments,
        '{"city":"Hong Kong"}',
      );
      expect(events[3], isA<legacy.ToolCallDeltaEvent>());
      expect(events[4], isA<legacy.CompletionEvent>());

      final completion = events[4] as legacy.CompletionEvent;
      expect(completion.response.text, 'Hello');
      expect(completion.response.thinking, 'Thinking...');
      expect(completion.response.toolCalls, hasLength(1));
      expect(completion.response.usage?.totalTokens, 7);
    });

    test(
        'Google legacy chat adapter projects generated images to legacy stream text markers',
        () async {
      final fakeModel = _FakeLanguageModel(
        onStream: (request) {
          return Stream<core.TextStreamEvent>.fromIterable([
            const core.TextDeltaEvent(
              id: 'text_1',
              delta: 'Here is the result.',
            ),
            core.FileEvent(
              core.GeneratedFile(
                mediaType: 'image/png',
                data: const core.FileBytesData.constBytes([1, 2, 3]),
              ),
            ),
            const core.FinishEvent(
              finishReason: core.FinishReason.stop,
            ),
          ]);
        },
      );

      final adapter = GoogleLegacyChatCapabilityAdapter(
        model: fakeModel,
        config: legacy.LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://example.com',
          model: 'gemini-2.5-flash',
        ),
      );

      final events = await adapter.chatStream([
        legacy.ChatMessage.user('Generate an image.'),
      ]).toList();

      expect(events, hasLength(3));
      expect(events[0], isA<legacy.TextDeltaEvent>());
      expect((events[0] as legacy.TextDeltaEvent).delta, 'Here is the result.');
      expect(events[1], isA<legacy.TextDeltaEvent>());
      expect(
        (events[1] as legacy.TextDeltaEvent).delta,
        '[Generated image: image/png]',
      );

      final completion = events[2] as legacy.CompletionEvent;
      expect(completion.response.text, 'Here is the result.');
    });

    test(
        'Anthropic legacy adapter promotes cached MessageBuilder tools into the bridged request',
        () {
      final adapter = AnthropicLegacyChatCapabilityAdapter(
        model: _FakeLanguageModel(),
        config: legacy.LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://example.com',
          model: 'claude-sonnet-4-5',
        ),
      );

      final request = adapter.buildRequest(
        [
          legacy.MessageBuilder.system()
              .text('Reusable instructions')
              .tools([
                legacy.Tool.function(
                  name: 'weather',
                  description: 'Get weather details.',
                  parameters: const legacy.ParametersSchema(
                    schemaType: 'object',
                    properties: {
                      'city': legacy.ParameterProperty(
                        propertyType: 'string',
                        description: 'City name.',
                      ),
                    },
                    required: ['city'],
                  ),
                ),
              ])
              .anthropicConfig(
                (anthropic) =>
                    anthropic.cache(ttl: legacy.AnthropicCacheTtl.oneHour),
              )
              .build(),
          legacy.ChatMessage.user('Hello'),
        ],
        null,
      );

      expect(request.tools, hasLength(1));
      expect(request.tools.single.name, 'weather');

      final providerOptions = request.callOptions.providerOptions
          as modern_anthropic.AnthropicGenerateTextOptions;
      expect(providerOptions.toolsCacheControl?.type, 'ephemeral');
      expect(providerOptions.toolsCacheControl?.ttl, '1h');

      final systemMessage = request.prompt.first as core.SystemPromptMessage;
      final textPart = systemMessage.parts.single as core.TextPromptPart;
      final promptOptions = textPart.providerOptions
          as modern_anthropic.AnthropicPromptPartOptions;
      expect(promptOptions.cacheControl?.type, 'ephemeral');
      expect(promptOptions.cacheControl?.ttl, '1h');
      expect(textPart.providerMetadata, isNull);
    });

    test(
        'Anthropic legacy adapter maps raw text content blocks into prompt parts with cache options',
        () {
      final adapter = AnthropicLegacyChatCapabilityAdapter(
        model: _FakeLanguageModel(),
        config: legacy.LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://example.com',
          model: 'claude-sonnet-4-5',
        ),
      );

      final request = adapter.buildRequest(
        [
          legacy.ChatMessage.user('Trailing content').withExtension(
            'anthropic',
            {
              'contentBlocks': [
                {
                  'type': 'text',
                  'text': 'Raw prefix',
                },
                {
                  'type': 'text',
                  'text': 'Cached raw block',
                  'cache_control': {
                    'type': 'ephemeral',
                    'ttl': '1h',
                  },
                },
              ],
            },
          ),
        ],
        null,
      );

      final userMessage = request.prompt.single as core.UserPromptMessage;
      expect(userMessage.parts, hasLength(3));

      final firstPart = userMessage.parts[0] as core.TextPromptPart;
      expect(firstPart.text, 'Raw prefix');
      expect(firstPart.providerMetadata, isNull);

      final secondPart = userMessage.parts[1] as core.TextPromptPart;
      expect(secondPart.text, 'Cached raw block');
      final secondPartOptions = secondPart.providerOptions
          as modern_anthropic.AnthropicPromptPartOptions;
      expect(
        secondPartOptions.cacheControl?.toJson(),
        {
          'type': 'ephemeral',
          'ttl': '1h',
        },
      );
      expect(secondPart.providerMetadata, isNull);

      final thirdPart = userMessage.parts[2] as core.TextPromptPart;
      expect(thirdPart.text, 'Trailing content');
      expect(thirdPart.providerMetadata, isNull);
    });

    test(
        'Anthropic legacy adapter maps raw image and document blocks into prompt parts',
        () {
      final adapter = AnthropicLegacyChatCapabilityAdapter(
        model: _FakeLanguageModel(),
        config: legacy.LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://example.com',
          model: 'claude-sonnet-4-5',
        ),
      );

      final request = adapter.buildRequest(
        [
          legacy.ChatMessage.user('').withExtension(
            'anthropic',
            {
              'contentBlocks': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'url',
                    'url': 'https://example.com/image.png',
                  },
                  'cache_control': {
                    'type': 'ephemeral',
                    'ttl': '1h',
                  },
                },
                {
                  'type': 'document',
                  'title': 'notes.txt',
                  'source': {
                    'type': 'text',
                    'media_type': 'text/plain',
                    'data': 'hello document',
                  },
                },
              ],
            },
          ),
        ],
        null,
      );

      final userMessage = request.prompt.single as core.UserPromptMessage;
      expect(userMessage.parts, hasLength(2));

      final imagePart = userMessage.parts[0] as core.ImagePromptPart;
      expect(imagePart.uri, Uri.parse('https://example.com/image.png'));
      expect(imagePart.bytes, isNull);
      final imagePartOptions = imagePart.providerOptions
          as modern_anthropic.AnthropicPromptPartOptions;
      expect(
        imagePartOptions.cacheControl?.toJson(),
        {
          'type': 'ephemeral',
          'ttl': '1h',
        },
      );
      expect(imagePart.providerMetadata, isNull);

      final documentPart = userMessage.parts[1] as core.FilePromptPart;
      expect(documentPart.mediaType, 'text/plain');
      expect(documentPart.filename, 'notes.txt');
      expect(documentPart.bytes, 'hello document'.codeUnits);
      expect(documentPart.providerMetadata, isNull);
    });

    test(
        'Anthropic legacy adapter maps raw tool replay blocks into prompt messages',
        () {
      final adapter = AnthropicLegacyChatCapabilityAdapter(
        model: _FakeLanguageModel(),
        config: legacy.LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://example.com',
          model: 'claude-sonnet-4-5',
        ),
      );

      final request = adapter.buildRequest(
        [
          legacy.ChatMessage.assistant('Trailing assistant text').withExtension(
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
                {
                  'type': 'mcp_tool_use',
                  'id': 'mcptoolu_1',
                  'name': 'search_docs',
                  'server_name': 'workspace',
                  'input': {
                    'query': 'bridge',
                  },
                },
              ],
            },
          ),
          legacy.ChatMessage.user('').withExtension(
            'anthropic',
            {
              'contentBlocks': [
                {
                  'type': 'tool_result',
                  'tool_use_id': 'toolu_1',
                  'content': '{"temp":72}',
                },
                {
                  'type': 'mcp_tool_result',
                  'tool_use_id': 'mcptoolu_1',
                  'content': {
                    'status': 'ok',
                  },
                  'is_error': true,
                },
              ],
            },
          ),
        ],
        null,
      );

      expect(request.prompt, hasLength(3));

      final assistantMessage = request.prompt[0] as core.AssistantPromptMessage;
      expect(assistantMessage.parts, hasLength(3));

      final toolUsePart = assistantMessage.parts[0] as core.ToolCallPromptPart;
      expect(toolUsePart.toolCallId, 'toolu_1');
      expect(toolUsePart.toolName, 'weather');
      expect(toolUsePart.providerExecuted, isFalse);

      final mcpToolUsePart =
          assistantMessage.parts[1] as core.ToolCallPromptPart;
      expect(mcpToolUsePart.toolCallId, 'mcptoolu_1');
      expect(mcpToolUsePart.toolName, 'mcp.search_docs');
      expect(mcpToolUsePart.providerExecuted, isTrue);
      expect(mcpToolUsePart.isDynamic, isTrue);
      expect(mcpToolUsePart.title, 'workspace');

      final trailingText = assistantMessage.parts[2] as core.TextPromptPart;
      expect(trailingText.text, 'Trailing assistant text');

      final toolResultMessage = request.prompt[1] as core.ToolPromptMessage;
      expect(toolResultMessage.toolName, 'weather');
      final toolResultPart =
          toolResultMessage.parts.single as core.ToolResultPromptPart;
      expect(toolResultPart.toolCallId, 'toolu_1');
      expect(toolResultPart.toolName, 'weather');
      expect(toolResultPart.output, '{"temp":72}');
      expect(toolResultPart.isError, isFalse);

      final mcpToolResultMessage = request.prompt[2] as core.ToolPromptMessage;
      expect(mcpToolResultMessage.toolName, 'mcp.search_docs');
      final mcpToolResultPart =
          mcpToolResultMessage.parts.single as core.ToolResultPromptPart;
      expect(mcpToolResultPart.toolCallId, 'mcptoolu_1');
      expect(mcpToolResultPart.toolName, 'mcp.search_docs');
      expect(mcpToolResultPart.output, {
        'status': 'ok',
      });
      expect(mcpToolResultPart.isError, isTrue);
    });

    test(
        'Anthropic legacy adapter maps provider-native retrieval result blocks into custom tool replay messages',
        () {
      final adapter = AnthropicLegacyChatCapabilityAdapter(
        model: _FakeLanguageModel(),
        config: legacy.LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://example.com',
          model: 'claude-sonnet-4-5',
        ),
      );

      final request = adapter.buildRequest(
        [
          legacy.ChatMessage.user('').withExtension(
            'anthropic',
            {
              'contentBlocks': [
                {
                  'type': 'web_search_tool_result',
                  'tool_use_id': 'srvtoolu_1',
                  'content': [
                    {
                      'url': 'https://example.com/search',
                      'title': 'Search Result',
                      'type': 'web_search_result',
                    },
                  ],
                },
                {
                  'type': 'web_fetch_tool_result',
                  'tool_use_id': 'srvtoolu_2',
                  'content': {
                    'type': 'web_fetch_result',
                    'url': 'https://example.com/article',
                    'content': {
                      'type': 'document',
                      'source': {
                        'type': 'text',
                        'media_type': 'text/plain',
                        'data': 'Article content',
                      },
                    },
                  },
                },
              ],
            },
          ),
        ],
        null,
      );

      expect(request.prompt, hasLength(2));

      final searchReplay = request.prompt[0] as core.ToolPromptMessage;
      expect(searchReplay.toolName, 'web_search');
      final searchPart = searchReplay.parts.single as core.CustomPromptPart;
      expect(searchPart.kind, 'anthropic.result.web_search');
      expect(searchPart.data, {
        'replayRole': 'tool',
        'toolCallId': 'srvtoolu_1',
        'toolName': 'web_search',
        'block': {
          'type': 'web_search_tool_result',
          'tool_use_id': 'srvtoolu_1',
          'content': [
            {
              'url': 'https://example.com/search',
              'title': 'Search Result',
              'type': 'web_search_result',
            },
          ],
        },
      });

      final fetchReplay = request.prompt[1] as core.ToolPromptMessage;
      expect(fetchReplay.toolName, 'web_fetch');
      final fetchPart = fetchReplay.parts.single as core.CustomPromptPart;
      expect(fetchPart.kind, 'anthropic.result.web_fetch');
      expect(fetchPart.data, {
        'replayRole': 'tool',
        'toolCallId': 'srvtoolu_2',
        'toolName': 'web_fetch',
        'block': {
          'type': 'web_fetch_tool_result',
          'tool_use_id': 'srvtoolu_2',
          'content': {
            'type': 'web_fetch_result',
            'url': 'https://example.com/article',
            'content': {
              'type': 'document',
              'source': {
                'type': 'text',
                'media_type': 'text/plain',
                'data': 'Article content',
              },
            },
          },
        },
      });
    });

    test(
        'Anthropic legacy adapter maps tool-search result blocks into custom tool replay messages',
        () {
      final adapter = AnthropicLegacyChatCapabilityAdapter(
        model: _FakeLanguageModel(),
        config: legacy.LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://example.com',
          model: 'claude-sonnet-4-5',
        ),
      );

      final request = adapter.buildRequest(
        [
          legacy.ChatMessage.assistant('').withExtension(
            'anthropic',
            {
              'contentBlocks': [
                {
                  'type': 'server_tool_use',
                  'id': 'srvtoolu_3',
                  'name': 'tool_search_tool_regex',
                  'input': {
                    'pattern': 'weather|forecast',
                    'limit': 5,
                  },
                },
              ],
            },
          ),
          legacy.ChatMessage.user('').withExtension(
            'anthropic',
            {
              'contentBlocks': [
                {
                  'type': 'tool_search_tool_result',
                  'tool_use_id': 'srvtoolu_3',
                  'content': {
                    'type': 'tool_search_tool_search_result',
                    'tool_references': [
                      {
                        'type': 'tool_reference',
                        'tool_name': 'get_weather',
                      },
                    ],
                  },
                },
              ],
            },
          ),
        ],
        null,
      );

      expect(request.prompt, hasLength(2));

      final replay = request.prompt[1] as core.ToolPromptMessage;
      expect(replay.toolName, 'tool_search_tool_regex');
      final part = replay.parts.single as core.CustomPromptPart;
      expect(part.kind, 'anthropic.result.tool_search');
      expect(part.data, {
        'replayRole': 'tool',
        'toolCallId': 'srvtoolu_3',
        'toolName': 'tool_search_tool_regex',
        'block': {
          'type': 'tool_search_tool_result',
          'tool_use_id': 'srvtoolu_3',
          'content': {
            'type': 'tool_search_tool_search_result',
            'tool_references': [
              {
                'type': 'tool_reference',
                'tool_name': 'get_weather',
              },
            ],
          },
        },
      });
    });

    test(
        'Compat DeepSeek provider maps namespaced providerOptions into typed DeepSeek request options',
        () async {
      TransportRequest? capturedRequest;

      final provider = buildCompatDeepSeekProvider(
        legacy.LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: 'deepseek-chat',
        ).withExtensions({
          'customTransportClient': _FakeTransportClient(
            onSend: (request) async {
              capturedRequest = request;
              return TransportResponse(
                statusCode: 200,
                body: {
                  'id': 'chatcmpl_deepseek_compat_options',
                  'model': 'deepseek-chat',
                  'created': 1710000200,
                  'choices': [
                    {
                      'index': 0,
                      'finish_reason': 'stop',
                      'message': {
                        'role': 'assistant',
                        'content': '{"value":"Done."}',
                      },
                    },
                  ],
                },
              );
            },
          ),
          legacyProviderOptionsBagKey: {
            LegacyProviderOptionNamespaces.deepseek: {
              LegacyExtensionKeys.logprobs: false,
              LegacyExtensionKeys.deepSeekTopLogprobs: 2,
              LegacyExtensionKeys.deepSeekFrequencyPenalty: 0.1,
              LegacyExtensionKeys.deepSeekPresencePenalty: 0.2,
              LegacyExtensionKeys.deepSeekResponseFormat: {
                'type': 'json_object',
              },
            },
          },
        }),
      );

      final response = await provider.chat([
        legacy.ChatMessage.user('Return JSON.'),
      ]);

      expect(response.text, '{"value":"Done."}');
      expect(capturedRequest, isNotNull);

      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(requestBody['logprobs'], isFalse);
      expect(requestBody['top_logprobs'], 2);
      expect(requestBody['frequency_penalty'], 0.1);
      expect(requestBody['presence_penalty'], 0.2);
      expect(requestBody['response_format'], {'type': 'json_object'});
    });

    test(
        'Compat OpenRouter provider maps legacy webSearchConfig into online-model settings',
        () async {
      TransportRequest? capturedRequest;

      final provider = buildCompatOpenRouterProvider(
        legacy.LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://openrouter.ai/api/v1/',
          model: 'openai/gpt-4o-mini',
        ).withExtensions({
          'customTransportClient': _FakeTransportClient(
            onSend: (request) async {
              capturedRequest = request;
              return TransportResponse(
                statusCode: 200,
                body: {
                  'id': 'chatcmpl_openrouter_compat_1',
                  'model': 'openai/gpt-4o-mini:online',
                  'created': 1710000400,
                  'choices': [
                    {
                      'index': 0,
                      'finish_reason': 'stop',
                      'message': {
                        'role': 'assistant',
                        'content': 'Search ready.',
                      },
                    },
                  ],
                },
              );
            },
          ),
          'webSearchConfig': const legacy.WebSearchConfig(
            maxResults: 5,
            searchPrompt: 'Focus on recent developments.',
            strategy: legacy.WebSearchStrategy.plugin,
            searchType: legacy.WebSearchType.web,
          ),
        }),
      );

      final response = await provider.chat([
        legacy.ChatMessage.user('Search the latest updates.'),
      ]);

      expect(response.text, 'Search ready.');
      expect(capturedRequest, isNotNull);

      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(requestBody['model'], 'openai/gpt-4o-mini:online');
    });

    test(
        'Compat OpenRouter provider maps namespaced webSearchConfig into online-model settings',
        () async {
      TransportRequest? capturedRequest;

      final provider = buildCompatOpenRouterProvider(
        legacy.LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://openrouter.ai/api/v1/',
          model: 'openai/gpt-4o-mini',
        ).withExtensions({
          'customTransportClient': _FakeTransportClient(
            onSend: (request) async {
              capturedRequest = request;
              return TransportResponse(
                statusCode: 200,
                body: {
                  'id': 'chatcmpl_openrouter_compat_2',
                  'model': 'openai/gpt-4o-mini:online',
                  'created': 1710000401,
                  'choices': [
                    {
                      'index': 0,
                      'finish_reason': 'stop',
                      'message': {
                        'role': 'assistant',
                        'content': 'Search ready.',
                      },
                    },
                  ],
                },
              );
            },
          ),
          legacyProviderOptionsBagKey: {
            LegacyProviderOptionNamespaces.openrouter: {
              LegacyExtensionKeys.webSearchConfig: const legacy.WebSearchConfig(
                maxResults: 5,
                searchPrompt: 'Focus on recent developments.',
                strategy: legacy.WebSearchStrategy.plugin,
                searchType: legacy.WebSearchType.web,
              ),
            },
          },
        }),
      );

      final response = await provider.chat([
        legacy.ChatMessage.user('Search the latest updates.'),
      ]);

      expect(response.text, 'Search ready.');
      expect(capturedRequest, isNotNull);

      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(requestBody['model'], 'openai/gpt-4o-mini:online');
    });

    test(
        'Compat OpenRouter provider routes namespaced jsonSchema through shared responseFormat',
        () async {
      TransportRequest? capturedRequest;
      const schema = legacy.StructuredOutputFormat(
        name: 'answer',
        strict: true,
        schema: {
          'type': 'object',
          'properties': {
            'value': {'type': 'string'},
          },
        },
      );

      final provider = buildCompatOpenRouterProvider(
        legacy.LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://openrouter.ai/api/v1/',
          model: 'openai/gpt-4o-mini',
        ).withExtensions({
          'customTransportClient': _FakeTransportClient(
            onSend: (request) async {
              capturedRequest = request;
              return TransportResponse(
                statusCode: 200,
                body: {
                  'id': 'chatcmpl_openrouter_structured',
                  'model': 'openai/gpt-4o-mini',
                  'created': 1710000402,
                  'choices': [
                    {
                      'index': 0,
                      'finish_reason': 'stop',
                      'message': {
                        'role': 'assistant',
                        'content': '{"value":"Done."}',
                      },
                    },
                  ],
                },
              );
            },
          ),
          legacyProviderOptionsBagKey: {
            LegacyProviderOptionNamespaces.openrouter: {
              LegacyExtensionKeys.jsonSchema: schema,
            },
          },
        }),
      );

      final response = await provider.chat([
        legacy.ChatMessage.user('Return JSON.'),
      ]);

      expect(response.text, '{"value":"Done."}');
      expect(capturedRequest, isNotNull);

      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['response_format'],
        {
          'type': 'json_schema',
          'json_schema': {
            'name': 'answer',
            'schema': {
              'type': 'object',
              'properties': {
                'value': {'type': 'string'},
              },
              'additionalProperties': false,
            },
            'strict': true,
          },
        },
      );
    });

    test(
        'Compat OpenAI provider routes legacy jsonSchema through shared responseFormat',
        () async {
      TransportRequest? capturedRequest;

      final provider = buildCompatOpenAIProvider(
        legacy.LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.openai.com/v1/',
          model: 'gpt-4.1-mini',
        ).withExtensions({
          'customTransportClient': _FakeTransportClient(
            onSend: (request) async {
              capturedRequest = request;
              return TransportResponse(
                statusCode: 200,
                body: {
                  'id': 'resp_compat_structured',
                  'model': 'gpt-4.1-mini',
                  'created_at': 1710000500,
                  'status': 'completed',
                  'output': [
                    {
                      'id': 'msg_1',
                      'type': 'message',
                      'status': 'completed',
                      'role': 'assistant',
                      'content': [
                        {
                          'type': 'output_text',
                          'text': '{"value":"Done."}',
                          'annotations': [],
                        },
                      ],
                    },
                  ],
                },
              );
            },
          ),
          'jsonSchema': const legacy.StructuredOutputFormat(
            name: 'answer',
            description: 'Structured answer payload.',
            strict: true,
            schema: {
              'type': 'object',
              'properties': {
                'value': {'type': 'string'},
              },
              'required': ['value'],
            },
          ),
        }),
      );

      final response = await provider.chat([
        legacy.ChatMessage.user('Return JSON.'),
      ]);

      expect(response.text, '{"value":"Done."}');
      expect(capturedRequest, isNotNull);

      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['response_format'],
        {
          'type': 'json_schema',
          'json_schema': {
            'name': 'answer',
            'description': 'Structured answer payload.',
            'schema': {
              'type': 'object',
              'properties': {
                'value': {'type': 'string'},
              },
              'required': ['value'],
              'additionalProperties': false,
            },
            'strict': true,
          },
        },
      );
    });

    test(
        'Compat OpenAI provider routes legacy user image and file messages through the Responses bridge',
        () async {
      TransportRequest? capturedRequest;

      final provider = buildCompatOpenAIProvider(
        legacy.LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.openai.com/v1/',
          model: 'gpt-4.1-mini',
        ).withExtensions({
          'customTransportClient': _FakeTransportClient(
            onSend: (request) async {
              capturedRequest = request;
              return TransportResponse(
                statusCode: 200,
                body: {
                  'id': 'resp_compat_multimodal',
                  'model': 'gpt-4.1-mini',
                  'created_at': 1710000500,
                  'status': 'completed',
                  'output': [
                    {
                      'id': 'msg_1',
                      'type': 'message',
                      'status': 'completed',
                      'role': 'assistant',
                      'content': [
                        {
                          'type': 'output_text',
                          'text': 'Done.',
                          'annotations': [],
                        },
                      ],
                    },
                  ],
                },
              );
            },
          ),
        }),
      );

      final response = await provider.chat([
        legacy.ChatMessage.user('Describe both inputs.'),
        legacy.ChatMessage.image(
          role: legacy.ChatRole.user,
          mime: legacy.ImageMime.png,
          data: const [1, 2, 3, 4],
        ),
        legacy.ChatMessage.file(
          role: legacy.ChatRole.user,
          mime: legacy.FileMime.pdf,
          data: const [5, 6, 7, 8],
        ),
      ]);

      expect(response.text, 'Done.');
      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.uri.toString(), contains('/responses'));

      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['input'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text': 'Describe both inputs.',
              },
            ],
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_image',
                'image_url': 'data:image/png;base64,AQIDBA==',
              },
            ],
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_file',
                'filename': 'part-0.pdf',
                'file_data': 'data:application/pdf;base64,BQYHCA==',
              },
            ],
          },
        ],
      );
    });

    test(
        'Compat OpenAI provider routes common tool replay through the Responses bridge',
        () async {
      TransportRequest? capturedRequest;
      final toolCall = legacy.ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const legacy.FunctionCall(
          name: 'weather',
          arguments: '{"city":"Hong Kong"}',
        ),
      );

      final provider = buildCompatOpenAIProvider(
        legacy.LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.openai.com/v1/',
          model: 'gpt-4.1-mini',
          toolChoice: const legacy.AutoToolChoice(),
        ).withExtensions({
          'customTransportClient': _FakeTransportClient(
            onSend: (request) async {
              capturedRequest = request;
              return TransportResponse(
                statusCode: 200,
                body: {
                  'id': 'resp_compat_tool_replay',
                  'model': 'gpt-4.1-mini',
                  'created_at': 1710000500,
                  'status': 'completed',
                  'output': [
                    {
                      'id': 'msg_1',
                      'type': 'message',
                      'status': 'completed',
                      'role': 'assistant',
                      'content': [
                        {
                          'type': 'output_text',
                          'text': 'Done.',
                          'annotations': [],
                        },
                      ],
                    },
                  ],
                },
              );
            },
          ),
        }),
      );

      final response = await provider.chatWithTools(
        [
          legacy.ChatMessage.user('Check the weather.'),
          legacy.ChatMessage.toolUse(toolCalls: [toolCall]),
          legacy.ChatMessage.toolResult(results: [toolCall]),
        ],
        [
          legacy.Tool.function(
            name: 'weather',
            description: 'Get weather information.',
            parameters: const legacy.ParametersSchema(
              schemaType: 'object',
              properties: {
                'city': legacy.ParameterProperty(
                  propertyType: 'string',
                  description: 'City name.',
                ),
              },
              required: ['city'],
            ),
          ),
        ],
      );

      expect(response.text, 'Done.');
      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.uri.toString(), contains('/responses'));

      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['input'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text': 'Check the weather.',
              },
            ],
          },
          {
            'type': 'function_call',
            'call_id': 'call_1',
            'name': 'weather',
            'arguments': '{"city":"Hong Kong"}',
          },
          {
            'type': 'function_call_output',
            'call_id': 'call_1',
            'output': '{"city":"Hong Kong"}',
          },
        ],
      );
    });

    test(
        'Compat Google provider routes legacy jsonSchema through shared responseFormat',
        () async {
      TransportRequest? capturedRequest;

      final provider = buildCompatGoogleProvider(
        legacy.LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://generativelanguage.googleapis.com',
          model: 'gemini-2.5-flash',
        ).withExtensions({
          'customTransportClient': _FakeTransportClient(
            onSend: (request) async {
              capturedRequest = request;
              return const TransportResponse(
                statusCode: 200,
                body: {
                  'responseId': 'resp_google_compat_structured',
                  'modelVersion': 'gemini-2.5-flash',
                  'candidates': [
                    {
                      'content': {
                        'parts': [
                          {
                            'text': '{"value":"Done."}',
                          },
                        ],
                      },
                      'finishReason': 'STOP',
                    },
                  ],
                },
              );
            },
          ),
          'jsonSchema': const legacy.StructuredOutputFormat(
            name: 'answer',
            schema: {
              'type': 'object',
              'properties': {
                'value': {'type': 'string'},
              },
              'required': ['value'],
            },
          ),
        }),
      );

      final response = await provider.chat([
        legacy.ChatMessage.user('Return JSON.'),
      ]);

      expect(response.text, '{"value":"Done."}');
      expect(capturedRequest, isNotNull);

      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['generationConfig'],
        {
          'responseMimeType': 'application/json',
          'responseSchema': {
            'type': 'object',
            'properties': {
              'value': {'type': 'string'},
            },
            'required': ['value'],
          },
        },
      );
    });

    test(
        'Compat Google provider routes legacy image-generation settings through the Google chat bridge',
        () async {
      TransportRequest? capturedRequest;

      final provider = buildCompatGoogleProvider(
        legacy.LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://generativelanguage.googleapis.com',
          model: 'gemini-2.5-flash',
        ).withExtensions({
          'customTransportClient': _FakeTransportClient(
            onSend: (request) async {
              capturedRequest = request;
              return const TransportResponse(
                statusCode: 200,
                body: {
                  'responseId': 'resp_google_compat_image',
                  'modelVersion': 'gemini-2.5-flash',
                  'candidates': [
                    {
                      'content': {
                        'parts': [
                          {
                            'inlineData': {
                              'mimeType': 'image/png',
                              'data': 'AQID',
                            },
                          },
                        ],
                      },
                      'finishReason': 'STOP',
                    },
                  ],
                },
              );
            },
          ),
          'enableImageGeneration': true,
          'candidateCount': 1,
          'webSearchEnabled': true,
        }),
      );

      final response = await provider.chat([
        legacy.ChatMessage.image(
          role: legacy.ChatRole.user,
          mime: legacy.ImageMime.png,
          data: const [1, 2, 3],
          content: 'Generate a variation.',
        ),
      ]);

      expect(response.text, isNull);
      expect(capturedRequest, isNotNull);

      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['generationConfig'],
        {
          'candidateCount': 1,
          'responseModalities': ['TEXT', 'IMAGE'],
        },
      );
      expect(
        requestBody['tools'],
        [
          {
            'googleSearch': <String, Object?>{},
          },
        ],
      );
    });

    test(
        'Compat xAI provider maps legacy live-search inputs into typed xAI request options',
        () async {
      TransportRequest? capturedRequest;

      final provider = buildCompatXAIProvider(
        legacy.LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://example.com/v1/',
          model: 'grok-3',
        ).withExtensions({
          'customTransportClient': _FakeTransportClient(
            onSend: (request) async {
              capturedRequest = request;
              return TransportResponse(
                statusCode: 200,
                body: {
                  'id': 'chatcmpl_xai_compat_1',
                  'model': 'grok-3',
                  'created': 1710000300,
                  'choices': [
                    {
                      'index': 0,
                      'finish_reason': 'stop',
                      'message': {
                        'role': 'assistant',
                        'content': 'Here is the summary.',
                      },
                    },
                  ],
                },
              );
            },
          ),
          'searchParameters': const legacy.SearchParameters(
            mode: 'always',
            sources: [
              legacy.SearchSource(
                sourceType: 'web',
                excludedWebsites: ['spam.example'],
              ),
              legacy.SearchSource(sourceType: 'news'),
            ],
            maxSearchResults: 7,
            fromDate: '2026-03-01',
            toDate: '2026-03-30',
          ),
          'jsonSchema': const legacy.StructuredOutputFormat(
            name: 'answer',
            strict: true,
            schema: {
              'type': 'object',
              'properties': {
                'value': {'type': 'string'},
              },
            },
          ),
        }),
      );

      final response = await provider.chat([
        legacy.ChatMessage.user('Search recent AI updates.'),
      ]);

      expect(response.text, 'Here is the summary.');
      expect(capturedRequest, isNotNull);

      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['search_parameters'],
        {
          'mode': 'on',
          'return_citations': true,
          'from_date': '2026-03-01',
          'to_date': '2026-03-30',
          'max_search_results': 7,
          'sources': [
            {
              'type': 'web',
              'excluded_websites': ['spam.example'],
            },
            {
              'type': 'news',
            },
          ],
        },
      );
      expect(
        requestBody['response_format'],
        {
          'type': 'json_schema',
          'json_schema': {
            'name': 'answer',
            'schema': {
              'type': 'object',
              'properties': {
                'value': {'type': 'string'},
              },
              'additionalProperties': false,
            },
            'strict': true,
          },
        },
      );
    });

    test(
        'Compat xAI provider routes namespaced jsonSchema through shared responseFormat',
        () async {
      TransportRequest? capturedRequest;
      const schema = legacy.StructuredOutputFormat(
        name: 'answer',
        strict: true,
        schema: {
          'type': 'object',
          'properties': {
            'value': {'type': 'string'},
          },
        },
      );

      final provider = buildCompatXAIProvider(
        legacy.LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://example.com/v1/',
          model: 'grok-3',
        ).withExtensions({
          'customTransportClient': _FakeTransportClient(
            onSend: (request) async {
              capturedRequest = request;
              return TransportResponse(
                statusCode: 200,
                body: {
                  'id': 'chatcmpl_xai_structured',
                  'model': 'grok-3',
                  'created': 1710000301,
                  'choices': [
                    {
                      'index': 0,
                      'finish_reason': 'stop',
                      'message': {
                        'role': 'assistant',
                        'content': '{"value":"Done."}',
                      },
                    },
                  ],
                },
              );
            },
          ),
          legacyProviderOptionsBagKey: {
            LegacyProviderOptionNamespaces.xai: {
              LegacyExtensionKeys.jsonSchema: schema,
            },
          },
        }),
      );

      final response = await provider.chat([
        legacy.ChatMessage.user('Return JSON.'),
      ]);

      expect(response.text, '{"value":"Done."}');
      expect(capturedRequest, isNotNull);

      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['response_format'],
        {
          'type': 'json_schema',
          'json_schema': {
            'name': 'answer',
            'schema': {
              'type': 'object',
              'properties': {
                'value': {'type': 'string'},
              },
              'additionalProperties': false,
            },
            'strict': true,
          },
        },
      );
    });

    test(
        'legacy chat adapter ignores core-only stream events that old API cannot represent',
        () async {
      final fakeModel = _FakeLanguageModel(
        onStream: (request) {
          return Stream<core.TextStreamEvent>.fromIterable([
            core.StartEvent(),
            const core.ResponseMetadataEvent(
              responseId: 'resp_123',
              modelId: 'fake-model',
            ),
            const core.StepStartEvent(stepId: 'step_1'),
            const core.TextStartEvent(id: 'text_1'),
            const core.TextDeltaEvent(
              id: 'text_1',
              delta: 'Hello',
            ),
            const core.TextEndEvent(id: 'text_1'),
            core.SourceEvent(
              core.SourceReference(
                kind: core.SourceReferenceKind.url,
                sourceId: 'source_1',
                uri: Uri.parse('https://example.com'),
              ),
            ),
            const core.FileEvent(
              core.GeneratedFile(
                mediaType: 'text/plain',
                filename: 'result.txt',
                data: core.FileTextData('result'),
              ),
            ),
            const core.ToolApprovalRequestEvent(
              approvalId: 'approval_1',
              toolCallId: 'call_1',
            ),
            const core.ToolOutputDeniedEvent(toolCallId: 'call_1'),
            const core.CustomEvent(kind: 'compat.note'),
            const core.FinishEvent(
              finishReason: core.FinishReason.stop,
            ),
          ]);
        },
      );

      final adapter = LegacyChatCapabilityAdapter(
        model: fakeModel,
        config: legacy.LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://example.com',
          model: 'test-model',
        ),
      );

      final events = await adapter.chatStream([
        legacy.ChatMessage.user('Say hello.'),
      ]).toList();

      expect(events, hasLength(2));
      expect(events[0], isA<legacy.TextDeltaEvent>());
      expect((events[0] as legacy.TextDeltaEvent).delta, 'Hello');
      expect(events[1], isA<legacy.CompletionEvent>());
      expect((events[1] as legacy.CompletionEvent).response.text, 'Hello');
    });
  });
}

typedef _FakeLanguageModel = FakeLanguageModel;
typedef _FakeTransportClient = FakeTransportClient;
