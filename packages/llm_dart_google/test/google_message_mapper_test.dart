import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:test/test.dart';

void main() {
  group('GoogleMessageMapper', () {
    test('extracts Google part metadata and custom summaries from a UI message',
        () {
      final message = ChatUiMessage(
        id: 'msg-1',
        role: ChatUiRole.assistant,
        parts: [
          const ReasoningUiPart(
            text: 'Plan first.',
            providerMetadata: ProviderMetadata({
              'google': {
                'thoughtSignature': 'sig_reasoning',
                'thought': true,
              },
            }),
          ),
          const TextUiPart(
            text: 'Visible answer.',
            providerMetadata: ProviderMetadata({
              'google': {
                'thoughtSignature': 'sig_text',
                'responsePart': 'visible_text',
              },
            }),
          ),
          SourceUiPart(
            SourceReference(
              kind: SourceReferenceKind.url,
              sourceId: 'https://example.com',
              uri: Uri.parse('https://example.com'),
              title: 'Example',
              providerMetadata: const ProviderMetadata({
                'google': {
                  'chunkType': 'web',
                },
              }),
            ),
          ),
          const FileUiPart(
            GeneratedFile(
              mediaType: 'application/pdf',
              filename: 'report.pdf',
              data: FileBytesData.constBytes([1, 2, 3]),
            ),
            providerMetadata: ProviderMetadata({
              'google': {
                'fileId': 'file_pdf_1',
              },
            }),
          ),
          GoogleToolCallReplay.fromToolCall(
            {
              'id': 'srvtool_1',
              'toolType': 'google_search',
              'query': 'Dart SDK',
            },
            providerMetadata: const ProviderMetadata({
              'google': {
                'thoughtSignature': 'sig_srvtool_1',
              },
            }),
          ).toCustomUiPart(),
          GoogleToolResponseReplay.fromToolResponse(
            {
              'id': 'srvtool_1',
              'toolType': 'google_search',
              'result': {
                'items': [
                  {
                    'uri': 'https://dart.dev',
                    'title': 'Dart',
                  },
                ],
              },
            },
          ).toCustomUiPart(),
        ],
        metadata: const {
          ChatUiMetadataKeys.responseProviderMetadata: ProviderMetadata({
            'google': {
              'candidateId': 'candidate_1',
            },
          }),
          ChatUiMetadataKeys.finishProviderMetadata: ProviderMetadata({
            'google': {
              'finishMessage': 'done',
            },
          }),
        },
      );

      final mapped = const GoogleMessageMapper().map(message);

      expect(mapped.hasGoogleMetadata, isTrue);
      expect(mapped.hasThoughtSignatures, isTrue);
      expect(mapped.partDetails, hasLength(6));
      expect(mapped.customParts, hasLength(2));
      expect(mapped.customPartSummaries, hasLength(2));
      expect(mapped.customPartSummaries.first.title, 'Google Search');
      expect(mapped.customPartSummaries.first.subtitle, 'Server Tool Call');
      expect(mapped.responseMetadata, {
        'candidateId': 'candidate_1',
      });
      expect(mapped.finishMetadata, {
        'finishMessage': 'done',
      });

      final reasoningDetail = mapped.partDetails[0];
      expect(reasoningDetail.type, GoogleUiPartType.reasoning);
      expect(reasoningDetail.thoughtSignature, 'sig_reasoning');
      expect(reasoningDetail.thought, isTrue);

      final textDetail = mapped.partDetails[1];
      expect(textDetail.type, GoogleUiPartType.text);
      expect(textDetail.responsePart, 'visible_text');

      final sourceDetail = mapped.partDetails[2];
      expect(sourceDetail.type, GoogleUiPartType.source);
      expect(sourceDetail.sourceId, 'https://example.com');
      expect(sourceDetail.chunkType, 'web');

      final fileDetail = mapped.partDetails[3];
      expect(fileDetail.type, GoogleUiPartType.file);
      expect(fileDetail.fileId, 'file_pdf_1');

      final customDetail = mapped.partDetails[4];
      expect(customDetail.type, GoogleUiPartType.custom);
      expect(customDetail.serverToolPart, 'toolCall');
      expect(customDetail.toolCallId, 'srvtool_1');
      expect(customDetail.toolType, 'google_search');
    });

    test('ignores messages without Google metadata or Google custom parts', () {
      final message = ChatUiMessage(
        id: 'msg-1',
        role: ChatUiRole.assistant,
        parts: const [
          TextUiPart(text: 'Hello'),
          CustomUiPart(
            kind: 'openai.compaction',
            data: {
              'id': 'cmp_1',
            },
          ),
        ],
      );

      final mapped = const GoogleMessageMapper().map(message);

      expect(mapped.hasGoogleMetadata, isFalse);
      expect(mapped.partDetails, isEmpty);
      expect(mapped.customParts, isEmpty);
      expect(mapped.customPartSummaries, isEmpty);
      expect(mapped.responseMetadata, isNull);
      expect(mapped.finishMetadata, isNull);
    });

    test('maps multiple messages in order', () {
      final messages = [
        ChatUiMessage(
          id: 'msg-1',
          role: ChatUiRole.assistant,
          parts: const [
            TextUiPart(
              text: 'Hello',
              providerMetadata: ProviderMetadata({
                'google': {
                  'responsePart': 'visible_text',
                },
              }),
            ),
          ],
        ),
        ChatUiMessage(
          id: 'msg-2',
          role: ChatUiRole.assistant,
          parts: [
            GoogleFunctionResponseReplay(
              toolCallId: 'call_google_2',
              toolName: 'render_chart',
              response: {
                'status': 'ok',
              },
            ).toCustomUiPart(),
          ],
        ),
      ];

      final mapped = const GoogleMessageMapper().mapMessages(messages);

      expect(mapped, hasLength(2));
      expect(mapped.first.partDetails.single.responsePart, 'visible_text');
      expect(
        mapped.last.customPartSummaries.single.subtitle,
        'Function Response',
      );
    });

    test('can compose shared and provider-specific mappings in one call', () {
      final message = ChatUiMessage(
        id: 'msg-3',
        role: ChatUiRole.assistant,
        parts: [
          const TextUiPart(
            text: 'Visible answer.',
            providerMetadata: ProviderMetadata({
              'google': {
                'responsePart': 'visible_text',
              },
            }),
          ),
          GoogleToolCallReplay.fromToolCall({
            'id': 'srvtool_2',
            'toolType': 'google_search',
            'query': 'Flutter',
          }).toCustomUiPart(),
        ],
      );

      final composed = const GoogleMessageMapper().mapComposed(message);

      expect(composed.shared.text, 'Visible answer.');
      expect(composed.shared.customParts, hasLength(1));
      expect(
        composed.provider.partDetails
            .firstWhere((detail) => detail.type == GoogleUiPartType.text)
            .responsePart,
        'visible_text',
      );
      expect(
        composed.provider.customPartSummaries.single.subtitle,
        'Server Tool Call',
      );
    });
  });
}
