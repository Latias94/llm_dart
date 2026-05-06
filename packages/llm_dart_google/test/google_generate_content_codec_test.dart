import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:test/test.dart';

void main() {
  const codec = GoogleGenerateContentCodec();

  group('GoogleGenerateContentCodec', () {
    test(
        'encodes request-side tools, system messages, multimodal user parts, and tool history',
        () {
      final weatherTool = FunctionToolDefinition(
        name: 'weather',
        description: 'Get the current weather for a city.',
        inputSchema: ToolJsonSchema.object(
          properties: const {
            'city': {
              'type': 'string',
              'description': 'The city to look up.',
            },
          },
          required: const ['city'],
        ),
      );

      final request = codec.encodeRequest(
        modelId: 'gemini-2.5-flash',
        prompt: [
          SystemPromptMessage.text('You are concise.'),
          UserPromptMessage(
            parts: [
              const TextPromptPart('Inspect the attachment.'),
              const ImagePromptPart(
                mediaType: 'image/png',
                bytes: [1, 2, 3],
              ),
              FilePromptPart(
                mediaType: 'application/pdf',
                uri: Uri.parse('https://example.com/spec.pdf'),
              ),
            ],
          ),
          AssistantPromptMessage(
            parts: [
              ToolCallPromptPart(
                toolCallId: 'tool_1',
                toolName: 'weather',
                input: {
                  'city': 'Hong Kong',
                },
              ),
              ToolApprovalRequestPromptPart(
                approvalId: 'approval_1',
                toolCallId: 'tool_1',
              ),
            ],
          ),
          ToolPromptMessage(
            toolName: 'weather',
            parts: [
              const ToolApprovalResponsePromptPart(
                approvalId: 'approval_1',
                toolCallId: 'tool_1',
                approved: true,
              ),
              ToolResultPromptPart(
                toolCallId: 'tool_1',
                toolName: 'weather',
                output: {
                  'temperature': 28,
                },
              ),
            ],
          ),
        ],
        tools: [
          weatherTool,
        ],
        toolChoice: const SpecificToolChoice('weather'),
        options: const GenerateTextOptions(
          maxOutputTokens: 256,
          temperature: 0.2,
          topP: 0.7,
          topK: 20,
          stopSequences: ['END'],
        ),
        settings: const GoogleChatModelSettings(
          safetySettings: [
            GoogleSafetySetting(
              category: GoogleHarmCategory.harassment,
              threshold: GoogleHarmBlockThreshold.blockOnlyHigh,
            ),
          ],
        ),
        providerOptions: const GoogleGenerateTextOptions(
          candidateCount: 2,
          includeThoughts: true,
          thinkingBudgetTokens: 128,
          responseModalities: [GoogleResponseModality.text],
        ),
      );

      expect(
        request.body['systemInstruction'],
        {
          'parts': [
            {
              'text': 'You are concise.',
            },
          ],
        },
      );
      expect(
        request.body['tools'],
        [
          {
            'functionDeclarations': [
              {
                'name': 'weather',
                'description': 'Get the current weather for a city.',
                'parameters': {
                  'type': 'object',
                  'properties': {
                    'city': {
                      'type': 'string',
                      'description': 'The city to look up.',
                    },
                  },
                  'required': ['city'],
                },
              },
            ],
          },
        ],
      );
      expect(
        request.body['toolConfig'],
        {
          'functionCallingConfig': {
            'mode': 'ANY',
            'allowedFunctionNames': ['weather'],
          },
        },
      );

      final contents = request.body['contents'] as List<Object?>;
      expect(contents, hasLength(3));
      expect(
        contents[0],
        {
          'role': 'user',
          'parts': [
            {
              'text': 'Inspect the attachment.',
            },
            {
              'inlineData': {
                'mimeType': 'image/png',
                'data': 'AQID',
              },
            },
            {
              'fileData': {
                'mimeType': 'application/pdf',
                'fileUri': 'https://example.com/spec.pdf',
              },
            },
          ],
        },
      );
      expect(
        contents[1],
        {
          'role': 'model',
          'parts': [
            {
              'functionCall': {
                'name': 'weather',
                'args': {
                  'city': 'Hong Kong',
                },
              },
            },
          ],
        },
      );
      expect(
        contents[2],
        {
          'role': 'user',
          'parts': [
            {
              'functionResponse': {
                'name': 'weather',
                'response': {
                  'name': 'weather',
                  'content': {
                    'temperature': 28,
                  },
                },
              },
            },
          ],
        },
      );

      expect(
        request.body['generationConfig'],
        {
          'maxOutputTokens': 256,
          'temperature': 0.2,
          'topP': 0.7,
          'topK': 20,
          'stopSequences': ['END'],
          'candidateCount': 1,
          'thinkingConfig': {
            'includeThoughts': true,
            'thinkingBudget': 128,
          },
          'responseModalities': ['TEXT'],
        },
      );
      expect(
        request.body['safetySettings'],
        [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_ONLY_HIGH',
          },
        ],
      );
      expect(
        request.warnings.map((warning) => warning.field),
        contains('candidateCount'),
      );
    });

    test('encodes Google provider references as fileData URIs', () {
      final request = codec.encodeRequest(
        modelId: 'gemini-2.5-flash',
        prompt: [
          UserPromptMessage(
            parts: [
              FilePromptPart(
                mediaType: 'application/pdf',
                data: FileProviderReferenceData(
                  ProviderReference({
                    'google':
                        'https://generativelanguage.googleapis.com/v1beta/files/spec',
                  }),
                ),
              ),
            ],
          ),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        settings: const GoogleChatModelSettings(),
        providerOptions: const GoogleGenerateTextOptions(),
      );

      expect(
        request.body['contents'],
        [
          {
            'role': 'user',
            'parts': [
              {
                'fileData': {
                  'mimeType': 'application/pdf',
                  'fileUri':
                      'https://generativelanguage.googleapis.com/v1beta/files/spec',
                },
              },
            ],
          },
        ],
      );
    });

    test('prepends system instructions for gemma models', () {
      final request = codec.encodeRequest(
        modelId: 'gemma-3-4b-it',
        prompt: [
          SystemPromptMessage.text('You are concise.'),
          UserPromptMessage.text('Say hello.'),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        settings: const GoogleChatModelSettings(),
        providerOptions: const GoogleGenerateTextOptions(),
      );

      expect(request.body.containsKey('systemInstruction'), isFalse);
      expect(
        request.body['contents'],
        [
          {
            'role': 'user',
            'parts': [
              {
                'text': 'You are concise.\n\n',
              },
              {
                'text': 'Say hello.',
              },
            ],
          },
        ],
      );
    });

    test(
        'uses Google native tools from provider options and ignores common tool choice for that call',
        () {
      final request = codec.encodeRequest(
        modelId: 'gemini-2.5-flash',
        prompt: [
          UserPromptMessage.text('Search the web.'),
        ],
        tools: [
          FunctionToolDefinition(
            name: 'weather',
            inputSchema: ToolJsonSchema.object(),
          ),
        ],
        toolChoice: const SpecificToolChoice('weather'),
        options: const GenerateTextOptions(),
        settings: const GoogleChatModelSettings(),
        providerOptions: const GoogleGenerateTextOptions(
          tools: [
            GoogleSearchTool(
              searchTypes: GoogleSearchTypes(
                webSearch: true,
                imageSearch: true,
              ),
            ),
          ],
        ),
      );

      expect(
        request.body['tools'],
        [
          {
            'googleSearch': {
              'searchTypes': {
                'webSearch': <String, Object?>{},
                'imageSearch': <String, Object?>{},
              },
            },
          },
        ],
      );
      expect(request.body.containsKey('toolConfig'), isFalse);
      expect(
        request.warnings.map((warning) => warning.field),
        containsAll([
          'tools',
          'toolChoice',
        ]),
      );
    });

    test(
        'encodes mixed Google native tools and common function tools for Gemini 3 when includeServerSideToolInvocations is enabled',
        () {
      final request = codec.encodeRequest(
        modelId: 'gemini-3-pro-preview',
        prompt: [
          UserPromptMessage.text('Search the web and check the weather.'),
        ],
        tools: [
          FunctionToolDefinition(
            name: 'weather',
            inputSchema: ToolJsonSchema.object(
              properties: const {
                'city': {'type': 'string'},
              },
              required: const ['city'],
            ),
          ),
        ],
        toolChoice: const SpecificToolChoice('weather'),
        options: const GenerateTextOptions(),
        settings: const GoogleChatModelSettings(),
        providerOptions: const GoogleGenerateTextOptions(
          includeServerSideToolInvocations: true,
          tools: [
            GoogleSearchTool(),
          ],
        ),
      );

      expect(
        request.body['tools'],
        [
          {
            'googleSearch': <String, Object?>{},
          },
          {
            'functionDeclarations': [
              {
                'name': 'weather',
                'description': '',
                'parameters': {
                  'type': 'object',
                  'properties': {
                    'city': {'type': 'string'},
                  },
                  'required': ['city'],
                },
              },
            ],
          },
        ],
      );
      expect(
        request.body['toolConfig'],
        {
          'includeServerSideToolInvocations': true,
          'functionCallingConfig': {
            'mode': 'ANY',
            'allowedFunctionNames': ['weather'],
          },
        },
      );
      expect(request.warnings, isEmpty);
    });

    test(
        'rejects includeServerSideToolInvocations for non-Gemini-3 Google models',
        () {
      expect(
        () => codec.encodeRequest(
          modelId: 'gemini-2.5-flash',
          prompt: [
            UserPromptMessage.text('Search the web.'),
          ],
          tools: const [],
          toolChoice: null,
          options: const GenerateTextOptions(),
          settings: const GoogleChatModelSettings(),
          providerOptions: const GoogleGenerateTextOptions(
            includeServerSideToolInvocations: true,
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            contains('Gemini 3'),
          ),
        ),
      );
    });

    test(
        'allows a call to override a model-level includeServerSideToolInvocations default',
        () {
      final request = codec.encodeRequest(
        modelId: 'gemini-3-pro-preview',
        prompt: [
          UserPromptMessage.text('Say hello.'),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        settings: const GoogleChatModelSettings(
          includeServerSideToolInvocations: true,
        ),
        providerOptions: const GoogleGenerateTextOptions(
          includeServerSideToolInvocations: false,
        ),
      );

      expect(request.body['contents'], isNotEmpty);
    });

    test(
        'requires includeServerSideToolInvocations for Google server-side tool replay prompt parts',
        () {
      expect(
        () => codec.encodeRequest(
          modelId: 'gemini-3-pro-preview',
          prompt: [
            UserPromptMessage.text('Continue the conversation.'),
            AssistantPromptMessage(
              parts: [
                GoogleToolCallReplay.fromToolCall(
                  {
                    'id': 'srvtool_1',
                    'toolType': 'google_search',
                    'query': 'Dart SDK',
                  },
                ).toCustomPromptPart(),
              ],
            ),
          ],
          tools: const [],
          toolChoice: null,
          options: const GenerateTextOptions(),
          settings: const GoogleChatModelSettings(),
          providerOptions: const GoogleGenerateTextOptions(),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            contains('includeServerSideToolInvocations=true'),
          ),
        ),
      );
    });

    test('encodes structured output as responseSchema for Google', () {
      final request = codec.encodeRequest(
        modelId: 'gemini-2.5-flash',
        prompt: [
          UserPromptMessage.text('Return JSON.'),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        settings: const GoogleChatModelSettings(),
        providerOptions: const GoogleGenerateTextOptions(
          responseFormat: GoogleJsonSchemaResponseFormat(
            schema: {
              'type': 'object',
              'properties': {
                'answer': {'type': 'string'},
              },
              'required': ['answer'],
              'additionalProperties': false,
            },
          ),
        ),
      );

      expect(
        request.body['generationConfig'],
        {
          'responseMimeType': 'application/json',
          'responseSchema': {
            'type': 'object',
            'properties': {
              'answer': {'type': 'string'},
            },
            'required': ['answer'],
          },
        },
      );
    });

    test(
        'encodes assistant reasoning, reasoning-file, and thought signatures from part metadata',
        () {
      final request = codec.encodeRequest(
        modelId: 'gemini-2.5-flash',
        prompt: [
          UserPromptMessage.text('Continue the conversation.'),
          AssistantPromptMessage(
            parts: [
              ReasoningPromptPart(
                'Thinking...',
                providerMetadata: ProviderMetadata({
                  'google': {
                    'thoughtSignature': 'sig_reasoning',
                  },
                }),
              ),
              ReasoningFilePromptPart(
                mediaType: 'image/png',
                filename: 'thought.png',
                bytes: [1, 2, 3],
                providerMetadata: ProviderMetadata({
                  'google': {
                    'thoughtSignature': 'sig_reasoning_file',
                  },
                }),
              ),
              FilePromptPart(
                mediaType: 'image/jpeg',
                bytes: [4, 5, 6],
                providerMetadata: ProviderMetadata({
                  'google': {
                    'thought': true,
                    'thoughtSignature': 'sig_file',
                  },
                }),
              ),
              ToolCallPromptPart(
                toolCallId: 'tool_1',
                toolName: 'weather',
                input: {
                  'city': 'Hong Kong',
                },
                providerMetadata: ProviderMetadata({
                  'google': {
                    'thoughtSignature': 'sig_tool',
                  },
                }),
              ),
              TextPromptPart(
                'Visible answer.',
                providerMetadata: ProviderMetadata({
                  'google': {
                    'thoughtSignature': 'sig_text',
                  },
                }),
              ),
            ],
          ),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        settings: const GoogleChatModelSettings(),
        providerOptions: const GoogleGenerateTextOptions(),
      );

      final contents = request.body['contents'] as List<Object?>;
      expect(contents, hasLength(2));
      expect(
        contents[1],
        {
          'role': 'model',
          'parts': [
            {
              'text': 'Thinking...',
              'thought': true,
              'thoughtSignature': 'sig_reasoning',
            },
            {
              'inlineData': {
                'mimeType': 'image/png',
                'data': 'AQID',
              },
              'thought': true,
              'thoughtSignature': 'sig_reasoning_file',
            },
            {
              'inlineData': {
                'mimeType': 'image/jpeg',
                'data': 'BAUG',
              },
              'thought': true,
              'thoughtSignature': 'sig_file',
            },
            {
              'functionCall': {
                'name': 'weather',
                'args': {
                  'city': 'Hong Kong',
                },
              },
              'thoughtSignature': 'sig_tool',
            },
            {
              'text': 'Visible answer.',
              'thoughtSignature': 'sig_text',
            },
          ],
        },
      );
    });

    test('replays Gemini 3 function-call ids in assistant and tool history',
        () {
      final request = codec.encodeRequest(
        modelId: 'gemini-3-pro-preview',
        prompt: [
          UserPromptMessage.text('Continue the conversation.'),
          AssistantPromptMessage(
            parts: const [
              ToolCallPromptPart(
                toolCallId: 'call_google_1',
                toolName: 'weather',
                input: {
                  'city': 'Hong Kong',
                },
                providerMetadata: ProviderMetadata({
                  'google': {
                    'functionCallId': 'call_google_1',
                  },
                }),
              ),
            ],
          ),
          ToolPromptMessage(
            toolName: 'weather',
            parts: [
              ToolResultPromptPart(
                toolCallId: 'call_google_1',
                toolName: 'weather',
                output: {
                  'temperature': 28,
                },
                providerMetadata: ProviderMetadata({
                  'google': {
                    'functionCallId': 'call_google_1',
                  },
                }),
              ),
            ],
          ),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        settings: const GoogleChatModelSettings(),
        providerOptions: const GoogleGenerateTextOptions(
          includeServerSideToolInvocations: true,
        ),
      );

      final contents = request.body['contents'] as List<Object?>;
      expect(
        contents[1],
        {
          'role': 'model',
          'parts': [
            {
              'functionCall': {
                'id': 'call_google_1',
                'name': 'weather',
                'args': {
                  'city': 'Hong Kong',
                },
              },
            },
          ],
        },
      );
      expect(
        contents[2],
        {
          'role': 'user',
          'parts': [
            {
              'functionResponse': {
                'id': 'call_google_1',
                'name': 'weather',
                'response': {
                  'name': 'weather',
                  'content': {
                    'temperature': 28,
                  },
                },
              },
            },
          ],
        },
      );
    });

    test(
        'encodes provider-owned Google function-response replay with multimodal files',
        () {
      final replay = GoogleFunctionResponseReplay(
        toolCallId: 'call_google_2',
        toolName: 'render_chart',
        functionCallId: 'call_google_2',
        response: {
          'status': 'ok',
        },
        files: [
          const GeneratedFile(
            mediaType: 'image/png',
            filename: 'chart.png',
            bytes: [1, 2, 3],
          ),
          GeneratedFile(
            mediaType: 'application/pdf',
            filename: 'quote.pdf',
            uri: Uri.parse('https://example.com/quote.pdf'),
          ),
        ],
        extraFunctionResponseFields: const {
          'source': 'local-cache',
        },
      );

      final request = codec.encodeRequest(
        modelId: 'gemini-3-pro-preview',
        prompt: [
          UserPromptMessage.text('Continue the conversation.'),
          AssistantPromptMessage(
            parts: const [
              ToolCallPromptPart(
                toolCallId: 'call_google_2',
                toolName: 'render_chart',
                input: {
                  'metric': 'sales',
                },
                providerMetadata: ProviderMetadata({
                  'google': {
                    'functionCallId': 'call_google_2',
                  },
                }),
              ),
            ],
          ),
          ToolPromptMessage(
            toolName: 'render_chart',
            parts: [
              replay.toCustomPromptPart(),
            ],
          ),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        settings: const GoogleChatModelSettings(),
        providerOptions: const GoogleGenerateTextOptions(
          includeServerSideToolInvocations: true,
        ),
      );

      final contents = request.body['contents'] as List<Object?>;
      expect(
        contents[2],
        {
          'role': 'user',
          'parts': [
            {
              'functionResponse': {
                'source': 'local-cache',
                'id': 'call_google_2',
                'name': 'render_chart',
                'response': {
                  'status': 'ok',
                },
                'parts': [
                  {
                    'inlineData': {
                      'mimeType': 'image/png',
                      'data': 'AQID',
                      'displayName': 'chart.png',
                    },
                  },
                  {
                    'fileData': {
                      'mimeType': 'application/pdf',
                      'fileUri': 'https://example.com/quote.pdf',
                      'displayName': 'quote.pdf',
                    },
                  },
                ],
              },
            },
          ],
        },
      );
    });

    test(
        'encodes provider-owned Google server-side tool-call and tool-response replay in assistant history',
        () {
      final toolCallReplay = GoogleToolCallReplay.fromToolCall(
        {
          'id': 'srvtool_1',
          'toolType': 'google_search',
          'query': 'Dart SDK',
        },
        providerMetadata: const ProviderMetadata({
          'google': {
            'thoughtSignature': 'sig_srvtool_1',
          },
        }),
      );
      final toolResponseReplay = GoogleToolResponseReplay.fromToolResponse(
        {
          'id': 'srvtool_1',
          'toolType': 'google_search',
          'result': {
            'items': [
              {
                'uri': 'https://dart.dev',
                'title': 'Dart',
              },
            ],
          },
        },
      );

      final request = codec.encodeRequest(
        modelId: 'gemini-3-pro-preview',
        prompt: [
          UserPromptMessage.text('Continue the conversation.'),
          AssistantPromptMessage(
            parts: [
              toolCallReplay.toCustomPromptPart(),
              toolResponseReplay.toCustomPromptPart(),
              const TextPromptPart('Dart search finished.'),
            ],
          ),
        ],
        tools: const [],
        toolChoice: null,
        options: const GenerateTextOptions(),
        settings: const GoogleChatModelSettings(),
        providerOptions: const GoogleGenerateTextOptions(
          includeServerSideToolInvocations: true,
        ),
      );

      final contents = request.body['contents'] as List<Object?>;
      expect(
        contents[1],
        {
          'role': 'model',
          'parts': [
            {
              'toolCall': {
                'id': 'srvtool_1',
                'toolType': 'google_search',
                'query': 'Dart SDK',
              },
              'thoughtSignature': 'sig_srvtool_1',
            },
            {
              'toolResponse': {
                'id': 'srvtool_1',
                'toolType': 'google_search',
                'result': {
                  'items': [
                    {
                      'uri': 'https://dart.dev',
                      'title': 'Dart',
                    },
                  ],
                },
              },
            },
            {
              'text': 'Dart search finished.',
            },
          ],
        },
      );
    });
  });
}
