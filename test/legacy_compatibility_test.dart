import 'package:llm_dart/llm_dart.dart' as legacy;
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as modern_anthropic;
import 'package:llm_dart/src/compatibility/compat_providers.dart';
import 'package:llm_dart/src/compatibility/legacy_chat_adapter.dart';
import 'package:llm_dart/src/config/legacy_config_keys.dart';
import 'package:llm_dart/src/config/legacy_provider_options.dart';
import 'package:llm_dart_core/llm_dart_core.dart' as core;
import 'package:llm_dart_openai/llm_dart_openai.dart' as modern_openai;
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('Legacy Compatibility', () {
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
    });

    test(
        'LLMBuilder.build keeps non-migrated Phind provider on legacy implementation',
        () async {
      final phindProvider = await legacy.LLMBuilder()
          .phind()
          .apiKey('test-key')
          .model('Phind-70B')
          .build();

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
                bytes: const [1, 2, 3],
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
      expect(textPart.providerMetadata?.values['anthropic'], isNotNull);
    });

    test(
        'Anthropic legacy adapter maps raw text content blocks into prompt parts with cache metadata',
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
      expect(
        secondPart.providerMetadata?.values,
        {
          'anthropic': {
            'cacheControl': {
              'type': 'ephemeral',
              'ttl': '1h',
            },
          },
        },
      );

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
      expect(
        imagePart.providerMetadata?.values,
        {
          'anthropic': {
            'cacheControl': {
              'type': 'ephemeral',
              'ttl': '1h',
            },
          },
        },
      );

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
          'webSearchConfig': legacy.WebSearchConfig.openRouter(
            maxResults: 5,
            searchPrompt: 'Focus on recent developments.',
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
              LegacyExtensionKeys.webSearchConfig:
                  legacy.WebSearchConfig.openRouter(
                maxResults: 5,
                searchPrompt: 'Focus on recent developments.',
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
