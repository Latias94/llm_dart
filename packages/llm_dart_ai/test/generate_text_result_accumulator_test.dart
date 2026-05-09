import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('GenerateTextResultAccumulator', () {
    test('collects stream events into a shared GenerateTextResult', () async {
      final result = await collectGenerateTextResult(
        Stream<TextStreamEvent>.fromIterable([
          StartEvent(
            warnings: const [
              ModelWarning(
                type: ModelWarningType.compatibility,
                message: 'compat',
              ),
            ],
          ),
          const ResponseMetadataEvent(
            responseId: 'resp_1',
            modelId: 'model_1',
            providerMetadata: ProviderMetadata({
              'test': {'phase': 'response'},
            }),
          ),
          const TextStartEvent(id: 'text_1'),
          const TextDeltaEvent(id: 'text_1', delta: 'hello'),
          const TextEndEvent(id: 'text_1'),
          const ReasoningStartEvent(id: 'reasoning_1'),
          const ReasoningDeltaEvent(id: 'reasoning_1', delta: 'think'),
          const ReasoningEndEvent(id: 'reasoning_1'),
          const ToolInputStartEvent(
            toolCallId: 'tool_1',
            toolName: 'lookup',
          ),
          const ToolInputDeltaEvent(
            toolCallId: 'tool_1',
            delta: '{"city":"paris"}',
          ),
          const ToolInputEndEvent(toolCallId: 'tool_1'),
          ToolResultEvent(
            toolResult: ToolResultContent(
              toolCallId: 'tool_1',
              toolName: 'lookup',
              output: {'ok': true},
            ),
          ),
          SourceEvent(
            SourceReference(
              kind: SourceReferenceKind.url,
              sourceId: 'src_1',
              uri: Uri.parse('https://example.com'),
            ),
          ),
          const CustomEvent(
            kind: 'test.payload',
            data: {'value': 1},
          ),
          const FinishEvent(
            finishReason: FinishReason.stop,
            providerMetadata: ProviderMetadata({
              'test': {'phase': 'finish'},
            }),
          ),
        ]),
      );

      expect(result.text, 'hello');
      expect(result.reasoningText, 'think');
      expect(result.responseId, 'resp_1');
      expect(result.responseModelId, 'model_1');
      expect(result.finishReason, FinishReason.stop);
      expect(result.warnings, hasLength(1));
      expect(result.content.whereType<ToolCallContentPart>(), hasLength(1));
      expect(result.content.whereType<ToolResultContentPart>(), hasLength(1));
      expect(result.content.whereType<SourceContentPart>(), hasLength(1));
      expect(result.content.whereType<CustomContentPart>(), hasLength(1));
      expect(
        result.providerMetadata?.toJsonMap(),
        {
          'test': {
            'phase': 'finish',
          },
        },
      );
    });

    test('throws the streamed model error when the stream contains ErrorEvent',
        () async {
      await expectLater(
        collectGenerateTextResult(
          Stream<TextStreamEvent>.fromIterable([
            const ErrorEvent(
              ModelError(
                kind: ModelErrorKind.provider,
                message: 'bad',
              ),
            ),
            const FinishEvent(
              finishReason: FinishReason.error,
            ),
          ]),
        ),
        throwsA(
          isA<ModelError>().having(
            (error) => error.message,
            'message',
            'bad',
          ),
        ),
      );
    });

    test('collects denied tool output as a replayable tool result', () async {
      final result = await collectGenerateTextResult(
        Stream<TextStreamEvent>.fromIterable([
          const ToolCallEvent(
            toolCall: ToolCallContent(
              toolCallId: 'tool_1',
              toolName: 'browser',
              input: {
                'url': 'https://example.com',
              },
              isDynamic: true,
            ),
          ),
          const ToolOutputDeniedEvent(
            toolCallId: 'tool_1',
            reason: 'The page is not trusted.',
            providerMetadata: ProviderMetadata({
              'openai': {
                'approvalPhase': 'denied',
              },
            }),
          ),
          const FinishEvent(finishReason: FinishReason.stop),
        ]),
      );

      final toolResult =
          result.content.whereType<ToolResultContentPart>().single.toolResult;
      expect(toolResult.toolOutput, isA<ExecutionDeniedToolOutput>());
      expect(toolResult.toolOutput.denied, isTrue);
      expect(
        (toolResult.toolOutput as ExecutionDeniedToolOutput).reason,
        'The page is not trusted.',
      );
      expect(toolResult.toolName, 'browser');
      expect(toolResult.isDynamic, isTrue);
    });

    test('throws when the stream ends before a finish event', () async {
      await expectLater(
        collectGenerateTextResult(
          Stream<TextStreamEvent>.fromIterable([
            const TextStartEvent(id: 'text_1'),
            const TextDeltaEvent(id: 'text_1', delta: 'hello'),
          ]),
        ),
        throwsStateError,
      );
    });
  });
}
