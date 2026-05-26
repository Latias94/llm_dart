import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:test/test.dart';

final anthropicFixtures = ProviderCodecContractRunner.forWorkspacePackage(
  'llm_dart_anthropic',
);

void main() {
  group('Anthropic fixture contracts', () {
    test('Messages request body matches golden fixture', () {
      final request = buildMessagesRequest();

      anthropicFixtures.expectJsonFixture(
        'anthropic/messages_request_body_golden.json',
        request.body,
      );
    });

    test('Messages request metadata matches golden fixture', () {
      final request = buildMessagesRequest();

      anthropicFixtures.expectJsonFixture(
        'anthropic/messages_request_metadata_golden.json',
        encodeRequestMetadata(request),
      );
    });

    test('Messages replay request body matches golden fixture', () {
      final request = buildReplayRequest();

      expect(request.warnings, isEmpty);
      anthropicFixtures.expectJsonFixture(
        'anthropic/messages_replay_request_body_golden.json',
        request.body,
      );
    });

    test('Messages stream events match golden fixture', () {
      const codec = AnthropicStreamCodec();
      final state = AnthropicMessagesStreamState();
      final events = <LanguageModelStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'type': 'message_start',
          'message': {
            'id': 'msg_fixture',
            'model': 'claude-sonnet-4-5',
            'usage': {
              'input_tokens': 18,
              'output_tokens': 1,
            },
          },
        },
        {
          'type': 'content_block_start',
          'index': 0,
          'content_block': {
            'type': 'text',
            'text': '',
          },
        },
        {
          'type': 'content_block_delta',
          'index': 0,
          'delta': {
            'type': 'text_delta',
            'text': 'Hello',
          },
        },
        {
          'type': 'content_block_delta',
          'index': 0,
          'delta': {
            'type': 'citations_delta',
            'citation': {
              'type': 'web_search_result_location',
              'url': 'https://dart.dev',
              'title': 'Dart',
              'cited_text': 'Dart',
              'encrypted_index': 'enc_citation_1',
            },
          },
        },
        {
          'type': 'content_block_stop',
          'index': 0,
        },
        {
          'type': 'content_block_start',
          'index': 1,
          'content_block': {
            'type': 'thinking',
            'thinking': '',
          },
        },
        {
          'type': 'content_block_delta',
          'index': 1,
          'delta': {
            'type': 'thinking_delta',
            'thinking': 'Plan',
          },
        },
        {
          'type': 'content_block_delta',
          'index': 1,
          'delta': {
            'type': 'signature_delta',
            'signature': 'sig_fixture',
          },
        },
        {
          'type': 'content_block_stop',
          'index': 1,
        },
        {
          'type': 'content_block_start',
          'index': 2,
          'content_block': {
            'type': 'tool_use',
            'id': 'toolu_weather',
            'name': 'weather',
          },
        },
        {
          'type': 'content_block_delta',
          'index': 2,
          'delta': {
            'type': 'input_json_delta',
            'partial_json': '{"city":"Hong Kong"}',
          },
        },
        {
          'type': 'content_block_stop',
          'index': 2,
        },
        {
          'type': 'content_block_start',
          'index': 3,
          'content_block': {
            'type': 'mcp_tool_use',
            'id': 'mcptoolu_browser',
            'name': 'open_browser',
            'server_name': 'workspace',
            'input': {
              'url': 'https://example.com',
            },
          },
        },
        {
          'type': 'content_block_stop',
          'index': 3,
        },
        {
          'type': 'content_block_start',
          'index': 4,
          'content_block': {
            'type': 'mcp_tool_result',
            'tool_use_id': 'mcptoolu_browser',
            'is_error': false,
            'content': [
              {
                'type': 'text',
                'text': 'opened',
              },
            ],
          },
        },
        {
          'type': 'content_block_start',
          'index': 5,
          'content_block': {
            'type': 'server_tool_use',
            'id': 'srvtoolu_search',
            'name': 'web_search',
            'input': {
              'query': 'dart sdk',
            },
          },
        },
        {
          'type': 'content_block_stop',
          'index': 5,
        },
        {
          'type': 'content_block_start',
          'index': 6,
          'content_block': {
            'type': 'web_search_tool_result',
            'tool_use_id': 'srvtoolu_search',
            'content': [
              {
                'url': 'https://dart.dev',
                'title': 'Dart',
                'page_age': '1d',
                'encrypted_content': 'enc_search_1',
                'type': 'web_search_result',
              },
            ],
          },
        },
        {
          'type': 'content_block_start',
          'index': 7,
          'content_block': {
            'type': 'server_tool_use',
            'id': 'srvtoolu_code',
            'name': 'bash_code_execution',
            'input': {
              'command': 'echo hi',
            },
          },
        },
        {
          'type': 'content_block_stop',
          'index': 7,
        },
        {
          'type': 'content_block_start',
          'index': 8,
          'content_block': {
            'type': 'bash_code_execution_tool_result',
            'tool_use_id': 'srvtoolu_code',
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
        {
          'type': 'message_delta',
          'delta': {
            'stop_reason': 'tool_use',
            'stop_sequence': null,
            'container': {
              'id': 'container_fixture',
              'expires_at': '2026-03-27T12:00:00Z',
            },
          },
          'usage': {
            'input_tokens': 18,
            'output_tokens': 42,
          },
          'context_management': {
            'clear_function_results': false,
          },
        },
        {
          'type': 'message_stop',
        },
      ]) {
        events.addAll(codec.decodeChunk(chunk, state));
      }

      anthropicFixtures.expectLanguageModelStreamEventsFixture(
        'anthropic/messages_stream_events_golden.json',
        events,
      );
    });
  });
}

