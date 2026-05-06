import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:test/test.dart';

void main() {
  const codec = GoogleGenerateContentStreamCodec();

  group('GoogleGenerateContentStreamCodec', () {
    test('maps text, reasoning, tool calls, sources, and finish events', () {
      final state = GoogleGenerateContentStreamState();
      final events = <TextStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'responseId': 'resp_1',
          'modelVersion': 'gemini-3-pro-preview',
          'usageMetadata': {
            'promptTokenCount': 5,
            'candidatesTokenCount': 1,
            'totalTokenCount': 6,
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
                    'thoughtSignature': 'sig_1',
                  },
                ],
              },
            },
          ],
        },
        {
          'usageMetadata': {
            'promptTokenCount': 5,
            'candidatesTokenCount': 3,
            'thoughtsTokenCount': 4,
            'totalTokenCount': 12,
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
                      'id': 'call_google_1',
                      'name': 'weather',
                      'args': {
                        'city': 'Hong Kong',
                      },
                    },
                    'thoughtSignature': 'sig_2',
                  },
                ],
              },
              'groundingMetadata': {
                'groundingChunks': [
                  {
                    'web': {
                      'uri': 'https://example.com',
                      'title': 'Example',
                    },
                  },
                ],
              },
              'finishReason': 'STOP',
              'finishMessage': 'Model generated function call(s).',
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

      expect(events.first, isA<ResponseMetadataEvent>());
      expect(events.whereType<TextStartEvent>().single.id, '0');
      expect(events.whereType<TextDeltaEvent>().first.delta, 'Hello ');
      expect(events.whereType<TextEndEvent>().single.id, '0');
      expect(events.whereType<ReasoningStartEvent>().single.id, '1');
      expect(events.whereType<ReasoningDeltaEvent>().single.delta, 'Plan');
      expect(events.whereType<ReasoningEndEvent>().single.id, '1');

      final toolInputStart = events.whereType<ToolInputStartEvent>().single;
      expect(toolInputStart.toolCallId, 'call_google_1');
      expect(toolInputStart.toolName, 'weather');
      final toolInputDelta = events.whereType<ToolInputDeltaEvent>().single;
      expect(toolInputDelta.delta, '{"city":"Hong Kong"}');
      final toolCall = events.whereType<ToolCallEvent>().single.toolCall;
      expect(toolCall.toolCallId, 'call_google_1');
      expect(toolCall.toolName, 'weather');
      expect(
        toolCall.input,
        {
          'city': 'Hong Kong',
        },
      );

      final source = events.whereType<SourceEvent>().single.source;
      expect(source.uri, Uri.parse('https://example.com'));

      final finish = events.whereType<FinishEvent>().single;
      expect(finish.finishReason, FinishReason.toolCalls);
      expect(finish.rawFinishReason, 'STOP');
      expect(finish.usage?.totalTokens, 12);
      expect(
        finish.providerMetadata?.values['google'],
        allOf(
          containsPair('finishMessage', 'Model generated function call(s).'),
          contains('groundingMetadata'),
          contains('promptFeedback'),
        ),
      );
    });

    test('maps provider-executed code execution events', () {
      final state = GoogleGenerateContentStreamState();
      final events = codec.decodeChunk(
        {
          'candidates': [
            {
              'content': {
                'parts': [
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
                ],
              },
              'finishReason': 'STOP',
            },
          ],
        },
        state,
      ).toList();

      final toolCall = events.whereType<ToolCallEvent>().single.toolCall;
      final toolResult = events.whereType<ToolResultEvent>().single.toolResult;

      expect(toolCall.toolName, 'code_execution');
      expect(toolCall.providerExecuted, isTrue);
      expect(toolCall.isDynamic, isTrue);
      expect(toolResult.toolName, 'code_execution');
      expect(toolResult.isDynamic, isTrue);
      expect(toolResult.isError, isFalse);
    });

    test('maps thought inline data into reasoning-file events', () {
      final state = GoogleGenerateContentStreamState();
      final events = codec.decodeChunk(
        {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'inlineData': {
                      'mimeType': 'image/png',
                      'data': 'AQID',
                    },
                    'thought': true,
                    'thoughtSignature': 'sig_reasoning_file',
                  },
                ],
              },
              'finishReason': 'STOP',
            },
          ],
        },
        state,
      ).toList();

      final reasoningFile = events.whereType<ReasoningFileEvent>().single;
      expect(reasoningFile.file.mediaType, 'image/png');
      expect(reasoningFile.file.bytes, [1, 2, 3]);
      expect(
        reasoningFile.providerMetadata?.values['google'],
        {
          'thoughtSignature': 'sig_reasoning_file',
          'thought': true,
        },
      );
    });

    test('maps non-thought inline data into file events', () {
      final state = GoogleGenerateContentStreamState();
      final events = codec.decodeChunk(
        {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'inlineData': {
                      'mimeType': 'application/pdf',
                      'data': 'AQID',
                    },
                  },
                ],
              },
              'finishReason': 'STOP',
            },
          ],
        },
        state,
      ).toList();

      final fileEvent = events.whereType<FileEvent>().single;
      expect(fileEvent.file.mediaType, 'application/pdf');
      expect(fileEvent.file.bytes, [1, 2, 3]);
      expect(events.whereType<ReasoningFileEvent>(), isEmpty);
    });

    test(
        'maps server-side tool-call and tool-response parts into custom events',
        () {
      final state = GoogleGenerateContentStreamState();
      final events = codec.decodeChunk(
        {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': 'Before tool.',
                  },
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
                ],
              },
              'finishReason': 'STOP',
            },
          ],
        },
        state,
      ).toList();

      expect(events.whereType<TextStartEvent>().single.id, '0');
      expect(events.whereType<TextEndEvent>().single.id, '0');
      expect(events.whereType<ToolCallEvent>(), isEmpty);
      expect(events.whereType<ToolResultEvent>(), isEmpty);

      final customEvents = events.whereType<CustomEvent>().toList();
      expect(customEvents, hasLength(2));

      final toolCallReplay =
          GoogleToolCallReplay.tryParseEvent(customEvents.first);
      expect(toolCallReplay, isNotNull);
      expect(toolCallReplay!.toolCallId, 'srvtool_1');
      expect(toolCallReplay.toolName, 'google_search');
      expect(
        toolCallReplay.providerMetadata?.values['google'],
        allOf(
          containsPair('serverToolPart', 'toolCall'),
          containsPair('thoughtSignature', 'sig_srvtool_1'),
        ),
      );

      final toolResponseReplay =
          GoogleToolResponseReplay.tryParseEvent(customEvents.last);
      expect(toolResponseReplay, isNotNull);
      expect(toolResponseReplay!.toolCallId, 'srvtool_1');
      expect(toolResponseReplay.toolName, 'google_search');
    });
  });
}
