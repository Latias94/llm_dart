import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('TextStreamEventJsonCodec', () {
    test('round-trips text stream events with metadata and tool content', () {
      const codec = TextStreamEventJsonCodec();
      final encoded = codec.encodeEvents([
        StartEvent(
          warnings: const [
            ModelWarning(
              type: ModelWarningType.unsupported,
              message: 'temperature not supported',
              field: 'temperature',
            ),
          ],
        ),
        ResponseMetadataEvent(
          responseId: 'resp_1',
          timestamp: DateTime.utc(2026, 3, 26, 10, 0),
          modelId: 'gpt-5-mini',
          providerMetadata: const ProviderMetadata({
            'openai': {
              'status': 'completed',
            },
          }),
        ),
        const StepStartEvent(stepId: 'step-1'),
        const TextStartEvent(id: 'text-1'),
        const TextDeltaEvent(
          id: 'text-1',
          delta: 'Hello',
          providerMetadata: ProviderMetadata({
            'openai': {
              'itemId': 'msg_1',
            },
          }),
        ),
        const ToolCallEvent(
          toolCall: ToolCallContent(
            toolCallId: 'tool-1',
            toolName: 'search',
            input: {
              'query': 'dart',
            },
            providerExecuted: true,
            isDynamic: true,
            title: 'Browser',
          ),
        ),
        const ToolApprovalRequestEvent(
          approvalId: 'approval-1',
          toolCallId: 'tool-1',
        ),
        const ToolOutputDeniedEvent(
          toolCallId: 'tool-1',
          providerMetadata: ProviderMetadata({
            'openai': {
              'approvalState': 'denied',
            },
          }),
        ),
        const ToolInputErrorEvent(
          toolCallId: 'tool-1',
          toolName: 'search',
          input: '{"query":}',
          errorText: 'Invalid JSON tool arguments for "search".',
          providerExecuted: true,
          isDynamic: true,
          title: 'Browser',
          providerMetadata: ProviderMetadata({
            'openai': {
              'stage': 'input',
            },
          }),
        ),
        ToolResultEvent(
          toolResult: ToolResultContent(
            toolCallId: 'tool-1',
            toolName: 'search',
            output: {
              'ok': true,
            },
            preliminary: true,
            isDynamic: true,
          ),
        ),
        SourceEvent(
          SourceReference(
            kind: SourceReferenceKind.url,
            sourceId: 'source-1',
            uri: Uri.parse('https://example.com'),
            title: 'Example',
          ),
        ),
        const FileEvent(
          GeneratedFile(
            mediaType: 'text/plain',
            filename: 'note.txt',
            data: FileBytesData.constBytes([1, 2, 3]),
          ),
        ),
        const CustomEvent(
          kind: 'openai.web_search_call',
          data: {
            'query': 'dart',
          },
        ),
        const RawChunkEvent({
          'type': 'response.output_text.delta',
        }),
        const ErrorEvent(
          ModelError(
            kind: ModelErrorKind.provider,
            message: 'soft failure',
            code: 'soft_failure',
            details: {
              'type': 'soft_failure',
              'message': 'soft failure',
            },
          ),
        ),
        const AbortEvent(
          reason: 'user cancelled',
        ),
        const FinishEvent(
          finishReason: FinishReason.toolCalls,
          rawFinishReason: 'tool_calls',
          usage: UsageStats(
            inputTokens: 10,
            outputTokens: 4,
            totalTokens: 14,
            reasoningTokens: 2,
          ),
          providerMetadata: ProviderMetadata({
            'openai': {
              'serviceTier': 'default',
            },
          }),
        ),
      ]);

      expect(encoded['kind'], TextStreamEventJsonCodec.envelopeKind);
      final envelopeData = encoded['data'] as Map<String, Object?>;
      final encodedEvents = envelopeData['events'] as List<Object?>;
      expect((encodedEvents[2] as Map<String, Object?>)['type'], 'step-start');
      expect((encodedEvents[15] as Map<String, Object?>)['type'], 'abort');

      final decoded = codec.decodeEvents(encoded);
      expect(decoded, hasLength(17));
      expect(decoded.first, isA<StartEvent>());
      expect(
          (decoded.first as StartEvent).warnings.single.field, 'temperature');

      final response = decoded[1] as ResponseMetadataEvent;
      expect(response.responseId, 'resp_1');
      expect(response.modelId, 'gpt-5-mini');
      expect(
        response.providerMetadata!['openai'],
        containsPair('status', 'completed'),
      );

      final textDelta = decoded[4] as TextDeltaEvent;
      expect(textDelta.delta, 'Hello');
      expect(
        textDelta.providerMetadata!['openai'],
        containsPair('itemId', 'msg_1'),
      );

      final toolCall = decoded[5] as ToolCallEvent;
      expect(toolCall.toolCall.providerExecuted, isTrue);
      expect(toolCall.toolCall.isDynamic, isTrue);
      expect(toolCall.toolCall.title, 'Browser');

      final denied = decoded[7] as ToolOutputDeniedEvent;
      expect(denied.toolCallId, 'tool-1');
      expect(
        denied.providerMetadata!['openai'],
        containsPair('approvalState', 'denied'),
      );

      final toolInputError = decoded[8] as ToolInputErrorEvent;
      expect(toolInputError.toolCallId, 'tool-1');
      expect(toolInputError.toolName, 'search');
      expect(toolInputError.input, '{"query":}');
      expect(toolInputError.errorText,
          'Invalid JSON tool arguments for "search".');
      expect(toolInputError.providerExecuted, isTrue);
      expect(toolInputError.isDynamic, isTrue);
      expect(toolInputError.title, 'Browser');
      expect(
        toolInputError.providerMetadata!['openai'],
        containsPair('stage', 'input'),
      );

      final toolResult = decoded[9] as ToolResultEvent;
      expect(toolResult.toolResult.preliminary, isTrue);
      expect(toolResult.toolResult.isDynamic, isTrue);

      final sourceEvent = decoded[10] as SourceEvent;
      expect(sourceEvent.source.kind, SourceReferenceKind.url);
      expect(sourceEvent.source.sourceId, 'source-1');
      expect(sourceEvent.source.uri, Uri.parse('https://example.com'));
      expect(sourceEvent.source.title, 'Example');

      final fileEvent = decoded[11] as FileEvent;
      expect(fileEvent.file.bytes, [1, 2, 3]);

      final finish = decoded.last as FinishEvent;
      expect(finish.finishReason, FinishReason.toolCalls);
      expect(finish.rawFinishReason, 'tool_calls');
      expect(finish.usage?.reasoningTokens, 2);

      final error = decoded[14] as ErrorEvent;
      expect(error.error.kind, ModelErrorKind.provider);
      expect(error.error.code, 'soft_failure');
      expect(error.error.message, 'soft failure');

      final abort = decoded[15] as AbortEvent;
      expect(abort.reason, 'user cancelled');
    });

    test('decodes both canonical and legacy step-end event names', () {
      const codec = TextStreamEventJsonCodec();

      final encoded =
          codec.encodeEvent(const StepFinishEvent(stepId: 'step-0'));
      expect(encoded['type'], 'step-end');

      final canonicalDecoded = codec.decodeEvent({
        'type': 'step-end',
        'stepId': 'step-1',
      });
      expect(canonicalDecoded, isA<StepFinishEvent>());
      expect((canonicalDecoded as StepFinishEvent).stepId, 'step-1');

      final legacyDecoded = codec.decodeEvent({
        'type': 'step-finish',
        'stepId': 'step-2',
      });
      expect(legacyDecoded, isA<StepFinishEvent>());
      expect((legacyDecoded as StepFinishEvent).stepId, 'step-2');
    });

    test('throws when raw chunk payload is not JSON-safe', () {
      const codec = TextStreamEventJsonCodec();

      expect(
        () => codec.encodeEvent(RawChunkEvent(Object())),
        throwsFormatException,
      );
    });

    test('round-trips reasoning file events', () {
      const codec = TextStreamEventJsonCodec();

      final decoded = codec.decodeEvents(
        codec.encodeEvents([
          const ReasoningFileEvent(
            GeneratedFile(
              mediaType: 'image/png',
              filename: 'thought.png',
              data: FileBytesData.constBytes([1, 2, 3]),
            ),
            providerMetadata: ProviderMetadata({
              'google': {
                'thoughtSignature': 'sig_reasoning_file',
              },
            }),
          ),
        ]),
      );

      final event = decoded.single as ReasoningFileEvent;
      expect(event.file.mediaType, 'image/png');
      expect(event.file.filename, 'thought.png');
      expect(event.file.bytes, [1, 2, 3]);
      expect(
        event.providerMetadata!['google'],
        containsPair('thoughtSignature', 'sig_reasoning_file'),
      );
    });
  });
}
