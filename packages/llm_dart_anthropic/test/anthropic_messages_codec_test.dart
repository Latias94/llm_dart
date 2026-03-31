import 'dart:convert';

import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  const codec = AnthropicMessagesCodec();

  group('AnthropicMessagesCodec', () {
    test('groups user and tool blocks into Anthropic user messages', () {
      final weatherTool = FunctionToolDefinition(
        name: 'weather',
        description: 'Get weather details for a city.',
        inputSchema: ToolJsonSchema.object(
          properties: const {
            'city': {
              'type': 'string',
            },
          },
          required: const ['city'],
        ),
      );

      final request = codec.encodeRequest(
        modelId: 'claude-sonnet-4-5',
        prompt: [
          SystemPromptMessage.text('You are helpful.'),
          UserPromptMessage(
            parts: const [
              TextPromptPart('Hello'),
            ],
          ),
          ToolPromptMessage(
            toolName: 'weather',
            parts: const [
              ToolResultPromptPart(
                toolCallId: 'toolu_1',
                toolName: 'weather',
                output: {
                  'temp': 72,
                },
              ),
            ],
          ),
          AssistantPromptMessage(
            parts: const [
              TextPromptPart('Answer   '),
            ],
          ),
        ],
        tools: [
          weatherTool,
        ],
        toolChoice: const RequiredToolChoice(),
        options: const GenerateTextOptions(),
        settings: const AnthropicChatModelSettings(),
        providerOptions: const AnthropicGenerateTextOptions(),
        stream: false,
      );

      expect(
        request.body['system'],
        [
          {
            'type': 'text',
            'text': 'You are helpful.',
          },
        ],
      );
      expect(
        request.body['tools'],
        [
          {
            'name': 'weather',
            'description': 'Get weather details for a city.',
            'input_schema': {
              'type': 'object',
              'properties': {
                'city': {
                  'type': 'string',
                },
              },
              'required': ['city'],
            },
          },
        ],
      );
      expect(
        request.body['tool_choice'],
        {
          'type': 'any',
        },
      );

      final messages = request.body['messages'] as List<Object?>;
      expect(messages, hasLength(2));
      expect(
        messages.first,
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': 'Hello',
            },
            {
              'type': 'tool_result',
              'tool_use_id': 'toolu_1',
              'content': '{"temp":72}',
            },
          ],
        },
      );
      expect(
        messages.last,
        {
          'role': 'assistant',
          'content': [
            {
              'type': 'text',
              'text': 'Answer',
            },
          ],
        },
      );
      expect(request.betaFeatures, isEmpty);
      expect(request.warnings, isEmpty);
    });

    test('encodes image and document prompt parts for multimodal chat', () {
      final request = codec.encodeRequest(
        modelId: 'claude-sonnet-4-5',
        prompt: [
          UserPromptMessage(
            parts: [
              const TextPromptPart('See attachment'),
              const ImagePromptPart(
                mediaType: 'image/png',
                bytes: [1, 2, 3],
              ),
              FilePromptPart(
                mediaType: 'text/plain',
                filename: 'notes.txt',
                bytes: utf8.encode('hello'),
              ),
              FilePromptPart(
                mediaType: 'application/pdf',
                filename: 'doc.pdf',
                uri: Uri.parse('https://example.com/doc.pdf'),
              ),
            ],
          ),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        settings: const AnthropicChatModelSettings(),
        providerOptions: const AnthropicGenerateTextOptions(),
        stream: false,
      );

      final messages = request.body['messages'] as List<Object?>;
      expect(
        messages.single,
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': 'See attachment',
            },
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': 'image/png',
                'data': 'AQID',
              },
            },
            {
              'type': 'document',
              'source': {
                'type': 'text',
                'media_type': 'text/plain',
                'data': 'hello',
              },
              'title': 'notes.txt',
            },
            {
              'type': 'document',
              'source': {
                'type': 'url',
                'url': 'https://example.com/doc.pdf',
              },
              'title': 'doc.pdf',
            },
          ],
        },
      );
    });

    test('adds thinking settings, beta features, and warnings', () {
      final request = codec.encodeRequest(
        modelId: 'claude-sonnet-4-5',
        prompt: [
          UserPromptMessage.text('Think step by step'),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(
          maxOutputTokens: 200,
          temperature: 0.6,
          topP: 0.8,
          topK: 40,
        ),
        settings: const AnthropicChatModelSettings(),
        providerOptions: AnthropicGenerateTextOptions(
          extendedThinking: true,
          interleavedThinking: true,
          metadata: const {
            'request_id': 'req_1',
          },
          container: 'container_1',
          mcpServers: const [
            AnthropicMcpServer.url(
              name: 'workspace',
              url: 'https://mcp.example.com',
            ),
          ],
        ),
        stream: true,
      );

      expect(request.body['max_tokens'], 1224);
      expect(
        request.body['thinking'],
        {
          'type': 'enabled',
          'budget_tokens': 1024,
        },
      );
      expect(request.body.containsKey('temperature'), isFalse);
      expect(request.body.containsKey('top_p'), isFalse);
      expect(request.body.containsKey('top_k'), isFalse);
      expect(
        request.body['metadata'],
        {
          'request_id': 'req_1',
        },
      );
      expect(request.body['container'], 'container_1');
      expect(
        request.body['mcp_servers'],
        [
          {
            'name': 'workspace',
            'type': 'url',
            'url': 'https://mcp.example.com',
          },
        ],
      );
      expect(
        request.betaFeatures,
        [
          'interleaved-thinking-2025-05-14',
          'mcp-client-2025-04-04',
        ],
      );
      expect(
        request.warnings.map((warning) => warning.field),
        containsAll([
          'thinkingBudgetTokens',
          'temperature',
          'topP',
          'topK',
        ]),
      );
    });

    test('rejects forced tool choice when extended thinking is enabled', () {
      expect(
        () => codec.encodeRequest(
          modelId: 'claude-sonnet-4-5',
          prompt: [
            UserPromptMessage.text('Think and use the weather tool.'),
          ],
          tools: [
            FunctionToolDefinition(
              name: 'weather',
              inputSchema: ToolJsonSchema.object(),
            ),
          ],
          toolChoice: const SpecificToolChoice('weather'),
          options: const GenerateTextOptions(),
          settings: const AnthropicChatModelSettings(),
          providerOptions: const AnthropicGenerateTextOptions(
            extendedThinking: true,
          ),
          stream: false,
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            contains('AutoToolChoice or NoneToolChoice'),
          ),
        ),
      );

      expect(
        () => codec.encodeRequest(
          modelId: 'claude-sonnet-4-5',
          prompt: [
            UserPromptMessage.text('Think and use any tool.'),
          ],
          tools: [
            FunctionToolDefinition(
              name: 'weather',
              inputSchema: ToolJsonSchema.object(),
            ),
          ],
          toolChoice: const RequiredToolChoice(),
          options: const GenerateTextOptions(),
          settings: const AnthropicChatModelSettings(),
          providerOptions: const AnthropicGenerateTextOptions(
            extendedThinking: true,
          ),
          stream: false,
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('rejects system messages after conversation blocks', () {
      expect(
        () => codec.encodeRequest(
          modelId: 'claude-sonnet-4-5',
          prompt: [
            SystemPromptMessage.text('Before'),
            UserPromptMessage.text('Hello'),
            SystemPromptMessage.text('After'),
          ],
          tools: const [],
          toolChoice: null,
          options: const GenerateTextOptions(),
          settings: const AnthropicChatModelSettings(),
          providerOptions: const AnthropicGenerateTextOptions(),
          stream: false,
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test(
        'replays provider-executed MCP tool calls and ignores approval responses',
        () {
      final request = codec.encodeRequest(
        modelId: 'claude-sonnet-4-5',
        prompt: [
          UserPromptMessage.text('Open the MCP tool.'),
          AssistantPromptMessage(
            parts: const [
              ToolCallPromptPart(
                toolCallId: 'mcptoolu_1',
                toolName: 'mcp.open_browser',
                input: {
                  'url': 'https://example.com',
                },
                providerExecuted: true,
                isDynamic: true,
                title: 'workspace',
              ),
            ],
          ),
          ToolPromptMessage(
            toolName: 'mcp.open_browser',
            parts: const [
              ToolApprovalResponsePromptPart(
                approvalId: 'approval_1',
                toolCallId: 'mcptoolu_1',
                approved: true,
                reason: 'User approved the external action.',
              ),
              ToolResultPromptPart(
                toolCallId: 'mcptoolu_1',
                toolName: 'mcp.open_browser',
                output: {
                  'status': 'ok',
                },
              ),
            ],
          ),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        settings: const AnthropicChatModelSettings(),
        providerOptions: const AnthropicGenerateTextOptions(),
        stream: false,
      );

      final messages = request.body['messages'] as List<Object?>;
      expect(messages, hasLength(3));
      expect(
        messages[1],
        {
          'role': 'assistant',
          'content': [
            {
              'type': 'mcp_tool_use',
              'id': 'mcptoolu_1',
              'name': 'open_browser',
              'server_name': 'workspace',
              'input': {
                'url': 'https://example.com',
              },
            },
          ],
        },
      );
      expect(
        messages[2],
        {
          'role': 'user',
          'content': [
            {
              'type': 'mcp_tool_result',
              'tool_use_id': 'mcptoolu_1',
              'content': {
                'status': 'ok',
              },
            },
          ],
        },
      );
    });

    test('replays Anthropic web-search tool results from custom prompt parts',
        () {
      final request = codec.encodeRequest(
        modelId: 'claude-sonnet-4-5',
        prompt: [
          UserPromptMessage.text('Search and summarize.'),
          AssistantPromptMessage(
            parts: const [
              ToolCallPromptPart(
                toolCallId: 'srvtoolu_1',
                toolName: 'web_search',
                input: {
                  'query': 'dart sdk',
                },
                providerExecuted: true,
                isDynamic: true,
              ),
            ],
          ),
          ToolPromptMessage(
            toolName: 'web_search',
            parts: const [
              CustomPromptPart(
                kind: 'anthropic.result.web_search',
                data: {
                  'replayRole': 'tool',
                  'toolCallId': 'srvtoolu_1',
                  'toolName': 'web_search',
                  'block': {
                    'type': 'web_search_tool_result',
                    'tool_use_id': 'srvtoolu_1',
                    'content': [
                      {
                        'url': 'https://dart.dev',
                        'title': 'Dart',
                        'type': 'web_search_result',
                      },
                    ],
                  },
                },
              ),
            ],
          ),
          AssistantPromptMessage.text('Dart has a modern SDK.'),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        settings: const AnthropicChatModelSettings(),
        providerOptions: const AnthropicGenerateTextOptions(),
        stream: false,
      );

      expect(
        request.body['messages'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'Search and summarize.',
              },
            ],
          },
          {
            'role': 'assistant',
            'content': [
              {
                'type': 'server_tool_use',
                'id': 'srvtoolu_1',
                'name': 'web_search',
                'input': {
                  'query': 'dart sdk',
                },
              },
            ],
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'web_search_tool_result',
                'tool_use_id': 'srvtoolu_1',
                'content': [
                  {
                    'url': 'https://dart.dev',
                    'title': 'Dart',
                    'type': 'web_search_result',
                  },
                ],
              },
            ],
          },
          {
            'role': 'assistant',
            'content': [
              {
                'type': 'text',
                'text': 'Dart has a modern SDK.',
              },
            ],
          },
        ],
      );
    });

    test('replays Anthropic web-fetch tool results from custom prompt parts',
        () {
      final request = codec.encodeRequest(
        modelId: 'claude-sonnet-4-5',
        prompt: [
          UserPromptMessage.text('Fetch the article.'),
          AssistantPromptMessage(
            parts: const [
              ToolCallPromptPart(
                toolCallId: 'srvtoolu_2',
                toolName: 'web_fetch',
                input: {
                  'url': 'https://example.com/article',
                },
                providerExecuted: true,
                isDynamic: true,
              ),
            ],
          ),
          ToolPromptMessage(
            toolName: 'web_fetch',
            parts: const [
              CustomPromptPart(
                kind: 'anthropic.result.web_fetch',
                data: {
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
                },
              ),
            ],
          ),
          AssistantPromptMessage.text('The article is about Dart.'),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        settings: const AnthropicChatModelSettings(),
        providerOptions: const AnthropicGenerateTextOptions(),
        stream: false,
      );

      expect(
        request.body['messages'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'Fetch the article.',
              },
            ],
          },
          {
            'role': 'assistant',
            'content': [
              {
                'type': 'server_tool_use',
                'id': 'srvtoolu_2',
                'name': 'web_fetch',
                'input': {
                  'url': 'https://example.com/article',
                },
              },
            ],
          },
          {
            'role': 'user',
            'content': [
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
          {
            'role': 'assistant',
            'content': [
              {
                'type': 'text',
                'text': 'The article is about Dart.',
              },
            ],
          },
        ],
      );
    });

    test('replays Anthropic tool-search tool results from custom prompt parts',
        () {
      final request = codec.encodeRequest(
        modelId: 'claude-sonnet-4-5',
        prompt: [
          UserPromptMessage.text('Find the right tool first.'),
          AssistantPromptMessage(
            parts: const [
              ToolCallPromptPart(
                toolCallId: 'srvtoolu_4',
                toolName: 'tool_search_tool_regex',
                input: {
                  'pattern': 'weather|forecast',
                  'limit': 5,
                },
                providerExecuted: true,
                isDynamic: true,
              ),
            ],
          ),
          ToolPromptMessage(
            toolName: 'tool_search_tool_regex',
            parts: const [
              CustomPromptPart(
                kind: 'anthropic.result.tool_search',
                data: {
                  'replayRole': 'tool',
                  'toolCallId': 'srvtoolu_4',
                  'toolName': 'tool_search_tool_regex',
                  'block': {
                    'type': 'tool_search_tool_result',
                    'tool_use_id': 'srvtoolu_4',
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
                },
              ),
            ],
          ),
          AssistantPromptMessage.text('I found the weather tool.'),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        settings: const AnthropicChatModelSettings(),
        providerOptions: const AnthropicGenerateTextOptions(),
        stream: false,
      );

      expect(
        request.body['messages'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'Find the right tool first.',
              },
            ],
          },
          {
            'role': 'assistant',
            'content': [
              {
                'type': 'server_tool_use',
                'id': 'srvtoolu_4',
                'name': 'tool_search_tool_regex',
                'input': {
                  'pattern': 'weather|forecast',
                  'limit': 5,
                },
              },
            ],
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'tool_search_tool_result',
                'tool_use_id': 'srvtoolu_4',
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
          {
            'role': 'assistant',
            'content': [
              {
                'type': 'text',
                'text': 'I found the weather tool.',
              },
            ],
          },
        ],
      );
    });

    test(
        'replays Anthropic code-execution tool results from custom prompt parts',
        () {
      final request = codec.encodeRequest(
        modelId: 'claude-sonnet-4-5',
        prompt: [
          UserPromptMessage.text('Run a command.'),
          AssistantPromptMessage(
            parts: const [
              ToolCallPromptPart(
                toolCallId: 'srvtoolu_3',
                toolName: 'bash_code_execution',
                input: {
                  'command': 'echo hi',
                },
                providerExecuted: true,
                isDynamic: true,
              ),
            ],
          ),
          ToolPromptMessage(
            toolName: 'code_execution',
            parts: const [
              CustomPromptPart(
                kind: 'anthropic.result.code_execution',
                data: {
                  'schema': 'anthropic.execution.result.v1',
                  'replayRole': 'tool',
                  'toolCallId': 'srvtoolu_3',
                  'toolName': 'code_execution',
                  'blockType': 'bash_code_execution_tool_result',
                  'block': {
                    'type': 'bash_code_execution_tool_result',
                    'tool_use_id': 'srvtoolu_3',
                    'content': {
                      'type': 'bash_code_execution_result',
                      'stdout': 'hi\n',
                      'stderr': '',
                      'return_code': 0,
                      'content': [
                        {
                          'type': 'bash_code_execution_output',
                          'file_id': 'file_123',
                        },
                      ],
                    },
                  },
                },
              ),
            ],
          ),
          AssistantPromptMessage.text('Command finished.'),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        settings: const AnthropicChatModelSettings(),
        providerOptions: const AnthropicGenerateTextOptions(),
        stream: false,
      );

      expect(
        request.body['messages'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'Run a command.',
              },
            ],
          },
          {
            'role': 'assistant',
            'content': [
              {
                'type': 'server_tool_use',
                'id': 'srvtoolu_3',
                'name': 'bash_code_execution',
                'input': {
                  'command': 'echo hi',
                },
              },
            ],
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'bash_code_execution_tool_result',
                'tool_use_id': 'srvtoolu_3',
                'content': {
                  'type': 'bash_code_execution_result',
                  'stdout': 'hi\n',
                  'stderr': '',
                  'return_code': 0,
                  'content': [
                    {
                      'type': 'bash_code_execution_output',
                      'file_id': 'file_123',
                    },
                  ],
                },
              },
            ],
          },
          {
            'role': 'assistant',
            'content': [
              {
                'type': 'text',
                'text': 'Command finished.',
              },
            ],
          },
        ],
      );
    });

    test('encodes Anthropic native tools alongside common function tools', () {
      final request = codec.encodeRequest(
        modelId: 'claude-sonnet-4-5',
        prompt: [
          UserPromptMessage.text('Search and answer.'),
        ],
        tools: [
          FunctionToolDefinition(
            name: 'weather',
            inputSchema: ToolJsonSchema.object(),
          ),
        ],
        toolChoice: const AutoToolChoice(),
        options: const GenerateTextOptions(),
        settings: const AnthropicChatModelSettings(),
        providerOptions: const AnthropicGenerateTextOptions(
          tools: [
            AnthropicWebSearchTool20250305(
              maxUses: 3,
            ),
            AnthropicCodeExecutionTool20260120(),
          ],
        ),
        stream: false,
      );

      expect(
        request.body['tools'],
        [
          {
            'name': 'weather',
            'input_schema': {
              'type': 'object',
            },
          },
          {
            'type': 'web_search_20250305',
            'name': 'web_search',
            'max_uses': 3,
          },
          {
            'type': 'code_execution_20260120',
            'name': 'code_execution',
          },
        ],
      );
      expect(
        request.body['tool_choice'],
        {
          'type': 'auto',
        },
      );
    });

    test(
        'encodes Anthropic tool-search native tools and deferred function tools',
        () {
      final request = codec.encodeRequest(
        modelId: 'claude-sonnet-4-5',
        prompt: [
          UserPromptMessage.text('Find and use the right tool.'),
        ],
        tools: [
          FunctionToolDefinition(
            name: 'get_weather',
            inputSchema: ToolJsonSchema.object(),
          ),
          FunctionToolDefinition(
            name: 'get_forecast',
            inputSchema: ToolJsonSchema.object(),
          ),
        ],
        toolChoice: const AutoToolChoice(),
        options: const GenerateTextOptions(),
        settings: const AnthropicChatModelSettings(
          tools: [
            AnthropicToolSearchRegexTool20251119(),
          ],
          deferredToolNames: [
            'get_weather',
          ],
        ),
        providerOptions: const AnthropicGenerateTextOptions(),
        stream: false,
      );

      expect(
        request.body['tools'],
        [
          {
            'name': 'get_weather',
            'input_schema': {
              'type': 'object',
            },
            'defer_loading': true,
          },
          {
            'name': 'get_forecast',
            'input_schema': {
              'type': 'object',
            },
          },
          {
            'type': 'tool_search_tool_regex_20251119',
            'name': 'tool_search_tool_regex',
          },
        ],
      );
      expect(
        request.body['tool_choice'],
        {
          'type': 'auto',
        },
      );
      expect(
        request.warnings
            .where((warning) => warning.field == 'deferredToolNames'),
        isEmpty,
      );
    });

    test('normalizes deferred tool names and warns when tool-search is missing',
        () {
      final request = codec.encodeRequest(
        modelId: 'claude-sonnet-4-5',
        prompt: [
          UserPromptMessage.text('Use a deferred tool.'),
        ],
        tools: [
          FunctionToolDefinition(
            name: 'get_weather',
            inputSchema: ToolJsonSchema.object(),
          ),
        ],
        toolChoice: const AutoToolChoice(),
        options: const GenerateTextOptions(),
        settings: const AnthropicChatModelSettings(),
        providerOptions: const AnthropicGenerateTextOptions(
          deferredToolNames: [
            'get_weather',
            'get_weather',
            '',
            'missing_tool',
          ],
        ),
        stream: false,
      );

      expect(
        request.body['tools'],
        [
          {
            'name': 'get_weather',
            'input_schema': {
              'type': 'object',
            },
            'defer_loading': true,
          },
        ],
      );

      final deferredWarnings = request.warnings
          .where((warning) => warning.field == 'deferredToolNames')
          .map((warning) => warning.message)
          .toList();
      expect(deferredWarnings, hasLength(3));
      expect(
        deferredWarnings,
        contains(
          contains(
            'duplicates or empty values',
          ),
        ),
      );
      expect(
        deferredWarnings,
        contains(
          contains(
            'Ignoring unknown names: missing_tool',
          ),
        ),
      );
      expect(
        deferredWarnings,
        contains(
          contains(
            'without a tool-search native tool',
          ),
        ),
      );
    });

    test('encodes cache control from Anthropic metadata and tool cache options',
        () {
      final request = codec.encodeRequest(
        modelId: 'claude-sonnet-4-5',
        prompt: [
          SystemPromptMessage(
            parts: [
              TextPromptPart(
                'Reusable instructions',
                providerMetadata: const ProviderMetadata({
                  'anthropic': {
                    'contentBlocks': [
                      {
                        'type': 'text',
                        'text': '',
                        'cache_control': {
                          'type': 'ephemeral',
                          'ttl': '1h',
                        },
                      },
                      {
                        'type': 'tools',
                        'tools': [],
                      },
                    ],
                  },
                }),
              ),
            ],
          ),
          UserPromptMessage(
            parts: [
              TextPromptPart(
                'Hello',
                providerMetadata: const ProviderMetadata({
                  'anthropic': {
                    'cacheControl': {
                      'type': 'ephemeral',
                      'ttl': '5m',
                    },
                  },
                }),
              ),
            ],
          ),
        ],
        tools: [
          FunctionToolDefinition(
            name: 'weather',
            inputSchema: ToolJsonSchema.object(),
          ),
        ],
        toolChoice: const AutoToolChoice(),
        options: const GenerateTextOptions(),
        settings: const AnthropicChatModelSettings(),
        providerOptions: const AnthropicGenerateTextOptions(
          toolsCacheControl: AnthropicCacheControl.ephemeral(
            ttl: '1h',
          ),
        ),
        stream: false,
      );

      expect(
        request.body['system'],
        [
          {
            'type': 'text',
            'text': 'Reusable instructions',
            'cache_control': {
              'type': 'ephemeral',
              'ttl': '1h',
            },
          },
        ],
      );

      expect(
        request.body['messages'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'Hello',
                'cache_control': {
                  'type': 'ephemeral',
                  'ttl': '5m',
                },
              },
            ],
          },
        ],
      );

      expect(
        request.body['tools'],
        [
          {
            'name': 'weather',
            'input_schema': {
              'type': 'object',
            },
            'cache_control': {
              'type': 'ephemeral',
              'ttl': '1h',
            },
          },
        ],
      );
      expect(
        request.betaFeatures,
        contains('extended-cache-ttl-2025-04-11'),
      );
    });

    test('encodes cache control for image and document prompt parts', () {
      final request = codec.encodeRequest(
        modelId: 'claude-sonnet-4-5',
        prompt: [
          UserPromptMessage(
            parts: [
              ImagePromptPart(
                mediaType: 'image/png',
                uri: Uri.parse('https://example.com/image.png'),
                providerMetadata: const ProviderMetadata({
                  'anthropic': {
                    'cacheControl': {
                      'type': 'ephemeral',
                      'ttl': '1h',
                    },
                  },
                }),
              ),
              FilePromptPart(
                mediaType: 'text/plain',
                filename: 'notes.txt',
                bytes: utf8.encode('cached document'),
                providerMetadata: const ProviderMetadata({
                  'anthropic': {
                    'cacheControl': {
                      'type': 'ephemeral',
                      'ttl': '5m',
                    },
                  },
                }),
              ),
            ],
          ),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        settings: const AnthropicChatModelSettings(),
        providerOptions: const AnthropicGenerateTextOptions(),
        stream: false,
      );

      expect(
        request.body['messages'],
        [
          {
            'role': 'user',
            'content': [
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
                'source': {
                  'type': 'text',
                  'media_type': 'text/plain',
                  'data': 'cached document',
                },
                'title': 'notes.txt',
                'cache_control': {
                  'type': 'ephemeral',
                  'ttl': '5m',
                },
              },
            ],
          },
        ],
      );
      expect(
        request.betaFeatures,
        contains('extended-cache-ttl-2025-04-11'),
      );
    });

    test('skips replay-only assistant parts that Anthropic cannot encode yet',
        () {
      final request = codec.encodeRequest(
        modelId: 'claude-sonnet-4-5',
        prompt: [
          UserPromptMessage.text('Hi'),
          AssistantPromptMessage(
            parts: const [
              ReasoningPromptPart('Hidden reasoning'),
              FilePromptPart(
                mediaType: 'application/pdf',
                bytes: [1, 2, 3],
              ),
              ReasoningFilePromptPart(
                mediaType: 'image/png',
                bytes: [1, 2, 3],
              ),
              CustomPromptPart(
                kind: 'openai.compaction',
                data: {
                  'type': 'compaction',
                },
              ),
            ],
          ),
          UserPromptMessage.text('Continue'),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        settings: const AnthropicChatModelSettings(),
        providerOptions: const AnthropicGenerateTextOptions(),
        stream: false,
      );

      expect(
        request.body['messages'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'Hi',
              },
            ],
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'Continue',
              },
            ],
          },
        ],
      );
      expect(
        request.warnings.map((warning) => warning.field),
        containsAll([
          'assistant.reasoning',
          'assistant.file',
          'assistant.reasoningFile',
          'assistant.custom',
        ]),
      );
    });
  });
}
