import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;
import 'package:test/test.dart';

void main() {
  group('ToolJsonSchema', () {
    test('builds an object-rooted schema', () {
      final schema = ToolJsonSchema.object(
        description: 'Weather lookup arguments.',
        properties: const {
          'city': {
            'type': 'string',
            'description': 'The city name.',
          },
        },
        required: const ['city'],
      );

      expect(
        schema.toJson(),
        {
          'type': 'object',
          'description': 'Weather lookup arguments.',
          'properties': {
            'city': {
              'type': 'string',
              'description': 'The city name.',
            },
          },
          'required': ['city'],
        },
      );
    });

    test('rejects non-object root schemas', () {
      expect(
        () => ToolJsonSchema.raw(
          const {
            'type': 'array',
          },
        ),
        throwsArgumentError,
      );
    });
  });

  group('GenerateTextRequest tools', () {
    final weatherTool = FunctionToolDefinition(
      name: 'weather',
      description: 'Get weather details for a city.',
      inputSchema: ToolJsonSchema.object(
        properties: const {
          'city': {
            'type': 'string',
          },
        },
        required: const ['city'],
      ),
    );

    test('rejects duplicate tool names', () {
      expect(
        () => GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Hello'),
          ],
          tools: [
            weatherTool,
            FunctionToolDefinition(
              name: 'weather',
              inputSchema: ToolJsonSchema.object(),
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects specific tool choices that do not match declared tools', () {
      expect(
        () => GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Hello'),
          ],
          tools: [
            weatherTool,
          ],
          toolChoice: const SpecificToolChoice('search'),
        ),
        throwsArgumentError,
      );
    });

    test('generateText forwards tools and toolChoice to the model', () async {
      final model = _RecordingLanguageModel();

      final result = await generateText(
        model: model,
        prompt: [
          UserPromptMessage.text('Check the forecast.'),
        ],
        tools: [
          weatherTool,
        ],
        toolChoice: const RequiredToolChoice(),
      );

      expect(result.text, 'ok');
      expect(model.lastRequest, isNotNull);
      expect(model.lastRequest!.tools.single.name, 'weather');
      expect(model.lastRequest!.toolChoice, isA<RequiredToolChoice>());
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
  Future<GenerateTextResult> doGenerate(GenerateTextRequest request) async {
    lastRequest = request;
    return GenerateTextResult(
      content: const [
        TextContentPart('ok'),
      ],
      finishReason: FinishReason.stop,
    );
  }

  @override
  Stream<provider.LanguageModelStreamEvent> doStream(
    GenerateTextRequest request,
  ) async* {
    lastRequest = request;
    yield const provider.FinishEvent(
      finishReason: FinishReason.stop,
    );
  }
}
