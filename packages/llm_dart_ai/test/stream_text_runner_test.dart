import 'dart:async';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_ai/internal.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;
import 'package:test/test.dart';

void main() {
  group('StreamTextRunner', () {
    test('streams a single generation step and returns a run result', () async {
      final model = _RecordingStreamLanguageModel([
        const [
          ResponseMetadataEvent(
            responseId: 'resp-1',
            modelId: 'test-model',
            providerMetadata: ProviderMetadata({
              'test': {
                'traceId': 'trace-1',
              },
            }),
          ),
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

      expect(events, hasLength(9));
      expect(events.first, isA<RunStartEvent>());
      expect(events.last, isA<RunFinishEvent>());
      expect(events.whereType<StepStartEvent>(), hasLength(1));
      expect(events.whereType<StepFinishEvent>(), hasLength(1));
      expect(events.whereType<TextDeltaEvent>().single.delta, 'Runner output');
      expect(await run.textStream.toList(), hasLength(9));

      final uiChunks = await run.chatUiStream(
        messageId: 'assistant-1',
        finalMessageMetadata: const {
          'done': true,
        },
      ).toList();
      expect(uiChunks.first, isA<ChatUiMessageStartChunk>());
      expect(uiChunks.whereType<ChatUiEventChunk>(), hasLength(9));
      expect(uiChunks.last, isA<ChatUiMessageFinishChunk>());

      expect(steps, hasLength(1));
      expect(steps.single.text, 'Runner output');
      expect(steps.single.finishReason, FinishReason.stop);

      expect(result.steps, hasLength(1));
      expect(result.text, 'Runner output');
      expect(result.totalUsage?.totalTokens, 12);
      expect((await run.content).single, isA<TextContentPart>());
      expect(
        await run.usage,
        const UsageStats(
          inputTokens: 5,
          outputTokens: 7,
          totalTokens: 12,
        ),
      );
      expect(await run.responseId, 'resp-1');
      expect(await run.responseModelId, 'test-model');
      expect(
        (await run.providerMetadata)!['test'],
        containsPair('traceId', 'trace-1'),
      );
      expect(await run.text, 'Runner output');
      expect(await run.finishReason, FinishReason.stop);
    });

    test('streamText uses the multi-step runner path', () async {
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
        const [
          TextStartEvent(id: 'text-1'),
          TextDeltaEvent(id: 'text-1', delta: 'It is sunny in Tokyo.'),
          TextEndEvent(id: 'text-1'),
          FinishEvent(finishReason: FinishReason.stop),
        ],
      ]);

      final events = await streamText(
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
      ).toList();

      expect(model.requests, hasLength(2));
      expect(events.whereType<TextDeltaEvent>().single.delta,
          'It is sunny in Tokyo.');
      expect(
          events.whereType<FinishEvent>().last.finishReason, FinishReason.stop);
    });

    test('accepts user-facing messages for the initial prompt', () async {
      final model = _RecordingStreamLanguageModel([
        const [
          TextStartEvent(id: 'text-1'),
          TextDeltaEvent(id: 'text-1', delta: 'Message output'),
          TextEndEvent(id: 'text-1'),
          FinishEvent(finishReason: FinishReason.stop),
        ],
      ]);

      final run = streamTextRun(
        model: model,
        messages: [
          UserModelMessage.text('Hello from messages'),
        ],
      );

      expect(await run.text, 'Message output');
      expect(model.requests, hasLength(1));
      final message = model.requests.single.prompt.single as UserPromptMessage;
      final text = message.parts.single as TextPromptPart;
      expect(text.text, 'Hello from messages');
    });

    test('invokes onChunk for streamed events', () async {
      final model = _RecordingStreamLanguageModel([
        const [
          TextStartEvent(id: 'text-1'),
          TextDeltaEvent(id: 'text-1', delta: 'Hello'),
          TextEndEvent(id: 'text-1'),
          FinishEvent(finishReason: FinishReason.stop),
        ],
      ]);
      final chunks = <TextStreamEvent>[];

      final run = streamTextRun(
        model: model,
        prompt: [
          UserPromptMessage.text('Hello'),
        ],
        onChunk: chunks.add,
      );

      await run.toList();
      await run.result;

      expect(chunks.map((event) => event.runtimeType), [
        RunStartEvent,
        StepStartEvent,
        TextStartEvent,
        TextDeltaEvent,
        TextEndEvent,
        FinishEvent,
        StepFinishEvent,
        RunFinishEvent,
      ]);
    });

    test('invokes onError when streamed generation fails', () async {
      final errors = <Object>[];
      final model = _RecordingStreamLanguageModel([]);

      final run = streamTextRun(
        model: model,
        prompt: [
          UserPromptMessage.text('Hello'),
        ],
        onError: (error, stackTrace) {
          errors.add(error);
        },
      );

      await expectLater(
        run.result,
        throwsA(isA<StateError>()),
      );
      await expectLater(
        run,
        emitsInOrder([
          isA<RunStartEvent>(),
          isA<StepStartEvent>(),
          isA<ErrorEvent>(),
          isA<RunFinishEvent>(),
          emitsError(isA<StateError>()),
        ]),
      );

      expect(errors, hasLength(1));
      expect(errors.single, isA<StateError>());
    });

    test('emits abort lifecycle when provider cancellation is triggered',
        () async {
      final cancellation = ProviderCancellation();
      final model = _RecordingStreamLanguageModel([
        [
          const TextStartEvent(id: 'text-1'),
          const TextDeltaEvent(id: 'text-1', delta: 'Partial'),
          _CancelAfterEvent(cancellation, 'user stopped'),
        ],
      ]);
      final callbackOrder = <String>[];
      final chunks = <TextStreamEvent>[];

      final run = streamTextRun(
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
        onChunk: chunks.add,
      );

      final events = await run.toList();
      final steps = await run.stepStream.toList();
      final result = await run.result;

      expect(callbackOrder, ['step-finish:aborted', 'finish:aborted']);
      expect(events.map((event) => event.runtimeType), [
        RunStartEvent,
        StepStartEvent,
        TextStartEvent,
        TextDeltaEvent,
        AbortEvent,
        StepFinishEvent,
        RunFinishEvent,
      ]);
      expect(chunks, hasLength(events.length));
      expect(events.whereType<AbortEvent>().single.reason, 'user stopped');
      final runFinish = events.whereType<RunFinishEvent>().single;
      expect(runFinish.finishReason, FinishReason.aborted);
      expect(runFinish.rawFinishReason, 'user stopped');
      expect(events.whereType<ErrorEvent>(), isEmpty);

      expect(steps, hasLength(1));
      expect(steps.single.text, 'Partial');
      expect(steps.single.finishReason, FinishReason.aborted);
      expect(steps.single.rawFinishReason, 'user stopped');
      expect(result.text, 'Partial');
      expect(result.finishReason, FinishReason.aborted);
      expect(result.rawFinishReason, 'user stopped');
      expect(await run.text, 'Partial');
      expect(await run.finishReason, FinishReason.aborted);
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
      final stepFinishes = <GenerateTextStepResult>[];

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
        onStepFinish: stepFinishes.add,
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
      expect(toolResult.output, {
        'forecast': 'sunny',
      });
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

      expect(
        events.map((event) => event.runtimeType).toList(),
        [
          RunStartEvent,
          StepStartEvent,
          ToolCallEvent,
          FinishEvent,
          ToolResultEvent,
          StepFinishEvent,
          StepStartEvent,
          TextStartEvent,
          TextDeltaEvent,
          TextEndEvent,
          FinishEvent,
          StepFinishEvent,
          RunFinishEvent,
        ],
      );

      expect(steps, hasLength(2));
      expect(steps[0].finishReason, FinishReason.toolCalls);
      expect(steps[0].toolCalls.single.toolName, 'weather');
      expect(steps[0].toolResults.single.output, {
        'forecast': 'sunny',
      });
      expect(stepFinishes, hasLength(2));
      expect(stepFinishes[0].toolResults.single.output, {
        'forecast': 'sunny',
      });
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

    test('invokes tool execution lifecycle callbacks on streaming path',
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
        const [
          TextStartEvent(id: 'text-1'),
          TextDeltaEvent(id: 'text-1', delta: 'Done.'),
          TextEndEvent(id: 'text-1'),
          FinishEvent(finishReason: FinishReason.stop),
        ],
      ]);
      final callbackOrder = <String>[];
      final startEvents = <GenerateTextToolExecutionStartEvent>[];
      final finishEvents = <GenerateTextToolExecutionFinishEvent>[];

      final run = streamText(
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

      await run.drain<void>();

      expect(callbackOrder, ['tool-start', 'execute', 'tool-finish']);
      expect(startEvents.single.toolCall.toolCallId, 'tool-1');
      expect(finishEvents.single.result.output, {
        'forecast': 'sunny',
      });
      expect(finishEvents.single.result.isError, isFalse);
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

    test('executes only client tool calls when provider-executed calls appear',
        () async {
      final model = _RecordingStreamLanguageModel([
        const [
          ToolCallEvent(
            toolCall: ToolCallContent(
              toolCallId: 'server-tool-1',
              toolName: 'computer',
              input: {
                'action': 'click',
              },
              providerExecuted: true,
            ),
          ),
          ToolCallEvent(
            toolCall: ToolCallContent(
              toolCallId: 'client-tool-1',
              toolName: 'weather',
              input: {
                'city': 'Tokyo',
              },
            ),
          ),
          FinishEvent(finishReason: FinishReason.toolCalls),
        ],
        const [
          TextStartEvent(id: 'text-1'),
          TextDeltaEvent(id: 'text-1', delta: 'Done.'),
          TextEndEvent(id: 'text-1'),
          FinishEvent(finishReason: FinishReason.stop),
        ],
      ]);
      final executedCalls = <GenerateTextFunctionToolExecutionRequest>[];

      final run = streamTextRun(
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

      expect(await run.text, 'Done.');
      final steps = await run.stepStream.toList();

      expect(executedCalls, hasLength(1));
      expect(executedCalls.single.toolCall.toolCallId, 'client-tool-1');
      expect(model.requests, hasLength(2));

      final continuationPrompt = model.requests[1].prompt;
      expect(continuationPrompt, hasLength(3));
      final assistantMessage = continuationPrompt[1] as AssistantPromptMessage;
      expect(
        assistantMessage.parts.whereType<ToolCallPromptPart>(),
        hasLength(2),
      );
      final toolMessages = continuationPrompt.whereType<ToolPromptMessage>();
      expect(toolMessages, hasLength(1));
      final toolResult =
          toolMessages.single.parts.single as ToolResultPromptPart;
      expect(toolResult.toolCallId, 'client-tool-1');
      expect(steps, hasLength(2));
    });

    test('executes declared dynamic tools and preserves dynamic stream result',
        () async {
      final model = _RecordingStreamLanguageModel([
        const [
          ToolCallEvent(
            toolCall: ToolCallContent(
              toolCallId: 'dynamic-tool-1',
              toolName: 'weather',
              input: {
                'city': 'Tokyo',
              },
              isDynamic: true,
            ),
          ),
          FinishEvent(finishReason: FinishReason.toolCalls),
        ],
        const [
          TextStartEvent(id: 'text-1'),
          TextDeltaEvent(id: 'text-1', delta: 'Dynamic tool completed.'),
          TextEndEvent(id: 'text-1'),
          FinishEvent(finishReason: FinishReason.stop),
        ],
      ]);
      final executedCalls = <GenerateTextFunctionToolExecutionRequest>[];

      final run = streamTextRun(
        model: model,
        prompt: [
          UserPromptMessage.text('Use the selected weather tool.'),
        ],
        tools: [
          FunctionToolDefinition(
            name: 'weather',
            inputSchema: ToolJsonSchema.object(),
          ),
        ],
        functionToolExecutor: (request) {
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
      expect(executedCalls.single.toolCall.isDynamic, isTrue);
      expect(
        events.whereType<ToolResultEvent>().single.toolResult.isDynamic,
        isTrue,
      );
      expect(steps.first.toolResults.single.isDynamic, isTrue);
      expect(result.text, 'Dynamic tool completed.');
      expect(model.requests, hasLength(2));
    });

    test('does not execute tools after a tool input error event', () async {
      final model = _RecordingStreamLanguageModel([
        const [
          ToolInputErrorEvent(
            toolCallId: 'tool-1',
            toolName: 'weather',
            input: '{"city":',
            errorText: 'Invalid JSON tool input.',
            isDynamic: true,
          ),
          FinishEvent(finishReason: FinishReason.toolCalls),
        ],
        const [
          TextStartEvent(id: 'text-1'),
          TextDeltaEvent(id: 'text-1', delta: 'The tool input was invalid.'),
          TextEndEvent(id: 'text-1'),
          FinishEvent(finishReason: FinishReason.stop),
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
        functionToolExecutor: (request) {
          executedCalls.add(request);
          return const GenerateTextToolExecutionResult.output({
            'forecast': 'sunny',
          });
        },
      );

      final steps = await run.stepStream.toList();
      final result = await run.result;

      expect(executedCalls, isEmpty);
      expect(model.requests, hasLength(2));
      expect(result.finishReason, FinishReason.stop);
      expect(result.text, 'The tool input was invalid.');
      expect(result.steps.first.toolCalls.single.input, '{"city":');
      expect(result.steps.first.toolCalls.single.isDynamic, isTrue);
      expect(
        result.steps.first.toolResults.single.output,
        'Invalid JSON tool input.',
      );
      expect(result.steps.first.toolResults.single.isError, isTrue);
      expect(steps, hasLength(2));
      expect(steps.first.toolResults.single.isError, isTrue);
    });

    test('stops when provider approval is waiting even with client tools',
        () async {
      final model = _RecordingStreamLanguageModel([
        const [
          ToolCallEvent(
            toolCall: ToolCallContent(
              toolCallId: 'server-tool-1',
              toolName: 'computer',
              input: {
                'action': 'click',
              },
              providerExecuted: true,
            ),
          ),
          ToolApprovalRequestEvent(
            approvalId: 'approval-1',
            toolCallId: 'server-tool-1',
          ),
          ToolCallEvent(
            toolCall: ToolCallContent(
              toolCallId: 'client-tool-1',
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
          UserPromptMessage.text('Approve browser and check weather.'),
        ],
        tools: [
          FunctionToolDefinition(
            name: 'weather',
            inputSchema: ToolJsonSchema.object(),
          ),
        ],
        functionToolExecutor: (request) {
          executedCalls.add(request);
          return const GenerateTextToolExecutionResult.output({
            'forecast': 'sunny',
          });
        },
      );

      final events = await run.toList();
      final steps = await run.stepStream.toList();
      final result = await run.result;

      expect(executedCalls, isEmpty);
      expect(model.requests, hasLength(1));
      expect(result.finishReason, FinishReason.toolCalls);
      expect(result.toolApprovalRequests.single.approvalId, 'approval-1');
      expect(result.toolCalls, hasLength(2));
      expect(result.toolResults, isEmpty);
      expect(steps, hasLength(1));
      expect(events.whereType<ToolResultEvent>(), isEmpty);
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

    test('stops streamed continuation when a stop condition is met', () async {
      final model = _RecordingStreamLanguageModel([
        const [
          ToolCallEvent(
            toolCall: ToolCallContent(
              toolCallId: 'tool-1',
              toolName: 'weather',
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
        functionToolExecutor: (request) {
          executedCalls.add(request);
          return const GenerateTextToolExecutionResult.output({
            'forecast': 'sunny',
          });
        },
        stopWhen: [
          isStepCount(1),
        ],
      );

      final events = await run.toList();
      final result = await run.result;

      expect(model.requests, hasLength(1));
      expect(executedCalls, hasLength(1));
      expect(result.steps, hasLength(1));
      expect(result.finishReason, FinishReason.toolCalls);
      expect(events.whereType<ToolResultEvent>(), hasLength(1));
      expect(events.last, isA<RunFinishEvent>());
    });
  });
}

final class _RecordingStreamLanguageModel implements LanguageModel {
  final List<List<Object>> _steps;
  final List<GenerateTextRequest> requests = [];

  _RecordingStreamLanguageModel(this._steps);

  @override
  String get modelId => 'test-model';

  @override
  String get providerId => 'test';

  @override
  Future<GenerateTextResult> doGenerate(GenerateTextRequest request) {
    requests.add(request);
    throw UnimplementedError(
        'generate(...) is not used in stream runner tests.');
  }

  @override
  Stream<provider.LanguageModelStreamEvent> doStream(
    GenerateTextRequest request,
  ) async* {
    requests.add(request);
    if (_steps.isEmpty) {
      throw StateError('No more fake step streams configured.');
    }

    for (final item in _steps.removeAt(0)) {
      switch (item) {
        case TextStreamEvent event:
          yield textStreamEventToProvider(event);
        case _CancelAfterEvent action:
          action.cancellation.cancel(action.reason);
          await Future<void>.delayed(const Duration(milliseconds: 1));
        case _:
          throw StateError('Unsupported fake stream item: $item');
      }
    }
  }
}

final class _CancelAfterEvent {
  final ProviderCancellation cancellation;
  final Object? reason;

  const _CancelAfterEvent(this.cancellation, [this.reason]);
}