AnthropicMessagesRequest buildMessagesRequest() {
  const codec = AnthropicMessagesCodec();

  return codec.encodeRequest(
    modelId: 'claude-sonnet-4-5',
    prompt: [
      SystemPromptMessage(
        parts: const [
          TextPromptPart(
            'Reusable instructions.',
            providerOptions: AnthropicPromptPartOptions(
              cacheControl: AnthropicCacheControl.ephemeral(ttl: '1h'),
            ),
          ),
        ],
      ),
      UserPromptMessage(
        parts: const [
          TextPromptPart(
            'Summarize the attachments and use tools when needed.',
            providerOptions: AnthropicPromptPartOptions(
              cacheControl: AnthropicCacheControl.ephemeral(ttl: '5m'),
            ),
          ),
          ImagePromptPart(
            mediaType: 'image/png',
            data: FileBytesData.constBytes([1, 2, 3]),
          ),
          FilePromptPart(
            mediaType: 'application/pdf',
            filename: 'source.pdf',
            data: FileProviderReferenceData(
              ProviderReference({'anthropic': 'file_pdf_123'}),
            ),
          ),
          FilePromptPart(
            mediaType: 'text/plain',
            filename: 'notes.txt',
            data: FileTextData('cached notes'),
            providerOptions: AnthropicPromptPartOptions(
              cacheControl: AnthropicCacheControl.ephemeral(ttl: '5m'),
            ),
          ),
        ],
      ),
    ],
    tools: [
      FunctionToolDefinition(
        name: 'weather',
        description: 'Get current weather.',
        inputSchema: ToolJsonSchema.object(
          properties: const {
            'city': {'type': 'string'},
            'units': {'type': 'string'},
          },
          required: const ['city'],
          additionalProperties: false,
        ),
        strict: true,
      ),
      FunctionToolDefinition(
        name: 'get_forecast',
        description: 'Get forecast details.',
        inputSchema: ToolJsonSchema.object(
          properties: const {
            'city': {'type': 'string'},
            'days': {'type': 'integer'},
          },
          required: const ['city'],
        ),
      ),
    ],
    toolChoice: const AutoToolChoice(),
    options: const GenerateTextOptions(
      maxOutputTokens: 256,
      temperature: 0.4,
      topP: 0.8,
      topK: 40,
      stopSequences: ['END'],
      reasoning: GenerateTextReasoningOptions.enabled(
        budgetTokens: 1024,
      ),
    ),
    settings: const AnthropicChatModelSettings(),
    providerOptions: const AnthropicGenerateTextOptions(
      extendedThinking: true,
      thinkingBudgetTokens: 1536,
      interleavedThinking: true,
      serviceTier: 'auto',
      metadata: {
        'suite': 'fixture-contract',
      },
      container: 'container_fixture',
      mcpServers: [
        AnthropicMcpServer.url(
          name: 'workspace',
          url: 'https://mcp.example.com',
          toolConfiguration: AnthropicMcpToolConfiguration(
            enabled: true,
            allowedTools: ['open_browser'],
          ),
        ),
      ],
      tools: [
        AnthropicWebSearchTool20250305(
          maxUses: 2,
          allowedDomains: ['dart.dev'],
          userLocation: AnthropicApproximateLocation(
            city: 'Hong Kong',
            country: 'HK',
          ),
        ),
        AnthropicCodeExecutionTool20260120(),
        AnthropicToolSearchRegexTool20251119(),
      ],
      deferredToolNames: [
        'weather',
      ],
      toolsCacheControl: AnthropicCacheControl.ephemeral(ttl: '1h'),
    ),
    stream: false,
  );
}

