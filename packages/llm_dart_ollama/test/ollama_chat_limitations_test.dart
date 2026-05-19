import 'package:llm_dart_ollama/src/ollama_chat_binary_part_encoder.dart';
import 'package:llm_dart_ollama/src/ollama_chat_prompt_projection.dart';
import 'package:llm_dart_ollama/src/ollama_chat_request_options_policy.dart';
import 'package:llm_dart_ollama/src/ollama_generate_text_options.dart';
import 'package:llm_dart_ollama/src/ollama_tool_codec.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('Ollama chat limitations', () {
    test('rejects unsupported prompt parts by role', () async {
      final codec = const OllamaChatPromptProjectionCodec();

      await expectLater(
        () => codec.encodePromptMessage(
          SystemPromptMessage(
            parts: [
              FilePromptPart(
                mediaType: 'text/plain',
                data: const FileTextData('system file'),
              ),
            ],
          ),
          binaryEncoder: const OllamaChatBinaryPartEncoder(),
          warnings: <ModelWarning>[],
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('Ollama system prompt part'),
              contains('FilePromptPart'),
            ),
          ),
        ),
      );

      await expectLater(
        () => codec.encodePromptMessage(
          UserPromptMessage(
            parts: [
              FilePromptPart(
                mediaType: 'application/pdf',
                data: const FileBytesData.constBytes([1, 2, 3]),
              ),
            ],
          ),
          binaryEncoder: const OllamaChatBinaryPartEncoder(),
          warnings: <ModelWarning>[],
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            contains('only supports image multimodal file prompt parts'),
          ),
        ),
      );

      await expectLater(
        () => codec.encodePromptMessage(
          AssistantPromptMessage(
            parts: [
              FilePromptPart(
                mediaType: 'text/plain',
                data: const FileTextData('assistant file'),
              ),
            ],
          ),
          binaryEncoder: const OllamaChatBinaryPartEncoder(),
          warnings: <ModelWarning>[],
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('Ollama assistant prompt part'),
              contains('FilePromptPart'),
            ),
          ),
        ),
      );

      await expectLater(
        () => codec.encodePromptMessage(
          ToolPromptMessage(
            toolName: 'weather',
            parts: const [
              TextPromptPart('tool text'),
            ],
          ),
          binaryEncoder: const OllamaChatBinaryPartEncoder(),
          warnings: <ModelWarning>[],
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('Ollama tool prompt part'),
              contains('TextPromptPart'),
            ),
          ),
        ),
      );
    });

    test('keeps reasoning and tool-error replay compatibility warnings stable',
        () async {
      final warnings = <ModelWarning>[];
      final codec = const OllamaChatPromptProjectionCodec();

      final messages = await codec.encodePrompt(
        prompt: [
          SystemPromptMessage(
            parts: const [
              TextPromptPart('Rules'),
              ReasoningPromptPart('System reasoning'),
            ],
          ),
          UserPromptMessage(
            parts: const [
              TextPromptPart('Hi'),
              ReasoningPromptPart('User reasoning'),
            ],
          ),
          ToolPromptMessage(
            toolName: 'weather',
            parts: [
              ToolResultPromptPart(
                toolCallId: 'tool-1',
                toolName: 'weather',
                output: {'error': 'timeout'},
                isError: true,
              ),
              ToolResultPromptPart(
                toolCallId: 'tool-2',
                toolName: 'weather',
                output: {'error': 'again'},
                isError: true,
              ),
            ],
          ),
        ],
        binaryEncoder: const OllamaChatBinaryPartEncoder(),
        warnings: warnings,
      );

      expect(
        messages,
        [
          {
            'role': 'system',
            'content': 'Rules\nSystem reasoning',
          },
          {
            'role': 'user',
            'content': 'Hi\nUser reasoning',
          },
          {
            'role': 'tool',
            'tool_name': 'weather',
            'content': '{"error":"timeout"}',
          },
          {
            'role': 'tool',
            'tool_name': 'weather',
            'content': '{"error":"again"}',
          },
        ],
      );
      expect(
        warnings.map((warning) => warning.field),
        [
          'prompt',
          'prompt',
          'prompt',
        ],
      );
      expect(
        warnings.where(
          (warning) => warning.message.contains('tool error state'),
        ),
        hasLength(1),
      );
    });

    test('reports binary prompt part resolver limitations', () async {
      await expectLater(
        () => const OllamaChatBinaryPartEncoder().resolveBytes(
          mediaType: 'image/png',
          uri: null,
          bytes: null,
          promptPartKind: 'image',
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('Ollama image prompt parts require bytes'),
              contains('OllamaBinaryResolver'),
            ),
          ),
        ),
      );

      await expectLater(
        () => const OllamaChatBinaryPartEncoder().resolveBytes(
          mediaType: 'image/png',
          uri: Uri.parse('https://example.test/cat.png'),
          bytes: null,
          promptPartKind: 'image',
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('cannot encode URI https://example.test/cat.png'),
              contains('OllamaBinaryResolver'),
            ),
          ),
        ),
      );
    });

    test('centralizes toolChoice and shared option warnings', () {
      final toolWarnings = <ModelWarning>[];
      final tools = const OllamaToolCodec().encodeToolDefinitions(
        tools: [
          FunctionToolDefinition(
            name: 'weather',
            inputSchema: ToolJsonSchema.object(),
          ),
        ],
        toolChoice: const SpecificToolChoice('weather'),
        warnings: toolWarnings,
      );

      expect(tools, hasLength(1));
      expect(toolWarnings.single.field, 'toolChoice');

      final optionWarnings = <ModelWarning>[];
      final projection = const OllamaChatRequestOptionsPolicy().project(
        options: GenerateTextOptions(
          frequencyPenalty: 0.2,
          presencePenalty: 0.1,
          reasoning: GenerateTextReasoningOptions.enabled(
            effort: ReasoningEffort.low,
            budgetTokens: 128,
          ),
          responseFormat: JsonResponseFormat(
            schema: JsonSchema.object(),
            name: 'answer',
          ),
        ),
        providerOptions: const OllamaGenerateTextOptions(reasoning: false),
        warnings: optionWarnings,
      );

      expect(projection.reasoning, isFalse);
      expect(
        optionWarnings.map((warning) => warning.field),
        [
          'options.reasoning.effort',
          'options.reasoning.budgetTokens',
          'options.reasoning',
          'options.frequencyPenalty',
          'options.presencePenalty',
          'options.responseFormat',
        ],
      );
    });
  });
}
