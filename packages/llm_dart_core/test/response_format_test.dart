import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('JsonSchema', () {
    test('normalizes nested JSON-safe values', () {
      final schema = JsonSchema.raw(
        const {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'count': {'type': 'integer'},
              'tags': {
                'type': 'array',
                'items': {'type': 'string'},
              },
            },
          },
        },
      );

      expect(
        schema.toJson(),
        const {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'count': {'type': 'integer'},
              'tags': {
                'type': 'array',
                'items': {'type': 'string'},
              },
            },
          },
        },
      );
    });
  });

  group('GenerateTextOptions.responseFormat', () {
    test('generateText forwards shared responseFormat to the model request',
        () async {
      final model = _RecordingLanguageModel();

      await generateText(
        model: model,
        prompt: [
          UserPromptMessage.text('Return structured output.'),
        ],
        options: GenerateTextOptions(
          responseFormat: JsonResponseFormat(
            name: 'answer',
            description: 'Structured answer payload.',
            schema: JsonSchema.object(
              properties: const {
                'value': {'type': 'string'},
              },
              required: const ['value'],
            ),
          ),
        ),
      );

      final responseFormat =
          model.lastRequest?.options.responseFormat as JsonResponseFormat?;
      expect(responseFormat, isNotNull);
      expect(responseFormat!.name, 'answer');
      expect(responseFormat.description, 'Structured answer payload.');
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
  });
}

final class _RecordingLanguageModel implements LanguageModel {
  GenerateTextRequest? lastRequest;

  @override
  String get modelId => 'test-model';

  @override
  String get providerId => 'test';

  @override
  Future<GenerateTextResult> generate(GenerateTextRequest request) async {
    lastRequest = request;
    return GenerateTextResult(
      content: const [
        TextContentPart('ok'),
      ],
      finishReason: FinishReason.stop,
    );
  }

  @override
  Stream<TextStreamEvent> stream(GenerateTextRequest request) async* {
    lastRequest = request;
    yield const FinishEvent(
      finishReason: FinishReason.stop,
    );
  }
}