AnthropicMessagesRequest buildReplayRequest() {
  const codec = AnthropicMessagesCodec();
  final replay = AnthropicCodeExecutionReplay.fromJson(
    {
      'schema': 'anthropic.execution.result.v1',
      'replayRole': 'tool',
      'toolCallId': 'srvtoolu_code',
      'toolName': 'code_execution',
      'blockType': 'bash_code_execution_tool_result',
      'block': {
        'type': 'bash_code_execution_tool_result',
        'tool_use_id': 'srvtoolu_code',
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
    providerMetadata: const ProviderMetadata({
      'anthropic': {
        'blockType': 'bash_code_execution_tool_result',
      },
    }),
  );

  return codec.encodeRequest(
    modelId: 'claude-sonnet-4-5',
    prompt: [
      UserPromptMessage.text('Use the available tools.'),
      AssistantPromptMessage(
        parts: const [
          ToolCallPromptPart(
            toolCallId: 'toolu_weather',
            toolName: 'weather',
            input: {
              'city': 'Hong Kong',
            },
          ),
          ToolCallPromptPart(
            toolCallId: 'mcptoolu_browser',
            toolName: 'mcp.open_browser',
            input: {
              'url': 'https://example.com',
            },
            providerExecuted: true,
            isDynamic: true,
            title: 'workspace',
          ),
          ToolCallPromptPart(
            toolCallId: 'srvtoolu_search',
            toolName: 'web_search',
            input: {
              'query': 'dart sdk',
            },
            providerExecuted: true,
            isDynamic: true,
          ),
          ToolCallPromptPart(
            toolCallId: 'srvtoolu_code',
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
        toolName: 'weather',
        parts: [
          ToolResultPromptPart(
            toolCallId: 'toolu_weather',
            toolName: 'weather',
            toolOutput: ContentToolOutput(
              parts: const [
                TextToolOutputContentPart('forecast'),
                JsonToolOutputContentPart({
                  'condition': 'Cloudy',
                  'temperatureC': 26,
                }),
              ],
            ),
          ),
          const ToolApprovalResponsePromptPart(
            approvalId: 'approval_1',
            toolCallId: 'mcptoolu_browser',
            approved: true,
            reason: 'User approved the external action.',
          ),
          ToolResultPromptPart(
            toolCallId: 'mcptoolu_browser',
            toolName: 'mcp.open_browser',
            output: {
              'status': 'opened',
            },
          ),
          const CustomPromptPart(
            kind: 'anthropic.result.web_search',
            data: {
              'replayRole': 'tool',
              'toolCallId': 'srvtoolu_search',
              'toolName': 'web_search',
              'block': {
                'type': 'web_search_tool_result',
                'tool_use_id': 'srvtoolu_search',
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
          replay.toCustomPromptPart(),
        ],
      ),
      AssistantPromptMessage.text('Tool replay complete.'),
    ],
    tools: const [],
    toolChoice: null,
    options: const GenerateTextOptions(),
    settings: const AnthropicChatModelSettings(),
    providerOptions: const AnthropicGenerateTextOptions(),
    stream: false,
  );
}

Map<String, Object?> encodeRequestMetadata(AnthropicMessagesRequest request) {
  return {
    'betaFeatures': request.betaFeatures,
    'warnings': [
      for (final warning in request.warnings)
        SerializationJsonSupport.encodeModelWarning(warning),
    ],
  };
}
