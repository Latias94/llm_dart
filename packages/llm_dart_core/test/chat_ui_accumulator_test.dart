import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('ChatUiAccumulator', () {
    test('projects text, reasoning, metadata, and step boundaries', () {
      final accumulator = ChatUiAccumulator(messageId: 'assistant-1');
      final timestamp = DateTime.parse('2026-03-26T10:00:00Z');

      accumulator.apply(
        StartEvent(
          warnings: const [
            ModelWarning(
              type: ModelWarningType.unsupported,
              message: 'temperature is ignored by this model',
              field: 'temperature',
            ),
          ],
        ),
      );
      accumulator.apply(
        ResponseMetadataEvent(
          responseId: 'resp_1',
          timestamp: timestamp,
          modelId: 'gpt-4.1-mini',
          providerMetadata: const ProviderMetadata({
            'openai': {
              'serviceTier': 'default',
            },
          }),
        ),
      );
      accumulator.apply(const StepStartEvent(stepId: 'step-1'));
      accumulator.apply(
        const ReasoningStartEvent(
          id: 'reasoning-1',
        ),
      );
      accumulator.apply(
        const ReasoningDeltaEvent(
          id: 'reasoning-1',
          delta: 'Planning',
        ),
      );
      accumulator.apply(
        const ReasoningEndEvent(
          id: 'reasoning-1',
        ),
      );
      accumulator.apply(
        const TextStartEvent(
          id: 'text-1',
        ),
      );
      accumulator.apply(
        const TextDeltaEvent(
          id: 'text-1',
          delta: 'Hello',
        ),
      );
      accumulator.apply(
        const TextEndEvent(
          id: 'text-1',
        ),
      );

      final message = accumulator.apply(
        const FinishEvent(
          finishReason: FinishReason.stop,
          rawFinishReason: 'stop',
          usage: UsageStats(
            inputTokens: 3,
            outputTokens: 2,
            totalTokens: 5,
          ),
        ),
      );

      expect(message.id, 'assistant-1');
      expect(message.parts.whereType<StepBoundaryUiPart>().single.stepId,
          'step-1');

      final reasoningPart = message.parts.whereType<ReasoningUiPart>().single;
      expect(reasoningPart.text, 'Planning');
      expect(reasoningPart.isStreaming, isFalse);

      final textPart = message.parts.whereType<TextUiPart>().single;
      expect(textPart.text, 'Hello');
      expect(textPart.isStreaming, isFalse);

      final warnings = (message.metadata[ChatUiMetadataKeys.warnings] as List)
          .cast<ModelWarning>();
      expect(warnings, hasLength(1));
      expect(warnings.single.field, 'temperature');
      expect(message.metadata[ChatUiMetadataKeys.responseId], 'resp_1');
      expect(message.metadata[ChatUiMetadataKeys.responseTimestamp], timestamp);
      expect(message.metadata[ChatUiMetadataKeys.modelId], 'gpt-4.1-mini');
      expect(
          message.metadata[ChatUiMetadataKeys.finishReason], FinishReason.stop);
      expect(message.metadata[ChatUiMetadataKeys.rawFinishReason], 'stop');

      final usage = message.metadata[ChatUiMetadataKeys.usage] as UsageStats;
      expect(usage.totalTokens, 5);

      final responseMetadata =
          message.metadata[ChatUiMetadataKeys.responseProviderMetadata]
              as ProviderMetadata;
      expect(
        responseMetadata['openai'],
        containsPair('serviceTier', 'default'),
      );
      expect(message.metadata[ChatUiMetadataKeys.isAborted], isNull);
      expect(message.metadata[ChatUiMetadataKeys.abortReason], isNull);
    });

    test('accumulates partial tool input and updates a single tool part', () {
      final accumulator = ChatUiAccumulator(messageId: 'assistant-1');

      accumulator.apply(const StepStartEvent(stepId: 'step-1'));
      accumulator.apply(
        const ToolInputStartEvent(
          toolCallId: 'tool-1',
          toolName: 'weather',
          providerExecuted: true,
          isDynamic: true,
          title: 'Weather lookup',
          providerMetadata: ProviderMetadata({
            'openai': {
              'startId': 'call_1',
            },
          }),
        ),
      );

      var message = accumulator.apply(
        const ToolInputDeltaEvent(
          toolCallId: 'tool-1',
          delta: '{"city":"',
        ),
      );

      var toolPart = message.parts.whereType<ToolUiPart>().single;
      expect(toolPart.state, ToolUiPartState.inputStreaming);
      expect(toolPart.inputText, '{"city":"');
      expect(toolPart.input, '{"city":"');
      expect(toolPart.providerExecuted, isTrue);
      expect(toolPart.isDynamic, isTrue);
      expect(toolPart.title, 'Weather lookup');

      message = accumulator.apply(
        const ToolInputDeltaEvent(
          toolCallId: 'tool-1',
          delta: 'London"}',
        ),
      );

      toolPart = message.parts.whereType<ToolUiPart>().single;
      expect(toolPart.input, isA<Map<String, Object?>>());
      expect((toolPart.input as Map<String, Object?>)['city'], 'London');

      message = accumulator.apply(
        const ToolInputEndEvent(
          toolCallId: 'tool-1',
        ),
      );

      toolPart = message.parts.whereType<ToolUiPart>().single;
      expect(toolPart.state, ToolUiPartState.inputAvailable);

      message = accumulator.apply(
        const ToolCallEvent(
          toolCall: ToolCallContent(
            toolCallId: 'tool-1',
            toolName: 'weather',
            input: {
              'city': 'London',
            },
            providerExecuted: true,
            isDynamic: true,
            title: 'Weather lookup',
          ),
          providerMetadata: ProviderMetadata({
            'openai': {
              'toolStatus': 'ready',
            },
          }),
        ),
      );

      toolPart = message.parts.whereType<ToolUiPart>().single;
      expect(message.parts.whereType<ToolUiPart>(), hasLength(1));
      expect(toolPart.state, ToolUiPartState.inputAvailable);
      expect(
        toolPart.callProviderMetadata!['openai'],
        allOf(
          containsPair('startId', 'call_1'),
          containsPair('toolStatus', 'ready'),
        ),
      );

      message = accumulator.apply(
        const ToolApprovalRequestEvent(
          approvalId: 'approval-1',
          toolCallId: 'tool-1',
        ),
      );

      toolPart = message.parts.whereType<ToolUiPart>().single;
      expect(toolPart.state, ToolUiPartState.approvalRequested);
      expect(toolPart.approval?.approvalId, 'approval-1');
      expect(toolPart.approval?.approved, isNull);

      message = accumulator.apply(
        const ToolResultEvent(
          toolResult: ToolResultContent(
            toolCallId: 'tool-1',
            toolName: 'weather',
            output: {
              'forecast': 'sunny',
            },
            preliminary: true,
            isDynamic: true,
          ),
          providerMetadata: ProviderMetadata({
            'openai': {
              'resultId': 'tool_result_1',
            },
          }),
        ),
      );

      toolPart = message.parts.whereType<ToolUiPart>().single;
      expect(toolPart.state, ToolUiPartState.outputAvailable);
      expect(toolPart.preliminary, isTrue);
      expect((toolPart.output as Map<String, Object?>)['forecast'], 'sunny');
      expect(
        toolPart.resultProviderMetadata!['openai'],
        containsPair('resultId', 'tool_result_1'),
      );

      message = accumulator.apply(
        const ToolResultEvent(
          toolResult: ToolResultContent(
            toolCallId: 'tool-1',
            toolName: 'weather',
            output: {
              'forecast': 'sunny',
              'temperatureC': 22,
            },
            preliminary: false,
            isDynamic: true,
          ),
        ),
      );

      toolPart = message.parts.whereType<ToolUiPart>().single;
      expect(message.parts.whereType<ToolUiPart>(), hasLength(1));
      expect(toolPart.preliminary, isFalse);
      expect(
        (toolPart.output as Map<String, Object?>)['temperatureC'],
        22,
      );
    });

    test('projects malformed tool input into the existing tool error path', () {
      final accumulator = ChatUiAccumulator(messageId: 'assistant-1');

      accumulator.apply(
        const ToolInputStartEvent(
          toolCallId: 'tool-1',
          toolName: 'weather',
          providerExecuted: true,
          isDynamic: true,
          title: 'Weather lookup',
          providerMetadata: ProviderMetadata({
            'openai': {
              'itemId': 'call_1',
            },
          }),
        ),
      );

      accumulator.apply(
        const ToolInputDeltaEvent(
          toolCallId: 'tool-1',
          delta: '{"city":',
        ),
      );

      final message = accumulator.apply(
        const ToolInputErrorEvent(
          toolCallId: 'tool-1',
          toolName: 'weather',
          input: '{"city":',
          errorText: 'Invalid JSON tool arguments for "weather".',
          providerExecuted: true,
          isDynamic: true,
          providerMetadata: ProviderMetadata({
            'openai': {
              'validation': 'json',
            },
          }),
        ),
      );

      final toolPart = message.parts.whereType<ToolUiPart>().single;
      expect(toolPart.state, ToolUiPartState.outputError);
      expect(toolPart.input, '{"city":');
      expect(toolPart.inputText, '{"city":');
      expect(toolPart.output, isNull);
      expect(toolPart.errorText, 'Invalid JSON tool arguments for "weather".');
      expect(toolPart.providerExecuted, isTrue);
      expect(toolPart.isDynamic, isTrue);
      expect(toolPart.title, 'Weather lookup');
      expect(
        toolPart.callProviderMetadata!['openai'],
        allOf(
          containsPair('itemId', 'call_1'),
          containsPair('validation', 'json'),
        ),
      );
    });

    test('projects denied tool output into the existing denied state path', () {
      final accumulator = ChatUiAccumulator(messageId: 'assistant-1');

      accumulator.apply(
        const ToolCallEvent(
          toolCall: ToolCallContent(
            toolCallId: 'tool-1',
            toolName: 'computer',
            input: {
              'action': 'click',
            },
            providerExecuted: true,
            isDynamic: true,
            title: 'Browser',
          ),
          providerMetadata: ProviderMetadata({
            'openai': {
              'itemId': 'call_1',
            },
          }),
        ),
      );

      accumulator.apply(
        const ToolApprovalRequestEvent(
          approvalId: 'approval-1',
          toolCallId: 'tool-1',
          providerMetadata: ProviderMetadata({
            'openai': {
              'approvalPhase': 'waiting',
            },
          }),
        ),
      );

      final message = accumulator.apply(
        const ToolOutputDeniedEvent(
          toolCallId: 'tool-1',
          providerMetadata: ProviderMetadata({
            'openai': {
              'approvalPhase': 'denied',
            },
          }),
        ),
      );

      final toolPart = message.parts.whereType<ToolUiPart>().single;
      expect(toolPart.state, ToolUiPartState.outputDenied);
      expect(toolPart.providerExecuted, isTrue);
      expect(toolPart.isDynamic, isTrue);
      expect(toolPart.title, 'Browser');
      expect(toolPart.approval?.approvalId, 'approval-1');
      expect(toolPart.approval?.approved, isNull);
      expect(
        toolPart.callProviderMetadata!['openai'],
        allOf(
          containsPair('itemId', 'call_1'),
          containsPair('approvalPhase', 'waiting'),
        ),
      );
      expect(
        toolPart.resultProviderMetadata!['openai'],
        containsPair('approvalPhase', 'denied'),
      );
    });

    test('projects source, file, reasoning-file, custom, raw, and error events',
        () async {
      final snapshots = await projectChatUiMessageStream(
        Stream<TextStreamEvent>.fromIterable([
          const StepStartEvent(stepId: 'step-1'),
          SourceEvent(
            SourceReference(
              kind: SourceReferenceKind.url,
              sourceId: 'source-1',
              uri: Uri.parse('https://example.com/docs/1'),
              title: 'Example document',
              providerMetadata: const ProviderMetadata({
                'openai': {
                  'annotationId': 'ann_1',
                },
              }),
            ),
          ),
          FileEvent(
            GeneratedFile(
              mediaType: 'text/plain',
              filename: 'answer.txt',
              uri: Uri.parse('https://example.com/files/answer.txt'),
            ),
            providerMetadata: const ProviderMetadata({
              'openai': {
                'fileId': 'file_1',
              },
            }),
          ),
          const ReasoningFileEvent(
            GeneratedFile(
              mediaType: 'image/png',
              filename: 'thought.png',
              bytes: [7, 8, 9],
            ),
            providerMetadata: ProviderMetadata({
              'google': {
                'thoughtSignature': 'sig_reasoning_file',
              },
            }),
          ),
          const CustomEvent(
            kind: 'openai.web_search_call',
            data: {
              'query': 'weather in london',
            },
            providerMetadata: ProviderMetadata({
              'openai': {
                'itemId': 'ws_1',
              },
            }),
          ),
          const RawChunkEvent({
            'type': 'diagnostic',
          }),
          const ErrorEvent(
            ModelError(
              kind: ModelErrorKind.unknown,
              message: 'soft failure',
            ),
          ),
        ]),
        messageId: 'assistant-1',
        options: const ChatUiAccumulatorOptions(
          includeRawChunksInMetadata: true,
        ),
      ).toList();

      final message = snapshots.last;

      expect(message.parts.whereType<SourceUiPart>(), hasLength(1));
      expect(message.parts.whereType<FileUiPart>(), hasLength(1));
      expect(message.parts.whereType<ReasoningFileUiPart>(), hasLength(1));
      expect(message.parts.whereType<CustomUiPart>().single.kind,
          'openai.web_search_call');

      final sourcePart = message.parts.whereType<SourceUiPart>().single;
      expect(sourcePart.source.kind, SourceReferenceKind.url);
      expect(
        sourcePart.source.providerMetadata!['openai'],
        containsPair('annotationId', 'ann_1'),
      );

      final filePart = message.parts.whereType<FileUiPart>().single;
      expect(
        filePart.providerMetadata!['openai'],
        containsPair('fileId', 'file_1'),
      );

      final reasoningFilePart =
          message.parts.whereType<ReasoningFileUiPart>().single;
      expect(reasoningFilePart.file.filename, 'thought.png');
      expect(
        reasoningFilePart.providerMetadata!['google'],
        containsPair('thoughtSignature', 'sig_reasoning_file'),
      );

      final rawChunks =
          message.metadata[ChatUiMetadataKeys.rawChunks] as List<Object?>;
      expect(rawChunks, hasLength(1));
      expect(rawChunks.single, containsPair('type', 'diagnostic'));

      final errors =
          message.metadata[ChatUiMetadataKeys.errors] as List<ModelError>;
      expect(errors.single.message, 'soft failure');
    });

    test('captures abort metadata independently from terminal finish state',
        () {
      final accumulator = ChatUiAccumulator(messageId: 'assistant-1');

      accumulator.apply(
        const AbortEvent(
          reason: 'user cancelled',
        ),
      );

      final message = accumulator.apply(
        const FinishEvent(
          finishReason: FinishReason.aborted,
          rawFinishReason: 'user cancelled',
        ),
      );

      expect(message.metadata[ChatUiMetadataKeys.isAborted], isTrue);
      expect(
        message.metadata[ChatUiMetadataKeys.abortReason],
        'user cancelled',
      );
      expect(
        message.metadata[ChatUiMetadataKeys.finishReason],
        FinishReason.aborted,
      );
    });

    test('continues an existing assistant message across steps', () {
      final seedMessage = ChatUiMessage(
        id: 'assistant-existing',
        role: ChatUiRole.assistant,
        parts: const [
          ToolUiPart(
            toolCallId: 'tool-1',
            toolName: 'weather',
            state: ToolUiPartState.outputAvailable,
            input: {
              'city': 'London',
            },
            output: {
              'forecast': 'sunny',
            },
          ),
        ],
      );

      final accumulator = ChatUiAccumulator(
        messageId: 'assistant-new',
        seedMessage: seedMessage,
      );

      accumulator.apply(const StepStartEvent(stepId: 'step-2'));
      accumulator.apply(const TextStartEvent(id: 'text-1'));
      accumulator.apply(
        const TextDeltaEvent(
          id: 'text-1',
          delta: 'Done',
        ),
      );
      final message = accumulator.apply(const TextEndEvent(id: 'text-1'));

      expect(message.id, 'assistant-existing');
      expect(message.parts.whereType<ToolUiPart>(), hasLength(1));
      expect(message.parts.whereType<StepBoundaryUiPart>().single.stepId,
          'step-2');
      expect(message.parts.whereType<TextUiPart>().single.text, 'Done');
    });

    test('upserts data parts by key and id while preserving append-only data',
        () {
      final accumulator = ChatUiAccumulator(messageId: 'assistant-1');

      accumulator.applyDataPart(
        const DataUiPart<Object?>(
          key: 'status',
          data: {
            'phase': 'queued',
          },
        ),
      );
      accumulator.applyDataPart(
        const DataUiPart<Object?>(
          id: 'progress',
          key: 'status',
          data: {
            'phase': 'running',
            'value': 0.25,
          },
        ),
      );

      final message = accumulator.applyDataPart(
        const DataUiPart<Object?>(
          id: 'progress',
          key: 'status',
          data: {
            'phase': 'running',
            'value': 0.75,
          },
        ),
      );

      final dataParts = message.parts.whereType<DataUiPart<Object?>>().toList();
      expect(dataParts, hasLength(2));
      expect(dataParts[0].id, isNull);
      expect((dataParts[0].data as Map<String, Object?>)['phase'], 'queued');
      expect(dataParts[1].id, 'progress');
      expect((dataParts[1].data as Map<String, Object?>)['value'], 0.75);
    });

    test('hydrates data-part upsert indexes from a seed message', () {
      final accumulator = ChatUiAccumulator(
        messageId: 'assistant-new',
        seedMessage: ChatUiMessage(
          id: 'assistant-existing',
          role: ChatUiRole.assistant,
          parts: const [
            DataUiPart<Object?>(
              id: 'progress',
              key: 'status',
              data: {
                'value': 0.25,
              },
            ),
          ],
        ),
      );

      final message = accumulator.applyDataPart(
        const DataUiPart<Object?>(
          id: 'progress',
          key: 'status',
          data: {
            'value': 1.0,
          },
        ),
      );

      final dataParts = message.parts.whereType<DataUiPart<Object?>>().toList();
      expect(message.id, 'assistant-existing');
      expect(dataParts, hasLength(1));
      expect((dataParts.single.data as Map<String, Object?>)['value'], 1.0);
    });

    test('throws on malformed event ordering', () {
      final accumulator = ChatUiAccumulator(messageId: 'assistant-1');

      expect(
        () => accumulator.apply(
          const TextDeltaEvent(
            id: 'missing-text',
            delta: 'Hello',
          ),
        ),
        throwsA(isA<StateError>()),
      );

      expect(
        () => accumulator.apply(
          const ToolInputDeltaEvent(
            toolCallId: 'missing-tool',
            delta: '{}',
          ),
        ),
        throwsA(isA<StateError>()),
      );

      expect(
        () => accumulator.apply(
          const ToolInputEndEvent(
            toolCallId: 'missing-tool',
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
