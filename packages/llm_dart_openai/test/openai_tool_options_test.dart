import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_openai/src/chat_completions/openai_chat_completions_request_tool_codec.dart';
import 'package:llm_dart_openai/src/responses/openai_responses_request_tool_projection.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIToolOptions', () {
    test('round-trips through its JSON codec', () {
      const codec = OpenAIToolOptionsJsonCodec();
      const options = OpenAIToolOptions(
        strict: false,
        deferLoading: true,
      );

      expect(codec.type, OpenAIToolOptionsJsonCodec.typeId);
      expect(codec.canEncode(options), isTrue);
      expect(codec.encode(options), {
        'strict': false,
        'deferLoading': true,
      });

      final decoded = codec.decode({
        'strict': false,
        'deferLoading': true,
      });

      expect(decoded.strict, isFalse);
      expect(decoded.deferLoading, isTrue);
      expect(
          openAIToolOptionsJsonCodec.type, OpenAIToolOptionsJsonCodec.typeId);
    });

    test('supports copyWith without forcing nullable fields to stay set', () {
      const options = OpenAIToolOptions(
        strict: true,
        deferLoading: true,
      );

      final copied = options.copyWith(strict: false, deferLoading: null);

      expect(copied.strict, isFalse);
      expect(copied.deferLoading, isNull);
    });
  });

  group('OpenAI function tool provider options', () {
    test('chat completions uses the per-tool strict override', () {
      const codec = OpenAIChatCompletionsRequestToolCodec();

      expect(
        codec.encodeTools([
          FunctionToolDefinition(
            name: 'weather',
            description: 'Get weather.',
            inputSchema: ToolJsonSchema.object(),
            strict: true,
            providerOptions: const OpenAIToolOptions(
              strict: false,
              deferLoading: true,
            ),
          ),
        ]),
        [
          {
            'type': 'function',
            'function': {
              'name': 'weather',
              'description': 'Get weather.',
              'parameters': {
                'type': 'object',
              },
              'strict': false,
            },
          },
        ],
      );
    });

    test('Responses uses strict override and Vercel-aligned defer_loading', () {
      const projection = OpenAIResponsesRequestToolProjection();

      expect(
        projection.encode(
          tools: [
            FunctionToolDefinition(
              name: 'weather',
              inputSchema: ToolJsonSchema.object(),
              strict: true,
              providerOptions: const OpenAIToolOptions(
                strict: false,
                deferLoading: true,
              ),
            ),
          ],
          builtInTools: null,
        ),
        [
          {
            'type': 'function',
            'name': 'weather',
            'parameters': {
              'type': 'object',
            },
            'strict': false,
            'defer_loading': true,
          },
        ],
      );
    });

    test('rejects non-OpenAI provider tool options', () {
      const codec = OpenAIChatCompletionsRequestToolCodec();

      expect(
        () => codec.encodeTools([
          FunctionToolDefinition(
            name: 'weather',
            inputSchema: ToolJsonSchema.object(),
            providerOptions: const _OtherToolOptions(),
          ),
        ]),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'tool.providerOptions')
              .having(
                (error) => error.message,
                'message',
                contains('Expected OpenAIToolOptions'),
              ),
        ),
      );
    });

    test('rejects OpenAI tool options on compatible provider profiles', () {
      final codec = OpenAIChatCompletionsRequestToolCodec.forProfile(
        const DeepSeekProfile(),
      );

      expect(
        () => codec.encodeTools([
          FunctionToolDefinition(
            name: 'weather',
            inputSchema: ToolJsonSchema.object(),
            providerOptions: const OpenAIToolOptions(strict: false),
          ),
        ]),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'tool.providerOptions')
              .having(
                (error) => error.message,
                'message',
                contains('not supported for deepseek function tool'),
              ),
        ),
      );
    });
  });
}

final class _OtherToolOptions implements ProviderToolOptions {
  const _OtherToolOptions();
}
