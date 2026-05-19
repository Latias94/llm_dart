import 'package:llm_dart_anthropic/src/anthropic_tool_configuration.dart';
import 'package:llm_dart_anthropic/src/anthropic_tool_limitations.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic tool limitations', () {
    test('normalizes deferred names and reports compatibility warnings', () {
      final warnings = <ModelWarning>[];
      final configuration = resolveAnthropicToolConfiguration(
        tools: [
          FunctionToolDefinition(
            name: 'get_weather',
            inputSchema: ToolJsonSchema.object(),
          ),
          FunctionToolDefinition(
            name: 'get_forecast',
            inputSchema: ToolJsonSchema.object(),
          ),
        ],
        nativeTools: const [],
        toolChoice: const AutoToolChoice(),
        deferredToolNames: const [
          ' get_weather ',
          'get_weather',
          '',
          'missing_tool',
        ],
        functionToolOptions: const {},
        defaultEagerInputStreaming: false,
        toolsCacheControl: null,
        warnings: warnings,
      );

      expect(
        configuration.tools,
        [
          {
            'name': 'get_weather',
            'input_schema': {
              'type': 'object',
            },
            'defer_loading': true,
          },
          {
            'name': 'get_forecast',
            'input_schema': {
              'type': 'object',
            },
          },
        ],
      );

      expect(
        warnings.map((warning) => warning.field),
        everyElement('deferredToolNames'),
      );
      expect(
        warnings.map((warning) => warning.message),
        containsAll([
          contains('duplicates or empty values'),
          contains('Ignoring unknown names: missing_tool'),
          contains('without a tool-search native tool'),
        ]),
      );
    });

    test('allows deferred names when a tool-search native tool is present', () {
      final warnings = <ModelWarning>[];
      final deferredNames = resolveAnthropicDeferredToolNames(
        deferredToolNames: const ['get_weather'],
        commonToolNames: const {'get_weather'},
        nativeTools: const [
          AnthropicToolSearchRegexTool20251119(),
        ],
        warnings: warnings,
      );

      expect(deferredNames, {'get_weather'});
      expect(warnings, isEmpty);
    });

    test('normalizes function tool option names and warns for unknown tools',
        () {
      final warnings = <ModelWarning>[];
      final options = resolveAnthropicFunctionToolOptions(
        optionsByToolName: const {
          ' get_weather ': AnthropicFunctionToolOptions(
            eagerInputStreaming: true,
          ),
          '': AnthropicFunctionToolOptions(deferLoading: true),
          'missing_tool': AnthropicFunctionToolOptions(deferLoading: true),
        },
        commonToolNames: const {'get_weather'},
        warnings: warnings,
      );

      expect(options.keys, ['get_weather']);
      expect(options['get_weather']?.eagerInputStreaming, isTrue);
      expect(
        warnings.map((warning) => warning.field),
        everyElement('functionToolOptions'),
      );
      expect(
        warnings.map((warning) => warning.message),
        containsAll([
          contains('duplicate or empty tool names'),
          contains('Ignoring unknown names: missing_tool'),
        ]),
      );
    });

    test('rejects native or undeclared specific tool choice', () {
      expect(
        () => resolveAnthropicToolConfiguration(
          tools: [
            FunctionToolDefinition(
              name: 'get_weather',
              inputSchema: ToolJsonSchema.object(),
            ),
          ],
          nativeTools: const [
            AnthropicWebSearchTool20250305(),
          ],
          toolChoice: const SpecificToolChoice('web_search'),
          deferredToolNames: const [],
          functionToolOptions: const {},
          defaultEagerInputStreaming: false,
          toolsCacheControl: null,
          warnings: <ModelWarning>[],
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            contains('provider-owned Anthropic tool-selection surface'),
          ),
        ),
      );
    });

    test('rejects forced tool choice when extended thinking is enabled', () {
      expect(
        () => validateAnthropicThinkingCompatibleToolChoice(
          extendedThinking: true,
          toolChoice: const RequiredToolChoice(),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            contains('AutoToolChoice or NoneToolChoice'),
          ),
        ),
      );
    });
  });
}
