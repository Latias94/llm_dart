import 'package:llm_dart_core/llm_dart_core.dart';
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
  GenerateTextRequest? lastRequest;

  _RecordingLanguageModel({
    required this.generateResult,
  });

  @override
  String get modelId => 'test-model';

  @override
  String get providerId => 'test';

  @override
  Future<GenerateTextResult> generate(GenerateTextRequest request) async {
    lastRequest = request;
    return generateResult;
  }

  @override
  Stream<TextStreamEvent> stream(GenerateTextRequest request) async* {
    lastRequest = request;
    yield const FinishEvent(
      finishReason: FinishReason.stop,
    );
  }
}
