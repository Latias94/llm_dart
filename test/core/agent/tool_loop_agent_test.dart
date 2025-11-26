import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class FakeChatResponse implements ChatResponse {
  final String? _text;

  FakeChatResponse(this._text);

  @override
  String? get text => _text;

  @override
  List<ToolCall>? get toolCalls => const [];

  @override
  UsageInfo? get usage => null;

  @override
  String? get thinking => null;

  @override
  List<CallWarning> get warnings => const [];

  @override
  Map<String, dynamic>? get metadata => null;

  @override
  CallMetadata? get callMetadata => null;
}

class FakeLanguageModel implements LanguageModel {
  @override
  final String providerId;

  @override
  final String modelId;

  @override
  final LLMConfig config;

  int callCount = 0;

  FakeLanguageModel(this.providerId, this.modelId, this.config);

  @override
  Future<GenerateTextResult> generateText(
    List<ChatMessage> messages, {
    CancellationToken? cancelToken,
  }) async {
    callCount++;

    if (callCount == 1) {
      // First call: request tool execution.
      final toolCall = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(
          name: 'get_sum',
          arguments: '{"a":1,"b":2}',
        ),
      );

      return GenerateTextResult(
        rawResponse: FakeChatResponse(null),
        text: null,
        toolCalls: [toolCall],
        usage: null,
        warnings: const [],
        metadata: null,
      );
    } else if (callCount == 2) {
      // Second call: return final answer.
      return GenerateTextResult(
        rawResponse: FakeChatResponse('3'),
        text: '3',
        toolCalls: const [],
        usage: null,
        warnings: const [],
        metadata: null,
      );
    }

    // Subsequent calls: return the same final answer.
    return GenerateTextResult(
      rawResponse: FakeChatResponse('3'),
      text: '3',
      toolCalls: const [],
      usage: null,
      warnings: const [],
      metadata: null,
    );
  }

  @override
  Stream<ChatStreamEvent> streamText(
    List<ChatMessage> messages, {
    CancellationToken? cancelToken,
  }) async* {
    final result = await generateText(messages, cancelToken: cancelToken);
    if (result.text != null) {
      yield TextDeltaEvent(result.text!);
    }
    yield CompletionEvent(result.rawResponse);
  }

  @override
  Stream<StreamTextPart> streamTextParts(
    List<ChatMessage> messages, {
    CancellationToken? cancelToken,
  }) {
    return adaptStreamText(streamText(messages, cancelToken: cancelToken));
  }

  @override
  Future<GenerateObjectResult<T>> generateObject<T>(
    OutputSpec<T> output,
    List<ChatMessage> messages, {
    CancellationToken? cancelToken,
  }) async {
    final textResult = await generateText(messages, cancelToken: cancelToken);
    final raw = textResult.text ?? '';
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final object = output.fromJson(decoded);
    return GenerateObjectResult<T>(object: object, textResult: textResult);
  }
}

class SumResult {
  final int result;

  const SumResult(this.result);

  static SumResult fromJson(Map<String, dynamic> json) {
    return SumResult(json['result'] as int);
  }
}

