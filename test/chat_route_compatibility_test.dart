import 'package:llm_dart/llm_dart.dart' as legacy;
import 'package:llm_dart/src/compatibility/chat_route_compatibility.dart';
import 'package:test/test.dart';

void main() {
  group('Chat Route Compatibility', () {
    test(
        'OpenAI bridge accepts simple text-only requests with allowed extensions',
        () {
      final config = _baseConfig('gpt-4o').withExtensions({
        'customTransportClient': _FakeTransportClient(),
        'useResponsesAPI': true,
        'previousResponseId': 'resp_123',
        'parallelToolCalls': true,
      });

      final result = canUseOpenAIChatBridge(
        config,
        [
          legacy.ChatMessage.system('You are concise.'),
          legacy.ChatMessage.user('Hello'),
        ],
        null,
      );

      expect(result, isTrue);
    });

    test(
        'OpenAI bridge accepts function tools, built-in tools, and structured output',
        () {
      final withSchema = _baseConfig('gpt-4o').withExtensions({
        'builtInTools': <legacy.OpenAIBuiltInTool>[
          legacy.OpenAIBuiltInTools.webSearch(),
          legacy.OpenAIBuiltInTools.fileSearch(
            vectorStoreIds: const ['vs_123'],
          ),
        ],
      });

      final config = withSchema.withExtension(
        'jsonSchema',
        const legacy.StructuredOutputFormat(
          name: 'answer',
          schema: {
            'type': 'object',
            'properties': {
              'value': {'type': 'string'},
            },
          },
        ),
      );

      final result = canUseOpenAIChatBridge(
        config,
        [
          legacy.ChatMessage.user('Return JSON'),
        ],
        [_weatherTool()],
      );

      expect(result, isTrue);
    });

    test(
        'DeepSeek bridge accepts the audited deepseek-chat text and function-tool subset',
        () {
      final toolCall = legacy.ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const legacy.FunctionCall(
          name: 'weather',
          arguments: '{"city":"Hong Kong"}',
        ),
      );

      final result = canUseDeepSeekChatBridge(
        _baseConfig('deepseek-chat'),
        [
          legacy.ChatMessage.system('You are concise.'),
          legacy.ChatMessage.user('Check the weather.'),
          legacy.ChatMessage.toolUse(toolCalls: [toolCall]),
          legacy.ChatMessage.toolResult(results: [toolCall]),
        ],
        [_weatherTool()],
      );

      expect(result, isTrue);
    });

    test(
        'DeepSeek bridge rejects deepseek-reasoner and DeepSeek-specific legacy extensions',
        () {
      final reasonerResult = canUseDeepSeekChatBridge(
        _baseConfig('deepseek-reasoner'),
        [
          legacy.ChatMessage.user('Think first.'),
        ],
        null,
      );

      final extensionResult = canUseDeepSeekChatBridge(
        _baseConfig('deepseek-chat').withExtensions({
          'logprobs': true,
        }),
        [
          legacy.ChatMessage.user('Hello'),
        ],
        null,
      );

      expect(reasonerResult, isFalse);
      expect(extensionResult, isFalse);
    });

    test(
        'DeepSeek bridge rejects stop sequences and mixed config/system-message shaping',
        () {
      final stopSequenceResult = canUseDeepSeekChatBridge(
        _baseConfig('deepseek-chat').copyWith(
          stopSequences: const ['STOP'],
        ),
        [
          legacy.ChatMessage.user('Hello'),
        ],
        null,
      );

      final mixedSystemResult = canUseDeepSeekChatBridge(
        _baseConfig('deepseek-chat').copyWith(
          systemPrompt: 'Global system prompt',
        ),
        [
          legacy.ChatMessage.system('Message-level system prompt'),
          legacy.ChatMessage.user('Hello'),
        ],
        null,
      );

      expect(stopSequenceResult, isFalse);
      expect(mixedSystemResult, isFalse);
    });

    test(
        'OpenRouter bridge accepts the audited text and function-tool subset without search shaping',
        () {
      final toolCall = legacy.ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const legacy.FunctionCall(
          name: 'weather',
          arguments: '{"city":"Hong Kong"}',
        ),
      );

      final result = canUseOpenRouterChatBridge(
        _baseConfig('openai/gpt-4o-mini'),
        [
          legacy.ChatMessage.system('You are concise.'),
          legacy.ChatMessage.user('Check the weather.'),
          legacy.ChatMessage.toolUse(toolCalls: [toolCall]),
          legacy.ChatMessage.toolResult(results: [toolCall]),
        ],
        [_weatherTool()],
      );

      expect(result, isTrue);
    });

    test(
        'OpenRouter bridge accepts explicit online-model traffic and the bare webSearchEnabled migration input',
        () {
      final onlineModelResult = canUseOpenRouterChatBridge(
        _baseConfig('openai/gpt-4o-mini:online'),
        [
          legacy.ChatMessage.user('Search the web.'),
        ],
        null,
      );

      final webSearchEnabledResult = canUseOpenRouterChatBridge(
        _baseConfig('openai/gpt-4o-mini').withExtensions({
          'webSearchEnabled': true,
        }),
        [
          legacy.ChatMessage.user('Search the web.'),
        ],
        null,
      );

      expect(onlineModelResult, isTrue);
      expect(webSearchEnabledResult, isTrue);
    });

    test(
        'OpenRouter bridge still rejects richer search-shaped requests and openrouter-specific search extensions',
        () {
      final webSearchConfigResult = canUseOpenRouterChatBridge(
        _baseConfig('openai/gpt-4o-mini').withExtensions({
          'webSearchConfig': legacy.WebSearchConfig.openRouter(
            maxResults: 5,
            searchPrompt: 'Focus on recent developments.',
          ),
        }),
        [
          legacy.ChatMessage.user('Search the web.'),
        ],
        null,
      );

      final searchPromptResult = canUseOpenRouterChatBridge(
        _baseConfig('openai/gpt-4o-mini').withExtensions({
          'searchPrompt': 'Focus on recent developments.',
        }),
        [
          legacy.ChatMessage.user('Search the web.'),
        ],
        null,
      );

      final useOnlineShortcutResult = canUseOpenRouterChatBridge(
        _baseConfig('openai/gpt-4o-mini').withExtensions({
          'useOnlineShortcut': true,
        }),
        [
          legacy.ChatMessage.user('Search the web.'),
        ],
        null,
      );

      expect(webSearchConfigResult, isFalse);
      expect(searchPromptResult, isFalse);
      expect(useOnlineShortcutResult, isFalse);
    });

    test(
        'OpenRouter bridge rejects deepseek-r1, user override, and Responses-only options',
        () {
      final deepseekR1Result = canUseOpenRouterChatBridge(
        _baseConfig('deepseek/deepseek-r1'),
        [
          legacy.ChatMessage.user('Think first.'),
        ],
        null,
      );

      final userResult = canUseOpenRouterChatBridge(
        _baseConfig('openai/gpt-4o-mini').copyWith(
          user: 'user-1',
        ),
        [
          legacy.ChatMessage.user('Hello'),
        ],
        null,
      );

      final responsesResult = canUseOpenRouterChatBridge(
        _baseConfig('openai/gpt-4o-mini').withExtensions({
          'useResponsesAPI': true,
        }),
        [
          legacy.ChatMessage.user('Hello'),
        ],
        null,
      );

      expect(deepseekR1Result, isFalse);
      expect(userResult, isFalse);
      expect(responsesResult, isFalse);
    });

    test(
        'Groq bridge accepts the audited text-only subset plus common function tools',
        () {
      final config = _baseConfig('llama-3.3-70b-versatile').copyWith(
        toolChoice: const legacy.AutoToolChoice(),
      );

      final result = canUseGroqChatBridge(
        config,
        [
          legacy.ChatMessage.system('You are concise.'),
          legacy.ChatMessage.user('Check the weather.'),
          legacy.ChatMessage.assistant('I can call a tool if needed.'),
        ],
        [_weatherTool()],
      );

      expect(result, isTrue);
    });

    test(
        'Groq bridge rejects tool replay, stop sequences, and ignored legacy-only controls',
        () {
      final toolCall = legacy.ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const legacy.FunctionCall(
          name: 'weather',
          arguments: '{"city":"Hong Kong"}',
        ),
      );

      final toolReplayResult = canUseGroqChatBridge(
        _baseConfig('llama-3.3-70b-versatile'),
        [
          legacy.ChatMessage.user('Hello'),
          legacy.ChatMessage.toolResult(results: [toolCall]),
        ],
        [_weatherTool()],
      );

      final stopSequenceResult = canUseGroqChatBridge(
        _baseConfig('llama-3.3-70b-versatile').copyWith(
          stopSequences: const ['STOP'],
        ),
        [
          legacy.ChatMessage.user('Hello'),
        ],
        null,
      );

      final structuredOutputResult = canUseGroqChatBridge(
        _baseConfig('llama-3.3-70b-versatile').withExtension(
          'jsonSchema',
          const legacy.StructuredOutputFormat(
            name: 'answer',
            schema: {
              'type': 'object',
              'properties': {
                'value': {'type': 'string'},
              },
            },
          ),
        ),
        [
          legacy.ChatMessage.user('Return JSON'),
        ],
        null,
      );

      expect(toolReplayResult, isFalse);
      expect(stopSequenceResult, isFalse);
      expect(structuredOutputResult, isFalse);
    });

    test(
        'xAI bridge accepts the audited no-search text subset with function tools and structured output',
        () {
      final config = _baseConfig('grok-3')
          .copyWith(
            toolChoice: const legacy.AutoToolChoice(),
          )
          .withExtension(
            'jsonSchema',
            const legacy.StructuredOutputFormat(
              name: 'answer',
              schema: {
                'type': 'object',
                'properties': {
                  'value': {'type': 'string'},
                },
              },
            ),
          );

      final result = canUseXAIChatBridge(
        config,
        [
          legacy.ChatMessage.system('You are concise.'),
          legacy.ChatMessage.user('Return JSON if needed.'),
          legacy.ChatMessage.assistant('I can call a tool if needed.'),
        ],
        [_weatherTool()],
      );

      expect(result, isTrue);
    });

    test('xAI bridge accepts the audited legacy live-search migration inputs',
        () {
      final liveSearchResult = canUseXAIChatBridge(
        _baseConfig('grok-3').withExtension('liveSearch', true),
        [
          legacy.ChatMessage.user('Search the web.'),
        ],
        null,
      );

      final searchParametersResult = canUseXAIChatBridge(
        _baseConfig('grok-3').withExtension(
          'searchParameters',
          const legacy.SearchParameters(
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
        ),
        [
          legacy.ChatMessage.user('Search recent updates.'),
        ],
        null,
      );

      final webSearchEnabledResult = canUseXAIChatBridge(
        _baseConfig('grok-3').withExtension('webSearchEnabled', true),
        [
          legacy.ChatMessage.user('Search the web.'),
        ],
        null,
      );

      final webSearchConfigResult = canUseXAIChatBridge(
        _baseConfig('grok-3').withExtension(
          'webSearchConfig',
          const legacy.WebSearchConfig(
            mode: 'always',
            maxResults: 9,
            blockedDomains: ['spam.example'],
            searchType: legacy.WebSearchType.news,
            fromDate: '2026-03-01',
            toDate: '2026-03-30',
          ),
        ),
        [
          legacy.ChatMessage.user('Search the latest news.'),
        ],
        null,
      );

      expect(liveSearchResult, isTrue);
      expect(searchParametersResult, isTrue);
      expect(webSearchEnabledResult, isTrue);
      expect(webSearchConfigResult, isTrue);
    });

    test(
        'xAI bridge still rejects tool replay, ignored legacy-only controls, and unsupported search subset',
        () {
      final toolCall = legacy.ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const legacy.FunctionCall(
          name: 'weather',
          arguments: '{"city":"Hong Kong"}',
        ),
      );

      final invalidModeResult = canUseXAIChatBridge(
        _baseConfig('grok-3').withExtension(
          'searchParameters',
          const legacy.SearchParameters(
            mode: 'sometimes',
          ),
        ),
        [
          legacy.ChatMessage.user('Search the web.'),
        ],
        null,
      );

      final invalidSourceResult = canUseXAIChatBridge(
        _baseConfig('grok-3').withExtension(
          'searchParameters',
          const legacy.SearchParameters(
            sources: [
              legacy.SearchSource(sourceType: 'rss'),
            ],
          ),
        ),
        [
          legacy.ChatMessage.user('Search RSS.'),
        ],
        null,
      );

      final invalidDateResult = canUseXAIChatBridge(
        _baseConfig('grok-3').withExtension(
          'searchParameters',
          const legacy.SearchParameters(
            fromDate: '2026-03-30',
            toDate: '2026-03-01',
          ),
        ),
        [
          legacy.ChatMessage.user('Search a bad range.'),
        ],
        null,
      );

      final toolReplayResult = canUseXAIChatBridge(
        _baseConfig('grok-3'),
        [
          legacy.ChatMessage.user('Hello'),
          legacy.ChatMessage.toolUse(toolCalls: [toolCall]),
        ],
        [_weatherTool()],
      );

      final serviceTierResult = canUseXAIChatBridge(
        _baseConfig('grok-3').copyWith(
          serviceTier: legacy.ServiceTier.auto,
        ),
        [
          legacy.ChatMessage.user('Hello'),
        ],
        null,
      );

      expect(invalidModeResult, isFalse);
      expect(invalidSourceResult, isFalse);
      expect(invalidDateResult, isFalse);
      expect(toolReplayResult, isFalse);
      expect(serviceTierResult, isFalse);
    });

    test('Google bridge accepts multimodal chat and mapped web-search options',
        () {
      final config = _baseConfig('gemini-2.5-flash').withExtensions({
        'webSearchEnabled': true,
        'responseModalities': ['TEXT', 'IMAGE'],
      });

      final toolCall = legacy.ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const legacy.FunctionCall(
          name: 'weather',
          arguments: '{"city":"Hong Kong"}',
        ),
      );

      final result = canUseGoogleChatBridge(
        config,
        [
          legacy.ChatMessage.system('You can browse.'),
          legacy.ChatMessage.image(
            role: legacy.ChatRole.user,
            mime: legacy.ImageMime.png,
            data: const [1, 2, 3],
            content: 'Describe this image',
          ),
          legacy.ChatMessage.toolUse(toolCalls: [toolCall]),
          legacy.ChatMessage.toolResult(results: [toolCall]),
        ],
        null,
      );

      expect(result, isTrue);
    });

    test('Google bridge accepts structured output in text-only mode', () {
      final config = _baseConfig('gemini-2.5-flash').withExtension(
        'jsonSchema',
        const legacy.StructuredOutputFormat(
          name: 'answer',
          schema: {
            'type': 'object',
            'properties': {
              'value': {'type': 'string'},
            },
          },
        ),
      );

      final result = canUseGoogleChatBridge(
        config,
        [
          legacy.ChatMessage.user('Return JSON'),
        ],
        [_weatherTool()],
      );

      expect(result, isTrue);
    });

    test('Google bridge rejects message decorators and unsupported modalities',
        () {
      final config = _baseConfig('gemini-2.5-flash').withExtension(
        'responseModalities',
        ['TEXT', 'AUDIO'],
      );

      final result = canUseGoogleChatBridge(
        config,
        [
          legacy.ChatMessage.user('Hello').withExtension('traceId', 'msg_1'),
        ],
        null,
      );

      expect(result, isFalse);
    });

    test('Google bridge rejects structured output with image modalities', () {
      final config = _baseConfig('gemini-2.5-flash').withExtensions({
        'jsonSchema': const legacy.StructuredOutputFormat(
          name: 'answer',
          schema: {
            'type': 'object',
            'properties': {
              'value': {'type': 'string'},
            },
          },
        ),
        'responseModalities': ['TEXT', 'IMAGE'],
      });

      final result = canUseGoogleChatBridge(
        config,
        [
          legacy.ChatMessage.user('Return JSON and an image'),
        ],
        null,
      );

      expect(result, isFalse);
    });

    test('Anthropic bridge accepts supported media and tool round-trips', () {
      final config = _baseConfig('claude-sonnet-4-5').withExtensions({
        'reasoning': true,
        'webSearchEnabled': true,
      });

      final toolCall = legacy.ToolCall(
        id: 'toolu_1',
        callType: 'function',
        function: const legacy.FunctionCall(
          name: 'lookup',
          arguments: '{"topic":"docs"}',
        ),
      );

      final result = canUseAnthropicChatBridge(
        config,
        [
          legacy.ChatMessage.user('Summarize this document'),
          legacy.ChatMessage.imageUrl(
            role: legacy.ChatRole.user,
            url: 'https://example.com/image.png',
          ),
          legacy.ChatMessage.pdf(
            role: legacy.ChatRole.user,
            data: const [1, 2, 3],
          ),
          legacy.ChatMessage.toolUse(toolCalls: [toolCall]),
          legacy.ChatMessage.toolResult(results: [toolCall]),
        ],
        null,
      );

      expect(result, isTrue);
    });

    test(
        'Anthropic bridge accepts legacy cache markers and tools blocks from MessageBuilder',
        () {
      final config = _baseConfig('claude-sonnet-4-5');
      final cachedSystemMessage = legacy.MessageBuilder.system()
          .text('Use the cached instructions.')
          .tools([
            _weatherTool(),
          ])
          .anthropicConfig(
            (anthropic) =>
                anthropic.cache(ttl: legacy.AnthropicCacheTtl.oneHour),
          )
          .build();

      final result = canUseAnthropicChatBridge(
        config,
        [
          cachedSystemMessage,
          legacy.ChatMessage.user('Hello'),
        ],
        null,
      );

      expect(result, isTrue);
    });

    test(
        'Anthropic bridge rejects ambiguous tool cache policies across cached messages',
        () {
      final config = _baseConfig('claude-sonnet-4-5');

      final cachedSystemMessage = legacy.MessageBuilder.system()
          .text('Cache policy one.')
          .tools([
            _weatherTool(),
          ])
          .anthropicConfig(
            (anthropic) =>
                anthropic.cache(ttl: legacy.AnthropicCacheTtl.oneHour),
          )
          .build();

      final cachedUserMessage = legacy.MessageBuilder.user()
          .text('Cache policy two.')
          .anthropicConfig(
            (anthropic) =>
                anthropic.cache(ttl: legacy.AnthropicCacheTtl.fiveMinutes),
          )
          .build();

      final result = canUseAnthropicChatBridge(
        config,
        [
          cachedSystemMessage,
          cachedUserMessage,
        ],
        null,
      );

      expect(result, isFalse);
    });

    test(
        'Anthropic bridge accepts raw text content blocks in message extensions',
        () {
      final config = _baseConfig('claude-sonnet-4-5');

      final result = canUseAnthropicChatBridge(
        config,
        [
          legacy.ChatMessage.user('Hello').withExtension(
            'anthropic',
            {
              'contentBlocks': [
                {
                  'type': 'text',
                  'text': 'raw provider block',
                },
                {
                  'type': 'text',
                  'text': 'cached provider block',
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

      expect(result, isTrue);
    });

    test(
        'Anthropic bridge accepts user raw image and document content blocks in message extensions',
        () {
      final config = _baseConfig('claude-sonnet-4-5');

      final result = canUseAnthropicChatBridge(
        config,
        [
          legacy.ChatMessage.user('Hello').withExtension(
            'anthropic',
            {
              'contentBlocks': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'url',
                    'url': 'https://example.com/image.png',
                  },
                },
                {
                  'type': 'document',
                  'title': 'notes.txt',
                  'source': {
                    'type': 'text',
                    'media_type': 'text/plain',
                    'data': 'cached notes',
                  },
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

      expect(result, isTrue);
    });

    test(
        'Anthropic bridge accepts raw tool replay blocks that the new Anthropic codec can re-encode',
        () {
      final config = _baseConfig('claude-sonnet-4-5');

      final result = canUseAnthropicChatBridge(
        config,
        [
          legacy.ChatMessage.assistant('').withExtension(
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
                },
              ],
            },
          ),
        ],
        null,
      );

      expect(result, isTrue);
    });

    test(
        'Anthropic bridge accepts raw provider-native retrieval result blocks that the new Anthropic codec can re-encode',
        () {
      final config = _baseConfig('claude-sonnet-4-5');

      final result = canUseAnthropicChatBridge(
        config,
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

      expect(result, isTrue);
    });

    test(
        'Anthropic bridge rejects unsupported raw anthropic content blocks in message extensions',
        () {
      final config = _baseConfig('claude-sonnet-4-5');

      final result = canUseAnthropicChatBridge(
        config,
        [
          legacy.ChatMessage.user('Hello').withExtension(
            'anthropic',
            {
              'contentBlocks': [
                {
                  'type': 'document',
                  'source': {
                    'type': 'url',
                    'url': 'https://example.com/doc.pdf',
                  },
                },
              ],
            },
          ),
        ],
        null,
      );

      expect(result, isFalse);
    });

    test(
        'Anthropic bridge rejects unsupported provider-native raw tool-result blocks',
        () {
      final config = _baseConfig('claude-sonnet-4-5');

      final result = canUseAnthropicChatBridge(
        config,
        [
          legacy.ChatMessage.user('').withExtension(
            'anthropic',
            {
              'contentBlocks': [
                {
                  'type': 'code_execution_tool_result',
                  'tool_use_id': 'srvtoolu_1',
                  'content': {
                    'type': 'code_execution_result',
                  },
                },
              ],
            },
          ),
        ],
        null,
      );

      expect(result, isFalse);
    });

    test(
        'Anthropic bridge rejects parallel tool overrides and unsupported files',
        () {
      final config = _baseConfig('claude-sonnet-4-5').copyWith(
        toolChoice: const legacy.AnyToolChoice(
          disableParallelToolUse: true,
        ),
      );

      final result = canUseAnthropicChatBridge(
        config,
        [
          legacy.ChatMessage.file(
            role: legacy.ChatRole.user,
            mime: const legacy.FileMime('application/json'),
            data: const [1, 2, 3],
          ),
        ],
        null,
      );

      expect(result, isFalse);
    });

    test(
        'Anthropic bridge rejects non-text messages that carry legacy Anthropic extensions',
        () {
      final config = _baseConfig('claude-sonnet-4-5');

      final result = canUseAnthropicChatBridge(
        config,
        [
          legacy.ChatMessage.image(
            role: legacy.ChatRole.user,
            mime: legacy.ImageMime.png,
            data: const [1, 2, 3],
          ).withExtension(
            'anthropic',
            {
              'contentBlocks': [
                {
                  'type': 'text',
                  'text': 'legacy raw text',
                },
              ],
            },
          ),
        ],
        null,
      );

      expect(result, isFalse);
    });

    test(
        'Anthropic bridge rejects raw image and document blocks on non-user messages',
        () {
      final config = _baseConfig('claude-sonnet-4-5');

      final systemImageResult = canUseAnthropicChatBridge(
        config,
        [
          legacy.ChatMessage.system('system').withExtension(
            'anthropic',
            {
              'contentBlocks': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'url',
                    'url': 'https://example.com/image.png',
                  },
                },
              ],
            },
          ),
        ],
        null,
      );

      final assistantDocumentResult = canUseAnthropicChatBridge(
        config,
        [
          legacy.ChatMessage.assistant('assistant').withExtension(
            'anthropic',
            {
              'contentBlocks': [
                {
                  'type': 'document',
                  'title': 'notes.txt',
                  'source': {
                    'type': 'text',
                    'media_type': 'text/plain',
                    'data': 'assistant notes',
                  },
                },
              ],
            },
          ),
        ],
        null,
      );

      expect(systemImageResult, isFalse);
      expect(assistantDocumentResult, isFalse);
    });
  });
}

legacy.LLMConfig _baseConfig(String model) {
  return legacy.LLMConfig(
    apiKey: 'test-key',
    baseUrl: 'https://example.com/',
    model: model,
  );
}

legacy.Tool _weatherTool() {
  return legacy.Tool.function(
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
  );
}

final class _FakeTransportClient implements legacy.TransportClient {
  @override
  Future<legacy.TransportResponse> send(legacy.TransportRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<legacy.StreamingTransportResponse> sendStream(
    legacy.TransportRequest request,
  ) async {
    throw UnimplementedError();
  }
}
