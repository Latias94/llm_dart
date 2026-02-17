library;

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _SequencedChatModel extends ChatCapability {
  final List<ChatResponse> responses;
  var _index = 0;

  _SequencedChatModel(this.responses);

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async {
    if (_index >= responses.length) {
      throw StateError('No more responses configured');
    }
    return responses[_index++];
  }
}

class _Response implements ChatResponseWithFinishReason {
  @override
  final String? text;

  @override
  final String? thinking;

  @override
  final List<ToolCall>? toolCalls;

  @override
  final UsageInfo? usage;

  @override
  final Map<String, dynamic>? providerMetadata;

  @override
  final LLMFinishReason? finishReason;

  const _Response({
    this.text,
    this.toolCalls,
    this.usage,
    this.finishReason,
  })  : thinking = null,
        providerMetadata = null;
}

void main() {
  group('Agent', () {
    test('streamText forwards providerTools', () async {
      final model = _CapturingProviderToolsStreamModel();
      final agent = Agent(model: model);

      final result = agent.streamText(
        messages: [ChatMessage.user('hi')],
        providerTools: const [ProviderTool(id: 'openai.web_search')],
      );

      await result.text;
      expect(model.lastProviderTools?.single.id, equals('openai.web_search'));
    });

    test('streamObject forwards providerTools and callOptions', () async {
      final model = _CapturingProviderToolsStreamObjectModel();
      final agent = Agent(model: model);

      final result = agent.streamObject(
        messages: [ChatMessage.user('hi')],
        schema: const ParametersSchema(
          schemaType: 'object',
          properties: {
            'answer': ParameterProperty(
              propertyType: 'string',
              description: 'answer',
            ),
          },
          required: ['answer'],
        ),
        providerTools: const [ProviderTool(id: 'openai.web_search')],
        callOptions: const LLMCallOptions(headers: {'x-test': '1'}),
      );

      final obj = await result.object;
      expect(obj['answer'], equals('ok'));
      expect(model.lastProviderTools?.single.id, equals('openai.web_search'));
      expect(model.lastCallOptions?.headers?['x-test'], equals('1'));
    });

    test('generateText(toolSet) runs tool loop and returns steps', () async {
      final model = _SequencedChatModel([
        _Response(
          toolCalls: const [
            ToolCall(
              id: 'call_1',
              callType: 'function',
              function:
                  FunctionCall(name: 'get_weather', arguments: '{"city":"SF"}'),
            ),
          ],
          finishReason: const LLMFinishReason(
            unified: LLMUnifiedFinishReason.toolCalls,
            raw: 'tool_calls',
          ),
        ),
        _Response(
          text: 'Done',
          usage: const UsageInfo(totalTokens: 3),
          finishReason: const LLMFinishReason(
            unified: LLMUnifiedFinishReason.stop,
            raw: 'stop',
          ),
        ),
      ]);

      final toolSet = ToolSet([
        functionTool(
          name: 'get_weather',
          description: 'weather',
          parameters: const ParametersSchema(
            schemaType: 'object',
            properties: {
              'city': ParameterProperty(
                propertyType: 'string',
                description: 'city',
              ),
            },
            required: ['city'],
          ),
          handler: (input, options) => {'temp': 70},
        ),
      ]);

      final agent = Agent(model: model, toolSet: toolSet, maxSteps: 3);
      final result = await agent.generateText(prompt: 'hi');

      expect(result.steps, hasLength(2));
      expect(result.finalResult.text, equals('Done'));
      expect(result.steps[0].toolCalls, hasLength(1));
      expect(result.steps[0].toolResults, hasLength(1));
      expect(result.steps[0].toolResults.single.result, equals({'temp': 70}));
    });

    test('generateText without toolSet returns a single-step ToolLoopResult',
        () async {
      final model = _SequencedChatModel([
        _Response(
          text: 'Hello',
          usage: const UsageInfo(totalTokens: 2),
          finishReason: const LLMFinishReason(
            unified: LLMUnifiedFinishReason.stop,
            raw: 'stop',
          ),
        ),
      ]);

      final agent = Agent(model: model);
      final result = await agent.generateText(prompt: 'hi');

      expect(result.steps, hasLength(1));
      expect(result.finalResult.text, equals('Hello'));
      expect(result.messages.where((m) => m.role == ChatRole.user), isNotEmpty);
      expect(
        result.messages.where((m) => m.role == ChatRole.assistant),
        isNotEmpty,
      );
    });
  });
}

class _CapturingProviderToolsStreamModel extends ChatCapability
    implements ChatStreamPartsCapability {
  List<ProviderTool>? lastProviderTools;

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async {
    throw UnsupportedError('not used');
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    lastProviderTools = providerTools;
    yield const LLMStreamStartPart();
    yield const LLMTextStartPart();
    yield const LLMTextDeltaPart('ok');
    yield const LLMTextEndPart('ok');
    yield const LLMFinishPart(_Response(text: 'ok'));
  }
}

class _CapturingProviderToolsStreamObjectModel extends ChatCapability
    implements ChatStreamPartsCallOptionsCapability {
  List<ProviderTool>? lastProviderTools;
  LLMCallOptions? lastCallOptions;

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async {
    throw UnsupportedError('not used');
  }

  @override
  Stream<LLMStreamPart> chatStreamPartsWithCallOptions(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    List<ProviderTool>? providerTools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async* {
    lastProviderTools = providerTools;
    lastCallOptions = callOptions;

    const toolName = 'return_object';
    const args = '{"answer":"ok"}';
    const callId = 'call_1';

    yield const LLMStreamStartPart();
    yield const LLMToolCallStartPart(
      ToolCall(
        id: callId,
        callType: 'function',
        function: FunctionCall(name: toolName, arguments: args),
      ),
    );
    yield const LLMToolCallEndPart(callId);
    yield const LLMFinishPart(
      _Response(
        text: '',
        toolCalls: [
          ToolCall(
            id: callId,
            callType: 'function',
            function: FunctionCall(name: toolName, arguments: args),
          ),
        ],
      ),
    );
  }
}