void main() {
  group('ToolLoopAgent', () {
    test('runText should perform tool loop and return final text', () async {
      final model = FakeLanguageModel(
        'fake',
        'test-model',
        LLMConfig(baseUrl: '', model: 'test-model'),
      );

      final tools = <String, ExecutableTool>{
        'get_sum': ExecutableTool(
          schema: Tool.function(
            name: 'get_sum',
            description: 'Sum two integers',
            parameters: ParametersSchema(
              schemaType: 'object',
              properties: {
                'a': ParameterProperty(
                  propertyType: 'integer',
                  description: 'First operand',
                ),
                'b': ParameterProperty(
                  propertyType: 'integer',
                  description: 'Second operand',
                ),
              },
              required: const ['a', 'b'],
            ),
          ),
          execute: (args) async {
            final a = args['a'] as int;
            final b = args['b'] as int;
            return {'result': a + b};
          },
        ),
      };

      final input = AgentInput(
        model: model,
        messages: [ChatMessage.user('Add 1 and 2')],
        tools: tools,
      );

      const agent = ToolLoopAgent();
      final result = await agent.runText(input);

      expect(model.callCount, greaterThanOrEqualTo(2));
      expect(result.text, equals('3'));
    });

    test('runObject should parse structured JSON into typed object', () async {
      final model = _JsonLanguageModel(
        LLMConfig(baseUrl: '', model: 'test-model'),
      );

      final tools = <String, ExecutableTool>{
        'get_sum': ExecutableTool(
          schema: Tool.function(
            name: 'get_sum',
            description: 'Sum two integers',
            parameters: ParametersSchema(
              schemaType: 'object',
              properties: {
                'a': ParameterProperty(
                  propertyType: 'integer',
                  description: 'First operand',
                ),
                'b': ParameterProperty(
                  propertyType: 'integer',
                  description: 'Second operand',
                ),
              },
              required: const ['a', 'b'],
            ),
          ),
          execute: (args) async {
            final a = args['a'] as int;
            final b = args['b'] as int;
            return {'result': a + b};
          },
        ),
      };

      final input = AgentInput(
        model: model,
        messages: [ChatMessage.user('Add 1 and 2 and return JSON')],
        tools: tools,
      );

      final output = OutputSpec<SumResult>.object(
        name: 'SumResult',
        properties: {
          'result': ParameterProperty(
            propertyType: 'integer',
            description: 'Sum result',
          ),
        },
        fromJson: SumResult.fromJson,
      );

      const agent = ToolLoopAgent();
      final result = await agent.runObject<SumResult>(
        input: input,
        output: output,
      );

      expect(result.object.result, equals(3));
    });
  });
}

/// Language model used for the runObject test that returns JSON
/// after performing a single tool loop iteration.
class _JsonLanguageModel implements LanguageModel {
  @override
  final String providerId = 'fake';

  @override
  final String modelId = 'test-model';

  @override
  final LLMConfig config;

  int callCount = 0;

  _JsonLanguageModel(this.config);

  @override
  Future<GenerateTextResult> generateText(
    List<ChatMessage> messages, {
    CancellationToken? cancelToken,
  }) async {
    callCount++;

    if (callCount == 1) {
      final toolCall = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(
          name: 'get_sum',
          arguments: '{"a":1,"b":2}',
        ),
      );

      return GenerateTextResult(
        rawResponse: FakeChatResponse(null),
        text: null,
        toolCalls: [toolCall],
        usage: null,
        warnings: const [],
        metadata: null,
      );
    } else {
      final jsonText = jsonEncode({'result': 3});
      return GenerateTextResult(
        rawResponse: FakeChatResponse(jsonText),
        text: jsonText,
        toolCalls: const [],
        usage: null,
        warnings: const [],
        metadata: null,
      );
    }
  }

  @override
  Stream<ChatStreamEvent> streamText(
    List<ChatMessage> messages, {
    CancellationToken? cancelToken,
  }) async* {
    final result = await generateText(messages, cancelToken: cancelToken);
    if (result.text != null) {
      yield TextDeltaEvent(result.text!);
    }
    yield CompletionEvent(result.rawResponse);
  }

  @override
  Stream<StreamTextPart> streamTextParts(
    List<ChatMessage> messages, {
    CancellationToken? cancelToken,
  }) {
    return adaptStreamText(streamText(messages, cancelToken: cancelToken));
  }

  @override
  Future<GenerateObjectResult<T>> generateObject<T>(
    OutputSpec<T> output,
    List<ChatMessage> messages, {
    CancellationToken? cancelToken,
  }) async {
    final textResult = await generateText(messages, cancelToken: cancelToken);
    final raw = textResult.text ?? '';
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final object = output.fromJson(decoded);
    return GenerateObjectResult<T>(object: object, textResult: textResult);
  }
}
