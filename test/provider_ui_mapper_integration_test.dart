import 'package:llm_dart/chat.dart' as chat;
import 'package:llm_dart/google.dart' as google;
import 'package:llm_dart/openai.dart' as openai;
import 'package:test/test.dart';

void main() {
  group('Provider UI mapper integration', () {
    test('root entrypoints compose shared and OpenAI mappers', () {
      final message = chat.ChatUiMessage(
        id: 'assistant-openai-1',
        role: chat.ChatUiRole.assistant,
        parts: [
          chat.TextUiPart(
            text: 'Visible answer.',
            providerMetadata: chat.ProviderMetadata({
              'openai': {
                'responseId': 'resp_openai_1',
                'itemId': 'msg_openai_1',
                'contentIndex': 0,
                'logprobs': const [
                  {
                    'token': 'Visible',
                    'logprob': -0.1,
                  },
                ],
              },
            }),
          ),
          chat.SourceUiPart(
            chat.SourceReference(
              kind: chat.SourceReferenceKind.url,
              sourceId: 'source-openai-1',
              uri: Uri.parse('https://example.com/openai'),
              title: 'OpenAI Source',
              providerMetadata: const chat.ProviderMetadata({
                'openai': {
                  'annotationType': 'url_citation',
                },
              }),
            ),
          ),
          const chat.CustomUiPart(
            kind: openai.OpenAIImageGenerationPartialCustomPart.customKind,
            data: {
              'item_id': 'img_openai_1',
              'output_index': 0,
              'partial_image_b64': 'AQID',
            },
            providerMetadata: chat.ProviderMetadata({
              'openai': {
                'responseId': 'resp_openai_1',
                'itemId': 'img_openai_1',
                'itemType': 'image_generation_call.partial_image',
                'outputIndex': 0,
              },
            }),
          ),
        ],
        metadata: const {
          chat.ChatUiMetadataKeys.responseProviderMetadata:
              chat.ProviderMetadata({
            'openai': {
              'responseId': 'resp_openai_1',
              'serviceTier': 'default',
            },
          }),
        },
      );

      final shared = const chat.ChatMessageMapper().map(message);
      final provider = const openai.OpenAIMessageMapper().map(message);

      expect(shared.text, 'Visible answer.');
      expect(shared.sources.single.sourceId, 'source-openai-1');
      expect(
        shared.customParts.single.kind,
        openai.OpenAIImageGenerationPartialCustomPart.customKind,
      );
      expect(
        shared.responseProviderMetadata!.namespace('openai'),
        containsPair('serviceTier', 'default'),
      );

      expect(provider.hasOpenAIMetadata, isTrue);
      expect(provider.hasLogprobs, isTrue);
      expect(provider.responseMetadata,
          containsPair('responseId', 'resp_openai_1'));
      expect(provider.partDetails, hasLength(3));
      expect(provider.partDetails.first.type, openai.OpenAIUiPartType.text);
      expect(provider.partDetails.first.itemId, 'msg_openai_1');
      expect(provider.partDetails[1].type, openai.OpenAIUiPartType.source);
      expect(provider.partDetails[1].annotationType, 'url_citation');
      expect(provider.partDetails.last.type, openai.OpenAIUiPartType.custom);
      expect(
        provider.customPartSummaries.single.subtitle,
        'Partial Image',
      );
    });

    test('root entrypoints compose shared and Google mappers', () {
      final message = chat.ChatUiMessage(
        id: 'assistant-google-1',
        role: chat.ChatUiRole.assistant,
        parts: [
          const chat.ReasoningUiPart(
            text: 'Plan first.',
            providerMetadata: chat.ProviderMetadata({
              'google': {
                'thoughtSignature': 'sig_reasoning_1',
                'thought': true,
              },
            }),
          ),
          chat.SourceUiPart(
            chat.SourceReference(
              kind: chat.SourceReferenceKind.url,
              sourceId: 'https://example.com/google',
              uri: Uri.parse('https://example.com/google'),
              title: 'Google Source',
              providerMetadata: const chat.ProviderMetadata({
                'google': {
                  'chunkType': 'web',
                },
              }),
            ),
          ),
          google.GoogleToolCallReplay.fromToolCall(
            {
              'id': 'srvtool_google_1',
              'toolType': 'google_search',
              'query': 'Dart 3.5',
            },
            providerMetadata: const chat.ProviderMetadata({
              'google': {
                'thoughtSignature': 'sig_srvtool_google_1',
              },
            }),
          ).toCustomUiPart(),
        ],
        metadata: const {
          chat.ChatUiMetadataKeys.responseProviderMetadata:
              chat.ProviderMetadata({
            'google': {
              'candidateId': 'candidate_google_1',
            },
          }),
        },
      );

      final shared = const chat.ChatMessageMapper().map(message);
      final provider = const google.GoogleMessageMapper().map(message);

      expect(shared.reasoningText, 'Plan first.');
      expect(shared.sources.single.sourceId, 'https://example.com/google');
      expect(shared.customParts.single.kind, google.GoogleToolCallReplay.kind);
      expect(
        shared.responseProviderMetadata!.namespace('google'),
        containsPair('candidateId', 'candidate_google_1'),
      );

      expect(provider.hasGoogleMetadata, isTrue);
      expect(provider.hasThoughtSignatures, isTrue);
      expect(provider.responseMetadata,
          containsPair('candidateId', 'candidate_google_1'));
      expect(provider.partDetails, hasLength(3));
      expect(
          provider.partDetails.first.type, google.GoogleUiPartType.reasoning);
      expect(provider.partDetails.first.thoughtSignature, 'sig_reasoning_1');
      expect(provider.partDetails[1].type, google.GoogleUiPartType.source);
      expect(provider.partDetails[1].chunkType, 'web');
      expect(provider.partDetails.last.type, google.GoogleUiPartType.custom);
      expect(provider.partDetails.last.toolType, 'google_search');
      expect(
        provider.customPartSummaries.single.subtitle,
        'Server Tool Call',
      );
    });
  });
}
