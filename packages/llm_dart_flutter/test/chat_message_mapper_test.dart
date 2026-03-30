import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_flutter/llm_dart_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('ChatMessageMapper', () {
    test('projects common parts and reserved metadata into a mapped message',
        () {
      final timestamp = DateTime.utc(2026, 3, 30, 12);
      final mapper = ChatMessageMapper(
        textSeparator: '',
        reasoningSeparator: '\n',
      );
      final message = ChatUiMessage(
        id: 'assistant-1',
        role: ChatUiRole.assistant,
        parts: [
          const TextUiPart(
            text: 'Hello',
            isStreaming: true,
          ),
          const TextUiPart(text: ' world'),
          const ReasoningUiPart(text: 'Plan first.'),
          const ToolUiPart(
            toolCallId: 'tool-1',
            toolName: 'weather',
            state: ToolUiPartState.outputAvailable,
            input: {
              'city': 'Hong Kong',
            },
            output: {
              'temperature': 28,
            },
          ),
          SourceUiPart(
            SourceReference(
              kind: SourceReferenceKind.url,
              sourceId: 'source-1',
              uri: Uri.parse('https://example.com'),
              title: 'Example',
            ),
          ),
          const FileUiPart(
            GeneratedFile(
              mediaType: 'application/pdf',
              filename: 'guide.pdf',
            ),
          ),
          const ReasoningFileUiPart(
            GeneratedFile(
              mediaType: 'image/png',
              filename: 'thought.png',
            ),
          ),
          const CustomUiPart(
            kind: 'provider.custom',
            data: {
              'ok': true,
            },
          ),
          const DataUiPart<Map<String, Object?>>(
            id: 'progress',
            key: 'upload',
            data: {
              'value': 0.5,
            },
          ),
          const StepBoundaryUiPart('step-1'),
        ],
        metadata: {
          ChatUiMetadataKeys.warnings: const [
            ModelWarning(
              type: ModelWarningType.compatibility,
              message: 'warning',
            ),
          ],
          ChatUiMetadataKeys.responseId: 'resp-1',
          ChatUiMetadataKeys.responseTimestamp: timestamp,
          ChatUiMetadataKeys.modelId: 'gpt-4.1-mini',
          ChatUiMetadataKeys.responseProviderMetadata: const ProviderMetadata({
            'openai': {
              'provider': 'openai',
            },
          }),
          ChatUiMetadataKeys.finishReason: FinishReason.stop,
          ChatUiMetadataKeys.rawFinishReason: 'STOP',
          ChatUiMetadataKeys.usage: const UsageStats(
            inputTokens: 10,
            outputTokens: 5,
            totalTokens: 15,
          ),
          ChatUiMetadataKeys.finishProviderMetadata: const ProviderMetadata({
            'openai': {
              'finish': 'ok',
            },
          }),
          ChatUiMetadataKeys.errors: const [
            ModelError(
              kind: ModelErrorKind.provider,
              message: 'soft-error',
              code: 'soft-error',
            ),
          ],
          ChatUiMetadataKeys.rawChunks: const [
            {'chunk': 1},
          ],
        },
      );

      final mapped = mapper.map(message);

      expect(mapped.message, same(message));
      expect(mapped.text, 'Hello world');
      expect(mapped.hasStreamingText, isTrue);
      expect(mapped.reasoningText, 'Plan first.');
      expect(mapped.hasStreamingReasoning, isFalse);
      expect(mapped.toolParts.single.toolName, 'weather');
      expect(mapped.sources.single.sourceId, 'source-1');
      expect(mapped.fileParts.single.file.filename, 'guide.pdf');
      expect(
        mapped.reasoningFileParts.single.file.filename,
        'thought.png',
      );
      expect(mapped.customParts.single.kind, 'provider.custom');
      expect(mapped.dataParts.single.key, 'upload');
      expect(mapped.stepIds, ['step-1']);
      expect(mapped.warnings.single.message, 'warning');
      expect(mapped.responseId, 'resp-1');
      expect(mapped.responseTimestamp, timestamp);
      expect(mapped.modelId, 'gpt-4.1-mini');
      expect(
        mapped.responseProviderMetadata!.namespace('openai'),
        containsPair('provider', 'openai'),
      );
      expect(mapped.finishReason, FinishReason.stop);
      expect(mapped.rawFinishReason, 'STOP');
      expect(mapped.usage!.totalTokens, 15);
      expect(
        mapped.finishProviderMetadata!.namespace('openai'),
        containsPair('finish', 'ok'),
      );
      expect(mapped.errors.single.message, 'soft-error');
      expect(mapped.rawChunks, [
        {'chunk': 1},
      ]);
      expect(mapped.hasWarnings, isTrue);
      expect(mapped.hasErrors, isTrue);
      expect(mapped.hasToolParts, isTrue);
      expect(mapped.hasSources, isTrue);
      expect(mapped.hasFiles, isTrue);
    });

    test('maps lists of messages in order and defaults missing metadata', () {
      const mapper = ChatMessageMapper();
      final messages = [
        ChatUiMessage(
          id: 'user-1',
          role: ChatUiRole.user,
          parts: const [
            TextUiPart(text: 'Hello'),
          ],
        ),
        ChatUiMessage(
          id: 'assistant-1',
          role: ChatUiRole.assistant,
          parts: const [
            ReasoningUiPart(text: 'Thinking'),
          ],
        ),
      ];

      final mapped = mapper.mapMessages(messages);

      expect(mapped, hasLength(2));
      expect(mapped.first.text, 'Hello');
      expect(mapped.first.warnings, isEmpty);
      expect(mapped.first.errors, isEmpty);
      expect(mapped.last.reasoningText, 'Thinking');
      expect(mapped.last.responseId, isNull);
    });
  });
}
