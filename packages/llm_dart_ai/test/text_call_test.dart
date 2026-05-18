import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_ai/internal.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;
import 'package:test/test.dart';

void main() {
  group('generateTextCall', () {
    test('returns a raw result wrapper when no outputSpec is provided',
        () async {
      final model = _RecordingLanguageModel(
        generateResult: GenerateTextResult(
          content: const [
            TextContentPart('plain text'),
          ],
          finishReason: FinishReason.stop,
          responseId: 'resp_text_call',
        ),
      );

      final result = await generateTextCall(
        model: model,
        prompt: [
          UserPromptMessage.text('Say hello.'),
        ],
      );

      expect(result.text, 'plain text');
      expect(result.responseId, 'resp_text_call');
      expect(result.hasOutput, isFalse);
      expect(result.outputOrNull, isNull);
      expect(
        () => result.output,
        throwsStateError,
      );
    });

    test('accepts user-facing messages for raw calls', () async {
      final model = _RecordingLanguageModel(
        generateResult: GenerateTextResult(
          content: const [
            TextContentPart('from messages'),
          ],
          finishReason: FinishReason.stop,
        ),
      );

      final result = await generateTextCall(
        model: model,
        messages: [
          UserModelMessage.text('Say hello.'),
        ],
      );

      expect(result.text, 'from messages');
      final message = model.lastRequest!.prompt.single as UserPromptMessage;
      final text = message.parts.single as TextPromptPart;
      expect(text.text, 'Say hello.');
    });

    test('parses structured output when outputSpec is provided', () async {
      final model = _RecordingLanguageModel(
        generateResult: GenerateTextResult(
          content: const [
            TextContentPart('{"value":"ok"}'),
          ],
          finishReason: FinishReason.stop,
        ),
      );

      final result = await generateTextCall<String>(
        model: model,
        prompt: [
          UserPromptMessage.text('Return JSON.'),
        ],
        outputSpec: ObjectOutputSpec<String>(
          schema: JsonSchema.object(
            properties: const {
              'value': {'type': 'string'},
            },
            required: const ['value'],
          ),
          decode: (json) => json['value']! as String,
        ),
      );

      expect(result.hasOutput, isTrue);
      expect(result.output, 'ok');
      expect(
        (model.lastRequest?.options.responseFormat as JsonResponseFormat?)
            ?.schema
            .toJson(),
        const {
          'type': 'object',
          'properties': {
            'value': {'type': 'string'},
          },
          'required': ['value'],
        },
      );
    });

    test('structured output can run through the runtime tool loop', () async {
      final model = _RecordingLanguageModel(
        generateResults: [
          GenerateTextResult(
            content: const [
              ToolCallContentPart(
                ToolCallContent(
                  toolCallId: 'tool-1',
                  toolName: 'weather',
                  input: {
                    'city': 'Tokyo',
                  },
                ),
              ),
            ],
            finishReason: FinishReason.toolCalls,
          ),
          GenerateTextResult(
            content: const [
              TextContentPart('{"value":"sunny"}'),
            ],
            finishReason: FinishReason.stop,
          ),
        ],
      );

      final result = await generateTextCall<String>(
        model: model,
        prompt: [
          UserPromptMessage.text('Return weather JSON.'),
        ],
        tools: [
          FunctionToolDefinition(
            name: 'weather',
            inputSchema: ToolJsonSchema.object(),
          ),
        ],
        functionToolExecutor: (_) {
          return const GenerateTextToolExecutionResult.output({
            'forecast': 'sunny',
          });
        },
        outputSpec: ObjectOutputSpec<String>(
          schema: JsonSchema.object(
            properties: const {
              'value': {'type': 'string'},
            },
            required: const ['value'],
          ),
          decode: (json) => json['value']! as String,
        ),
        stopWhen: [
          isLoopFinished(),
        ],
      );

      expect(model.requests, hasLength(2));
      expect(result.output, 'sunny');
      expect(result.text, '{"value":"sunny"}');
    });
  });

  group('streamTextCall', () {
    test('replays the raw stream and exposes a final raw result', () async {
      final model = _RecordingLanguageModel(
        generateResult: GenerateTextResult(
          content: const [
            TextContentPart('unused'),
          ],
          finishReason: FinishReason.stop,
        ),
        streamEvents: const [
          ResponseMetadataEvent(
            responseId: 'resp_stream_text_call',
          ),
          TextStartEvent(id: 'text_1'),
          TextDeltaEvent(id: 'text_1', delta: 'plain'),
          TextDeltaEvent(id: 'text_1', delta: ' text'),
          TextEndEvent(id: 'text_1'),
          FinishEvent(
            finishReason: FinishReason.stop,
          ),
        ],
      );

      final stream = streamTextCall(
        model: model,
        prompt: [
          UserPromptMessage.text('Say hello.'),
        ],
      );

      final events = await stream.toList();
      expect(events, hasLength(10));
      expect(events.first, isA<RunStartEvent>());
      expect(events.last, isA<RunFinishEvent>());
      expect(await stream.textStream.toList(), hasLength(10));
      expect(
        await stream.chatUiStream(messageId: 'assistant-1').toList(),
        [
          isA<ChatUiMessageStartChunk>(),
          isA<ChatUiEventChunk>(),
          isA<ChatUiEventChunk>(),
          isA<ChatUiEventChunk>(),
          isA<ChatUiEventChunk>(),
          isA<ChatUiEventChunk>(),
          isA<ChatUiEventChunk>(),
          isA<ChatUiEventChunk>(),
          isA<ChatUiEventChunk>(),
          isA<ChatUiEventChunk>(),
          isA<ChatUiEventChunk>(),
        ],
      );
      expect(await stream.text, 'plain text');
      expect((await stream.result).responseId, 'resp_stream_text_call');
      expect(stream.hasOutput, isFalse);
      expect(await stream.partialOutputStream.toList(), isEmpty);
      await expectLater(
        stream.output,
        throwsStateError,
      );
    });

    test('accepts user-facing messages for raw streams', () async {
      final model = _RecordingLanguageModel(
        generateResult: GenerateTextResult(
          content: const [
            TextContentPart('unused'),
          ],
          finishReason: FinishReason.stop,
        ),
        streamEvents: const [
          TextStartEvent(id: 'text_1'),
          TextDeltaEvent(id: 'text_1', delta: 'from messages'),
          TextEndEvent(id: 'text_1'),
          FinishEvent(finishReason: FinishReason.stop),
        ],
      );

      final stream = streamTextCall(
        model: model,
        messages: [
          UserModelMessage.text('Say hello.'),
        ],
      );

      expect(await stream.text, 'from messages');
      final message = model.lastRequest!.prompt.single as UserPromptMessage;
      final text = message.parts.single as TextPromptPart;
      expect(text.text, 'Say hello.');
    });

    test(
        'keeps raw stream compatibility while exposing structured side channels',
        () async {
      final model = _RecordingLanguageModel(
        generateResult: GenerateTextResult(
          content: const [
            TextContentPart('unused'),
          ],
          finishReason: FinishReason.stop,
        ),
        streamEvents: const [
          ResponseMetadataEvent(
            responseId: 'resp_structured_stream_call',
          ),
          TextStartEvent(id: 'text_1'),
          TextDeltaEvent(
            id: 'text_1',
            delta: '{"elements":[{"value":"a"},',
          ),
          TextDeltaEvent(
            id: 'text_1',
            delta: '{"value":"b"}]}',
          ),
          TextEndEvent(id: 'text_1'),
          FinishEvent(
            finishReason: FinishReason.stop,
          ),
        ],
      );

      final stream = streamTextCall<List<String>>(
        model: model,
        prompt: [
          UserPromptMessage.text('Return an array.'),
        ],
        outputSpec: ArrayOutputSpec<String>(
          elementSchema: JsonSchema.object(
            properties: const {
              'value': {'type': 'string'},
            },
            required: const ['value'],
          ),
          decodeElement: (json) {
            final map = json as Map<String, Object?>;
            return map['value']! as String;
          },
        ),
      );

      final events = await stream.toList();
      expect(events.whereType<TextDeltaEvent>().length, 2);
      expect(stream.hasOutput, isTrue);
      expect(await stream.output, ['a', 'b']);
      expect(await stream.text, '{"elements":[{"value":"a"},{"value":"b"}]}');
      expect(
        await stream.partialOutputStream.toList(),
        [
          const <String>[],
          const ['a', 'b'],
        ],
      );
      expect(
        await stream.elementStream<String>().toList(),
        ['a', 'b'],
      );
      expect(
        (await stream.result).responseId,
        'resp_structured_stream_call',
      );
    });

    test('keeps raw result available when structured output parsing fails',
        () async {
      final model = _RecordingLanguageModel(
        generateResult: GenerateTextResult(
          content: const [
            TextContentPart('unused'),
          ],
          finishReason: FinishReason.stop,
        ),
        streamEvents: const [
          ResponseMetadataEvent(
            responseId: 'resp_structured_error_call',
          ),
          TextStartEvent(id: 'text_1'),
          TextDeltaEvent(id: 'text_1', delta: 'not-json'),
          TextEndEvent(id: 'text_1'),
          FinishEvent(
            finishReason: FinishReason.stop,
          ),
        ],
      );

      final stream = streamTextCall<Object?>(
        model: model,
        prompt: [
          UserPromptMessage.text('Return JSON.'),
        ],
        outputSpec: JsonOutputSpec.json(
          schema: JsonSchema.object(),
        ),
      );

      expect(await stream.text, 'not-json');
      expect((await stream.result).responseId, 'resp_structured_error_call');
      expect(await stream.partialOutputStream.toList(), isEmpty);
      await expectLater(
        stream.output,
        throwsA(
          isA<ModelError>()
              .having((error) => error.kind, 'kind', ModelErrorKind.validation),
        ),
      );
    });
  });
}

