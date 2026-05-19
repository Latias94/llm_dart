import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_openai/src/openai_responses_assistant_prompt_projection.dart';
import 'package:llm_dart_openai/src/openai_responses_request_prompt_codec.dart';
import 'package:llm_dart_openai/src/openai_responses_replay_policy.dart';
import 'package:llm_dart_openai/src/openai_responses_tool_prompt_projection.dart';
import 'package:llm_dart_openai/src/openai_responses_user_part_encoder.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIResponsesPromptCodec', () {
    test('reports unsupported system prompt parts as provider limitations', () {
      const codec = OpenAIResponsesPromptCodec();
      final warnings = <ModelWarning>[];

      expect(
        () => codec.encodePromptMessage(
          SystemPromptMessage(
            parts: const [
              FilePromptPart(
                mediaType: 'text/plain',
                data: FileBytesData.constBytes([1, 2, 3]),
              ),
            ],
          ),
          warnings,
          systemMessageMode: OpenAISystemMessageMode.system,
          store: false,
          hasConversation: false,
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('OpenAI Responses system prompt messages'),
              contains('FilePromptPart'),
            ),
          ),
        ),
      );
      expect(warnings, isEmpty);
    });
  });

  group('OpenAIResponsesUserPartEncoder', () {
    test('encodes image file references and PDF bytes', () {
      const encoder = OpenAIResponsesUserPartEncoder();

      expect(
        encoder.encode(
          const FilePromptPart(
            mediaType: 'image/png',
            data: FileProviderReferenceData(
              ProviderReference({'openai': 'file-img-1'}),
            ),
            providerOptions: OpenAIPromptPartOptions(
              imageDetail: 'high',
            ),
          ),
          index: 0,
        ),
        {
          'type': 'input_image',
          'file_id': 'file-img-1',
          'detail': 'high',
        },
      );

      expect(
        encoder.encode(
          const FilePromptPart(
            mediaType: 'application/pdf',
            data: FileBytesData.constBytes([1, 2, 3]),
          ),
          index: 2,
        ),
        {
          'type': 'input_file',
          'filename': 'part-2.pdf',
          'file_data': 'data:application/pdf;base64,AQID',
        },
      );
    });

    test('encodes non-PDF OpenAI file references as input_file file_id', () {
      const encoder = OpenAIResponsesUserPartEncoder();

      expect(
        encoder.encode(
          const FilePromptPart(
            mediaType: 'text/plain',
            data: FileProviderReferenceData(
              ProviderReference({'openai': 'file-notes-1'}),
            ),
          ),
          index: 0,
        ),
        {
          'type': 'input_file',
          'file_id': 'file-notes-1',
        },
      );
    });

    test('encodes non-PDF file URLs as input_file file_url', () {
      const encoder = OpenAIResponsesUserPartEncoder();

      expect(
        encoder.encode(
          FilePromptPart(
            mediaType: 'text/plain',
            data: FileUrlData(
              Uri.parse('https://example.com/notes.txt'),
            ),
          ),
          index: 0,
        ),
        {
          'type': 'input_file',
          'file_url': 'https://example.com/notes.txt',
        },
      );
    });

    test('rejects non-PDF data files on the Responses user prompt path', () {
      const encoder = OpenAIResponsesUserPartEncoder();

      expect(
        () => encoder.encode(
          const FilePromptPart(
            mediaType: 'text/plain',
            data: FileBytesData.constBytes([1, 2, 3]),
          ),
          index: 0,
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('do not support in-memory file data'),
              contains('text/plain'),
            ),
          ),
        ),
      );
    });
  });

  group('OpenAIResponsesAssistantPromptProjection', () {
    const projection = OpenAIResponsesAssistantPromptProjection();

    test('groups assistant text with the same replay item metadata', () {
      final warnings = <ModelWarning>[];

      final items = projection.encode(
        AssistantPromptMessage(
          parts: const [
            TextPromptPart(
              'first',
              providerOptions: ProviderReplayPromptPartOptions(
                ProviderMetadata({
                  'openai': {
                    'itemId': 'msg_1',
                    'phase': 'final_answer',
                  },
                }),
              ),
            ),
            TextPromptPart(
              'second',
              providerOptions: ProviderReplayPromptPartOptions(
                ProviderMetadata({
                  'openai': {
                    'itemId': 'msg_1',
                    'phase': 'final_answer',
                  },
                }),
              ),
            ),
          ],
        ),
        warnings,
        replayPolicy: const OpenAIResponsesReplayPolicy(
          store: false,
          hasConversation: false,
        ),
      );

      expect(items, [
        {
          'role': 'assistant',
          'id': 'msg_1',
          'phase': 'final_answer',
          'content': [
            {
              'type': 'output_text',
              'text': 'first',
            },
            {
              'type': 'output_text',
              'text': 'second',
            },
          ],
        },
      ]);
      expect(warnings, isEmpty);
    });

    test('references stored reasoning item only once', () {
      final warnings = <ModelWarning>[];

      final items = projection.encode(
        AssistantPromptMessage(
          parts: const [
            ReasoningPromptPart(
              'step 1',
              providerOptions: ProviderReplayPromptPartOptions(
                ProviderMetadata({
                  'openai': {
                    'itemId': 'rs_1',
                    'reasoningEncryptedContent': 'enc_1',
                  },
                }),
              ),
            ),
            ReasoningPromptPart(
              'step 2',
              providerOptions: ProviderReplayPromptPartOptions(
                ProviderMetadata({
                  'openai': {
                    'itemId': 'rs_1',
                    'reasoningEncryptedContent': 'enc_2',
                  },
                }),
              ),
            ),
          ],
        ),
        warnings,
        replayPolicy: const OpenAIResponsesReplayPolicy(
          store: true,
          hasConversation: false,
        ),
      );

      expect(items, [
        {
          'type': 'item_reference',
          'id': 'rs_1',
        },
      ]);
      expect(warnings, isEmpty);
    });

    test('removes reasoning without encrypted content when store is false', () {
      final warnings = <ModelWarning>[];

      final items = projection.encode(
        AssistantPromptMessage(
          parts: const [
            ReasoningPromptPart(
              'step',
              providerOptions: ProviderReplayPromptPartOptions(
                ProviderMetadata({
                  'openai': {
                    'itemId': 'rs_1',
                  },
                }),
              ),
            ),
          ],
        ),
        warnings,
        replayPolicy: const OpenAIResponsesReplayPolicy(
          store: false,
          hasConversation: false,
        ),
      );

      expect(items, isEmpty);
      expect(warnings, hasLength(1));
      expect(warnings.single.field, 'prompt.assistant.reasoning');
      expect(
        warnings.single.message,
        contains('without encrypted content'),
      );
    });

    test('reports unsupported assistant prompt parts as provider limitations',
        () {
      final warnings = <ModelWarning>[];

      expect(
        () => projection.encode(
          AssistantPromptMessage(
            parts: const [
              ImagePromptPart(
                mediaType: 'image/png',
                data: FileBytesData.constBytes([1, 2, 3]),
              ),
            ],
          ),
          warnings,
          replayPolicy: const OpenAIResponsesReplayPolicy(
            store: false,
            hasConversation: false,
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('OpenAI Responses assistant prompt messages'),
              contains('ImagePromptPart'),
            ),
          ),
        ),
      );
      expect(warnings, isEmpty);
    });
  });

  group('OpenAIResponsesToolPromptProjection', () {
    test('adds approval references only when store is enabled', () {
      const projection = OpenAIResponsesToolPromptProjection();
      final message = ToolPromptMessage(
        toolName: 'mcp.create_short_url',
        parts: const [
          ToolApprovalResponsePromptPart(
            approvalId: 'approval_1',
            toolCallId: 'approval_1',
            approved: true,
          ),
        ],
      );

      expect(
        projection.encode(
          message,
          replayPolicy: const OpenAIResponsesReplayPolicy(
            store: true,
            hasConversation: false,
          ),
        ),
        [
          {
            'type': 'item_reference',
            'id': 'approval_1',
          },
          {
            'type': 'mcp_approval_response',
            'approval_request_id': 'approval_1',
            'approve': true,
          },
        ],
      );

      expect(
        projection.encode(
          message,
          replayPolicy: const OpenAIResponsesReplayPolicy(
            store: false,
            hasConversation: false,
          ),
        ),
        [
          {
            'type': 'mcp_approval_response',
            'approval_request_id': 'approval_1',
            'approve': true,
          },
        ],
      );
    });

    test('reports unsupported tool prompt parts as provider limitations', () {
      const projection = OpenAIResponsesToolPromptProjection();

      expect(
        () => projection.encode(
          ToolPromptMessage(
            toolName: 'weather',
            parts: const [
              TextPromptPart('unexpected'),
            ],
          ),
          replayPolicy: const OpenAIResponsesReplayPolicy(
            store: false,
            hasConversation: false,
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('OpenAI Responses tool prompt messages'),
              contains('TextPromptPart'),
            ),
          ),
        ),
      );
    });
  });
}
