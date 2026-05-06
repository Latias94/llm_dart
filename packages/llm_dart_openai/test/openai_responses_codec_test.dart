import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_openai/src/openai_responses_codec.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIResponsesCodec', () {
    test('encodes user image and file prompt parts on the Responses path', () {
      const codec = OpenAIResponsesCodec();

      final request = codec.encodeRequest(
        modelId: 'gpt-5-mini',
        prompt: [
          UserPromptMessage(
            parts: const [
              TextPromptPart('Describe both inputs.'),
              ImagePromptPart(
                mediaType: 'image/png',
                data: FileBytesData.constBytes([0, 1, 2, 3]),
              ),
              FilePromptPart(
                mediaType: 'application/pdf',
                data: FileBytesData.constBytes([1, 2, 3, 4]),
              ),
            ],
          ),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        providerOptions: const OpenAIGenerateTextOptions(),
        stream: false,
      );

      expect(
        request.body['input'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text': 'Describe both inputs.',
              },
              {
                'type': 'input_image',
                'image_url': 'data:image/png;base64,AAECAw==',
              },
              {
                'type': 'input_file',
                'filename': 'part-2.pdf',
                'file_data': 'data:application/pdf;base64,AQIDBA==',
              },
            ],
          },
        ],
      );
    });

    test(
        'encodes OpenAI-owned fileId and imageDetail hints on the Responses path',
        () {
      const codec = OpenAIResponsesCodec();

      final request = codec.encodeRequest(
        modelId: 'gpt-5-mini',
        prompt: [
          UserPromptMessage(
            parts: const [
              ImagePromptPart(
                mediaType: 'image/png',
                data: FileProviderReferenceData(
                  ProviderReference({'openai': 'assistant-img-abc123'}),
                ),
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'imageDetail': 'high',
                  },
                }),
              ),
              FilePromptPart(
                mediaType: 'application/pdf',
                data: FileProviderReferenceData(
                  ProviderReference({'openai': 'file-pdf-12345'}),
                ),
              ),
            ],
          ),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        providerOptions: const OpenAIGenerateTextOptions(),
        stream: false,
      );

      expect(
        request.body['input'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_image',
                'file_id': 'assistant-img-abc123',
                'detail': 'high',
              },
              {
                'type': 'input_file',
                'file_id': 'file-pdf-12345',
              },
            ],
          },
        ],
      );
    });

    test('encodes OpenAI provider references on the Responses path', () {
      const codec = OpenAIResponsesCodec();

      final request = codec.encodeRequest(
        modelId: 'gpt-5-mini',
        prompt: [
          UserPromptMessage(
            parts: const [
              ImagePromptPart(
                mediaType: 'image/png',
                data: FileProviderReferenceData(
                  ProviderReference({'openai': 'file-img-123'}),
                ),
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'imageDetail': 'low',
                  },
                }),
              ),
              FilePromptPart(
                mediaType: 'application/pdf',
                data: FileProviderReferenceData(
                  ProviderReference({'openai': 'file-pdf-123'}),
                ),
              ),
            ],
          ),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        providerOptions: const OpenAIGenerateTextOptions(),
        stream: false,
      );

      expect(
        request.body['input'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_image',
                'file_id': 'file-img-123',
                'detail': 'low',
              },
              {
                'type': 'input_file',
                'file_id': 'file-pdf-123',
              },
            ],
          },
        ],
      );
    });

    test('encodes PDF file URIs on the Responses path', () {
      const codec = OpenAIResponsesCodec();

      final request = codec.encodeRequest(
        modelId: 'gpt-5-mini',
        prompt: [
          UserPromptMessage(
            parts: [
              FilePromptPart(
                mediaType: 'application/pdf',
                data: FileUrlData(
                  Uri.parse('https://example.com/document.pdf'),
                ),
              ),
            ],
          ),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        providerOptions: const OpenAIGenerateTextOptions(),
        stream: false,
      );

      expect(
        request.body['input'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_file',
                'file_url': 'https://example.com/document.pdf',
              },
            ],
          },
        ],
      );
    });

    test('rejects URI-backed non-PDF file prompt parts on the Responses path',
        () {
      const codec = OpenAIResponsesCodec();

      expect(
        () => codec.encodeRequest(
          modelId: 'gpt-5-mini',
          prompt: [
            UserPromptMessage(
              parts: [
                FilePromptPart(
                  mediaType: 'text/plain',
                  data: FileUrlData(
                    Uri.parse('https://example.com/notes.txt'),
                  ),
                ),
              ],
            ),
          ],
          tools: const [],
          toolChoice: null,
          options: const GenerateTextOptions(),
          providerOptions: const OpenAIGenerateTextOptions(),
          stream: false,
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            contains('need bytes'),
          ),
        ),
      );
    });

    test(
        'encodes full assistant replay items for text, reasoning, tool calls, and compaction when store is false',
        () {
      const codec = OpenAIResponsesCodec();

      final request = codec.encodeRequest(
        modelId: 'gpt-5-mini',
        prompt: [
          UserPromptMessage.text('Hi'),
          AssistantPromptMessage(
            parts: const [
              TextPromptPart(
                'Commentary',
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'itemId': 'msg_commentary',
                    'phase': 'commentary',
                  },
                }),
              ),
              TextPromptPart(
                'Final answer',
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'itemId': 'msg_final',
                    'phase': 'final_answer',
                  },
                }),
              ),
              ReasoningPromptPart(
                'Thinking step 1',
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'itemId': 'rs_1',
                    'encryptedContent': 'enc_1',
                  },
                }),
              ),
              ReasoningPromptPart(
                'Thinking step 2',
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'itemId': 'rs_1',
                    'reasoningEncryptedContent': 'enc_2',
                  },
                }),
              ),
              ToolCallPromptPart(
                toolCallId: 'call_1',
                toolName: 'weather',
                input: {
                  'city': 'Hong Kong',
                },
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'itemId': 'fc_1',
                  },
                }),
              ),
              CustomPromptPart(
                kind: 'openai.compaction',
                data: {
                  'encryptedContent': 'enc_comp',
                  'compact_threshold': 50000,
                },
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'itemId': 'cmp_1',
                  },
                }),
              ),
            ],
          ),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        providerOptions: const OpenAIGenerateTextOptions(
          store: false,
        ),
        stream: false,
      );

      expect(
        request.body['input'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text': 'Hi',
              },
            ],
          },
          {
            'role': 'assistant',
            'id': 'msg_commentary',
            'phase': 'commentary',
            'content': [
              {
                'type': 'output_text',
                'text': 'Commentary',
              },
            ],
          },
          {
            'role': 'assistant',
            'id': 'msg_final',
            'phase': 'final_answer',
            'content': [
              {
                'type': 'output_text',
                'text': 'Final answer',
              },
            ],
          },
          {
            'type': 'reasoning',
            'id': 'rs_1',
            'encrypted_content': 'enc_2',
            'summary': [
              {
                'type': 'summary_text',
                'text': 'Thinking step 1',
              },
              {
                'type': 'summary_text',
                'text': 'Thinking step 2',
              },
            ],
          },
          {
            'type': 'function_call',
            'call_id': 'call_1',
            'id': 'fc_1',
            'name': 'weather',
            'arguments': '{"city":"Hong Kong"}',
          },
          {
            'type': 'compaction',
            'id': 'cmp_1',
            'encrypted_content': 'enc_comp',
            'compact_threshold': 50000,
          },
        ],
      );

      expect(request.body['store'], isFalse);
      expect(
        request.body['include'],
        contains('reasoning.encrypted_content'),
      );
    });

    test(
        'uses item references for stored assistant replay items by default on the Responses path',
        () {
      const codec = OpenAIResponsesCodec();

      final request = codec.encodeRequest(
        modelId: 'gpt-5-mini',
        prompt: [
          UserPromptMessage.text('Hi'),
          AssistantPromptMessage(
            parts: const [
              TextPromptPart(
                'Commentary',
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'itemId': 'msg_commentary',
                    'phase': 'commentary',
                  },
                }),
              ),
              TextPromptPart(
                'Final answer',
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'itemId': 'msg_final',
                    'phase': 'final_answer',
                  },
                }),
              ),
              ReasoningPromptPart(
                'Thinking step 1',
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'itemId': 'rs_1',
                    'encryptedContent': 'enc_1',
                  },
                }),
              ),
              ReasoningPromptPart(
                'Thinking step 2',
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'itemId': 'rs_1',
                    'reasoningEncryptedContent': 'enc_2',
                  },
                }),
              ),
              ToolCallPromptPart(
                toolCallId: 'call_1',
                toolName: 'weather',
                input: {
                  'city': 'Hong Kong',
                },
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'itemId': 'fc_1',
                  },
                }),
              ),
              CustomPromptPart(
                kind: 'openai.compaction',
                data: {
                  'encryptedContent': 'enc_comp',
                  'compact_threshold': 50000,
                },
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'itemId': 'cmp_1',
                  },
                }),
              ),
            ],
          ),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        providerOptions: const OpenAIGenerateTextOptions(),
        stream: false,
      );

      expect(
        request.body['input'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text': 'Hi',
              },
            ],
          },
          {
            'type': 'item_reference',
            'id': 'msg_commentary',
          },
          {
            'type': 'item_reference',
            'id': 'msg_final',
          },
          {
            'type': 'item_reference',
            'id': 'rs_1',
          },
          {
            'type': 'item_reference',
            'id': 'fc_1',
          },
          {
            'type': 'item_reference',
            'id': 'cmp_1',
          },
        ],
      );
      expect(request.body.containsKey('store'), isFalse);
    });

    test('skips stored assistant replay items when conversation is set', () {
      const codec = OpenAIResponsesCodec();

      final request = codec.encodeRequest(
        modelId: 'gpt-5-mini',
        prompt: [
          UserPromptMessage.text('Hi'),
          AssistantPromptMessage(
            parts: const [
              TextPromptPart(
                'Existing answer',
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'itemId': 'msg_existing',
                    'phase': 'final_answer',
                  },
                }),
              ),
              TextPromptPart('New answer fragment'),
              ReasoningPromptPart(
                'Existing reasoning',
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'itemId': 'rs_existing',
                    'encryptedContent': 'enc_existing',
                  },
                }),
              ),
              ToolCallPromptPart(
                toolCallId: 'call_existing',
                toolName: 'weather',
                input: {
                  'city': 'Hong Kong',
                },
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'itemId': 'fc_existing',
                  },
                }),
              ),
              CustomPromptPart(
                kind: 'openai.compaction',
                data: {
                  'encryptedContent': 'enc_comp',
                },
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'itemId': 'cmp_existing',
                  },
                }),
              ),
            ],
          ),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        providerOptions: const OpenAIGenerateTextOptions(
          conversation: 'conv_123',
        ),
        stream: false,
      );

      expect(
        request.body['input'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text': 'Hi',
              },
            ],
          },
          {
            'role': 'assistant',
            'content': [
              {
                'type': 'output_text',
                'text': 'New answer fragment',
              },
            ],
          },
        ],
      );
      expect(request.body['conversation'], 'conv_123');
    });

    test(
        'adds an item reference before MCP approval responses when store is enabled',
        () {
      const codec = OpenAIResponsesCodec();

      final request = codec.encodeRequest(
        modelId: 'gpt-4.1-mini',
        prompt: [
          UserPromptMessage.text('Approve the MCP tool.'),
          ToolPromptMessage(
            toolName: 'mcp.create_short_url',
            parts: const [
              ToolApprovalResponsePromptPart(
                approvalId: 'approval-1',
                toolCallId: 'approval-1',
                approved: true,
              ),
            ],
          ),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        providerOptions: const OpenAIGenerateTextOptions(),
        stream: false,
      );

      expect(
        request.body['input'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text': 'Approve the MCP tool.',
              },
            ],
          },
          {
            'type': 'item_reference',
            'id': 'approval-1',
          },
          {
            'type': 'mcp_approval_response',
            'approval_request_id': 'approval-1',
            'approve': true,
          },
        ],
      );
    });

    test('decodes provider metadata needed for replay fidelity', () {
      const codec = OpenAIResponsesCodec();

      final result = codec.decodeGenerateResponse({
        'id': 'resp_1',
        'status': 'completed',
        'output': [
          {
            'id': 'msg_1',
            'type': 'message',
            'status': 'completed',
            'role': 'assistant',
            'phase': 'commentary',
            'content': [
              {
                'type': 'output_text',
                'text': 'Hello',
              },
            ],
          },
          {
            'id': 'rs_1',
            'type': 'reasoning',
            'encrypted_content': 'enc_reason',
            'summary': [
              {
                'type': 'summary_text',
                'text': 'Think',
              },
            ],
          },
          {
            'id': 'cmp_1',
            'type': 'compaction',
            'encrypted_content': 'enc_comp',
          },
        ],
      });

      final textPart = result.content.whereType<TextContentPart>().single;
      final reasoningPart =
          result.content.whereType<ReasoningContentPart>().single;
      final customPart = result.content.whereType<CustomContentPart>().single;

      expect(
        textPart.providerMetadata?['openai'],
        containsPair('itemId', 'msg_1'),
      );
      expect(
        textPart.providerMetadata?['openai'],
        containsPair('phase', 'commentary'),
      );
      expect(
        reasoningPart.providerMetadata?['openai'],
        containsPair('itemId', 'rs_1'),
      );
      expect(
        reasoningPart.providerMetadata?['openai'],
        containsPair('reasoningEncryptedContent', 'enc_reason'),
      );
      expect(customPart.kind, 'openai.compaction');
      expect(
        customPart.providerMetadata?['openai'],
        containsPair('itemId', 'cmp_1'),
      );
      expect(
        customPart.providerMetadata?['openai'],
        containsPair('encryptedContent', 'enc_comp'),
      );
    });

    test('decodes image generation and mcp list tools as custom content parts',
        () {
      const codec = OpenAIResponsesCodec();

      final result = codec.decodeGenerateResponse({
        'id': 'resp_custom_outputs',
        'status': 'completed',
        'output': [
          {
            'id': 'img_1',
            'type': 'image_generation_call',
            'result': 'AAEC',
          },
          {
            'id': 'mcp_tools_1',
            'type': 'mcp_list_tools',
            'server_label': 'zip1',
            'tools': [
              {
                'name': 'create_short_url',
              },
              {
                'name': 'get_status',
              },
            ],
          },
        ],
      });

      final customParts = OpenAICustomPart.parseContentParts(result.content);
      expect(customParts, hasLength(2));
      expect(customParts[0], isA<OpenAIImageGenerationCallCustomPart>());
      expect(
        (customParts[0] as OpenAIImageGenerationCallCustomPart)
            .decodeImageBytes(),
        [0, 1, 2],
      );
      expect(customParts[1], isA<OpenAIMcpListToolsCustomPart>());
      expect(
        (customParts[1] as OpenAIMcpListToolsCustomPart).toolNames,
        ['create_short_url', 'get_status'],
      );
    });
  });
}
