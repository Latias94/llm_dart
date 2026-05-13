import 'dart:async';

import 'package:llm_dart_ai/llm_dart_ai.dart';
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

      expect(events, hasLength(5));
      expect(events.whereType<TextDeltaEvent>().single.delta, 'Runner output');
      expect(await run.textStream.toList(), hasLength(5));

      final uiChunks = await run.chatUiStream(
        messageId: 'assistant-1',
        finalMessageMetadata: const {
          'done': true,
        },
      ).toList();
      expect(uiChunks.first, isA<ChatUiMessageStartChunk>());
      expect(uiChunks.whereType<ChatUiEventChunk>(), hasLength(5));
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
        TextStartEvent,
        TextDeltaEvent,
        TextEndEvent,
        FinishEvent,
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
        emitsError(isA<StateError>()),
      );

      expect(errors, hasLength(1));
      expect(errors.single, isA<StateError>());
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
  Future<GenerateTextResult> doGenerate(GenerateTextRequest request) {
    requests.add(request);
    throw UnimplementedError(
        'generate(...) is not used in stream runner tests.');
  }

  @override
  Stream<TextStreamEvent> doStream(GenerateTextRequest request) async* {
    requests.add(request);
    if (_steps.isEmpty) {
      throw StateError('No more fake step streams configured.');
    }

    for (final event in _steps.removeAt(0)) {
      yield event;
    }
  }
}
