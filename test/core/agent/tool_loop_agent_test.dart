import 'dart:convert';

import 'package:test/test.dart';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart/llm_dart.dart' as root;
import '../../utils/mock_language_model.dart';

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

  LanguageModelCallOptions? lastOptions;

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

  @override
  Future<GenerateTextResult> generateTextWithOptions(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    lastOptions = options;
    return generateText(messages, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> streamTextWithOptions(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    lastOptions = options;
    return streamText(messages, cancelToken: cancelToken);
  }

  @override
  Stream<StreamTextPart> streamTextPartsWithOptions(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    lastOptions = options;
    return streamTextParts(messages, cancelToken: cancelToken);
  }

  @override
  Future<GenerateObjectResult<T>> generateObjectWithOptions<T>(
    OutputSpec<T> output,
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    lastOptions = options;
    return generateObject<T>(output, messages, cancelToken: cancelToken);
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

    test('runText forwards AgentInput.callOptions to LanguageModel', () async {
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

      final options = LanguageModelCallOptions(
        maxTokens: 123,
        temperature: 0.5,
        topP: 0.9,
      );

      final input = AgentInput(
        model: model,
        messages: [ChatMessage.user('Add 1 and 2')],
        tools: tools,
        callOptions: options,
      );

      const agent = ToolLoopAgent();
      final result = await agent.runText(input);

      expect(result.text, equals('3'));
      expect(model.callCount, greaterThanOrEqualTo(2));
      expect(model.lastOptions, isNotNull);
      expect(model.lastOptions!.maxTokens, equals(123));
      expect(model.lastOptions!.temperature, equals(0.5));
      expect(model.lastOptions!.topP, equals(0.9));
    });

    test(
        'runAgentObject helper forwards LanguageModelCallOptions to LanguageModel',
        () async {
      final model = _JsonLanguageModelWithOptions(
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

      final options = LanguageModelCallOptions(
        maxTokens: 456,
        temperature: 0.7,
        topP: 0.8,
      );

      final result = await root.runAgentObject<SumResult>(
        model: model,
        messages: [ChatMessage.user('Add 1 and 2 and return JSON')],
        tools: tools,
        output: output,
        options: options,
      );

      expect(result.object.result, equals(3));
      expect(model.callCount, greaterThanOrEqualTo(2));
      expect(model.lastOptions, isNotNull);
      expect(model.lastOptions!.maxTokens, equals(456));
      expect(model.lastOptions!.temperature, equals(0.7));
      expect(model.lastOptions!.topP, equals(0.8));
    });

    test('runTextWithSteps records tool calls and results', () async {
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
      final traced = await agent.runTextWithSteps(input);

      // Final result should still be the sum.
      expect(traced.result.text, equals('3'));
      expect(model.callCount, greaterThanOrEqualTo(2));

      // First step should contain the tool call and its successful result.
      expect(traced.steps, isNotEmpty);
      final firstStep = traced.steps.first;
      expect(firstStep.toolCalls, hasLength(1));

      final toolRecord = firstStep.toolCalls.first;
      expect(toolRecord.call.function.name, equals('get_sum'));
      expect(toolRecord.isSuccess, isTrue);
      expect(toolRecord.result, equals({'result': 3}));
      expect(toolRecord.error, isNull);
    });

    test('runAgentPromptText bridges ModelMessage prompts to LanguageModel',
        () async {
      final model = MockLanguageModel(
        providerId: 'mock',
        modelId: 'prompt-model',
        config: LLMConfig(baseUrl: '', model: 'prompt-model'),
        doGenerate: (messages, options) async {
          expect(messages, hasLength(1));
          final prompt = messages.first;
          expect(prompt.role, ChatRole.user);
          expect(prompt.parts, hasLength(1));
          final part = prompt.parts.first;
          expect(part, isA<TextContentPart>());
          expect((part as TextContentPart).text, 'Add 1 and 2');

          expect(options, isNotNull);
          expect(options!.maxTokens, equals(32));

          return GenerateTextResult(
            rawResponse: FakeChatResponse('result'),
            text: 'result',
            toolCalls: const [],
            usage: null,
            warnings: const [],
            metadata: null,
          );
        },
      );

      final promptMessages = [
        ModelMessage(
          role: ChatRole.user,
          parts: const [TextContentPart('Add 1 and 2')],
        ),
      ];

      final tools = <String, ExecutableTool>{};

      final options = LanguageModelCallOptions(
        maxTokens: 32,
      );

      final result = await root.runAgentPromptText(
        model: model,
        promptMessages: promptMessages,
        tools: tools,
        options: options,
      );

      expect(result.text, equals('result'));
      // MockLanguageModel only performs a single generateText call here.
      expect(model.lastPromptMessages, isNotNull);
      expect(model.lastPromptMessages, hasLength(1));
      final recorded = model.lastPromptMessages!.first;
      expect(recorded.role, equals(ChatRole.user));
      expect(recorded.parts, hasLength(1));
      expect((recorded.parts.first as TextContentPart).text, 'Add 1 and 2');
    });

    // Note: pruning of ModelMessage-based prompts is validated at the
    // core level via pruneModelMessages tests. Agent helpers do not
    // implicitly modify prompts and rely on callers to perform any
    // desired pruning before invoking runAgentPrompt* helpers.

    test('runAgentPromptTextWithSteps returns steps for ModelMessage prompts',
        () async {
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

      final promptMessages = [
        ModelMessage(
          role: ChatRole.user,
          parts: const [TextContentPart('Add 1 and 2')],
        ),
      ];

      final traced = await root.runAgentPromptTextWithSteps(
        model: model,
        promptMessages: promptMessages,
        tools: tools,
      );

      expect(traced.result.text, equals('3'));
      expect(traced.steps, isNotEmpty);
      expect(traced.steps.first.toolCalls, isNotEmpty);
    });

    test('runTextWithSteps executes tools in parallel when configured',
        () async {
      // Language model that emits two tool calls in the first iteration,
      // then returns a final answer without tool calls.
      var callCount = 0;
      final model = MockLanguageModel(
        providerId: 'mock',
        modelId: 'multi-tool',
        config: LLMConfig(baseUrl: '', model: 'multi-tool'),
        doGenerate: (messages, options) async {
          callCount++;
          if (callCount == 1) {
            final firstCall = ToolCall(
              id: 'call_1',
              callType: 'function',
              function: const FunctionCall(
                name: 'tool_a',
                arguments: '{"value":1}',
              ),
            );
            final secondCall = ToolCall(
              id: 'call_2',
              callType: 'function',
              function: const FunctionCall(
                name: 'tool_b',
                arguments: '{"value":2}',
              ),
            );

            return GenerateTextResult(
              rawResponse: FakeChatResponse(null),
              text: null,
              toolCalls: [firstCall, secondCall],
              usage: null,
              warnings: const [],
              metadata: null,
            );
          }

          return GenerateTextResult(
            rawResponse: FakeChatResponse('done'),
            text: 'done',
            toolCalls: const [],
            usage: null,
            warnings: const [],
            metadata: null,
          );
        },
      );

      var activeExecutions = 0;
      var maxActiveExecutions = 0;

      Future<Map<String, dynamic>> trackedExecute(
        int delayMillis,
        Map<String, dynamic> args,
      ) async {
        activeExecutions++;
        if (activeExecutions > maxActiveExecutions) {
          maxActiveExecutions = activeExecutions;
        }
        await Future<void>.delayed(Duration(milliseconds: delayMillis));
        activeExecutions--;
        return {'value': args['value']};
      }

      final tools = <String, ExecutableTool>{
        'tool_a': ExecutableTool(
          schema: Tool.function(
            name: 'tool_a',
            description: 'Test tool A',
            parameters: ParametersSchema(
              schemaType: 'object',
              properties: {
                'value': ParameterProperty(
                  propertyType: 'integer',
                  description: 'Test value',
                ),
              },
              required: const ['value'],
            ),
          ),
          execute: (args) => trackedExecute(20, args),
        ),
        'tool_b': ExecutableTool(
          schema: Tool.function(
            name: 'tool_b',
            description: 'Test tool B',
            parameters: ParametersSchema(
              schemaType: 'object',
              properties: {
                'value': ParameterProperty(
                  propertyType: 'integer',
                  description: 'Test value',
                ),
              },
              required: const ['value'],
            ),
          ),
          execute: (args) => trackedExecute(20, args),
        ),
      };

      final input = AgentInput(
        model: model,
        messages: [ChatMessage.user('Call two tools in parallel')],
        tools: tools,
        loopConfig: const ToolLoopConfig(
          maxIterations: 4,
          runToolsInParallel: true,
        ),
      );

      const agent = ToolLoopAgent();
      final traced = await agent.runTextWithSteps(input);

      expect(traced.result.text, equals('done'));
      // With parallel execution, there should be a moment where both
      // tool executors are running concurrently.
      expect(maxActiveExecutions, greaterThanOrEqualTo(2));
    });

    test('runTextWithSteps executes tools sequentially when not in parallel',
        () async {
      var callCount = 0;
      final model = MockLanguageModel(
        providerId: 'mock',
        modelId: 'multi-tool',
        config: LLMConfig(baseUrl: '', model: 'multi-tool'),
        doGenerate: (messages, options) async {
          callCount++;
          if (callCount == 1) {
            final firstCall = ToolCall(
              id: 'call_1',
              callType: 'function',
              function: const FunctionCall(
                name: 'tool_a',
                arguments: '{"value":1}',
              ),
            );
            final secondCall = ToolCall(
              id: 'call_2',
              callType: 'function',
              function: const FunctionCall(
                name: 'tool_b',
                arguments: '{"value":2}',
              ),
            );

            return GenerateTextResult(
              rawResponse: FakeChatResponse(null),
              text: null,
              toolCalls: [firstCall, secondCall],
              usage: null,
              warnings: const [],
              metadata: null,
            );
          }

          return GenerateTextResult(
            rawResponse: FakeChatResponse('done'),
            text: 'done',
            toolCalls: const [],
            usage: null,
            warnings: const [],
            metadata: null,
          );
        },
      );

      var activeExecutions = 0;
      var maxActiveExecutions = 0;

      Future<Map<String, dynamic>> trackedExecute(
        int delayMillis,
        Map<String, dynamic> args,
      ) async {
        activeExecutions++;
        if (activeExecutions > maxActiveExecutions) {
          maxActiveExecutions = activeExecutions;
        }
        await Future<void>.delayed(Duration(milliseconds: delayMillis));
        activeExecutions--;
        return {'value': args['value']};
      }

      final tools = <String, ExecutableTool>{
        'tool_a': ExecutableTool(
          schema: Tool.function(
            name: 'tool_a',
            description: 'Test tool A',
            parameters: ParametersSchema(
              schemaType: 'object',
              properties: {
                'value': ParameterProperty(
                  propertyType: 'integer',
                  description: 'Test value',
                ),
              },
              required: const ['value'],
            ),
          ),
          execute: (args) => trackedExecute(10, args),
        ),
        'tool_b': ExecutableTool(
          schema: Tool.function(
            name: 'tool_b',
            description: 'Test tool B',
            parameters: ParametersSchema(
              schemaType: 'object',
              properties: {
                'value': ParameterProperty(
                  propertyType: 'integer',
                  description: 'Test value',
                ),
              },
              required: const ['value'],
            ),
          ),
          execute: (args) => trackedExecute(10, args),
        ),
      };

      final input = AgentInput(
        model: model,
        messages: [ChatMessage.user('Call two tools sequentially')],
        tools: tools,
        loopConfig: const ToolLoopConfig(
          maxIterations: 4,
          runToolsInParallel: false,
        ),
      );

      const agent = ToolLoopAgent();
      final traced = await agent.runTextWithSteps(input);

      expect(traced.result.text, equals('done'));
      // When not running in parallel, at most one tool executor should
      // be active at a time.
      expect(maxActiveExecutions, equals(1));
    });

    test('respects maxToolRetries and succeeds after transient failures',
        () async {
      var callCount = 0;
      final model = MockLanguageModel(
        providerId: 'mock',
        modelId: 'retry-model',
        config: LLMConfig(baseUrl: '', model: 'retry-model'),
        doGenerate: (messages, options) async {
          callCount++;
          if (callCount == 1) {
            final toolCall = ToolCall(
              id: 'call_1',
              callType: 'function',
              function: const FunctionCall(
                name: 'flaky_tool',
                arguments: '{"value":1}',
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
          }

          return GenerateTextResult(
            rawResponse: FakeChatResponse('ok'),
            text: 'ok',
            toolCalls: const [],
            usage: null,
            warnings: const [],
            metadata: null,
          );
        },
      );

      var executionAttempts = 0;

      final tools = <String, ExecutableTool>{
        'flaky_tool': ExecutableTool(
          schema: Tool.function(
            name: 'flaky_tool',
            description: 'Transiently failing tool',
            parameters: ParametersSchema(
              schemaType: 'object',
              properties: {
                'value': ParameterProperty(
                  propertyType: 'integer',
                  description: 'Value',
                ),
              },
              required: const ['value'],
            ),
          ),
          execute: (args) async {
            executionAttempts++;
            if (executionAttempts <= 2) {
              throw Exception('Transient failure');
            }
            return {'value': args['value']};
          },
        ),
      };

      final input = AgentInput(
        model: model,
        messages: [ChatMessage.user('Call flaky tool')],
        tools: tools,
        loopConfig: const ToolLoopConfig(
          maxIterations: 4,
          runToolsInParallel: false,
          maxToolRetries: 2,
        ),
      );

      const agent = ToolLoopAgent();
      final traced = await agent.runTextWithSteps(input);

      expect(traced.result.text, equals('ok'));
      expect(executionAttempts, equals(3));
      final firstStep = traced.steps.first;
      expect(firstStep.toolCalls, hasLength(1));
      expect(firstStep.toolCalls.first.isSuccess, isTrue);
    });

    test('throws GenericError when tool retries are exhausted', () async {
      var callCount = 0;
      final model = MockLanguageModel(
        providerId: 'mock',
        modelId: 'retry-model',
        config: LLMConfig(baseUrl: '', model: 'retry-model'),
        doGenerate: (messages, options) async {
          callCount++;
          final toolCall = ToolCall(
            id: 'call_1',
            callType: 'function',
            function: const FunctionCall(
              name: 'always_fail',
              arguments: '{"value":1}',
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
        },
      );

      final tools = <String, ExecutableTool>{
        'always_fail': ExecutableTool(
          schema: Tool.function(
            name: 'always_fail',
            description: 'Always failing tool',
            parameters: ParametersSchema(
              schemaType: 'object',
              properties: {
                'value': ParameterProperty(
                  propertyType: 'integer',
                  description: 'Value',
                ),
              },
              required: const ['value'],
            ),
          ),
          execute: (args) async {
            throw Exception('Permanent failure');
          },
        ),
      };

      final input = AgentInput(
        model: model,
        messages: [ChatMessage.user('Call always failing tool')],
        tools: tools,
        loopConfig: const ToolLoopConfig(
          maxIterations: 2,
          runToolsInParallel: false,
          maxToolRetries: 1,
        ),
      );

      const agent = ToolLoopAgent();

      expect(
        () => agent.runTextWithSteps(input),
        throwsA(
          isA<GenericError>().having(
            (e) => e.message,
            'message',
            contains('Tool execution failed for "always_fail"'),
          ),
        ),
      );
    });

    test(
        'runTextWithSteps records per-step usage and final result uses last step usage',
        () async {
      var callCount = 0;
      const firstUsage = UsageInfo(
        promptTokens: 5,
        completionTokens: 7,
        totalTokens: 12,
      );
      const secondUsage = UsageInfo(
        promptTokens: 3,
        completionTokens: 4,
        totalTokens: 7,
      );

      final model = MockLanguageModel(
        providerId: 'mock',
        modelId: 'usage-model',
        config: LLMConfig(baseUrl: '', model: 'usage-model'),
        doGenerate: (messages, options) async {
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
              usage: firstUsage,
              warnings: const [],
              metadata: null,
            );
          }

          return GenerateTextResult(
            rawResponse: FakeChatResponse('3'),
            text: '3',
            toolCalls: const [],
            usage: secondUsage,
            warnings: const [],
            metadata: null,
          );
        },
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
        loopConfig: const ToolLoopConfig(
          maxIterations: 4,
          runToolsInParallel: false,
        ),
      );

      const agent = ToolLoopAgent();
      final traced = await agent.runTextWithSteps(input);

      // Final text should come from the second model call.
      expect(traced.result.text, equals('3'));
      expect(traced.steps, hasLength(2));

      // Per-step usage should match the usage returned by the model.
      final firstStep = traced.steps[0];
      final secondStep = traced.steps[1];
      expect(firstStep.iteration, equals(1));
      expect(secondStep.iteration, equals(2));

      expect(firstStep.modelResult.usage, equals(firstUsage));
      expect(secondStep.modelResult.usage, equals(secondUsage));

      // The final result usage is taken from the last model call, which
      // mirrors the Vercel generateText semantics (usage of final step).
      expect(traced.result.usage, equals(secondUsage));
    });

    test('runAgentPromptObject parses structured JSON from ModelMessage',
        () async {
      final model = _SimpleJsonLanguageModel(
        LLMConfig(baseUrl: '', model: 'json-model'),
      );

      final promptMessages = [
        ModelMessage(
          role: ChatRole.user,
          parts: const [TextContentPart('Return a JSON object')],
        ),
      ];

      final tools = <String, ExecutableTool>{};

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

      final result = await root.runAgentPromptObject<SumResult>(
        model: model,
        promptMessages: promptMessages,
        tools: tools,
        output: output,
      );

      expect(result.object.result, equals(7));
    });

    test(
        'runAgentPromptObjectWithSteps returns steps for structured output from ModelMessage',
        () async {
      final model = _SimpleJsonLanguageModel(
        LLMConfig(baseUrl: '', model: 'json-model'),
      );

      final promptMessages = [
        ModelMessage(
          role: ChatRole.user,
          parts: const [TextContentPart('Return a JSON object')],
        ),
      ];

      final tools = <String, ExecutableTool>{};

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

      final traced = await root.runAgentPromptObjectWithSteps<SumResult>(
        model: model,
        promptMessages: promptMessages,
        tools: tools,
        output: output,
      );

      expect(traced.result.object.result, equals(7));
      // Even without tools, the agent should record the final model step.
      expect(traced.steps, isNotEmpty);
      expect(traced.steps.first.modelResult.text, equals('{"result":7}'));
    });
  });
}

/// Minimal language model that always returns a fixed JSON object.
class _SimpleJsonLanguageModel implements LanguageModel {
  @override
  final String providerId = 'simple';

  @override
  final String modelId = 'json-model';

  @override
  final LLMConfig config;

  _SimpleJsonLanguageModel(this.config);

  @override
  Future<GenerateTextResult> generateText(
    List<ChatMessage> messages, {
    CancellationToken? cancelToken,
  }) async {
    const jsonText = '{"result":7}';
    return GenerateTextResult(
      rawResponse: FakeChatResponse(jsonText),
      text: jsonText,
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

  @override
  Future<GenerateTextResult> generateTextWithOptions(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return generateText(messages, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> streamTextWithOptions(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return streamText(messages, cancelToken: cancelToken);
  }

  @override
  Stream<StreamTextPart> streamTextPartsWithOptions(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return streamTextParts(messages, cancelToken: cancelToken);
  }

  @override
  Future<GenerateObjectResult<T>> generateObjectWithOptions<T>(
    OutputSpec<T> output,
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return generateObject<T>(output, messages, cancelToken: cancelToken);
  }
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

  @override
  Future<GenerateTextResult> generateTextWithOptions(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return generateText(messages, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> streamTextWithOptions(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return streamText(messages, cancelToken: cancelToken);
  }

  @override
  Stream<StreamTextPart> streamTextPartsWithOptions(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return streamTextParts(messages, cancelToken: cancelToken);
  }

  @override
  Future<GenerateObjectResult<T>> generateObjectWithOptions<T>(
    OutputSpec<T> output,
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return generateObject<T>(output, messages, cancelToken: cancelToken);
  }
}

/// Variant of [_JsonLanguageModel] that records the last per-call options.
class _JsonLanguageModelWithOptions implements LanguageModel {
  @override
  final String providerId = 'fake';

  @override
  final String modelId = 'test-model';

  @override
  final LLMConfig config;

  int callCount = 0;

  LanguageModelCallOptions? lastOptions;

  _JsonLanguageModelWithOptions(this.config);

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

  @override
  Future<GenerateTextResult> generateTextWithOptions(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    lastOptions = options;
    return generateText(messages, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> streamTextWithOptions(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    lastOptions = options;
    return streamText(messages, cancelToken: cancelToken);
  }

  @override
  Stream<StreamTextPart> streamTextPartsWithOptions(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    lastOptions = options;
    return streamTextParts(messages, cancelToken: cancelToken);
  }

  @override
  Future<GenerateObjectResult<T>> generateObjectWithOptions<T>(
    OutputSpec<T> output,
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    lastOptions = options;
    return generateObject<T>(output, messages, cancelToken: cancelToken);
  }
}
