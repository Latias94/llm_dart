library;

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _CaptureToolsModel extends ChatCapability {
  List<Tool>? lastTools;

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async {
    lastTools = tools;
    return const _FakeChatResponse(text: 'ok');
  }
}

class _FakeChatResponse implements ChatResponse {
  @override
  final String? text;

  const _FakeChatResponse({this.text});

  @override
  String? get thinking => null;

  @override
  List<ToolCall>? get toolCalls => null;

  @override
  UsageInfo? get usage => null;

  @override
  Map<String, dynamic>? get providerMetadata => null;
}

void main() {
  group('AddToolInputExamplesMiddleware', () {
    test('appends examples to tool description and removes inputExamples',
        () async {
      final inner = _CaptureToolsModel();
      final wrapped = wrapLanguageModelWithMiddleware(
        inner,
        middlewares: [
          AddToolInputExamplesMiddleware(),
        ],
      );

      final tools = [
        Tool.function(
          name: 'testTool',
          description: 'Do a thing.',
          parameters: const ParametersSchema(
            schemaType: 'object',
            properties: {},
            required: [],
          ),
          inputExamples: const [
            {
              'input': {'foo': 'bar'}
            },
            {
              'input': {'x': 1}
            },
          ],
        ),
      ];

      await generateText(
        model: wrapped,
        messages: [ChatMessage.user('hi')],
        tools: tools,
      );

      expect(inner.lastTools, isNotNull);
      expect(inner.lastTools, hasLength(1));

      final transformed = inner.lastTools!.single;
      expect(transformed.inputExamples, isNull);
      expect(transformed.function.description, contains('Input Examples:'));
      expect(transformed.function.description, contains('{"foo":"bar"}'));
      expect(transformed.function.description, contains('{"x":1}'));
    });

    test('keeps inputExamples when remove=false', () async {
      final inner = _CaptureToolsModel();
      final wrapped = wrapLanguageModelWithMiddleware(
        inner,
        middlewares: [
          AddToolInputExamplesMiddleware(remove: false),
        ],
      );

      final tools = [
        Tool.function(
          name: 'testTool',
          description: '',
          parameters: const ParametersSchema(
            schemaType: 'object',
            properties: {},
            required: [],
          ),
          inputExamples: const [
            {
              'input': {'foo': 'bar'}
            },
          ],
        ),
      ];

      await generateText(
        model: wrapped,
        messages: [ChatMessage.user('hi')],
        tools: tools,
      );

      final transformed = inner.lastTools!.single;
      expect(transformed.inputExamples, isNotNull);
      expect(transformed.function.description, contains('Input Examples:'));
    });
  });
}
