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
        const ToolResultEvent(
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
            sourceId: 'source-1',
            uri: Uri.parse('https://example.com'),
            title: 'Example',
          ),
        ),
        const FileEvent(
          GeneratedFile(
            mediaType: 'text/plain',
            filename: 'note.txt',
            bytes: [1, 2, 3],
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
        const ErrorEvent({
          'message': 'soft failure',
        }),
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

      final decoded = codec.decodeEvents(encoded);
      expect(decoded, hasLength(14));
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

      final toolResult = decoded[7] as ToolResultEvent;
      expect(toolResult.toolResult.preliminary, isTrue);
      expect(toolResult.toolResult.isDynamic, isTrue);

      final fileEvent = decoded[9] as FileEvent;
      expect(fileEvent.file.bytes, [1, 2, 3]);

      final finish = decoded.last as FinishEvent;
      expect(finish.finishReason, FinishReason.toolCalls);
      expect(finish.rawFinishReason, 'tool_calls');
      expect(finish.usage?.reasoningTokens, 2);
    });

    test('throws when raw chunk payload is not JSON-safe', () {
      const codec = TextStreamEventJsonCodec();

      expect(
        () => codec.encodeEvent(RawChunkEvent(Object())),
        throwsFormatException,
      );
    });
  });
}
