import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('ChatUiJsonCodec', () {
    test('round-trips chat messages, metadata, and rich UI parts', () {
      const codec = ChatUiJsonCodec();
      final responseTimestamp = DateTime.utc(2026, 3, 30, 12, 0, 0);
      final source = SourceReference(
        kind: SourceReferenceKind.url,
        sourceId: 'source-1',
        uri: Uri.parse('https://example.com/source'),
        title: 'Example Source',
        filename: 'source.txt',
        mediaType: 'text/plain',
        providerMetadata: const ProviderMetadata({
          'openai': {
            'sourceId': 'source-1',
          },
        }),
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
          const TextUiPart(
            text: 'Hello',
            isStreaming: true,
            providerMetadata: ProviderMetadata({
              'openai': {
                'itemId': 'text-1',
              },
            }),
          ),
          const ReasoningUiPart(
            text: 'Think',
            isStreaming: false,
            providerMetadata: ProviderMetadata({
              'openai': {
                'itemId': 'reason-1',
              },
            }),
          ),
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
              reason: 'approved',
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
          FileUiPart(
            file,
            providerMetadata: const ProviderMetadata({
              'openai': {
                'fileId': 'file-1',
              },
            }),
          ),
          ReasoningFileUiPart(
            reasoningFile,
            providerMetadata: const ProviderMetadata({
              'openai': {
                'fileId': 'file-2',
              },
            }),
          ),
          const CustomUiPart(
            kind: 'app.note',
            data: {
              'value': 1,
            },
            providerMetadata: ProviderMetadata({
              'openai': {
                'customId': 'custom-1',
              },
            }),
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
          ChatUiMetadataKeys.responseTimestamp: responseTimestamp,
          ChatUiMetadataKeys.modelId: 'gpt-test',
          ChatUiMetadataKeys.responseProviderMetadata: const ProviderMetadata({
            'openai': {
              'requestId': 'req-1',
            },
          }),
          ChatUiMetadataKeys.finishReason: FinishReason.stop,
          ChatUiMetadataKeys.rawFinishReason: 'stop',
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
              isRetryable: true,
              details: {
                'retryable': true,
              },
              originalType: 'SocketException',
            ),
          ],
          ChatUiMetadataKeys.rawChunks: const [
            'chunk-1',
            {
              'type': 'raw',
              'value': 1,
            },
          ],
          'customFlag': 'preserved',
        },
      );

      final encoded = codec.encodeMessages([message]);
      expect(encoded['kind'], ChatUiJsonCodec.envelopeKind);

      final decoded = codec.decodeMessages(encoded);
      expect(decoded, hasLength(1));

      final decodedMessage = decoded.single;
      expect(decodedMessage.id, 'msg-1');
      expect(decodedMessage.role, ChatUiRole.assistant);
      expect(decodedMessage.parts, hasLength(9));

      final text = decodedMessage.parts[0] as TextUiPart;
      expect(text.text, 'Hello');
      expect(text.isStreaming, isTrue);
      expect(
        text.providerMetadata,
        const ProviderMetadata({
          'openai': {
            'itemId': 'text-1',
          },
        }),
      );

      final reasoning = decodedMessage.parts[1] as ReasoningUiPart;
      expect(reasoning.text, 'Think');
      expect(reasoning.isStreaming, isFalse);

      final tool = decodedMessage.parts[2] as ToolUiPart;
      expect(tool.toolCallId, 'tool-1');
      expect(tool.toolName, 'weather');
      expect(tool.state, ToolUiPartState.outputAvailable);
      expect(tool.output, 'sunny');
      expect(
        tool.toolOutput,
        isA<TextToolOutput>().having((value) => value.value, 'value', 'sunny'),
      );
      expect(tool.providerExecuted, isTrue);
      expect(tool.isDynamic, isTrue);
      expect(tool.preliminary, isTrue);
      expect(tool.title, 'Weather tool');
      expect(tool.approval?.approved, isTrue);
      expect(
          tool.providerMetadata,
          const ProviderMetadata({
            'openai': {
              'resultId': 'result-1',
            },
          }));

      final sourcePart = decodedMessage.parts[3] as SourceUiPart;
      expect(sourcePart.source.sourceId, 'source-1');
      expect(sourcePart.source.uri, Uri.parse('https://example.com/source'));
      expect(sourcePart.source.title, 'Example Source');

      final filePart = decodedMessage.parts[4] as FileUiPart;
      expect(filePart.file.filename, 'note.txt');
      expect(filePart.file.text, 'note');

      final reasoningFilePart = decodedMessage.parts[5] as ReasoningFileUiPart;
      expect(reasoningFilePart.file.filename, 'reasoning.txt');
      expect(reasoningFilePart.file.text, 'why');

      final custom = decodedMessage.parts[6] as CustomUiPart;
      expect(custom.kind, 'app.note');
      expect(custom.data, {
        'value': 1,
      });

      expect(decodedMessage.parts[7], isA<StepBoundaryUiPart>());

      final metadata = decodedMessage.metadata;
      final warnings =
          metadata[ChatUiMetadataKeys.warnings] as List<ModelWarning>;
      expect(warnings, hasLength(1));
      expect(
        warnings.single,
        const ModelWarning(
          type: ModelWarningType.unsupported,
          message: 'ignored',
          feature: 'temperature',
        ),
      );
      expect(metadata[ChatUiMetadataKeys.responseId], 'resp-1');
      expect(
        metadata[ChatUiMetadataKeys.responseTimestamp],
        responseTimestamp,
      );
      expect(metadata[ChatUiMetadataKeys.modelId], 'gpt-test');
      expect(
        metadata[ChatUiMetadataKeys.responseProviderMetadata],
        const ProviderMetadata({
          'openai': {
            'requestId': 'req-1',
          },
        }),
      );
      expect(metadata[ChatUiMetadataKeys.finishReason], FinishReason.stop);
      expect(metadata[ChatUiMetadataKeys.rawFinishReason], 'stop');
      expect(metadata[ChatUiMetadataKeys.isAborted], isTrue);
      expect(metadata[ChatUiMetadataKeys.abortReason], 'user cancelled');
      expect(
        metadata[ChatUiMetadataKeys.usage],
        const UsageStats(
          inputTokens: 1,
          outputTokens: 2,
          totalTokens: 3,
        ),
      );
      expect(
        metadata[ChatUiMetadataKeys.finishProviderMetadata],
        const ProviderMetadata({
          'openai': {
            'finishId': 'fin-1',
          },
        }),
      );
      final errors = metadata[ChatUiMetadataKeys.errors] as List<ModelError>;
      expect(errors, hasLength(1));
      expect(
        errors.single,
        const ModelError(
          kind: ModelErrorKind.transport,
          message: 'oops',
          code: 'http-500',
          statusCode: 500,
          isRetryable: true,
          details: {
            'retryable': true,
          },
          originalType: 'SocketException',
        ),
      );
      expect(metadata[ChatUiMetadataKeys.rawChunks], [
        'chunk-1',
        {
          'type': 'raw',
          'value': 1,
        },
      ]);
      expect(metadata['customFlag'], 'preserved');
    });

    test('rejects unsupported schema versions', () {
      const codec = ChatUiJsonCodec();

      expect(
        () => codec.decodeMessages({
          'schemaVersion': '2099-01-1',
          'kind': ChatUiJsonCodec.envelopeKind,
          'data': {
            'messages': const [],
          },
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(
              'Unsupported llm_dart AI JSON schema version "2099-01-1"',
            ),
          ),
        ),
      );
    });
  });
}
