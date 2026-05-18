import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('ChatMessageMapper', () {
    test('projects the stable message summary fields from a chat message', () {
      final source = SourceReference(
        kind: SourceReferenceKind.url,
        sourceId: 'source-1',
        uri: Uri.parse('https://example.com/source'),
      );
      final file = GeneratedFile(
        mediaType: 'text/plain',
        filename: 'note.txt',
        data: const FileTextData('note'),
      );
      final reasoningFile = GeneratedFile(
        mediaType: 'text/plain',
        filename: 'reasoning.txt',
        data: const FileTextData('why'),
      );
      final message = ChatUiMessage(
        id: 'msg-1',
        role: ChatUiRole.assistant,
        parts: [
          const TextUiPart(text: 'Hello', isStreaming: true),
          const TextUiPart(text: 'world'),
          const ReasoningUiPart(text: 'Think', isStreaming: true),
          const ReasoningUiPart(text: 'more'),
          ToolUiPart(
            toolCallId: 'tool-1',
            toolName: 'weather',
            state: ToolUiPartState.outputAvailable,
            input: {
              'city': 'Tokyo',
            },
            output: 'sunny',
            toolOutput: const TextToolOutput('sunny'),
            providerExecuted: true,
            isDynamic: true,
            preliminary: true,
            title: 'Weather tool',
            approval: const ToolApprovalUiState(
              approvalId: 'approval-1',
              approved: true,
            ),
            callProviderMetadata: const ProviderMetadata({
              'openai': {
                'callId': 'call-1',
              },
            }),
            resultProviderMetadata: const ProviderMetadata({
              'openai': {
                'resultId': 'result-1',
              },
            }),
          ),
          SourceUiPart(source),
          FileUiPart(file),
          ReasoningFileUiPart(reasoningFile),
          const CustomUiPart(
            kind: 'app.note',
            data: {
              'value': 1,
            },
          ),
          const StepBoundaryUiPart('step-1'),
          const DataUiPart<Object?>(
            id: 'data-1',
            key: 'status',
            data: {
              'value': true,
            },
          ),
        ],
        metadata: {
          ChatUiMetadataKeys.warnings: const [
            ModelWarning(
              type: ModelWarningType.unsupported,
              message: 'ignored',
              feature: 'temperature',
            ),
          ],
          ChatUiMetadataKeys.responseId: 'resp-1',
          ChatUiMetadataKeys.responseTimestamp:
              DateTime.utc(2026, 3, 30, 12, 0, 0),
          ChatUiMetadataKeys.modelId: 'gpt-test',
          ChatUiMetadataKeys.responseProviderMetadata: const ProviderMetadata({
            'openai': {
              'requestId': 'req-1',
            },
          }),
          ChatUiMetadataKeys.finishReason: FinishReason.aborted,
          ChatUiMetadataKeys.rawFinishReason: 'cancelled',
          ChatUiMetadataKeys.isAborted: true,
          ChatUiMetadataKeys.abortReason: 'user cancelled',
          ChatUiMetadataKeys.usage: const UsageStats(
            inputTokens: 1,
            outputTokens: 2,
            totalTokens: 3,
          ),
          ChatUiMetadataKeys.finishProviderMetadata: const ProviderMetadata({
            'openai': {
              'finishId': 'fin-1',
            },
          }),
          ChatUiMetadataKeys.errors: const [
            ModelError(
              kind: ModelErrorKind.transport,
              message: 'oops',
              code: 'http-500',
              statusCode: 500,
            ),
          ],
          ChatUiMetadataKeys.rawChunks: const [
            'chunk-1',
          ],
        },
      );

      const mapper = ChatMessageMapper(
        textSeparator: ' ',
        reasoningSeparator: ' | ',
      );

      final mapped = mapper.map(message);

      expect(mapped.message, same(message));
      expect(mapped.textParts, hasLength(2));
      expect(mapped.text, 'Hello world');
      expect(mapped.hasStreamingText, isTrue);
      expect(mapped.reasoningParts, hasLength(2));
      expect(mapped.reasoningText, 'Think | more');
      expect(mapped.hasStreamingReasoning, isTrue);
      expect(mapped.toolParts, hasLength(1));
      expect(mapped.toolParts.single.toolCallId, 'tool-1');
      expect(
          mapped.toolParts.single.providerMetadata,
          const ProviderMetadata({
            'openai': {
              'resultId': 'result-1',
            },
          }));
      expect(mapped.sources, [source]);
      expect(mapped.fileParts, hasLength(1));
      expect(mapped.fileParts.single.file, same(file));
      expect(mapped.reasoningFileParts, hasLength(1));
      expect(mapped.reasoningFileParts.single.file, same(reasoningFile));
      expect(mapped.customParts, hasLength(1));
      expect(mapped.customParts.single.kind, 'app.note');
      expect(mapped.dataParts, hasLength(1));
      expect(mapped.dataParts.single.key, 'status');
      expect(mapped.stepIds, ['step-1']);
      expect(mapped.warnings, [
        const ModelWarning(
          type: ModelWarningType.unsupported,
          message: 'ignored',
          feature: 'temperature',
        ),
      ]);
      expect(mapped.responseId, 'resp-1');
      expect(mapped.responseTimestamp, DateTime.utc(2026, 3, 30, 12, 0, 0));
      expect(mapped.modelId, 'gpt-test');
      expect(
        mapped.responseProviderMetadata,
        const ProviderMetadata({
          'openai': {
            'requestId': 'req-1',
          },
        }),
      );
      expect(mapped.finishReason, FinishReason.aborted);
      expect(mapped.rawFinishReason, 'cancelled');
      expect(mapped.isAborted, isTrue);
      expect(mapped.abortReason, 'user cancelled');
      expect(
        mapped.usage,
        const UsageStats(
          inputTokens: 1,
          outputTokens: 2,
          totalTokens: 3,
        ),
      );
      expect(
        mapped.finishProviderMetadata,
        const ProviderMetadata({
          'openai': {
            'finishId': 'fin-1',
          },
        }),
      );
      expect(mapped.errors, hasLength(1));
      expect(mapped.errors.single.kind, ModelErrorKind.transport);
      expect(mapped.rawChunks, ['chunk-1']);
      expect(mapped.hasWarnings, isTrue);
      expect(mapped.hasErrors, isTrue);
      expect(mapped.hasToolParts, isTrue);
      expect(mapped.hasSources, isTrue);
      expect(mapped.hasFiles, isTrue);
    });
  });
}
