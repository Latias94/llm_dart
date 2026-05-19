import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:llm_dart_google/src/google_assistant_prompt_projection.dart';
import 'package:llm_dart_google/src/google_binary_part_encoder.dart';
import 'package:llm_dart_google/src/google_content_projection.dart';
import 'package:llm_dart_google/src/google_language_model_policy.dart';
import 'package:llm_dart_google/src/google_prompt_replay_metadata.dart';
import 'package:llm_dart_google/src/google_tool_prompt_projection.dart';
import 'package:llm_dart_google/src/google_user_prompt_projection.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('GoogleUserPromptProjection', () {
    test('encodes text and file references as Google binary parts', () {
      const projection = GoogleUserPromptProjection();

      expect(
        projection.encodePart(
          const TextPromptPart('hello'),
        ),
        {
          'text': 'hello',
        },
      );

      expect(
        projection.encodePart(
          FilePromptPart(
            mediaType: 'application/pdf',
            data: FileProviderReferenceData(
              ProviderReference({
                'google':
                    'https://generativelanguage.googleapis.com/v1beta/files/spec',
              }),
            ),
          ),
        ),
        {
          'fileData': {
            'mimeType': 'application/pdf',
            'fileUri':
                'https://generativelanguage.googleapis.com/v1beta/files/spec',
          },
        },
      );
    });

    test('encodes user text file data as inlineData', () {
      const projection = GoogleUserPromptProjection();

      expect(
        projection.encodePart(
          const FilePromptPart(
            mediaType: 'text/plain',
            data: FileTextData('hello'),
          ),
        ),
        {
          'inlineData': {
            'mimeType': 'text/plain',
            'data': 'aGVsbG8=',
          },
        },
      );
    });

    test('reports unsupported user prompt parts as provider limitations', () {
      const projection = GoogleUserPromptProjection();

      expect(
        () => projection.encodePart(
          const ReasoningPromptPart('hidden'),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('Google user prompt messages'),
              contains('ReasoningPromptPart'),
            ),
          ),
        ),
      );
    });
  });

  group('GoogleAssistantPromptProjection', () {
    const projection = GoogleAssistantPromptProjection();

    test('replays thought signatures and Gemini 3 function-call ids', () {
      final policy = const GoogleLanguageModelPolicy('gemini-3-pro-preview');
      final metadata = ProviderReplayPromptPartOptions(
        ProviderMetadata({
          'google': {
            'thoughtSignature': 'sig_1',
            'functionCallId': 'call_1',
          },
        }),
      );

      final encoded = projection.encodePart(
        ToolCallPromptPart(
          toolCallId: 'call_1',
          toolName: 'weather',
          input: {
            'city': 'Hong Kong',
          },
          providerOptions: metadata,
        ),
        policy: policy,
      );

      expect(
        encoded,
        {
          'functionCall': {
            'id': 'call_1',
            'name': 'weather',
            'args': {
              'city': 'Hong Kong',
            },
          },
          'thoughtSignature': 'sig_1',
        },
      );
    });

    test(
        'encodes Google tool response replay custom parts from provider metadata',
        () {
      final encoded = projection.encodePart(
        GoogleToolResponseReplay.fromToolResponse(
          {
            'id': 'call_2',
            'toolType': 'render_chart',
            'result': {
              'status': 'ok',
            },
          },
        ).toCustomPromptPart(),
        policy: const GoogleLanguageModelPolicy('gemini-2.5-flash'),
      );

      expect(
        encoded,
        {
          'toolResponse': {
            'id': 'call_2',
            'toolType': 'render_chart',
            'result': {
              'status': 'ok',
            },
          },
        },
      );
    });

    test('reports unsupported assistant prompt parts as provider limitations',
        () {
      expect(
        () => projection.encodePart(
          const ImagePromptPart(
            mediaType: 'image/png',
            data: FileBytesData.constBytes([1, 2, 3]),
          ),
          policy: const GoogleLanguageModelPolicy('gemini-2.5-flash'),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('Google assistant prompt messages'),
              contains('ImagePromptPart'),
            ),
          ),
        ),
      );
    });
  });

  group('GoogleToolPromptProjection', () {
    const projection = GoogleToolPromptProjection();

    test('replays function responses and preserves functionCallId on Gemini 3',
        () {
      final encoded = projection.encodePart(
        ToolResultPromptPart(
          toolCallId: 'call_3',
          toolName: 'weather',
          output: {
            'temperature': 28,
          },
          providerOptions: ProviderReplayPromptPartOptions(
            ProviderMetadata({
              'google': {
                'functionCallId': 'call_3',
              },
            }),
          ),
        ),
        policy: const GoogleLanguageModelPolicy('gemini-3-pro-preview'),
      );

      expect(
        encoded,
        {
          'functionResponse': {
            'id': 'call_3',
            'name': 'weather',
            'response': {
              'name': 'weather',
              'content': {
                'temperature': 28,
              },
            },
          },
        },
      );
    });

    test('encodes function response replay custom parts on Gemini 3', () {
      final encoded = projection.encodePart(
        GoogleFunctionResponseReplay(
          toolCallId: 'call_4',
          toolName: 'render_report',
          functionCallId: 'call_4',
          response: {
            'status': 'ok',
          },
        ).toCustomPromptPart(),
        policy: const GoogleLanguageModelPolicy('gemini-3-pro-preview'),
      );

      expect(
        encoded,
        {
          'functionResponse': {
            'id': 'call_4',
            'name': 'render_report',
            'response': {
              'status': 'ok',
            },
          },
        },
      );
    });

    test('reports unsupported tool prompt parts as provider limitations', () {
      expect(
        () => projection.encodePart(
          const TextPromptPart('unexpected'),
          policy: const GoogleLanguageModelPolicy('gemini-2.5-flash'),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('Google tool prompt messages'),
              contains('TextPromptPart'),
            ),
          ),
        ),
      );
    });
  });

  group('GoogleBinaryPartEncoder', () {
    const encoder = GoogleBinaryPartEncoder();

    test('encodes assistant inline bytes with thought metadata', () {
      expect(
        encoder.encodeAssistantInlineDataPart(
          mediaType: 'image/png',
          data: FileBytesData.constBytes([1, 2, 3]),
          metadata: const GooglePromptPartMetadata(
            thought: true,
            thoughtSignature: 'sig_4',
          ),
        ),
        {
          'inlineData': {
            'mimeType': 'image/png',
            'data': 'AQID',
          },
          'thought': true,
          'thoughtSignature': 'sig_4',
        },
      );
    });

    test('reports missing user binary data as provider limitations', () {
      expect(
        () => encoder.encodeUserBinaryPart(
          mediaType: 'application/pdf',
          data: null,
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            contains('require in-memory bytes, text, a URI'),
          ),
        ),
      );
    });

    test('reports unsupported assistant file data as provider limitations', () {
      expect(
        () => encoder.encodeAssistantInlineDataPart(
          mediaType: 'text/plain',
          data: const FileTextData('hello'),
          metadata: const GooglePromptPartMetadata(),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('assistant file prompt parts require in-memory bytes'),
              contains('provider references are not supported'),
            ),
          ),
        ),
      );
    });
  });

  group('GoogleContentProjectionCodec', () {
    test('reports unsupported system prompt parts as provider limitations', () {
      const codec = GoogleContentProjectionCodec();

      expect(
        () => codec.encodePrompt(
          modelId: 'gemini-2.5-flash',
          prompt: [
            SystemPromptMessage(
              parts: const [
                FilePromptPart(
                  mediaType: 'text/plain',
                  data: FileBytesData.constBytes([1, 2, 3]),
                ),
              ],
            ),
            UserPromptMessage.text('hello'),
          ],
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('Google system prompt messages'),
              contains('FilePromptPart'),
            ),
          ),
        ),
      );
    });
  });
}
