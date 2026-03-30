import 'package:llm_dart_core/llm_dart_core.dart';
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
            parts: const [
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
            parts: const [
              ToolApprovalResponsePromptPart(
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
            parts: const [
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
  });
}
