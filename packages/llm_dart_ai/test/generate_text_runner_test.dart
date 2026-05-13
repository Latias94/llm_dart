import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;
import 'package:test/test.dart';

void main() {
  group('GenerateTextRunner', () {
    test('runs a single generation step and returns a run result', () async {
      final model = _RecordingLanguageModel([
        GenerateTextResult(
          content: const [
            TextContentPart('Runner output'),
          ],
          finishReason: FinishReason.stop,
          usage: const UsageStats(
            inputTokens: 5,
            outputTokens: 7,
            totalTokens: 12,
          ),
        ),
      ]);

      final runResult = await runTextGeneration(
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
      );

      expect(model.requests, hasLength(1));
      expect(model.requests.single.prompt, hasLength(1));
      expect(model.requests.single.tools.single.name, 'weather');
      expect(model.requests.single.toolChoice, isA<RequiredToolChoice>());
      expect(model.requests.single.options.temperature, 0.2);
      expect(
        model.requests.single.callOptions.timeout,
        const Duration(seconds: 30),
      );

      expect(runResult.steps, hasLength(1));
      expect(runResult.text, 'Runner output');
      expect(runResult.totalUsage?.totalTokens, 12);
    });

    test('generateText uses the multi-step runner path', () async {
      final model = _RecordingLanguageModel([
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
            TextContentPart('It is sunny in Tokyo.'),
          ],
          finishReason: FinishReason.stop,
        ),
      ]);

      final result = await generateText(
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
        functionToolExecutor: (request) {
          expect(request.stepNumber, 0);
          return const GenerateTextToolExecutionResult.output({
            'forecast': 'sunny',
          });
        },
      );

      expect(model.requests, hasLength(2));
      expect(result.text, 'It is sunny in Tokyo.');
      expect(result.finishReason, FinishReason.stop);
    });

    test('accepts user-facing messages for the initial prompt', () async {
      final model = _RecordingLanguageModel([
        GenerateTextResult(
          content: const [
            TextContentPart('Message output'),
          ],
          finishReason: FinishReason.stop,
        ),
      ]);

      final runResult = await runTextGeneration(
        model: model,
        messages: [
          UserModelMessage.text('Hello from messages'),
        ],
      );

      expect(runResult.text, 'Message output');
      expect(model.requests, hasLength(1));
      final message = model.requests.single.prompt.single as UserPromptMessage;
      final text = message.parts.single as TextPromptPart;
      expect(text.text, 'Hello from messages');
    });

    test(
        'continues tool-call steps with a common function tool executor and prompt replay',
        () async {
      final model = _RecordingLanguageModel([
        GenerateTextResult(
          content: const [
            ReasoningContentPart('Need weather data first.'),
            ToolCallContentPart(
              ToolCallContent(
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
          ],
          finishReason: FinishReason.toolCalls,
        ),
        GenerateTextResult(
          content: const [
            TextContentPart('It is sunny in Tokyo.'),
          ],
          finishReason: FinishReason.stop,
          usage: UsageStats(
            inputTokens: 10,
            outputTokens: 8,
            totalTokens: 18,
          ),
        ),
      ]);
      final executedCalls = <GenerateTextFunctionToolExecutionRequest>[];
      final stepStartEvents = <GenerateTextStepStartEvent>[];

      final runResult = await runTextGeneration(
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
          return GenerateTextToolExecutionResult.toolOutput(
            ContentToolOutput(
              parts: [
                TextToolOutputContentPart('forecast'),
                JsonToolOutputContentPart({
                  'forecast': 'sunny',
                }),
              ],
            ),
          );
        },
        onStepStart: (event) {
          stepStartEvents.add(event);
        },
      );

      expect(stepStartEvents, hasLength(2));
      expect(stepStartEvents[0].stepNumber, 0);
      expect(stepStartEvents[0].previousSteps, isEmpty);
      expect(stepStartEvents[1].stepNumber, 1);
      expect(stepStartEvents[1].previousSteps, hasLength(1));

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
      expect(assistantMessage.parts, hasLength(2));
      expect(assistantMessage.parts[0], isA<ReasoningPromptPart>());
      expect(assistantMessage.parts[1], isA<ToolCallPromptPart>());
      final replayedToolCall = assistantMessage.parts[1] as ToolCallPromptPart;
      expect(replayedToolCall.toolCallId, 'tool-1');
      expect(replayedToolCall.toolName, 'weather');
      expect(
        replayedToolCall.providerOptions,
        isA<ProviderReplayPromptPartOptions>().having(
          (options) => options.metadata,
          'metadata',
          const ProviderMetadata({
            'google': {
              'functionCallId': 'tool-1',
            },
          }),
        ),
      );

      final toolMessage = continuationPrompt[2] as ToolPromptMessage;
      expect(toolMessage.toolName, 'weather');
      final toolResult = toolMessage.parts.single as ToolResultPromptPart;
      expect(toolResult.toolCallId, 'tool-1');
      expect(toolResult.toolOutput, isA<ContentToolOutput>());
      expect((toolResult.toolOutput as ContentToolOutput).parts, hasLength(2));
      expect(toolResult.isError, isFalse);
      expect(
        toolResult.providerOptions,
        isA<ProviderReplayPromptPartOptions>().having(
          (options) => options.metadata,
          'metadata',
          const ProviderMetadata({
            'google': {
              'functionCallId': 'tool-1',
            },
          }),
        ),
      );

      expect(runResult.steps, hasLength(2));
      expect(runResult.text, 'It is sunny in Tokyo.');
      expect(runResult.finishReason, FinishReason.stop);
      expect(
          runResult.totalUsage,
          const UsageStats(
            inputTokens: 10,
            outputTokens: 8,
            totalTokens: 18,
          ));
    });

    test('invokes tool execution lifecycle callbacks around local tools',
        () async {
      final model = _RecordingLanguageModel([
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
            TextContentPart('Done.'),
          ],
          finishReason: FinishReason.stop,
        ),
      ]);
      final callbackOrder = <String>[];
      final startEvents = <GenerateTextToolExecutionStartEvent>[];
      final finishEvents = <GenerateTextToolExecutionFinishEvent>[];

      await generateText(
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
        functionToolExecutor: (request) {
          callbackOrder.add('execute');
          return const GenerateTextToolExecutionResult.output({
            'forecast': 'sunny',
          });
        },
        onToolStart: (event) {
          callbackOrder.add('tool-start');
          startEvents.add(event);
        },
        onToolFinish: (event) {
          callbackOrder.add('tool-finish');
          finishEvents.add(event);
        },
      );

      expect(callbackOrder, ['tool-start', 'execute', 'tool-finish']);
      expect(startEvents.single.stepNumber, 0);
      expect(startEvents.single.toolCall.toolCallId, 'tool-1');
      expect(finishEvents.single.stepNumber, 0);
      expect(finishEvents.single.toolCall, same(startEvents.single.toolCall));
      expect(finishEvents.single.result.output, {
        'forecast': 'sunny',
      });
      expect(finishEvents.single.result.isError, isFalse);
    });

    test('reports failed local tool execution through finish callback',
        () async {
      final model = _RecordingLanguageModel([
        GenerateTextResult(
          content: const [
            ToolCallContentPart(
              ToolCallContent(
                toolCallId: 'tool-1',
                toolName: 'weather',
              ),
            ),
          ],
          finishReason: FinishReason.toolCalls,
        ),
        GenerateTextResult(
          content: const [
            TextContentPart('Recovered.'),
          ],
          finishReason: FinishReason.stop,
        ),
      ]);
      final finishEvents = <GenerateTextToolExecutionFinishEvent>[];

      await runTextGeneration(
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
        functionToolExecutor: (request) {
          throw StateError('offline');
        },
        onToolFinish: finishEvents.add,
      );

      expect(finishEvents, hasLength(1));
      expect(finishEvents.single.result.isError, isTrue);
      expect(
        finishEvents.single.result.output,
        contains('Function tool "weather" execution failed'),
      );
    });

    test('executes only client tool calls when provider-executed calls appear',
        () async {
      final model = _RecordingLanguageModel([
        GenerateTextResult(
          content: const [
            ToolCallContentPart(
              ToolCallContent(
                toolCallId: 'server-tool-1',
                toolName: 'computer',
                input: {
                  'action': 'click',
                },
                providerExecuted: true,
              ),
            ),
            ToolCallContentPart(
              ToolCallContent(
                toolCallId: 'client-tool-1',
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
            TextContentPart('Done.'),
          ],
          finishReason: FinishReason.stop,
        ),
      ]);
      final executedCalls = <GenerateTextFunctionToolExecutionRequest>[];

      final runResult = await runTextGeneration(
        model: model,
        prompt: [
          UserPromptMessage.text('Click the button and check weather.'),
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

      expect(executedCalls, hasLength(1));
      expect(executedCalls.single.toolCall.toolCallId, 'client-tool-1');
      expect(model.requests, hasLength(2));

      final continuationPrompt = model.requests[1].prompt;
      expect(continuationPrompt, hasLength(3));
      final assistantMessage = continuationPrompt[1] as AssistantPromptMessage;
      expect(
          assistantMessage.parts.whereType<ToolCallPromptPart>(), hasLength(2));
      final toolMessages = continuationPrompt.whereType<ToolPromptMessage>();
      expect(toolMessages, hasLength(1));
      final toolResult =
          toolMessages.single.parts.single as ToolResultPromptPart;
      expect(toolResult.toolCallId, 'client-tool-1');
      expect(runResult.text, 'Done.');
    });

    test('stops after a tool-call step when no function executor is provided',
        () async {
      final model = _RecordingLanguageModel([
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
      ]);

      final runResult = await runTextGeneration(
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

      expect(model.requests, hasLength(1));
      expect(runResult.steps, hasLength(1));
      expect(runResult.finishReason, FinishReason.toolCalls);
      expect(runResult.toolCalls, hasLength(1));
      expect(runResult.toolCalls.single.toolName, 'weather');
    });

    test('throws when multi-step continuation exceeds maxSteps', () async {
      final model = _RecordingLanguageModel([
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
      ]);
      final executedCalls = <GenerateTextFunctionToolExecutionRequest>[];

      await expectLater(
        runTextGeneration(
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
        ),
        throwsA(isA<StateError>()),
      );

      expect(model.requests, hasLength(1));
      expect(executedCalls, hasLength(1));
    });

    test('invokes lifecycle callbacks in order with shared step context',
        () async {
      final callbackOrder = <String>[];
      final model = _RecordingLanguageModel([
        GenerateTextResult(
          content: const [
            TextContentPart('Done'),
          ],
          finishReason: FinishReason.stop,
        ),
      ]);

      GenerateTextRequest? startedRequest;
      GenerateTextStepResult? finishedStep;
      GenerateTextRunResult? finishedRun;

      final runResult = await GenerateTextRunner(
        model: model,
        prompt: [
          UserPromptMessage.text('Hello'),
        ],
        onStepStart: (event) async {
          callbackOrder.add('start');
          startedRequest = event.request;
          expect(event.stepNumber, 0);
          expect(event.providerId, 'test');
          expect(event.modelId, 'test-model');
          expect(event.previousSteps, isEmpty);
        },
        onStepFinish: (step) async {
          callbackOrder.add('step-finish');
          finishedStep = step;
          expect(step.stepNumber, 0);
          expect(step.request, same(startedRequest));
          expect(step.text, 'Done');
        },
        onFinish: (run) async {
          callbackOrder.add('finish');
          finishedRun = run;
          expect(run.steps.single, same(finishedStep));
        },
      ).run();

      expect(callbackOrder, ['start', 'step-finish', 'finish']);
      expect(runResult, same(finishedRun));
      expect(runResult.lastStep, same(finishedStep));
    });

    test('invokes onError when generation fails', () async {
      final errors = <Object>[];
      final stackTraces = <StackTrace>[];
      final model = _RecordingLanguageModel([]);

      await expectLater(
        GenerateTextRunner(
          model: model,
          prompt: [
            UserPromptMessage.text('Hello'),
          ],
          onError: (error, stackTrace) {
            errors.add(error);
            stackTraces.add(stackTrace);
          },
        ).run(),
        throwsA(isA<StateError>()),
      );

      expect(errors, hasLength(1));
      expect(errors.single, isA<StateError>());
      expect(stackTraces, hasLength(1));
    });

    test('returns an aborted run result when generation is cancelled',
        () async {
      final cancellation = ProviderCancellation();
      final callbackOrder = <String>[];
      final model = _RecordingLanguageModel([
        _GeneratedResult(
          GenerateTextResult(
            content: const [
              TextContentPart('Partial'),
            ],
            finishReason: FinishReason.stop,
            responseId: 'resp-cancelled',
            usage: const UsageStats(
              inputTokens: 3,
              outputTokens: 4,
              totalTokens: 7,
            ),
          ),
          cancelAfterResult: cancellation,
          cancelReason: 'user stopped',
        ),
      ]);

      final runResult = await runTextGeneration(
        model: model,
        prompt: [
          UserPromptMessage.text('Hello'),
        ],
        callOptions: CallOptions(cancellation: cancellation),
        onStepFinish: (step) {
          callbackOrder.add('step-finish:${step.finishReason.name}');
        },
        onFinish: (result) {
          callbackOrder.add('finish:${result.finishReason.name}');
        },
        onError: (error, stackTrace) {
          callbackOrder.add('error');
        },
      );

      expect(callbackOrder, ['step-finish:aborted', 'finish:aborted']);
      expect(runResult.steps, hasLength(1));
      expect(runResult.text, 'Partial');
      expect(runResult.finishReason, FinishReason.aborted);
      expect(runResult.rawFinishReason, 'user stopped');
      expect(runResult.responseId, 'resp-cancelled');
      expect(runResult.totalUsage?.totalTokens, 7);
      expect(model.requests, hasLength(1));
    });

    test('returns an empty aborted result when provider throws cancellation',
        () async {
      final cancellation = ProviderCancellation();
      final callbackOrder = <String>[];
      final model = _RecordingLanguageModel([
        const _CancellationFailure('provider aborted'),
      ]);

      final runResult = await runTextGeneration(
        model: model,
        prompt: [
          UserPromptMessage.text('Hello'),
        ],
        callOptions: CallOptions(cancellation: cancellation),
        onStepFinish: (step) {
          callbackOrder.add('step-finish:${step.finishReason.name}');
        },
        onFinish: (result) {
          callbackOrder.add('finish:${result.finishReason.name}');
        },
        onError: (error, stackTrace) {
          callbackOrder.add('error');
        },
      );

      expect(callbackOrder, ['step-finish:aborted', 'finish:aborted']);
      expect(runResult.steps, hasLength(1));
      expect(runResult.text, isEmpty);
      expect(runResult.finishReason, FinishReason.aborted);
      expect(runResult.rawFinishReason, 'provider aborted');
      expect(model.requests, hasLength(1));
    });
  });
}

final class _RecordingLanguageModel implements LanguageModel {
  final List<Object> _results;
  final List<GenerateTextRequest> requests = [];

  _RecordingLanguageModel(this._results);

  @override
  String get modelId => 'test-model';

  @override
  String get providerId => 'test';

  @override
  Future<GenerateTextResult> doGenerate(GenerateTextRequest request) async {
    requests.add(request);
    if (_results.isEmpty) {
      throw StateError('No more fake results configured.');
    }

    final item = _results.removeAt(0);
    switch (item) {
      case GenerateTextResult result:
        return result;
      case _GeneratedResult generated:
        generated.cancelAfterResult?.cancel(generated.cancelReason);
        return generated.result;
      case _CancellationFailure failure:
        throw ProviderCancelledException(failure.reason);
      case _:
        throw StateError('Unsupported fake generate item: $item');
    }
  }

  @override
  Stream<provider.LanguageModelStreamEvent> doStream(
    GenerateTextRequest request,
  ) async* {
    requests.add(request);
    yield const provider.FinishEvent(
      finishReason: FinishReason.stop,
    );
  }
}

final class _GeneratedResult {
  final GenerateTextResult result;
  final ProviderCancellation? cancelAfterResult;
  final Object? cancelReason;

  const _GeneratedResult(
    this.result, {
    this.cancelAfterResult,
    this.cancelReason,
  });
}

final class _CancellationFailure {
  final Object? reason;

  const _CancellationFailure([this.reason]);
}
