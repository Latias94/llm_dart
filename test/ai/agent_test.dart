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
    this.thinking,
    this.toolCalls,
    this.usage,
    this.providerMetadata,
    this.finishReason,
  });
}

void main() {
  group('Agent', () {
    test('generateText(toolSet) runs tool loop and returns steps', () async {
      final model = _SequencedChatModel([
        _Response(
          toolCalls: const [
            ToolCall(
              id: 'call_1',
              callType: 'function',
              function: FunctionCall(name: 'get_weather', arguments: '{"city":"SF"}'),
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
          handler: (toolCall, {cancelToken}) => {'temp': 70},
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

    test('generateText without toolSet returns a single-step ToolLoopResult', () async {
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
