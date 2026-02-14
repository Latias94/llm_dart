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
  group('generateText(toolSet)', () {
    test('runs tool loop and returns steps + totalUsage', () async {
      final model = _SequencedChatModel([
        const _Response(
          toolCalls: [
            ToolCall(
              id: 'call_1',
              callType: 'function',
              function:
                  FunctionCall(name: 'get_weather', arguments: '{"city":"SF"}'),
            ),
          ],
          usage: UsageInfo(totalTokens: 3),
          finishReason: LLMFinishReason(
            unified: LLMUnifiedFinishReason.toolCalls,
            raw: 'tool_calls',
          ),
        ),
        const _Response(
          text: 'Done',
          usage: UsageInfo(totalTokens: 30),
          finishReason: LLMFinishReason(
            unified: LLMUnifiedFinishReason.stop,
            raw: 'stop',
          ),
        ),
      ]);

      final toolSet = ToolSet([
        functionTool(
          name: 'get_weather',
          description: 'get weather',
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

      final finishedSteps = <int>[];
      GenerateTextFinishEvent? finishEvent;

      final result = await generateText(
        model: model,
        prompt: 'hi',
        toolSet: toolSet,
        maxSteps: 3,
        onStepFinish: (step) => finishedSteps.add(step.index),
        onFinish: (event) => finishEvent = event,
      );

      expect(result.text, equals('Done'));
      expect(result.steps, hasLength(2));
      expect(result.totalUsage?.totalTokens, equals(33));
      expect(finishedSteps, equals([0, 1]));
      expect(finishEvent, isNotNull);
      expect(finishEvent!.totalUsage?.totalTokens, equals(33));

      final step0 = result.steps.first;
      expect(step0.toolCalls, hasLength(1));
      expect(step0.toolResults, hasLength(1));
      expect(step0.toolResults.single.result, equals({'temp': 70}));
      expect(step0.result.content.map((p) => p.type).toList(), [
        'tool-call',
        'tool-result',
      ]);

      final step1 = result.steps.last;
      expect(step1.result.content.map((p) => p.type).toList(), ['text']);
    });
  });
}
