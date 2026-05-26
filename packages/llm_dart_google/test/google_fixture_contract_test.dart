import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:test/test.dart';

final googleFixtures = ProviderCodecContractRunner.forWorkspacePackage(
  'llm_dart_google',
);

void main() {
  group('Google fixture contracts', () {
    test('GenerateContent request body matches golden fixture', () {
      final request = buildGoogleGenerateContentFixtureRequest();

      expect(request.warnings, isEmpty);
      googleFixtures.expectJsonFixture(
        'google/generate_content_request_body_golden.json',
        request.body,
      );
    });

    test('GenerateContent stream events match golden fixture', () {
      final events = buildGoogleGenerateContentStreamFixtureEvents();

      googleFixtures.expectLanguageModelStreamEventsFixture(
        'google/generate_content_stream_events_golden.json',
        events,
      );
    });
  });
}

GoogleGenerateContentRequest buildGoogleGenerateContentFixtureRequest() {
  const codec = GoogleGenerateContentCodec();
  final serverToolCallReplay = GoogleToolCallReplay.fromToolCall(
    {
      'id': 'srvtool_google_search',
      'toolType': 'google_search',
      'query': 'Dart SDK',
    },
    providerMetadata: const ProviderMetadata({
      'google': {
        'thoughtSignature': 'sig_server_tool_call',
      },
    }),
  );
  final serverToolResponseReplay = GoogleToolResponseReplay.fromToolResponse(
    {
      'id': 'srvtool_google_search',
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

  return codec.encodeRequest(
    modelId: 'gemini-3-pro-preview',
    prompt: [
      SystemPromptMessage.text('Use concise Google answers.'),
      UserPromptMessage(
        parts: const [
          TextPromptPart('Summarize the Google fixture inputs.'),
          ImagePromptPart(
            mediaType: 'image/png',
            data: FileBytesData.constBytes([1, 2, 3]),
          ),
          FilePromptPart(
            mediaType: 'application/pdf',
            filename: 'brief.pdf',
            data: FileProviderReferenceData(
              ProviderReference({
                'google':
                    'https://generativelanguage.googleapis.com/v1beta/files/brief',
              }),
            ),
          ),
        ],
      ),
      AssistantPromptMessage(
        parts: [
          const ReasoningPromptPart(
            'Plan the answer.',
            providerOptions: ProviderReplayPromptPartOptions(
              ProviderMetadata({
                'google': {
                  'thoughtSignature': 'sig_reasoning',
                },
              }),
            ),
          ),
          const ToolCallPromptPart(
            toolCallId: 'call_google_weather',
            toolName: 'weather',
            input: {
              'city': 'Hong Kong',
            },
            providerOptions: ProviderReplayPromptPartOptions(
              ProviderMetadata({
                'google': {
                  'functionCallId': 'call_google_weather',
                },
              }),
            ),
          ),
          serverToolCallReplay.toCustomPromptPart(),
          serverToolResponseReplay.toCustomPromptPart(),
          const TextPromptPart('Search complete.'),
        ],
      ),
      ToolPromptMessage(
        toolName: 'weather',
        parts: [
          ToolResultPromptPart(
            toolCallId: 'call_google_weather',
            toolName: 'weather',
            toolOutput: ContentToolOutput(
              parts: const [
                TextToolOutputContentPart('Forecast ready.'),
                JsonToolOutputContentPart({
                  'temperatureC': 26,
                  'condition': 'Cloudy',
                }),
                FileToolOutputContentPart(
                  mediaType: 'image/png',
                  filename: 'chart.png',
                  data: FileBytesData.constBytes([4, 5, 6]),
                ),
              ],
              providerMetadata: const ProviderMetadata({
                'google': {
                  'functionCallId': 'call_google_weather',
                },
              }),
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
          },
          required: const ['city'],
          additionalProperties: false,
        ),
        strict: true,
      ),
    ],
    toolChoice: const SpecificToolChoice('weather'),
    options: const GenerateTextOptions(
      maxOutputTokens: 128,
      temperature: 0.2,
      topP: 0.8,
      topK: 40,
      stopSequences: ['END'],
      reasoning: GenerateTextReasoningOptions.enabled(
        effort: ReasoningEffort.medium,
      ),
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
      includeServerSideToolInvocations: true,
      includeThoughts: true,
      candidateCount: 1,
      responseModalities: [GoogleResponseModality.text],
      responseFormat: GoogleJsonSchemaResponseFormat(
        schema: {
          'type': 'object',
          'properties': {
            'summary': {'type': 'string'},
          },
          'required': ['summary'],
          'additionalProperties': false,
        },
      ),
      tools: [
        GoogleSearchTool(),
      ],
    ),
  );
}

List<LanguageModelStreamEvent> buildGoogleGenerateContentStreamFixtureEvents() {
  const codec = GoogleGenerateContentStreamCodec();
  final state = GoogleGenerateContentStreamState();
  final events = <LanguageModelStreamEvent>[];

  for (final chunk in <Map<String, Object?>>[
    {
      'responseId': 'resp_google_fixture',
      'modelVersion': 'gemini-3-pro-preview',
      'usageMetadata': {
        'promptTokenCount': 10,
        'candidatesTokenCount': 2,
        'totalTokenCount': 12,
      },
      'candidates': [
        {
          'content': {
            'parts': [
              {
                'text': 'Hello ',
              },
            ],
          },
        },
      ],
    },
    {
      'candidates': [
        {
          'content': {
            'parts': [
              {
                'text': 'Plan',
                'thought': true,
                'thoughtSignature': 'sig_stream_reasoning',
              },
              {
                'inlineData': {
                  'mimeType': 'image/png',
                  'data': 'AQID',
                },
                'thought': true,
                'thoughtSignature': 'sig_stream_reasoning_file',
              },
            ],
          },
        },
      ],
    },
    {
      'usageMetadata': {
        'promptTokenCount': 10,
        'candidatesTokenCount': 8,
        'thoughtsTokenCount': 3,
        'totalTokenCount': 21,
      },
      'promptFeedback': {
        'safetyRatings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'probability': 'NEGLIGIBLE',
          },
        ],
      },
      'candidates': [
        {
          'content': {
            'parts': [
              {
                'functionCall': {
                  'id': 'call_google_weather',
                  'name': 'weather',
                  'args': {
                    'city': 'Hong Kong',
                  },
                },
                'thoughtSignature': 'sig_stream_tool',
              },
              {
                'executableCode': {
                  'language': 'PYTHON',
                  'code': 'print("hi")',
                },
              },
              {
                'codeExecutionResult': {
                  'outcome': 'OUTCOME_OK',
                  'output': 'hi',
                },
              },
              {
                'toolCall': {
                  'id': 'srvtool_google_search',
                  'toolType': 'google_search',
                  'query': 'Dart SDK',
                },
                'thoughtSignature': 'sig_stream_server_tool',
              },
              {
                'toolResponse': {
                  'id': 'srvtool_google_search',
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
                'inlineData': {
                  'mimeType': 'application/pdf',
                  'data': 'BAUG',
                },
              },
            ],
          },
          'groundingMetadata': {
            'groundingChunks': [
              {
                'web': {
                  'uri': 'https://dart.dev',
                  'title': 'Dart',
                },
              },
            ],
          },
          'urlContextMetadata': {
            'urlMetadata': [
              {
                'retrievedUrl': 'https://dart.dev',
                'urlRetrievalStatus': 'URL_RETRIEVAL_STATUS_SUCCESS',
              },
            ],
          },
          'finishReason': 'STOP',
          'finishMessage': 'Fixture complete.',
          'safetyRatings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'probability': 'NEGLIGIBLE',
            },
          ],
        },
      ],
    },
  ]) {
    events.addAll(codec.decodeChunk(chunk, state));
  }

  events.addAll(codec.finish(state));
  return events;
}