final class _RecordingLanguageModel implements LanguageModel {
  final List<GenerateTextResult> _generateResults;
  final List<TextStreamEvent> streamEvents;
  final List<GenerateTextRequest> requests = [];
  GenerateTextRequest? lastRequest;

  _RecordingLanguageModel({
    GenerateTextResult? generateResult,
    List<GenerateTextResult>? generateResults,
    this.streamEvents = const [
      FinishEvent(
        finishReason: FinishReason.stop,
      ),
    ],
  }) : _generateResults = List<GenerateTextResult>.from(
          generateResults ??
              [
                if (generateResult != null)
                  generateResult
                else
                  GenerateTextResult(
                    content: const [],
                    finishReason: FinishReason.stop,
                  ),
              ],
        );

  @override
  String get modelId => 'test-model';

  @override
  String get providerId => 'test';

  @override
  Future<GenerateTextResult> doGenerate(GenerateTextRequest request) async {
    lastRequest = request;
    requests.add(request);
    if (_generateResults.isEmpty) {
      throw StateError('No more fake generate results configured.');
    }

    return _generateResults.removeAt(0);
  }

  @override
  Stream<provider.LanguageModelStreamEvent> doStream(
    GenerateTextRequest request,
  ) async* {
    lastRequest = request;
    requests.add(request);
    for (final event in streamEvents) {
      yield textStreamEventToProvider(event);
    }
  }
}
