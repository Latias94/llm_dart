import 'dart:convert';

import 'package:llm_dart_ollama/llm_dart_ollama.dart';
import 'package:llm_dart_ollama/src/ollama_chat_request_codec.dart';
import 'package:llm_dart_ollama/src/ollama_chat_response_codec.dart';
import 'package:llm_dart_ollama/src/ollama_chat_stream_codec.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:test/test.dart';

final ollamaFixtures = ProviderCodecContractRunner.forWorkspacePackage(
  'llm_dart_ollama',
);

void main() {
  group('Ollama fixture contracts', () {
    test('Chat request body matches golden fixture', () async {
      final prepared = await buildOllamaChatFixtureRequest();

      ollamaFixtures.expectJsonFixture(
        'ollama/chat_request_body_golden.json',
        prepared.body,
      );
      ollamaFixtures.expectJsonFixture(
        'ollama/chat_request_warnings_golden.json',
        prepared.warnings
            .map(SerializationJsonSupport.encodeModelWarning)
            .toList(growable: false),
      );
    });

    test('Chat stream events match golden fixture', () {
      final events = buildOllamaChatStreamFixtureEvents();

      ollamaFixtures.expectLanguageModelStreamEventsFixture(
        'ollama/chat_stream_events_golden.json',
        events,
      );
    });
  });
}

Future<OllamaPreparedChatRequest> buildOllamaChatFixtureRequest() {
  final codec = OllamaChatRequestCodec(
    modelId: 'llama3.2-vision',
    settings: OllamaChatModelSettings(
      binaryResolver: (uri, {required mediaType, filename}) {
        _checkFixtureBinaryRequest(
          uri: uri,
          mediaType: mediaType,
          filename: filename,
        );
        return utf8.encode('fixture-image');
      },
    ),
  );

  return codec.encode(
    request: GenerateTextRequest(
      prompt: [
        SystemPromptMessage.text('Use concise local answers.'),
        UserPromptMessage(
          parts: [
            const TextPromptPart('Summarize the local fixture input.'),
            FilePromptPart(
              mediaType: 'image/png',
              filename: 'cat.png',
              data: FileUrlData(Uri.parse('https://example.test/cat.png')),
            ),
          ],
        ),
        AssistantPromptMessage(
          parts: const [
            ReasoningPromptPart('Need weather data.'),
            ToolCallPromptPart(
              toolCallId: 'call_weather',
              toolName: 'weather',
              input: {
                'city': 'Hong Kong',
              },
            ),
          ],
        ),
        ToolPromptMessage(
          toolName: 'weather',
          parts: [
            ToolResultPromptPart(
              toolCallId: 'call_weather',
              toolName: 'weather',
              toolOutput: ContentToolOutput(
                parts: const [
                  TextToolOutputContentPart('Forecast ready.'),
                  JsonToolOutputContentPart({
                    'temperatureC': 26,
                    'condition': 'Cloudy',
                  }),
                  CustomToolOutputContentPart(
                    kind: 'ollama-note',
                    data: {
                      'source': 'fixture',
                    },
                  ),
                ],
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
          ),
          strict: true,
        ),
      ],
      toolChoice: const SpecificToolChoice('weather'),
      options: GenerateTextOptions(
        maxOutputTokens: 128,
        temperature: 0.2,
        topP: 0.8,
        topK: 40,
        seed: 1234,
        stopSequences: const ['END'],
        responseFormat: JsonResponseFormat(
          schema: JsonSchema.object(
            properties: {
              'summary': {'type': 'string'},
            },
            required: ['summary'],
          ),
          name: 'summary',
          strict: true,
        ),
        reasoning: const GenerateTextReasoningOptions.enabled(
          effort: ReasoningEffort.medium,
          budgetTokens: 512,
        ),
      ),
      callOptions: const CallOptions(
        providerOptions: OllamaGenerateTextOptions(
          numCtx: 4096,
          keepAlive: '10m',
          raw: false,
          reasoning: true,
        ),
      ),
    ),
    stream: false,
  );
}

List<LanguageModelStreamEvent> buildOllamaChatStreamFixtureEvents() {
  const responseCodec = OllamaChatResponseCodec(modelId: 'llama3.2');
  const codec = OllamaChatStreamCodec(responseCodec: responseCodec);
  final state = OllamaChatStreamState();
  final events = <LanguageModelStreamEvent>[];

  for (final chunk in <Map<String, Object?>>[
    {
      'model': 'llama3.2',
      'created_at': '2026-04-08T10:00:00Z',
      'done': false,
      'message': {
        'thinking': 'Plan',
        'content': 'Hello ',
      },
      'total_duration': 100,
    },
    {
      'model': 'llama3.2',
      'created_at': '2026-04-08T10:00:01Z',
      'done': true,
      'done_reason': 'stop',
      'message': {
        'content': 'world',
        'tool_calls': [
          {
            'function': {
              'name': 'weather',
              'arguments': {
                'city': 'Hong Kong',
              },
            },
          },
        ],
      },
      'prompt_eval_count': 7,
      'eval_count': 3,
      'total_duration': 200,
    },
  ]) {
    events.addAll(
      codec.decodeJsonChunk(
        chunk,
        state,
        includeRawChunks: true,
      ),
    );
  }

  return events;
}

void _checkFixtureBinaryRequest({
  required Uri uri,
  required String mediaType,
  required String? filename,
}) {
  if (uri.toString() != 'https://example.test/cat.png' ||
      mediaType != 'image/png' ||
      filename != 'cat.png') {
    throw StateError(
      'Unexpected Ollama fixture binary request: '
      'uri=$uri mediaType=$mediaType filename=$filename',
    );
  }
}
