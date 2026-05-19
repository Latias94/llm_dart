import 'package:llm_dart_anthropic/src/anthropic_content_encoder.dart';
import 'package:llm_dart_anthropic/src/anthropic_file_source_encoder.dart';
import 'package:llm_dart_anthropic/src/anthropic_prompt_blocks.dart';
import 'package:llm_dart_anthropic/src/anthropic_tool_replay_encoder.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic prompt limitations', () {
    test('rejects unsupported system, user, and tool prompt parts', () {
      expect(
        () => const AnthropicPromptBlockEncoder().encode(
          [
            SystemPromptMessage(
              parts: [
                FilePromptPart(
                  mediaType: 'text/plain',
                  data: FileTextData('system file'),
                ),
              ],
            ),
            UserPromptMessage.text('Hi'),
          ],
          warnings: <ModelWarning>[],
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            allOf(
              contains('Anthropic system prompt messages'),
              contains('FilePromptPart'),
            ),
          ),
        ),
      );

      expect(
        () => const AnthropicContentEncoder().encodeUserPart(
          const ReasoningPromptPart('hidden reasoning'),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            allOf(
              contains('Anthropic user prompt messages'),
              contains('ReasoningPromptPart'),
            ),
          ),
        ),
      );

      expect(
        () => const AnthropicToolReplayEncoder()
            .encodeToolReplayParts(const TextPromptPart('tool text'))
            .toList(),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            allOf(
              contains('Anthropic tool prompt messages'),
              contains('TextPromptPart'),
            ),
          ),
        ),
      );
    });

    test('rejects unsupported user document media types', () {
      expect(
        () => const AnthropicContentEncoder().encodeUserPart(
          FilePromptPart(
            mediaType: 'text/markdown',
            data: const FileTextData('# Notes'),
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            allOf(
              contains('Anthropic user document prompt parts'),
              contains('text/markdown'),
            ),
          ),
        ),
      );
    });

    test('centralizes assistant replay warning fields', () {
      final warnings = <ModelWarning>[];

      final prompt = const AnthropicPromptBlockEncoder().encode(
        [
          UserPromptMessage.text('Hi'),
          AssistantPromptMessage(
            parts: const [
              ReasoningPromptPart('hidden reasoning'),
              FilePromptPart(
                mediaType: 'application/pdf',
                data: FileBytesData.constBytes([1, 2, 3]),
              ),
              ReasoningFilePromptPart(
                mediaType: 'image/png',
                data: FileBytesData.constBytes([4, 5, 6]),
              ),
              CustomPromptPart(
                kind: 'openai.compaction',
                data: {
                  'type': 'compaction',
                },
              ),
            ],
          ),
          UserPromptMessage.text('Continue'),
        ],
        warnings: warnings,
      );

      expect(
        prompt.messages,
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'Hi',
              },
            ],
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'Continue',
              },
            ],
          },
        ],
      );
      expect(
        warnings.map((warning) => warning.field),
        [
          'assistant.reasoning',
          'assistant.file',
          'assistant.reasoningFile',
          'assistant.custom',
        ],
      );
      expect(
        warnings.map((warning) => warning.type).toSet(),
        {ModelWarningType.unsupported},
      );
      expect(
        warnings.last.message,
        contains('custom part "openai.compaction"'),
      );
    });

    test('rejects unsupported file source data shapes', () {
      expect(
        () => const AnthropicFileSourceEncoder().encodeUserBinarySource(
          mediaType: 'image/png',
          data: const FileTextData('not bytes'),
          path: 'user.image',
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            allOf(
              contains('Anthropic user.image requires in-memory bytes'),
              contains('Anthropic provider reference'),
            ),
          ),
        ),
      );

      expect(
        () => const AnthropicFileSourceEncoder().encodeUserTextDocumentSource(
          data: FileUrlData(Uri.parse('file:///tmp/notes.txt')),
          path: 'user.document',
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            allOf(
              contains('Anthropic text document prompt parts'),
              contains('HTTP/HTTPS URI'),
            ),
          ),
        ),
      );
    });

    test('rejects unsupported tool output file media and image text data', () {
      expect(
        () => const AnthropicFileSourceEncoder().encodeToolOutputFileBlock(
          mediaType: 'application/octet-stream',
          filename: 'archive.bin',
          data: const FileBytesData.constBytes([1, 2, 3]),
          path: 'toolResult(toolu_1).output.parts[0]',
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            allOf(
              contains('Anthropic tool output file parts'),
              contains('application/octet-stream'),
            ),
          ),
        ),
      );

      expect(
        () => const AnthropicFileSourceEncoder().encodeToolOutputFileBlock(
          mediaType: 'image/png',
          filename: 'image.png',
          data: const FileTextData('not image bytes'),
          path: 'toolResult(toolu_1).output.parts[1]',
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            allOf(
              contains('Anthropic tool output image parts'),
              contains('in-memory bytes'),
            ),
          ),
        ),
      );
    });
  });
}
