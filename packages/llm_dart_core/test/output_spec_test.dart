import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_ai/internal.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;
import 'package:test/test.dart';

void main() {
  group('generateOutput', () {
    test('injects shared responseFormat and parses decoded output', () async {
      final model = _RecordingLanguageModel(
        generateResult: GenerateTextResult(
          content: const [
            TextContentPart('{"value":"ok"}'),
          ],
          finishReason: FinishReason.stop,
          responseId: 'resp_1',
          responseModelId: 'test-model',
        ),
      );

      final result = await generateOutput<String>(
        model: model,
        prompt: [
          UserPromptMessage.text('Return JSON.'),
        ],
        outputSpec: JsonOutputSpec<String>(
          name: 'answer',
          schema: JsonSchema.object(
            properties: const {
              'value': {'type': 'string'},
            },
            required: const ['value'],
          ),
          decode: (json) {
            final map = json as Map<String, Object?>;
            return map['value']! as String;
          },
        ),
      );

      expect(result.output, 'ok');
      expect(result.responseId, 'resp_1');

      final responseFormat =
          model.lastRequest?.options.responseFormat as JsonResponseFormat?;
      expect(responseFormat, isNotNull);
      expect(responseFormat!.name, 'answer');
      expect(
        responseFormat.schema.toJson(),
        const {
          'type': 'object',
          'properties': {
            'value': {'type': 'string'},
          },
          'required': ['value'],
        },
      );
    });

    test('rejects explicit GenerateTextOptions.responseFormat', () async {
      final model = _RecordingLanguageModel(
        generateResult: GenerateTextResult(
          content: const [
            TextContentPart('{"value":"ok"}'),
          ],
          finishReason: FinishReason.stop,
        ),
      );

      await expectLater(
        generateOutput<Object?>(
          model: model,
          prompt: [
            UserPromptMessage.text('Return JSON.'),
          ],
          options: GenerateTextOptions(
            responseFormat: JsonResponseFormat(
              schema: JsonSchema.object(),
            ),
          ),
          outputSpec: JsonOutputSpec.json(
            schema: JsonSchema.object(),
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('responseFormat'),
          ),
        ),
      );
    });

    test('wraps parse failures as validation ModelError with context details',
        () async {
      final model = _RecordingLanguageModel(
        generateResult: GenerateTextResult(
          content: const [
            TextContentPart('not-json'),
          ],
          finishReason: FinishReason.stop,
          responseId: 'resp_bad',
          responseModelId: 'test-model',
          usage: const UsageStats(
            inputTokens: 1,
            outputTokens: 2,
            totalTokens: 3,
          ),
          providerMetadata: const ProviderMetadata({
            'test': {
              'traceId': 'trace_1',
            },
          }),
        ),
      );

      await expectLater(
        generateOutput<Object?>(
          model: model,
          prompt: [
            UserPromptMessage.text('Return JSON.'),
          ],
          outputSpec: JsonOutputSpec.json(
            schema: JsonSchema.object(),
          ),
        ),
        throwsA(
          isA<ModelError>()
              .having((error) => error.kind, 'kind', ModelErrorKind.validation)
              .having(
                (error) => error.message,
                'message',
                contains('Could not parse structured output JSON'),
              )
              .having(
                (error) => error.details,
                'details',
                allOf(
                  containsPair('stage', 'structured_output'),
                  containsPair('responseId', 'resp_bad'),
                  containsPair('responseModelId', 'test-model'),
                ),
              ),
        ),
      );
    });

    test('parses object output through the shared object spec', () async {
      final model = _RecordingLanguageModel(
        generateResult: GenerateTextResult(
          content: const [
            TextContentPart('{"answer":"ok"}'),
          ],
          finishReason: FinishReason.stop,
        ),
      );

      final result = await generateOutput<String>(
        model: model,
        prompt: [
          UserPromptMessage.text('Return an object.'),
        ],
        outputSpec: ObjectOutputSpec<String>(
          schema: JsonSchema.object(
            properties: const {
              'answer': {'type': 'string'},
            },
            required: const ['answer'],
          ),
          decode: (json) => json['answer']! as String,
        ),
      );

      expect(result.output, 'ok');
    });

    test('wraps array output in a shared object schema and decodes elements',
        () async {
      final model = _RecordingLanguageModel(
        generateResult: GenerateTextResult(
          content: const [
            TextContentPart('{"elements":[{"value":"a"},{"value":"b"}]}'),
          ],
          finishReason: FinishReason.stop,
        ),
      );

      final result = await generateOutput<List<String>>(
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

      expect(result.output, ['a', 'b']);

      final responseFormat =
          model.lastRequest?.options.responseFormat as JsonResponseFormat?;
      expect(responseFormat, isNotNull);
      expect(
        responseFormat!.schema.toJson(),
        const {
          'type': 'object',
          'properties': {
            'elements': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'value': {'type': 'string'},
                },
                'required': ['value'],
              },
            },
          },
          'required': ['elements'],
          'additionalProperties': false,
        },
      );
    });

    test('parses choice output through the shared choice spec', () async {
      final model = _RecordingLanguageModel(
        generateResult: GenerateTextResult(
          content: const [
            TextContentPart('{"result":"green"}'),
          ],
          finishReason: FinishReason.stop,
        ),
      );

      final result = await generateOutput<String>(
        model: model,
        prompt: [
          UserPromptMessage.text('Pick one option.'),
        ],
        outputSpec: ChoiceOutputSpec<String>(
          options: const ['red', 'green', 'blue'],
        ),
      );

      expect(result.output, 'green');
    });
  });

  group('streamOutput', () {
    test(
        'reuses OutputSpec on the streaming path and emits a final parsed result',
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
            responseId: 'resp_stream',
            modelId: 'test-model',
          ),
          TextStartEvent(id: 'text_1'),
          TextDeltaEvent(id: 'text_1', delta: '{"value":"ok"}'),
          TextEndEvent(id: 'text_1'),
          FinishEvent(
            finishReason: FinishReason.stop,
          ),
        ],
      );

      final events = await streamOutput<String>(
        model: model,
        prompt: [
          UserPromptMessage.text('Return JSON.'),
        ],
        outputSpec: JsonOutputSpec<String>(
          name: 'answer',
          schema: JsonSchema.object(
            properties: const {
              'value': {'type': 'string'},
            },
            required: const ['value'],
          ),
          decode: (json) {
            final map = json as Map<String, Object?>;
            return map['value']! as String;
          },
        ),
      ).toList();

      expect(events.whereType<OutputTextStreamEvent<String>>(), hasLength(9));
      expect(events.whereType<OutputPartialEvent<String>>(), hasLength(1));
      expect(
        events.whereType<OutputPartialEvent<String>>().single.partialOutput,
        {
          'value': 'ok',
        },
      );
      final resultEvent = events.last as OutputResultEvent<String>;
      expect(resultEvent.result.output, 'ok');
      expect(resultEvent.result.responseId, 'resp_stream');

      final responseFormat =
          model.lastRequest?.options.responseFormat as JsonResponseFormat?;
      expect(responseFormat, isNotNull);
      expect(responseFormat!.name, 'answer');
    });

    test('emits partial object outputs for reparable streamed JSON', () async {
      final model = _RecordingLanguageModel(
        generateResult: GenerateTextResult(
          content: const [
            TextContentPart('unused'),
          ],
          finishReason: FinishReason.stop,
        ),
        streamEvents: const [
          TextStartEvent(id: 'text_1'),
          TextDeltaEvent(id: 'text_1', delta: '{"answer":"hel'),
          TextDeltaEvent(id: 'text_1', delta: 'lo"}'),
          TextEndEvent(id: 'text_1'),
          FinishEvent(
            finishReason: FinishReason.stop,
          ),
        ],
      );

      final events = await streamOutput<String>(
        model: model,
        prompt: [
          UserPromptMessage.text('Return JSON.'),
        ],
        outputSpec: ObjectOutputSpec<String>(
          schema: JsonSchema.object(
            properties: const {
              'answer': {'type': 'string'},
            },
            required: const ['answer'],
          ),
          decode: (json) => json['answer']! as String,
        ),
      ).toList();

      final partialEvents = events
          .whereType<OutputPartialEvent<String>>()
          .toList(growable: false);
      expect(partialEvents, hasLength(2));
      expect(
        partialEvents[0].partialOutput,
        {
          'answer': 'hel',
        },
      );
      expect(
        partialEvents[1].partialOutput,
        {
          'answer': 'hello',
        },
      );

      final resultEvent = events.last as OutputResultEvent<String>;
      expect(resultEvent.result.output, 'hello');
    });

    test('emits partial array outputs with only completed decoded elements',
        () async {
      final model = _RecordingLanguageModel(
        generateResult: GenerateTextResult(
          content: const [
            TextContentPart('unused'),
          ],
          finishReason: FinishReason.stop,
        ),
        streamEvents: const [
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

      final events = await streamOutput<List<String>>(
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
      ).toList();

      final partialEvents = events
          .whereType<OutputPartialEvent<List<String>>>()
          .toList(growable: false);
      expect(partialEvents, hasLength(2));
      expect(partialEvents[0].partialOutput, isEmpty);
      expect(partialEvents[1].partialOutput, ['a', 'b']);

      final elementEvents = events
          .whereType<OutputElementEvent<String>>()
          .toList(growable: false);
      expect(elementEvents, hasLength(2));
      expect(elementEvents[0].element, 'a');
      expect(elementEvents[1].element, 'b');

      final resultEvent = events.last as OutputResultEvent<List<String>>;
      expect(resultEvent.result.output, ['a', 'b']);
    });

    test('emits partial choice output when a repaired prefix is unambiguous',
        () async {
      final model = _RecordingLanguageModel(
        generateResult: GenerateTextResult(
          content: const [
            TextContentPart('unused'),
          ],
          finishReason: FinishReason.stop,
        ),
        streamEvents: const [
          TextStartEvent(id: 'text_1'),
          TextDeltaEvent(id: 'text_1', delta: '{"result":"ur'),
          TextDeltaEvent(id: 'text_1', delta: 'gent"}'),
          TextEndEvent(id: 'text_1'),
          FinishEvent(
            finishReason: FinishReason.stop,
          ),
        ],
      );

      final events = await streamOutput<String>(
        model: model,
        prompt: [
          UserPromptMessage.text('Pick one.'),
        ],
        outputSpec: ChoiceOutputSpec<String>(
          options: const ['calm', 'urgent', 'playful'],
        ),
      ).toList();

      final partialEvents = events
          .whereType<OutputPartialEvent<String>>()
          .toList(growable: false);
      expect(partialEvents, hasLength(1));
      expect(partialEvents.single.partialOutput, 'urgent');

      final resultEvent = events.last as OutputResultEvent<String>;
      expect(resultEvent.result.output, 'urgent');
    });

    test(
        'rejects explicit GenerateTextOptions.responseFormat on the streaming path',
        () async {
      final model = _RecordingLanguageModel(
        generateResult: GenerateTextResult(
          content: const [
            TextContentPart('unused'),
          ],
          finishReason: FinishReason.stop,
        ),
        streamEvents: const [
          FinishEvent(
            finishReason: FinishReason.stop,
          ),
        ],
      );

      await expectLater(
        streamOutput<Object?>(
          model: model,
          prompt: [
            UserPromptMessage.text('Return JSON.'),
          ],
          options: GenerateTextOptions(
            responseFormat: JsonResponseFormat(
              schema: JsonSchema.object(),
            ),
          ),
          outputSpec: JsonOutputSpec.json(
            schema: JsonSchema.object(),
          ),
        ).drain<void>(),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('responseFormat'),
          ),
        ),
      );
    });

    test('wraps streaming parse failures as validation ModelError', () async {
      final model = _RecordingLanguageModel(
        generateResult: GenerateTextResult(
          content: const [
            TextContentPart('unused'),
          ],
          finishReason: FinishReason.stop,
        ),
        streamEvents: const [
          ResponseMetadataEvent(
            responseId: 'resp_bad_stream',
          ),
          TextStartEvent(id: 'text_1'),
          TextDeltaEvent(id: 'text_1', delta: 'not-json'),
          TextEndEvent(id: 'text_1'),
          FinishEvent(
            finishReason: FinishReason.stop,
          ),
        ],
      );

      await expectLater(
        streamOutput<Object?>(
          model: model,
          prompt: [
            UserPromptMessage.text('Return JSON.'),
          ],
          outputSpec: JsonOutputSpec.json(
            schema: JsonSchema.object(),
          ),
        ).drain<void>(),
        throwsA(
          isA<ModelError>()
              .having((error) => error.kind, 'kind', ModelErrorKind.validation)
              .having(
                (error) => error.details,
                'details',
                containsPair('responseId', 'resp_bad_stream'),
              ),
        ),
      );
    });
  });

  group('streamOutputResult', () {
    test(
        'replays buffered partial outputs, array elements, text events, and final output',
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
            responseId: 'resp_stream_result',
            modelId: 'test-model',
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

      final streamResult = streamOutputResult<List<String>>(
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

      expect(await streamResult.output, ['a', 'b']);
      expect((await streamResult.result).responseId, 'resp_stream_result');
      expect(
        await streamResult.partialOutputStream.toList(),
        [
          const <String>[],
          const ['a', 'b'],
        ],
      );
      expect(
        await streamResult.elementStream<String>().toList(),
        ['a', 'b'],
      );

      final textEvents = await streamResult.textStream.toList();
      expect(
        textEvents,
        hasLength(10),
      );
      expect(textEvents.whereType<TextDeltaEvent>().length, 2);

      final outputEvents = await streamResult.eventStream.toList();
      expect(
          outputEvents.whereType<OutputPartialEvent<List<String>>>().length, 2);
      expect(
        outputEvents.whereType<OutputElementEvent<String>>().length,
        2,
      );
      expect(
        outputEvents
            .whereType<OutputResultEvent<List<String>>>()
            .single
            .result
            .output,
        ['a', 'b'],
      );
    });

    test(
        'propagates structured-output errors through result and replay streams',
        () async {
      final model = _RecordingLanguageModel(
        generateResult: GenerateTextResult(
          content: const [
            TextContentPart('unused'),
          ],
          finishReason: FinishReason.stop,
        ),
        streamEvents: const [
          TextStartEvent(id: 'text_1'),
          TextDeltaEvent(id: 'text_1', delta: 'not-json'),
          TextEndEvent(id: 'text_1'),
          FinishEvent(
            finishReason: FinishReason.stop,
          ),
        ],
      );

      final streamResult = streamOutputResult<Object?>(
        model: model,
        prompt: [
          UserPromptMessage.text('Return JSON.'),
        ],
        outputSpec: JsonOutputSpec.json(
          schema: JsonSchema.object(),
        ),
      );

      await expectLater(
        streamResult.output,
        throwsA(
          isA<ModelError>()
              .having((error) => error.kind, 'kind', ModelErrorKind.validation),
        ),
      );

      await expectLater(
        streamResult.eventStream.drain<void>(),
        throwsA(
          isA<ModelError>()
              .having((error) => error.kind, 'kind', ModelErrorKind.validation),
        ),
      );

      await expectLater(
        streamResult.partialOutputStream.drain<void>(),
        throwsA(
          isA<ModelError>()
              .having((error) => error.kind, 'kind', ModelErrorKind.validation),
        ),
      );
    });
  });

  group('output spec validation', () {
    test('object spec rejects non-object schemas', () {
      expect(
        () => ObjectOutputSpec.json(
          schema: JsonSchema.array(),
        ),
        throwsArgumentError,
      );
    });

    test('choice spec rejects empty or duplicate options', () {
      expect(
        () => ChoiceOutputSpec<String>(options: const []),
        throwsArgumentError,
      );
      expect(
        () => ChoiceOutputSpec<String>(
          options: const ['red', 'red'],
        ),
        throwsArgumentError,
      );
    });
  });
}

final class _RecordingLanguageModel implements LanguageModel {
  final GenerateTextResult generateResult;
  final List<TextStreamEvent> streamEvents;
  GenerateTextRequest? lastRequest;

  _RecordingLanguageModel({
    required this.generateResult,
    this.streamEvents = const [
      FinishEvent(
        finishReason: FinishReason.stop,
      ),
    ],
  });

  @override
  String get modelId => 'test-model';

  @override
  String get providerId => 'test';

  @override
  Future<GenerateTextResult> doGenerate(GenerateTextRequest request) async {
    lastRequest = request;
    return generateResult;
  }

  @override
  Stream<provider.LanguageModelStreamEvent> doStream(
    GenerateTextRequest request,
  ) async* {
    lastRequest = request;
    for (final event in streamEvents) {
      yield textStreamEventToProvider(event);
    }
  }
}
