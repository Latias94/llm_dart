import 'dart:async';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('StreamTextRunner', () {
    test('streams a single generation step and returns a run result', () async {
      final model = _RecordingStreamLanguageModel([
        const [
          TextStartEvent(id: 'text-1'),
          TextDeltaEvent(id: 'text-1', delta: 'Runner output'),
          TextEndEvent(id: 'text-1'),
          FinishEvent(
            finishReason: FinishReason.stop,
            usage: UsageStats(
              inputTokens: 5,
              outputTokens: 7,
              totalTokens: 12,
            ),
          ),
        ],
      ]);
      final callbackOrder = <String>[];
      final stepStarts = <GenerateTextStepStartEvent>[];

      final run = streamTextRun(
        model: model,
        prompt: [
          UserPromptMessage.text('Hello'),
        ],
        tools: [
          FunctionToolDefinition(
            name: 'weather',
            inputSchema: ToolJsonSchema.object(),
          ),
        ],
        toolChoice: const RequiredToolChoice(),
        options: const GenerateTextOptions(
          temperature: 0.2,
        ),
        callOptions: const CallOptions(
          timeout: Duration(seconds: 30),
        ),
        onStepStart: (event) {
          callbackOrder.add('start');
          stepStarts.add(event);
        },
        onStepFinish: (_) {
          callbackOrder.add('step-finish');
        },
        onFinish: (_) {
          callbackOrder.add('finish');
        },
      );

      final events = await run.toList();
      final steps = await run.stepStream.toList();
      final result = await run.result;

      expect(callbackOrder, ['start', 'step-finish', 'finish']);
      expect(stepStarts, hasLength(1));
      expect(stepStarts.single.stepNumber, 0);
      expect(stepStarts.single.previousSteps, isEmpty);

      expect(model.requests, hasLength(1));
      expect(model.requests.single.prompt, hasLength(1));
      expect(model.requests.single.tools.single.name, 'weather');
      expect(model.requests.single.toolChoice, isA<RequiredToolChoice>());
      expect(model.requests.single.options.temperature, 0.2);
      expect(
        model.requests.single.callOptions.timeout,
        const Duration(seconds: 30),
      );

      expect(events, hasLength(4));
      expect(events.whereType<TextDeltaEvent>().single.delta, 'Runner output');

      expect(steps, hasLength(1));
      expect(steps.single.text, 'Runner output');
      expect(steps.single.finishReason, FinishReason.stop);

      expect(result.steps, hasLength(1));
      expect(result.text, 'Runner output');
      expect(result.totalUsage?.totalTokens, 12);
      expect(await run.text, 'Runner output');
      expect(await run.finishReason, FinishReason.stop);
    });

    test('continues tool-call steps with stitched event and step streams',
        () async {
      final model = _RecordingStreamLanguageModel([
        const [
          ToolCallEvent(
            toolCall: ToolCallContent(
              toolCallId: 'tool-1',
              toolName: 'weather',
              input: {
                'city': 'Tokyo',
              },
            ),
            providerMetadata: ProviderMetadata({
              'google': {
                'functionCallId': 'tool-1',
              },
            }),
          ),
          FinishEvent(finishReason: FinishReason.toolCalls),
        ],
        const [
          TextStartEvent(id: 'text-1'),
          TextDeltaEvent(id: 'text-1', delta: 'It is sunny in Tokyo.'),
          TextEndEvent(id: 'text-1'),
          FinishEvent(
            finishReason: FinishReason.stop,
            usage: UsageStats(
              inputTokens: 10,
              outputTokens: 8,
              totalTokens: 18,
            ),
          ),
        ],
      ]);
      final executedCalls = <GenerateTextFunctionToolExecutionRequest>[];

      final run = streamTextRun(
        model: model,
        prompt: [
          UserPromptMessage.text('Weather in Tokyo?'),
        ],
        tools: [
          FunctionToolDefinition(
            name: 'weather',
            inputSchema: ToolJsonSchema.object(),
          ),
        ],
        functionToolExecutor: (request) async {
          executedCalls.add(request);
          return const GenerateTextToolExecutionResult.output({
            'forecast': 'sunny',
          });
        },
      );

      final events = await run.toList();
      final steps = await run.stepStream.toList();
      final result = await run.result;

      expect(executedCalls, hasLength(1));
      expect(executedCalls.single.stepNumber, 0);
      expect(executedCalls.single.toolCall.toolName, 'weather');
      expect(executedCalls.single.toolCall.input, {
        'city': 'Tokyo',
      });

      expect(model.requests, hasLength(2));
      final continuationPrompt = model.requests[1].prompt;
      expect(continuationPrompt, hasLength(3));
      expect(continuationPrompt[0], isA<UserPromptMessage>());
      expect(continuationPrompt[1], isA<AssistantPromptMessage>());
      expect(continuationPrompt[2], isA<ToolPromptMessage>());

      final assistantMessage = continuationPrompt[1] as AssistantPromptMessage;
      expect(assistantMessage.parts, hasLength(1));
      expect(assistantMessage.parts.single, isA<ToolCallPromptPart>());
      final replayedToolCall =
          assistantMessage.parts.single as ToolCallPromptPart;
      expect(replayedToolCall.toolCallId, 'tool-1');
      expect(replayedToolCall.toolName, 'weather');

      final toolMessage = continuationPrompt[2] as ToolPromptMessage;
      expect(toolMessage.toolName, 'weather');
      final toolResult = toolMessage.parts.single as ToolResultPromptPart;
      expect(toolResult.toolCallId, 'tool-1');
      expect(toolResult.output, {
        'forecast': 'sunny',
      });
      expect(toolResult.isError, isFalse);
      expect(
        toolResult.providerMetadata,
        const ProviderMetadata({
          'google': {
            'functionCallId': 'tool-1',
          },
        }),
      );

      expect(
        events.map((event) => event.runtimeType).toList(),
        [
          ToolCallEvent,
          FinishEvent,
          TextStartEvent,
          TextDeltaEvent,
          TextEndEvent,
          FinishEvent,
        ],
      );

      expect(steps, hasLength(2));
      expect(steps[0].finishReason, FinishReason.toolCalls);
      expect(steps[0].toolCalls.single.toolName, 'weather');
      expect(steps[1].text, 'It is sunny in Tokyo.');

      expect(result.steps, hasLength(2));
      expect(result.text, 'It is sunny in Tokyo.');
      expect(result.finishReason, FinishReason.stop);
      expect(
        result.totalUsage,
        const UsageStats(
          inputTokens: 10,
          outputTokens: 8,
          totalTokens: 18,
        ),
      );
    });

    test('stops after a tool-call step when no function executor is provided',
        () async {
      final model = _RecordingStreamLanguageModel([
        const [
          ToolCallEvent(
            toolCall: ToolCallContent(
              toolCallId: 'tool-1',
              toolName: 'weather',
              input: {
                'city': 'Tokyo',
              },
            ),
          ),
          FinishEvent(finishReason: FinishReason.toolCalls),
        ],
      ]);

      final run = streamTextRun(
        model: model,
        prompt: [
          UserPromptMessage.text('Weather in Tokyo?'),
        ],
        tools: [
          FunctionToolDefinition(
            name: 'weather',
            inputSchema: ToolJsonSchema.object(),
          ),
        ],
      );

      final steps = await run.stepStream.toList();
      final result = await run.result;

      expect(model.requests, hasLength(1));
      expect(steps, hasLength(1));
      expect(result.steps, hasLength(1));
      expect(result.finishReason, FinishReason.toolCalls);
      expect(result.toolCalls, hasLength(1));
      expect(result.toolCalls.single.toolName, 'weather');
    });

    test('rejects provider-executed tool continuations in the streamed runner',
        () async {
      final model = _RecordingStreamLanguageModel([
        const [
          ToolCallEvent(
            toolCall: ToolCallContent(
              toolCallId: 'tool-1',
              toolName: 'computer',
              input: {
                'action': 'click',
              },
              providerExecuted: true,
            ),
          ),
          FinishEvent(finishReason: FinishReason.toolCalls),
        ],
      ]);
      final emittedSteps = <GenerateTextStepResult>[];
      Object? stepError;

      final run = streamTextRun(
        model: model,
        prompt: [
          UserPromptMessage.text('Click the button'),
        ],
        tools: [
          FunctionToolDefinition(
            name: 'computer',
            inputSchema: ToolJsonSchema.object(),
          ),
        ],
        functionToolExecutor: (_) async =>
            const GenerateTextToolExecutionResult.output({'ok': true}),
      );

      final subscription = run.stepStream.listen(
        emittedSteps.add,
        onError: (Object error, StackTrace _) {
          stepError = error;
        },
      );

      await expectLater(
        run.result,
        throwsA(isA<UnsupportedError>()),
      );
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(model.requests, hasLength(1));
      expect(emittedSteps, hasLength(1));
      expect(stepError, isA<UnsupportedError>());
    });

    test('throws when streamed continuation exceeds maxSteps', () async {
      final model = _RecordingStreamLanguageModel([
        const [
          ToolCallEvent(
            toolCall: ToolCallContent(
              toolCallId: 'tool-1',
              toolName: 'weather',
              input: {
                'city': 'Tokyo',
              },
            ),
          ),
          FinishEvent(finishReason: FinishReason.toolCalls),
        ],
      ]);
      final executedCalls = <GenerateTextFunctionToolExecutionRequest>[];

      final run = streamTextRun(
        model: model,
        prompt: [
          UserPromptMessage.text('Weather in Tokyo?'),
        ],
        tools: [
          FunctionToolDefinition(
            name: 'weather',
            inputSchema: ToolJsonSchema.object(),
          ),
        ],
        functionToolExecutor: (request) async {
          executedCalls.add(request);
          return const GenerateTextToolExecutionResult.output({
            'forecast': 'sunny',
          });
        },
        maxSteps: 1,
      );

      await expectLater(
        run.result,
        throwsA(isA<StateError>()),
      );

      expect(model.requests, hasLength(1));
      expect(executedCalls, hasLength(1));
    });
  });
}

final class _RecordingStreamLanguageModel implements LanguageModel {
  final List<List<TextStreamEvent>> _steps;
  final List<GenerateTextRequest> requests = [];

  _RecordingStreamLanguageModel(this._steps);

  @override
  String get modelId => 'test-model';

  @override
  String get providerId => 'test';

  @override
  Future<GenerateTextResult> generate(GenerateTextRequest request) {
    requests.add(request);
    throw UnimplementedError(
        'generate(...) is not used in stream runner tests.');
  }

  @override
  Stream<TextStreamEvent> stream(GenerateTextRequest request) async* {
    requests.add(request);
    if (_steps.isEmpty) {
      throw StateError('No more fake step streams configured.');
    }

    for (final event in _steps.removeAt(0)) {
      yield event;
    }
  }
}
