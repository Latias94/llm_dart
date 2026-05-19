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
        'encodes OpenAI provider references and imageDetail on the Responses path',
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
                providerOptions: OpenAIPromptPartOptions(
                  imageDetail: 'high',
                ),
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

    test('serializes OpenAI prompt part options through prompt JSON', () {
      const promptCodec = PromptJsonCodec(
        providerPromptPartOptionsCodecs: [
          openAIPromptPartOptionsJsonCodec,
        ],
      );

      final decoded = promptCodec.decodeMessages(
        promptCodec.encodeMessages([
          UserPromptMessage(
            parts: const [
              ImagePromptPart(
                mediaType: 'image/png',
                data: FileProviderReferenceData(
                  ProviderReference({'openai': 'assistant-img-abc123'}),
                ),
                providerOptions: OpenAIPromptPartOptions(
                  imageDetail: 'high',
                ),
              ),
            ],
          ),
        ]),
      );

      final user = decoded.single as UserPromptMessage;
      final image = user.parts.single as ImagePromptPart;
      final options = image.providerOptions as OpenAIPromptPartOptions;
      expect(options.imageDetail, 'high');
    });

    test('does not use ProviderMetadata as OpenAI image request options', () {
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
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'imageDetail': 'high',
                    },
                  }),
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
                providerOptions: OpenAIPromptPartOptions(
                  imageDetail: 'low',
                ),
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

    test('rejects legacy metadata fileId for input file identity', () {
      const codec = OpenAIResponsesCodec();

      expect(
        () => codec.encodeRequest(
          modelId: 'gpt-5-mini',
          prompt: [
            UserPromptMessage(
              parts: const [
                FilePromptPart(
                  mediaType: 'application/pdf',
                  data: FileTextData('legacy-metadata-only'),
                  providerOptions: ProviderReplayPromptPartOptions(
                    ProviderMetadata({
                      'openai': {
                        'fileId': 'file-pdf-123',
                      },
                    }),
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
            (error) => error.message,
            'message',
            contains('OpenAI provider reference'),
          ),
        ),
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

    test('encodes structured tool outputs on the Responses path', () {
      const codec = OpenAIResponsesCodec();

      final request = codec.encodeRequest(
        modelId: 'gpt-5-mini',
        prompt: [
          ToolPromptMessage(
            toolName: 'weather',
            parts: [
              ToolResultPromptPart(
                toolCallId: 'call-weather-1',
                toolName: 'weather',
                toolOutput: ContentToolOutput(
                  parts: [
                    const TextToolOutputContentPart('forecast'),
                    const JsonToolOutputContentPart({
                      'summary': 'ok',
                    }),
                    const FileToolOutputContentPart(
                      mediaType: 'image/png',
                      filename: 'chart.png',
                      data: FileBytesData.constBytes([1, 2, 3]),
                      providerOptions: OpenAIPromptPartOptions(
                        imageDetail: 'high',
                      ),
                    ),
                    const FileToolOutputContentPart(
                      mediaType: 'application/pdf',
                      filename: 'report.pdf',
                      data: FileProviderReferenceData(
                        ProviderReference({'openai': 'file_pdf_1'}),
                      ),
                    ),
                    const CustomToolOutputContentPart(
                      kind: 'demo.custom',
                      data: {
                        'flag': true,
                      },
                    ),
                  ],
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
            'type': 'function_call_output',
            'call_id': 'call-weather-1',
            'output': [
              {
                'type': 'input_text',
                'text': 'forecast',
              },
              {
                'type': 'input_text',
                'text': '{"summary":"ok"}',
              },
              {
                'type': 'input_image',
                'image_url': 'data:image/png;base64,AQID',
                'detail': 'high',
              },
              {
                'type': 'input_file',
                'file_id': 'file_pdf_1',
              },
              {
                'type': 'input_text',
                'text':
                    '{"type":"custom","kind":"demo.custom","data":{"flag":true}}',
              },
            ],
          },
        ],
      );
      expect(request.warnings, isEmpty);
    });

    test('encodes URI-backed non-PDF file prompt parts on the Responses path',
        () {
      const codec = OpenAIResponsesCodec();

      final request = codec.encodeRequest(
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
      );

      expect(
        request.body['input'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_file',
                'file_url': 'https://example.com/notes.txt',
              },
            ],
          },
        ],
      );
    });

    test('rejects bytes-backed non-PDF file prompt parts on the Responses path',
        () {
      const codec = OpenAIResponsesCodec();

      expect(
        () => codec.encodeRequest(
          modelId: 'gpt-5-mini',
          prompt: [
            UserPromptMessage(
              parts: const [
                FilePromptPart(
                  mediaType: 'text/plain',
                  data: FileBytesData.constBytes([1, 2, 3]),
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
            (error) => error.message,
            'message',
            allOf(
              contains('do not support in-memory file data'),
              contains('text/plain'),
            ),
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
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'msg_commentary',
                      'phase': 'commentary',
                    },
                  }),
                ),
              ),
              TextPromptPart(
                'Final answer',
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'msg_final',
                      'phase': 'final_answer',
                    },
                  }),
                ),
              ),
              ReasoningPromptPart(
                'Thinking step 1',
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'rs_1',
                      'encryptedContent': 'enc_1',
                    },
                  }),
                ),
              ),
              ReasoningPromptPart(
                'Thinking step 2',
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'rs_1',
                      'reasoningEncryptedContent': 'enc_2',
                    },
                  }),
                ),
              ),
              ToolCallPromptPart(
                toolCallId: 'call_1',
                toolName: 'weather',
                input: {
                  'city': 'Hong Kong',
                },
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'fc_1',
                    },
                  }),
                ),
              ),
              CustomPromptPart(
                kind: 'openai.compaction',
                data: {
                  'encryptedContent': 'enc_comp',
                  'compact_threshold': 50000,
                },
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'cmp_1',
                    },
                  }),
                ),
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

    test('encodes assistant replay metadata from provider replay options', () {
      const codec = OpenAIResponsesCodec();

      final request = codec.encodeRequest(
        modelId: 'gpt-5-mini',
        prompt: [
          UserPromptMessage.text('Hi'),
          AssistantPromptMessage(
            parts: const [
              TextPromptPart(
                'Final answer',
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'msg_final',
                      'phase': 'final_answer',
                    },
                  }),
                ),
              ),
              ToolCallPromptPart(
                toolCallId: 'call_1',
                toolName: 'weather',
                input: {
                  'city': 'Hong Kong',
                },
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'fc_1',
                    },
                  }),
                ),
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
            'type': 'function_call',
            'call_id': 'call_1',
            'id': 'fc_1',
            'name': 'weather',
            'arguments': '{"city":"Hong Kong"}',
          },
        ],
      );
    });

    test('reconstructs hosted tool search replay when store is false', () {
      const codec = OpenAIResponsesCodec();

      final request = codec.encodeRequest(
        modelId: 'gpt-5-mini',
        prompt: [
          UserPromptMessage.text('Find a tool.'),
          AssistantPromptMessage(
            parts: [
              const ToolCallPromptPart(
                toolCallId: 'tsc_hosted_123',
                toolName: 'tool_search',
                input: {
                  'arguments': {
                    'paths': ['get_weather'],
                  },
                  'call_id': null,
                },
                providerExecuted: true,
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'tsc_hosted_123',
                    },
                  }),
                ),
              ),
              ToolResultPromptPart(
                toolCallId: 'tsc_hosted_123',
                toolName: 'tool_search',
                output: {
                  'tools': [
                    {
                      'type': 'function',
                      'name': 'get_weather',
                      'defer_loading': true,
                    },
                  ],
                },
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'tso_hosted_456',
                      'execution': 'server',
                    },
                  }),
                ),
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
                'text': 'Find a tool.',
              },
            ],
          },
          {
            'type': 'tool_search_call',
            'id': 'tsc_hosted_123',
            'execution': 'server',
            'call_id': null,
            'status': 'completed',
            'arguments': {
              'paths': ['get_weather'],
            },
          },
          {
            'type': 'tool_search_output',
            'id': 'tso_hosted_456',
            'execution': 'server',
            'call_id': null,
            'status': 'completed',
            'tools': [
              {
                'type': 'function',
                'name': 'get_weather',
                'defer_loading': true,
              },
            ],
          },
        ],
      );
      expect(request.warnings, isEmpty);
    });

    test('uses distinct tool search replay item references by default', () {
      const codec = OpenAIResponsesCodec();

      final request = codec.encodeRequest(
        modelId: 'gpt-5-mini',
        prompt: [
          UserPromptMessage.text('Find a tool.'),
          AssistantPromptMessage(
            parts: [
              const ToolCallPromptPart(
                toolCallId: 'tsc_hosted_123',
                toolName: 'tool_search',
                input: {
                  'arguments': {
                    'paths': ['get_weather'],
                  },
                  'call_id': null,
                },
                providerExecuted: true,
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'tsc_hosted_123',
                    },
                  }),
                ),
              ),
              ToolResultPromptPart(
                toolCallId: 'tsc_hosted_123',
                toolName: 'tool_search',
                output: {
                  'tools': [
                    {
                      'type': 'function',
                      'name': 'get_weather',
                    },
                  ],
                },
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'tso_hosted_456',
                    },
                  }),
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
                'type': 'input_text',
                'text': 'Find a tool.',
              },
            ],
          },
          {
            'type': 'item_reference',
            'id': 'tsc_hosted_123',
          },
          {
            'type': 'item_reference',
            'id': 'tso_hosted_456',
          },
        ],
      );
      expect(request.warnings, isEmpty);
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
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'msg_commentary',
                      'phase': 'commentary',
                    },
                  }),
                ),
              ),
              TextPromptPart(
                'Final answer',
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'msg_final',
                      'phase': 'final_answer',
                    },
                  }),
                ),
              ),
              ReasoningPromptPart(
                'Thinking step 1',
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'rs_1',
                      'encryptedContent': 'enc_1',
                    },
                  }),
                ),
              ),
              ReasoningPromptPart(
                'Thinking step 2',
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'rs_1',
                      'reasoningEncryptedContent': 'enc_2',
                    },
                  }),
                ),
              ),
              ToolCallPromptPart(
                toolCallId: 'call_1',
                toolName: 'weather',
                input: {
                  'city': 'Hong Kong',
                },
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'fc_1',
                    },
                  }),
                ),
              ),
              CustomPromptPart(
                kind: 'openai.compaction',
                data: {
                  'encryptedContent': 'enc_comp',
                  'compact_threshold': 50000,
                },
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'cmp_1',
                    },
                  }),
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
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'msg_existing',
                      'phase': 'final_answer',
                    },
                  }),
                ),
              ),
              TextPromptPart('New answer fragment'),
              ReasoningPromptPart(
                'Existing reasoning',
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'rs_existing',
                      'encryptedContent': 'enc_existing',
                    },
                  }),
                ),
              ),
              ToolCallPromptPart(
                toolCallId: 'call_existing',
                toolName: 'weather',
                input: {
                  'city': 'Hong Kong',
                },
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'fc_existing',
                    },
                  }),
                ),
              ),
              CustomPromptPart(
                kind: 'openai.compaction',
                data: {
                  'encryptedContent': 'enc_comp',
                },
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'cmp_existing',
                    },
                  }),
                ),
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

    test('decodes image generation as provider-executed tool content', () {
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
        ],
      });

      final toolCall = result.content.whereType<ToolCallContentPart>().single;
      expect(toolCall.toolCall.toolCallId, 'img_1');
      expect(toolCall.toolCall.toolName, 'image_generation');
      expect(toolCall.toolCall.providerExecuted, isTrue);
      expect(toolCall.toolCall.input, isEmpty);

      final toolResult =
          result.content.whereType<ToolResultContentPart>().single;
      expect(toolResult.toolResult.toolCallId, 'img_1');
      expect(toolResult.toolResult.toolName, 'image_generation');
      expect(toolResult.toolResult.output, {
        'result': 'AAEC',
      });
      expect(OpenAICustomPart.parseContentParts(result.content), isEmpty);
    });

    test('decodes mcp list tools as custom content parts', () {
      const codec = OpenAIResponsesCodec();

      final result = codec.decodeGenerateResponse({
        'id': 'resp_custom_outputs',
        'status': 'completed',
        'output': [
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
      expect(customParts, hasLength(1));
      expect(customParts.single, isA<OpenAIMcpListToolsCustomPart>());
      expect(
        (customParts.single as OpenAIMcpListToolsCustomPart).toolNames,
        ['create_short_url', 'get_status'],
      );
    });

    test('decodes code interpreter calls as provider-executed tool content',
        () {
      const codec = OpenAIResponsesCodec();

      final result = codec.decodeGenerateResponse({
        'id': 'resp_code_interpreter',
        'status': 'completed',
        'output': [
          {
            'id': 'ci_1',
            'type': 'code_interpreter_call',
            'status': 'completed',
            'code': 'print("hi")',
            'container_id': 'cntr_1',
            'outputs': [
              {
                'type': 'logs',
                'logs': 'hi',
              },
            ],
          },
        ],
      });

      final toolCall = result.content.whereType<ToolCallContentPart>().single;
      expect(toolCall.toolCall.toolCallId, 'ci_1');
      expect(toolCall.toolCall.toolName, 'code_interpreter');
      expect(toolCall.toolCall.providerExecuted, isTrue);
      expect(toolCall.toolCall.input, {
        'code': 'print("hi")',
        'containerId': 'cntr_1',
      });
      expect(
        toolCall.providerMetadata?.namespace('openai'),
        allOf(
          containsPair('itemId', 'ci_1'),
          containsPair('itemType', 'code_interpreter_call'),
          containsPair('containerId', 'cntr_1'),
          containsPair('outputCount', 1),
        ),
      );

      final toolResult =
          result.content.whereType<ToolResultContentPart>().single;
      expect(toolResult.toolResult.toolCallId, 'ci_1');
      expect(toolResult.toolResult.toolName, 'code_interpreter');
      expect(toolResult.toolResult.output, {
        'outputs': [
          {
            'type': 'logs',
            'logs': 'hi',
          },
        ],
      });
      expect(result.finishReason, FinishReason.toolCalls);
      expect(OpenAICustomPart.parseContentParts(result.content), isEmpty);
    });

    test('decodes file search calls as provider-executed tool content', () {
      const codec = OpenAIResponsesCodec();

      final result = codec.decodeGenerateResponse({
        'id': 'resp_file_search',
        'status': 'completed',
        'output': [
          {
            'id': 'fs_1',
            'type': 'file_search_call',
            'status': 'completed',
            'queries': ['architecture notes'],
            'results': [
              {
                'attributes': {
                  'source': 'adr',
                  'version': 2,
                },
                'file_id': 'file_1',
                'filename': 'ADR-001.md',
                'score': 0.91,
                'text': 'Provider-local projection keeps OpenAI details local.',
              },
            ],
          },
        ],
      });

      final toolCall = result.content.whereType<ToolCallContentPart>().single;
      expect(toolCall.toolCall.toolCallId, 'fs_1');
      expect(toolCall.toolCall.toolName, 'file_search');
      expect(toolCall.toolCall.providerExecuted, isTrue);
      expect(toolCall.toolCall.input, isEmpty);

      final toolResult =
          result.content.whereType<ToolResultContentPart>().single;
      expect(toolResult.toolResult.toolCallId, 'fs_1');
      expect(toolResult.toolResult.toolName, 'file_search');
      expect(toolResult.toolResult.output, {
        'queries': ['architecture notes'],
        'results': [
          {
            'attributes': {
              'source': 'adr',
              'version': 2,
            },
            'fileId': 'file_1',
            'filename': 'ADR-001.md',
            'score': 0.91,
            'text': 'Provider-local projection keeps OpenAI details local.',
          },
        ],
      });
      expect(
        toolResult.providerMetadata?.namespace('openai'),
        allOf(
          containsPair('itemId', 'fs_1'),
          containsPair('itemType', 'file_search_call'),
          containsPair('queryCount', 1),
          containsPair('resultCount', 1),
        ),
      );
      expect(result.finishReason, FinishReason.toolCalls);
      expect(OpenAICustomPart.parseContentParts(result.content), isEmpty);
    });

    test('preserves missing file search include results as null', () {
      const codec = OpenAIResponsesCodec();

      final result = codec.decodeGenerateResponse({
        'id': 'resp_file_search_no_include',
        'status': 'completed',
        'output': [
          {
            'id': 'fs_1',
            'type': 'file_search_call',
            'queries': ['architecture notes'],
          },
        ],
      });

      final toolResult =
          result.content.whereType<ToolResultContentPart>().single;
      expect(toolResult.toolResult.output, {
        'queries': ['architecture notes'],
        'results': null,
      });
      expect(
        toolResult.providerMetadata?.namespace('openai'),
        isNot(contains('resultCount')),
      );
    });

    test('decodes web search calls as provider-executed tool content', () {
      const codec = OpenAIResponsesCodec();

      final result = codec.decodeGenerateResponse({
        'id': 'resp_web_search',
        'status': 'completed',
        'output': [
          {
            'id': 'ws_1',
            'type': 'web_search_call',
            'status': 'completed',
            'action': {
              'type': 'search',
              'query': 'Vercel AI SDK',
              'sources': [
                {
                  'type': 'url',
                  'url': 'https://ai-sdk.dev',
                },
                {
                  'type': 'api',
                  'name': 'oai-search',
                },
              ],
            },
          },
        ],
      });

      final toolCall = result.content.whereType<ToolCallContentPart>().single;
      expect(toolCall.toolCall.toolCallId, 'ws_1');
      expect(toolCall.toolCall.toolName, 'web_search');
      expect(toolCall.toolCall.providerExecuted, isTrue);
      expect(toolCall.toolCall.input, isEmpty);

      final toolResult =
          result.content.whereType<ToolResultContentPart>().single;
      expect(toolResult.toolResult.toolCallId, 'ws_1');
      expect(toolResult.toolResult.toolName, 'web_search');
      expect(toolResult.toolResult.output, {
        'action': {
          'type': 'search',
          'query': 'Vercel AI SDK',
        },
        'sources': [
          {
            'type': 'url',
            'url': 'https://ai-sdk.dev',
          },
          {
            'type': 'api',
            'name': 'oai-search',
          },
        ],
      });
      expect(
        toolResult.providerMetadata?.namespace('openai'),
        allOf(
          containsPair('itemId', 'ws_1'),
          containsPair('itemType', 'web_search_call'),
          containsPair('actionType', 'search'),
          containsPair('sourceCount', 2),
        ),
      );
      expect(result.finishReason, FinishReason.toolCalls);
      expect(OpenAICustomPart.parseContentParts(result.content), isEmpty);
    });

    test('maps web search page actions and missing action payloads', () {
      const codec = OpenAIResponsesCodec();

      final result = codec.decodeGenerateResponse({
        'id': 'resp_web_search_actions',
        'status': 'completed',
        'output': [
          {
            'id': 'ws_open',
            'type': 'web_search_call',
            'action': {
              'type': 'open_page',
              'url': 'https://ai-sdk.dev/docs',
            },
          },
          {
            'id': 'ws_find',
            'type': 'web_search_call',
            'action': {
              'type': 'find_in_page',
              'url': 'https://ai-sdk.dev/docs',
              'pattern': 'streamText',
            },
          },
          {
            'id': 'ws_missing',
            'type': 'web_search_call',
          },
        ],
      });

      final outputs = result.content
          .whereType<ToolResultContentPart>()
          .map((part) => part.toolResult.output)
          .toList();
      expect(outputs, [
        {
          'action': {
            'type': 'openPage',
            'url': 'https://ai-sdk.dev/docs',
          },
        },
        {
          'action': {
            'type': 'findInPage',
            'url': 'https://ai-sdk.dev/docs',
            'pattern': 'streamText',
          },
        },
        <String, Object?>{},
      ]);
    });

    test('decodes tool search calls and outputs as unified tool content', () {
      const codec = OpenAIResponsesCodec();

      final result = codec.decodeGenerateResponse({
        'id': 'resp_tool_search',
        'status': 'completed',
        'output': [
          {
            'id': 'tsc_1',
            'type': 'tool_search_call',
            'execution': 'server',
            'call_id': null,
            'status': 'completed',
            'arguments': {
              'goal': 'Find the weather tool',
            },
          },
          {
            'id': 'tso_1',
            'type': 'tool_search_output',
            'execution': 'server',
            'call_id': null,
            'status': 'completed',
            'tools': [
              {
                'type': 'function',
                'name': 'get_weather',
              },
            ],
          },
        ],
      });

      final toolCall = result.content.whereType<ToolCallContentPart>().single;
      expect(toolCall.toolCall.toolCallId, 'tsc_1');
      expect(toolCall.toolCall.toolName, 'tool_search');
      expect(toolCall.toolCall.providerExecuted, isTrue);
      expect(toolCall.toolCall.input, {
        'arguments': {
          'goal': 'Find the weather tool',
        },
        'call_id': null,
      });

      final toolResult =
          result.content.whereType<ToolResultContentPart>().single;
      expect(toolResult.toolResult.toolCallId, 'tsc_1');
      expect(toolResult.toolResult.toolName, 'tool_search');
      expect(toolResult.toolResult.output, {
        'tools': [
          {
            'type': 'function',
            'name': 'get_weather',
          },
        ],
      });
      expect(
        toolResult.providerMetadata?.namespace('openai'),
        allOf(
          containsPair('itemId', 'tso_1'),
          containsPair('itemType', 'tool_search_output'),
          containsPair('toolCount', 1),
        ),
      );
      expect(result.finishReason, FinishReason.toolCalls);
      expect(OpenAICustomPart.parseContentParts(result.content), isEmpty);
    });
  });
}
