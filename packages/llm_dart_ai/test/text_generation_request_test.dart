import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;
import 'package:test/test.dart';

void main() {
  group('TextGenerationRequest', () {
    test('drives text generation through one immutable request object',
        () async {
      final tools = [
        FunctionToolDefinition(
          name: 'weather',
          inputSchema: ToolJsonSchema.object(),
        ),
      ];
      final stopWhen = [
        isStepCount(1),
      ];
      final model = _RecordingLanguageModel([
        GenerateTextResult(
          content: const [
            TextContentPart('Request output'),
          ],
          finishReason: FinishReason.stop,
        ),
      ]);

      final request = TextGenerationRequest.fromMessages(
        model: model,
        messages: [
          UserModelMessage.text('Hello from request'),
        ],
        tools: tools,
        toolChoice: const RequiredToolChoice(),
        options: const GenerateTextOptions(
          temperature: 0.2,
        ),
        callOptions: const CallOptions(
          timeout: Duration(seconds: 30),
        ),
        stopWhen: stopWhen,
      );

      tools.add(
        FunctionToolDefinition(
          name: 'later',
          inputSchema: ToolJsonSchema.object(),
        ),
      );
      stopWhen.add(isLoopFinished());

      final result = await generateTextForRequest(request);

      expect(result.text, 'Request output');
      expect(model.requests, hasLength(1));
      final providerRequest = model.requests.single;
      expect(providerRequest.tools.map((tool) => tool.name), ['weather']);
      expect(providerRequest.toolChoice, isA<RequiredToolChoice>());
      expect(providerRequest.options.temperature, 0.2);
      expect(providerRequest.callOptions.timeout, const Duration(seconds: 30));

      final message = providerRequest.prompt.single as UserPromptMessage;
      final text = message.parts.single as TextPromptPart;
      expect(text.text, 'Hello from request');
    });

    test('can be reused by structured output and text call helpers', () async {
      final model = _RecordingLanguageModel([
        GenerateTextResult(
          content: const [
            TextContentPart('{"answer":"structured"}'),
          ],
          finishReason: FinishReason.stop,
        ),
        GenerateTextResult(
          content: const [
            TextContentPart('{"answer":"call"}'),
          ],
          finishReason: FinishReason.stop,
        ),
      ]);
      final outputSpec = ObjectOutputSpec.json(
        schema: JsonSchema.object(
          properties: const {
            'answer': {'type': 'string'},
          },
          required: const ['answer'],
        ),
      );
      final request = TextGenerationRequest.fromMessages(
        model: model,
        messages: [
          UserModelMessage.text('Return an answer object'),
        ],
      );

      final output = await generateOutputForRequest(
        request,
        outputSpec: outputSpec,
      );
      final call = await generateTextCallForRequest<Map<String, Object?>>(
        request,
        outputSpec: outputSpec,
      );

      expect(output.output, {'answer': 'structured'});
      expect(call.output, {'answer': 'call'});
      expect(model.requests, hasLength(2));
      for (final request in model.requests) {
        expect(request.options.responseFormat, isA<JsonResponseFormat>());
        final message = request.prompt.single as UserPromptMessage;
        final text = message.parts.single as TextPromptPart;
        expect(text.text, 'Return an answer object');
      }
    });
  });
}

final class _RecordingLanguageModel implements LanguageModel {
  final List<GenerateTextResult> _results;
  final List<GenerateTextRequest> requests = [];

  _RecordingLanguageModel(this._results);

  @override
  String get modelId => 'recording-model';

  @override
  String get providerId => 'test';

  @override
  Future<GenerateTextResult> doGenerate(GenerateTextRequest request) async {
    requests.add(request);
    return _results.removeAt(0);
  }

  @override
  Stream<provider.LanguageModelStreamEvent> doStream(
    GenerateTextRequest request,
  ) async* {
    throw UnimplementedError();
  }
}
