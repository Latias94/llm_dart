import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('PromptJsonCodec', () {
    test('round-trips prompt messages with tool approval parts', () {
      const codec = PromptJsonCodec();

      final encoded = codec.encodeMessages([
        SystemPromptMessage.text('You are concise.'),
        UserPromptMessage(
          parts: [
            TextPromptPart('Show the latest screenshot.'),
            ImagePromptPart(
              mediaType: 'image/png',
              bytes: [1, 2, 3],
            ),
          ],
        ),
        AssistantPromptMessage(
          parts: [
            const ToolCallPromptPart(
              toolCallId: 'tool-1',
              toolName: 'mcp.open_browser',
              input: {
                'url': 'https://example.com',
              },
              providerExecuted: true,
              isDynamic: true,
              title: 'Browser',
            ),
            const ToolApprovalRequestPromptPart(
              approvalId: 'approval-1',
              toolCallId: 'tool-1',
            ),
          ],
        ),
        ToolPromptMessage(
          toolName: 'mcp.open_browser',
          parts: const [
            ToolApprovalResponsePromptPart(
              approvalId: 'approval-1',
              toolCallId: 'tool-1',
              approved: true,
              reason: 'User confirmed the external action.',
            ),
            ToolResultPromptPart(
              toolCallId: 'tool-1',
              toolName: 'mcp.open_browser',
              output: {
                'status': 'ok',
              },
            ),
          ],
        ),
      ]);

      expect(encoded['schemaVersion'], '2026-03-1');
      expect(encoded['kind'], PromptJsonCodec.envelopeKind);

      final decoded = codec.decodeMessages(encoded);
      expect(decoded, hasLength(4));
      expect(decoded[0], isA<SystemPromptMessage>());
      expect(decoded[1], isA<UserPromptMessage>());
      expect(decoded[2], isA<AssistantPromptMessage>());
      expect(decoded[3], isA<ToolPromptMessage>());

      final assistant = decoded[2] as AssistantPromptMessage;
      expect(assistant.parts, hasLength(2));
      final toolCall = assistant.parts.first as ToolCallPromptPart;
      expect(toolCall.providerExecuted, isTrue);
      expect(toolCall.isDynamic, isTrue);
      expect(toolCall.title, 'Browser');
      expect((toolCall.input as Map<String, Object?>)['url'],
          'https://example.com');

      final toolMessage = decoded[3] as ToolPromptMessage;
      expect(toolMessage.toolName, 'mcp.open_browser');
      expect(toolMessage.parts[0], isA<ToolApprovalResponsePromptPart>());
      expect(
        (toolMessage.parts[0] as ToolApprovalResponsePromptPart).approved,
        isTrue,
      );
      expect(
        (toolMessage.parts[0] as ToolApprovalResponsePromptPart).reason,
        'User confirmed the external action.',
      );
      expect(toolMessage.parts[1], isA<ToolResultPromptPart>());
    });

    test('round-trips replayable prompt parts and part-level metadata', () {
      const codec = PromptJsonCodec();

      final encoded = codec.encodeMessages([
        AssistantPromptMessage(
          parts: const [
            ReasoningPromptPart(
              'Planning the answer.',
              providerMetadata: ProviderMetadata({
                'google': {
                  'thoughtSignature': 'sig_reasoning',
                },
              }),
            ),
            ReasoningFilePromptPart(
              mediaType: 'image/png',
              filename: 'thought.png',
              bytes: [1, 2, 3],
              providerMetadata: ProviderMetadata({
                'google': {
                  'thoughtSignature': 'sig_reasoning_file',
                },
              }),
            ),
            CustomPromptPart(
              kind: 'openai.compaction',
              data: {
                'type': 'compaction',
                'id': 'cmp_1',
              },
              providerMetadata: ProviderMetadata({
                'openai': {
                  'itemId': 'cmp_1',
                },
              }),
            ),
          ],
        ),
      ]);

      final decoded =
          codec.decodeMessages(encoded).single as AssistantPromptMessage;
      expect(decoded.parts, hasLength(3));

      final reasoningPart = decoded.parts[0] as ReasoningPromptPart;
      expect(reasoningPart.text, 'Planning the answer.');
      expect(
        reasoningPart.providerMetadata!['google'],
        containsPair('thoughtSignature', 'sig_reasoning'),
      );

      final reasoningFilePart = decoded.parts[1] as ReasoningFilePromptPart;
      expect(reasoningFilePart.mediaType, 'image/png');
      expect(reasoningFilePart.filename, 'thought.png');
      expect(reasoningFilePart.bytes, [1, 2, 3]);
      expect(
        reasoningFilePart.providerMetadata!['google'],
        containsPair('thoughtSignature', 'sig_reasoning_file'),
      );

      final customPart = decoded.parts[2] as CustomPromptPart;
      expect(customPart.kind, 'openai.compaction');
      expect(customPart.data, {
        'type': 'compaction',
        'id': 'cmp_1',
      });
      expect(
        customPart.providerMetadata!['openai'],
        containsPair('itemId', 'cmp_1'),
      );
    });
  });

  group('ChatUiJsonCodec', () {
    test('round-trips chat UI messages with metadata and tool state', () {
      const codec = ChatUiJsonCodec();

      final encoded = codec.encodeMessages([
        ChatUiMessage(
          id: 'assistant-1',
          role: ChatUiRole.assistant,
          parts: [
            const StepBoundaryUiPart('step-1'),
            const TextUiPart(
              text: 'Looking up the result.',
              isStreaming: false,
              providerMetadata: ProviderMetadata({
                'openai': {
                  'itemId': 'msg_1',
                },
              }),
            ),
            const ToolUiPart(
              toolCallId: 'tool-1',
              toolName: 'mcp.create_short_url',
              state: ToolUiPartState.approvalResponded,
              input: {
                'url': 'https://example.com',
              },
              output: {
                'shortUrl': 'https://sho.rt/abc',
              },
              providerExecuted: true,
              isDynamic: true,
              title: 'zip1',
              approval: ToolApprovalUiState(
                approvalId: 'approval-1',
                approved: true,
                reason: 'User confirmed the external action.',
              ),
              callProviderMetadata: ProviderMetadata({
                'openai': {
                  'approvalRequestId': 'approval-1',
                },
              }),
              resultProviderMetadata: ProviderMetadata({
                'openai': {
                  'itemId': 'call_1',
                },
              }),
            ),
            SourceUiPart(
              SourceReference(
                kind: SourceReferenceKind.url,
                sourceId: 'src-1',
                uri: Uri.parse('https://example.com/doc'),
                title: 'Example Doc',
                providerMetadata: ProviderMetadata({
                  'openai': {
                    'annotationType': 'url_citation',
                  },
                }),
              ),
            ),
            const FileUiPart(
              GeneratedFile(
                mediaType: 'image/png',
                filename: 'preview.png',
                bytes: [4, 5, 6],
              ),
            ),
            const ReasoningFileUiPart(
              GeneratedFile(
                mediaType: 'application/pdf',
                filename: 'thoughts.pdf',
                bytes: [7, 8, 9],
              ),
              providerMetadata: ProviderMetadata({
                'google': {
                  'thoughtSignature': 'sig_reasoning_file',
                },
              }),
            ),
            const CustomUiPart(
              kind: 'openai.web_search_call',
              data: {
                'query': 'example',
              },
            ),
            const DataUiPart<Object?>(
              id: 'debug-1',
              key: 'debug',
              data: {
                'step': 1,
              },
            ),
          ],
          metadata: {
            ChatUiMetadataKeys.warnings: [
              const ModelWarning(
                type: ModelWarningType.compatibility,
                message: 'Using fallback mode.',
              ),
            ],
            ChatUiMetadataKeys.responseId: 'resp_1',
            ChatUiMetadataKeys.responseTimestamp:
                DateTime.parse('2026-03-26T12:00:00.000Z'),
            ChatUiMetadataKeys.modelId: 'gpt-4.1-mini',
            ChatUiMetadataKeys.responseProviderMetadata:
                const ProviderMetadata({
              'openai': {
                'responseStatus': 'completed',
              },
            }),
            ChatUiMetadataKeys.finishReason: FinishReason.stop,
            ChatUiMetadataKeys.rawFinishReason: 'stop',
            ChatUiMetadataKeys.isAborted: false,
            ChatUiMetadataKeys.abortReason: null,
            ChatUiMetadataKeys.usage: const UsageStats(
              inputTokens: 10,
              outputTokens: 4,
              totalTokens: 14,
              reasoningTokens: 1,
            ),
            ChatUiMetadataKeys.finishProviderMetadata: const ProviderMetadata({
              'openai': {
                'serviceTier': 'default',
              },
            }),
            ChatUiMetadataKeys.errors: [
              const ModelError(
                kind: ModelErrorKind.provider,
                message: 'none',
                code: 'provider-none',
              ),
            ],
          },
        ),
      ]);

      expect(encoded['schemaVersion'], '2026-03-1');
      expect(encoded['kind'], ChatUiJsonCodec.envelopeKind);

      final decoded = codec.decodeMessages(encoded);
      expect(decoded, hasLength(1));

      final message = decoded.single;
      expect(message.id, 'assistant-1');
      expect(message.role, ChatUiRole.assistant);
      expect(message.parts, hasLength(8));

      final tool = message.parts.whereType<ToolUiPart>().single;
      expect(tool.state, ToolUiPartState.approvalResponded);
      expect(tool.providerExecuted, isTrue);
      expect(tool.isDynamic, isTrue);
      expect(tool.approval?.approvalId, 'approval-1');
      expect(tool.approval?.approved, isTrue);
      expect(tool.approval?.reason, 'User confirmed the external action.');
      expect(
        (tool.callProviderMetadata!['openai']
            as Map<String, Object?>)['approvalRequestId'],
        'approval-1',
      );

      final file = message.parts.whereType<FileUiPart>().single.file;
      expect(file.filename, 'preview.png');
      expect(file.bytes, [4, 5, 6]);

      final reasoningFile =
          message.parts.whereType<ReasoningFileUiPart>().single;
      expect(reasoningFile.file.filename, 'thoughts.pdf');
      expect(reasoningFile.file.bytes, [7, 8, 9]);
      expect(
        reasoningFile.providerMetadata!['google'],
        containsPair('thoughtSignature', 'sig_reasoning_file'),
      );

      final source = message.parts.whereType<SourceUiPart>().single.source;
      expect(source.kind, SourceReferenceKind.url);
      expect(source.sourceId, 'src-1');
      expect(source.uri, Uri.parse('https://example.com/doc'));
      expect(source.title, 'Example Doc');

      final dataPart = message.parts.whereType<DataUiPart<Object?>>().single;
      expect(dataPart.id, 'debug-1');
      expect(dataPart.key, 'debug');
      expect((dataPart.data as Map<String, Object?>)['step'], 1);

      final responseMetadata =
          message.metadata[ChatUiMetadataKeys.responseProviderMetadata]
              as ProviderMetadata;
      expect(
        (responseMetadata['openai'] as Map<String, Object?>)['responseStatus'],
        'completed',
      );
      expect(
        message.metadata[ChatUiMetadataKeys.finishReason],
        FinishReason.stop,
      );
      expect(message.metadata[ChatUiMetadataKeys.rawFinishReason], 'stop');
      expect(message.metadata[ChatUiMetadataKeys.isAborted], isFalse);
      expect(message.metadata[ChatUiMetadataKeys.abortReason], isNull);
      final usage = message.metadata[ChatUiMetadataKeys.usage] as UsageStats;
      expect(usage.totalTokens, 14);

      final warnings =
          message.metadata[ChatUiMetadataKeys.warnings] as List<ModelWarning>;
      expect(warnings.single.type, ModelWarningType.compatibility);
      expect(warnings.single.message, 'Using fallback mode.');

      final errors =
          message.metadata[ChatUiMetadataKeys.errors] as List<ModelError>;
      expect(errors.single.code, 'provider-none');
      expect(errors.single.message, 'none');
    });

    test('encodes empty warning metadata lists from runtime session state', () {
      const codec = ChatUiJsonCodec();

      final encoded = codec.encodeMessages([
        ChatUiMessage(
          id: 'assistant-2',
          role: ChatUiRole.assistant,
          parts: const [
            TextUiPart(text: 'Hello'),
          ],
          metadata: const {
            ChatUiMetadataKeys.warnings: [],
          },
        ),
      ]);

      final decoded = codec.decodeMessages(encoded);
      final warnings = decoded.single.metadata[ChatUiMetadataKeys.warnings]
          as List<ModelWarning>;
      expect(warnings, isEmpty);
    });
  });
}
