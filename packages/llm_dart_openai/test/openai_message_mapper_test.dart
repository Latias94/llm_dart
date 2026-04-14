import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIMessageMapper', () {
    test('maps custom OpenAI UI parts and provider metadata', () {
      final message = ChatUiMessage(
        id: 'msg_1',
        role: ChatUiRole.assistant,
        parts: const [
          CustomUiPart(
            kind: OpenAIMcpListToolsCustomPart.customKind,
            data: {
              'id': 'mcp_tools_1',
              'server_label': 'zip1',
              'tools': [
                {'name': 'create_short_url'},
              ],
            },
          ),
        ],
        metadata: {
          ChatUiMetadataKeys.responseProviderMetadata: ProviderMetadata({
            'openai': {
              'serviceTier': 'default',
            },
          }),
          ChatUiMetadataKeys.finishProviderMetadata: ProviderMetadata({
            'openai': {
              'status': 'completed',
            },
          }),
        },
      );

      final mapped = const OpenAIMessageMapper().map(message);

      expect(mapped.customParts, hasLength(1));
      expect(mapped.customParts.single, isA<OpenAIMcpListToolsCustomPart>());
      expect(mapped.customPartSummaries, hasLength(1));
      expect(mapped.customPartSummaries.single.subtitle, 'Available Tools');
      expect(mapped.responseMetadata, containsPair('serviceTier', 'default'));
      expect(mapped.finishMetadata, containsPair('status', 'completed'));
      expect(mapped.hasOpenAIMetadata, isTrue);
    });

    test('extracts OpenAI part metadata across shared UI parts', () {
      final responseLogprobs = [
        {
          'token': 'Hello',
          'logprob': -0.1,
        },
      ];

      final message = ChatUiMessage(
        id: 'msg_2',
        role: ChatUiRole.assistant,
        parts: [
          const ReasoningUiPart(
            text: 'Plan first.',
            providerMetadata: ProviderMetadata({
              'openai': {
                'responseId': 'resp_1',
                'itemId': 'rs_1',
                'summaryIndex': 0,
              },
            }),
          ),
          TextUiPart(
            text: 'Hello world.',
            providerMetadata: ProviderMetadata({
              'openai': {
                'responseId': 'resp_1',
                'itemId': 'msg_1',
                'outputIndex': 1,
                'contentIndex': 0,
                'logprobs': responseLogprobs,
              },
            }),
          ),
          const ToolUiPart(
            toolCallId: 'call_1',
            toolName: 'weather',
            state: ToolUiPartState.inputAvailable,
            callProviderMetadata: ProviderMetadata({
              'openai': {
                'responseId': 'resp_1',
                'itemId': 'fc_1',
                'itemType': 'function_call',
                'toolIndex': 2,
              },
            }),
          ),
          SourceUiPart(
            SourceReference(
              kind: SourceReferenceKind.document,
              sourceId: 'file_1',
              title: 'Spec',
              providerMetadata: const ProviderMetadata({
                'openai': {
                  'annotationType': 'file_citation',
                  'fileId': 'file_1',
                },
              }),
            ),
          ),
          const CustomUiPart(
            kind: OpenAIImageGenerationPartialCustomPart.customKind,
            data: {
              'item_id': 'img_1',
              'output_index': 1,
              'partial_image_b64': 'AQID',
            },
            providerMetadata: ProviderMetadata({
              'openai': {
                'responseId': 'resp_1',
                'itemId': 'img_1',
                'itemType': 'image_generation_call.partial_image',
                'outputIndex': 1,
                'serviceTier': 'default',
              },
            }),
          ),
        ],
      );

      final mapped = const OpenAIMessageMapper().map(message);

      expect(mapped.partDetails, hasLength(5));
      expect(mapped.hasOpenAIMetadata, isTrue);
      expect(mapped.hasLogprobs, isTrue);

      final reasoningDetail = mapped.partDetails[0];
      expect(reasoningDetail.type, OpenAIUiPartType.reasoning);
      expect(reasoningDetail.itemId, 'rs_1');
      expect(reasoningDetail.summaryIndex, 0);

      final textDetail = mapped.partDetails[1];
      expect(textDetail.type, OpenAIUiPartType.text);
      expect(textDetail.itemId, 'msg_1');
      expect(textDetail.outputIndex, 1);
      expect(textDetail.contentIndex, 0);
      expect(textDetail.logprobs, responseLogprobs);

      final toolDetail = mapped.partDetails[2];
      expect(toolDetail.type, OpenAIUiPartType.tool);
      expect(toolDetail.itemType, 'function_call');
      expect(toolDetail.toolIndex, 2);
      expect(toolDetail.toolCallId, 'call_1');

      final sourceDetail = mapped.partDetails[3];
      expect(sourceDetail.type, OpenAIUiPartType.source);
      expect(sourceDetail.annotationType, 'file_citation');
      expect(sourceDetail.fileId, 'file_1');
      expect(sourceDetail.sourceId, 'file_1');

      final customDetail = mapped.partDetails[4];
      expect(customDetail.type, OpenAIUiPartType.custom);
      expect(customDetail.itemId, 'img_1');
      expect(customDetail.itemType, 'image_generation_call.partial_image');
      expect(customDetail.outputIndex, 1);
      expect(customDetail.serviceTier, 'default');

      expect(mapped.customParts, hasLength(1));
      expect(
        mapped.customPartSummaries.single.title,
        'Image Generation',
      );
      expect(
        mapped.customPartSummaries.single.subtitle,
        'Partial Image',
      );
    });

    test('can compose shared and provider-specific mappings in one call', () {
      final message = ChatUiMessage(
        id: 'msg_3',
        role: ChatUiRole.assistant,
        parts: const [
          TextUiPart(
            text: 'Hello',
            providerMetadata: ProviderMetadata({
              'openai': {
                'responseId': 'resp_2',
                'itemId': 'msg_2',
              },
            }),
          ),
          CustomUiPart(
            kind: OpenAIMcpListToolsCustomPart.customKind,
            data: {
              'id': 'mcp_tools_2',
              'server_label': 'workspace',
              'tools': [
                {'name': 'open_browser'},
              ],
            },
          ),
        ],
      );

      final composed = const OpenAIMessageMapper().mapComposed(message);

      expect(composed.shared.text, 'Hello');
      expect(composed.shared.customParts, hasLength(1));
      expect(composed.provider.partDetails.single.itemId, 'msg_2');
      expect(
        composed.provider.customPartSummaries.single.subtitle,
        'Available Tools',
      );
    });
  });
}
