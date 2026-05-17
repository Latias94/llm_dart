import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:llm_dart_google/src/google_assistant_prompt_projection.dart';
import 'package:llm_dart_google/src/google_binary_part_encoder.dart';
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
  });
}
