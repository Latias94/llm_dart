import 'package:test/test.dart';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

class _FakeToolCatalogModel extends ChatCapability
    implements ChatStreamPartsCapability {
  var _step = 0;

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    if (_step == 0) {
      _step++;
      expect(tools, isNotNull);
      expect(tools, isEmpty);

      yield const LLMProviderToolResultPart(
        toolCallId: 'srvtoolu_1',
        toolName: 'tool_search',
        result: [
          {'type': 'tool_reference', 'toolName': 'get_weather'}
        ],
      );

      yield const LLMToolCallStartPart(
        const V3ToolCall(
          toolCallId: 'call_1',
          toolName: 'get_weather',
          input: '',
        ),
      );
      yield const LLMToolCallDeltaPart(
        const V3ToolCall(
          toolCallId: 'call_1',
          toolName: 'get_weather',
          input: '{"location":"San Francisco"}',
        ),
      );
      yield LLMFinishPart(_FakeStreamResponse());
      return;
    }

    _step++;
    expect(
      tools?.any((t) => t.function.name == 'get_weather'),
      isTrue,
      reason: 'tool loop should hydrate tool definitions from catalog',
    );

    yield const LLMTextStartPart();
    yield const LLMTextDeltaPart('done');
    yield const LLMTextEndPart('done');
    yield LLMFinishPart(_FakeStreamResponse());
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) {
    throw StateError('Should not be called for ChatStreamPartsCapability.');
  }
}

class _FakeStreamResponse extends ChatResponse {
  @override
  String? get text => null;

  @override
  List<ToolCall>? get toolCalls => null;
}

void main() {
  group('ToolCatalog hydration', () {
    test('hydrates missing tool schema + handler before executing tool calls',
        () async {
      final model = _FakeToolCatalogModel();
      var handlerCalls = 0;

      final catalog = ToolSetCatalog(
        ToolSet([
          LocalTool(
            tool: Tool.function(
              name: 'get_weather',
              description: 'Get weather',
              inputSchema: Schema.params(
                properties: {
                  'location': Schema.string('location'),
                },
                required: ['location'],
              ),
            ),
            handler: (input, options) async {
              handlerCalls++;
              return {'tempC': 20};
            },
          ),
        ]),
      );

      final parts = await streamToolLoopParts(
        model: model,
        messages: [ChatMessage.user('hi')],
        tools: const [],
        toolHandlers: const {},
        toolCatalog: catalog,
      ).toList();

      expect(handlerCalls, equals(1));

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals('done'));
    });
  });
}
