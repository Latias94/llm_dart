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
