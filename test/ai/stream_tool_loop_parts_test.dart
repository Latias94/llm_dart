library;

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _FakeChatResponse implements ChatResponse {
  @override
  final String? text;

  @override
  final String? thinking;

  @override
  final List<ToolCall>? toolCalls;

  @override
  final UsageInfo? usage;

  final Map<String, dynamic>? _providerMetadata;

  const _FakeChatResponse({
    Map<String, dynamic>? providerMetadata,
  })  : text = null,
        thinking = null,
        toolCalls = null,
        usage = null,
        _providerMetadata = providerMetadata;

  @override
  Map<String, dynamic>? get providerMetadata => _providerMetadata;
}

class _SequencedStreamChatModel extends ChatCapability
    implements ChatStreamPartsCapability {
  final List<List<LLMStreamPart>> steps;

  _SequencedStreamChatModel(this.steps);

  var _index = 0;

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) {
    throw UnsupportedError('chatWithTools not used in this test');
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    if (_index >= steps.length) {
      throw StateError('No more stream steps configured for fake model');
    }
    final parts = steps[_index++];
    for (final part in parts) {
      yield part;
    }
  }
}

void main() {
  group('streamToolLoopParts', () {
    test('should emit tool results and a single finish part', () async {
      final model = _SequencedStreamChatModel([
        [
          const LLMTextStartPart(),
          const LLMTextDeltaPart('Need '),
          LLMToolCallStartPart(
            const V3ToolCall(
              toolCallId: 'call_1',
              toolName: 'get_weather',
              input: '{',
            ),
          ),
          LLMToolCallDeltaPart(
            const V3ToolCall(
              toolCallId: 'call_1',
              toolName: '',
              input: '"city":"SF"}',
            ),
          ),
          const LLMTextEndPart('Need '),
          const LLMToolCallEndPart('call_1'),
          const LLMFinishPart(
            _FakeChatResponse(
              providerMetadata: {
                'openai': {'id': 'resp_step_1'}
              },
            ),
          ),
        ],
        [
          const LLMTextStartPart(),
          const LLMTextDeltaPart('Done'),
          const LLMTextEndPart('Done'),
          const LLMFinishPart(
            _FakeChatResponse(
              providerMetadata: {
                'openai': {'id': 'resp_step_2'}
              },
            ),
          ),
        ],
      ]);

      final parts = await streamToolLoopParts(
        model: model,
        messages: [ChatMessage.user('hi')],
        toolHandlers: {
          'get_weather': (input, options) => {'temp': 70},
        },
        maxSteps: 3,
      ).toList();

      // Step 1
      expect(parts[0], isA<LLMStreamStartPart>());
      expect(parts.whereType<LLMStreamStartPart>(), hasLength(1));

      expect(parts[1], isA<LLMTextStartPart>());
      expect(parts[2], isA<LLMTextDeltaPart>());
      expect((parts[2] as LLMTextDeltaPart).delta, equals('Need '));

      final toolInputStart =
          parts.whereType<LLMToolInputStartPart>().singleWhere(
                (p) => p.id == 'call_1',
              );
      expect(toolInputStart.toolName, equals('get_weather'));

      final toolInputDeltas = parts
          .whereType<LLMToolInputDeltaPart>()
          .where((p) => p.id == 'call_1')
          .map((p) => p.delta)
          .join();
      expect(toolInputDeltas, equals('{"city":"SF"}'));

      expect(
        parts.whereType<LLMToolInputEndPart>().where((p) => p.id == 'call_1'),
        hasLength(1),
      );

      expect(
        parts.whereType<LLMToolCallStartPart>().where(
              (p) => p.toolCall.toolCallId == 'call_1',
            ),
        hasLength(1),
      );
      expect(parts.whereType<LLMToolCallDeltaPart>(), hasLength(1));
      expect(
        parts.whereType<LLMToolCallEndPart>().where(
              (p) => p.toolCallId == 'call_1',
            ),
        hasLength(1),
      );

      final toolCallStartIndex =
          parts.indexWhere((p) => p is LLMToolCallStartPart);
      final toolInputStartIndex =
          parts.indexWhere((p) => p is LLMToolInputStartPart);
      final toolInputEndIndex =
          parts.indexWhere((p) => p is LLMToolInputEndPart);
      final toolCallEndIndex = parts.indexWhere((p) => p is LLMToolCallEndPart);
      expect(toolInputStartIndex, lessThan(toolCallStartIndex));
      expect(toolCallStartIndex, lessThan(toolInputEndIndex));
      expect(toolInputEndIndex, lessThan(toolCallEndIndex));

      final providerMetadataIndex =
          parts.indexWhere((p) => p is LLMProviderMetadataPart);
      expect(providerMetadataIndex, isNonNegative);
      expect(parts[providerMetadataIndex], isA<LLMProviderMetadataPart>());
      expect(
        (parts[providerMetadataIndex] as LLMProviderMetadataPart)
            .providerMetadata,
        containsPair('openai', {'id': 'resp_step_1'}),
      );

      final toolResultPart = parts.whereType<LLMToolResultPart>().first;
      final toolResult = toolResultPart.result;
      expect(toolResult.toolCallId, equals('call_1'));
      expect(toolResult.isError, isFalse);
      expect(toolResult.result, equals({'temp': 70}));

      // Step 2 (final)
      expect(parts.whereType<LLMTextEndPart>().last.text, equals('Done'));
      expect(parts.whereType<LLMFinishPart>().single.response.text,
          equals('Done'));
    });

    test('should stop when a tool handler is missing (schema-only tool)',
        () async {
      final model = _SequencedStreamChatModel([
        [
          LLMToolCallStartPart(
            const V3ToolCall(
              toolCallId: 'call_1',
              toolName: 'search_web',
              input: '{',
            ),
          ),
          LLMToolCallDeltaPart(
            const V3ToolCall(
              toolCallId: 'call_1',
              toolName: '',
              input: '"q":"dart"}',
            ),
          ),
          const LLMToolCallEndPart('call_1'),
          const LLMFinishPart(
            _FakeChatResponse(
              providerMetadata: {
                'openai': {'id': 'resp_step_1'}
              },
            ),
          ),
        ],
      ]);

      final parts = await streamToolLoopParts(
        model: model,
        messages: [ChatMessage.user('hi')],
        toolHandlers: {},
        maxSteps: 3,
      ).toList();

      expect(parts.whereType<LLMToolResultPart>(), isEmpty);
      expect(parts.whereType<LLMErrorPart>(), isEmpty);
      expect(parts.whereType<LLMFinishPart>(), hasLength(1));
    });

    test('continues when provider tool result is deferred to next step',
        () async {
      final model = _SequencedStreamChatModel([
        [
          const LLMProviderToolCallPart(
            toolCallId: 'prov_1',
            toolName: 'code_execution',
            input: {'code': 'print("hi")'},
            providerExecuted: true,
            supportsDeferredResults: true,
          ),
          const LLMFinishPart(
            _FakeChatResponse(
              providerMetadata: {
                'openai': {'id': 'resp_step_1'}
              },
            ),
          ),
        ],
        [
          const LLMProviderToolResultPart(
            toolCallId: 'prov_1',
            toolName: 'code_execution',
            result: {'ok': true},
          ),
          const LLMTextStartPart(),
          const LLMTextDeltaPart('Done'),
          const LLMTextEndPart('Done'),
          const LLMFinishPart(
            _FakeChatResponse(
              providerMetadata: {
                'openai': {'id': 'resp_step_2'}
              },
            ),
          ),
        ],
      ]);

      final parts = await streamToolLoopParts(
        model: model,
        messages: [ChatMessage.user('hi')],
        toolHandlers: const {},
        maxSteps: 3,
      ).toList();

      expect(parts.whereType<LLMFinishPart>(), hasLength(1));
      expect(parts.whereType<LLMProviderToolCallPart>(), hasLength(1));
      expect(parts.whereType<LLMProviderToolResultPart>(), hasLength(1));
      expect(parts.whereType<LLMFinishPart>().single.response.text,
          equals('Done'));
    });

    test('stops waiting when deferred provider tool wait budget is exhausted',
        () async {
      final model = _SequencedStreamChatModel([
        [
          const LLMProviderToolCallPart(
            toolCallId: 'prov_1',
            toolName: 'code_execution',
            input: {'code': 'print("hi")'},
            providerExecuted: true,
            supportsDeferredResults: true,
          ),
          const LLMFinishPart(
            _FakeChatResponse(
              providerMetadata: {
                'openai': {'id': 'resp_step_1'}
              },
            ),
          ),
        ],
        [
          const LLMTextStartPart(),
          const LLMTextDeltaPart('Done'),
          const LLMTextEndPart('Done'),
          const LLMFinishPart(
            _FakeChatResponse(
              providerMetadata: {
                'openai': {'id': 'resp_step_2'}
              },
            ),
          ),
        ],
      ]);

      final parts = await streamToolLoopParts(
        model: model,
        messages: [ChatMessage.user('hi')],
        toolHandlers: const {},
        maxSteps: 10,
        maxAdditionalProviderToolResultSteps: 1,
      ).toList();

      expect(parts.whereType<LLMFinishPart>(), hasLength(1));
      expect(parts.whereType<LLMProviderToolCallPart>(), hasLength(1));
      expect(parts.whereType<LLMProviderToolResultPart>(), isEmpty);
      expect(parts.whereType<LLMFinishPart>().single.response.text,
          equals('Done'));
    });

    test('ToolSet tool input hooks are invoked (start/delta/available)',
        () async {
      final model = _SequencedStreamChatModel([
        [
          LLMToolCallStartPart(
            const V3ToolCall(
              toolCallId: 'call_1',
              toolName: 'get_weather',
              input: '{',
            ),
          ),
          LLMToolCallDeltaPart(
            const V3ToolCall(
              toolCallId: 'call_1',
              toolName: '',
              input: '"city":"SF"}',
            ),
          ),
          const LLMToolCallEndPart('call_1'),
          const LLMFinishPart(
            _FakeChatResponse(
              providerMetadata: {
                'openai': {'id': 'resp_step_1'}
              },
            ),
          ),
        ],
        [
          const LLMTextStartPart(),
          const LLMTextDeltaPart('Done'),
          const LLMTextEndPart('Done'),
          const LLMFinishPart(
            _FakeChatResponse(
              providerMetadata: {
                'openai': {'id': 'resp_step_2'}
              },
            ),
          ),
        ],
      ]);

      final started = <String>[];
      final deltas = <String>[];
      Object? available;

      final toolSet = ToolSet([
        functionTool(
          name: 'get_weather',
          description: 'Get weather',
          inputSchema: Schema.params(
            properties: {
              'city': Schema.string('City name'),
            },
            required: ['city'],
          ),
          handler: (input, options) => {'temp': 70},
          onInputStart: (toolCallId) => started.add(toolCallId),
          onInputDelta: (toolCallId, delta) => deltas.add(delta),
          onInputAvailable: (toolCallId, input) => available = input,
        ),
      ]);

      await streamToolLoopPartsWithToolSet(
        model: model,
        messages: [ChatMessage.user('hi')],
        toolSet: toolSet,
        maxSteps: 3,
      ).toList();

      expect(started, equals(['call_1']));
      expect(deltas.join(), equals('{"city":"SF"}'));
      expect(available, equals({'city': 'SF'}));
    });

    Tool getWeatherToolDefinition() {
      return Tool.function(
        name: 'get_weather',
        description: 'Get weather for a city',
        inputSchema: Schema.params(
          properties: {
            'city': Schema.string('City name'),
          },
          required: ['city'],
        ),
      );
    }

    test('skips execution and emits error tool result for invalid JSON input',
        () async {
      var handlerCalls = 0;

      final model = _SequencedStreamChatModel([
        [
          LLMToolCallStartPart(
            const V3ToolCall(
              toolCallId: 'call_bad_json',
              toolName: 'get_weather',
              input: '{',
            ),
          ),
          const LLMToolCallEndPart('call_bad_json'),
          const LLMFinishPart(
            _FakeChatResponse(
              providerMetadata: {
                'openai': {'id': 'resp_step_1'}
              },
            ),
          ),
        ],
        [
          const LLMTextStartPart(),
          const LLMTextDeltaPart('Done'),
          const LLMTextEndPart('Done'),
          const LLMFinishPart(
            _FakeChatResponse(
              providerMetadata: {
                'openai': {'id': 'resp_step_2'}
              },
            ),
          ),
        ],
      ]);

      final parts = await streamToolLoopParts(
        model: model,
        messages: [ChatMessage.user('hi')],
        tools: [getWeatherToolDefinition()],
        toolHandlers: {
          'get_weather': (input, options) {
            handlerCalls++;
            return {'temp': 70};
          },
        },
        maxSteps: 3,
      ).toList();

      expect(handlerCalls, equals(0));

      final toolResult = parts.whereType<LLMToolResultPart>().single.result;
      expect(toolResult.toolCallId, equals('call_bad_json'));
      expect(toolResult.isError, isTrue);
      expect(toolResult.result.toString(), contains('Invalid JSON'));

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals('Done'));
    });

    test('repairs invalid JSON input when repair hook is provided', () async {
      var handlerCalls = 0;
      var repairCalls = 0;
      String? lastReason;
      String? lastInput;

      final model = _SequencedStreamChatModel([
        [
          LLMToolCallStartPart(
            const V3ToolCall(
              toolCallId: 'call_bad_json',
              toolName: 'get_weather',
              input: '{',
            ),
          ),
          const LLMToolCallEndPart('call_bad_json'),
          const LLMFinishPart(
            _FakeChatResponse(
              providerMetadata: {
                'openai': {'id': 'resp_step_1'}
              },
            ),
          ),
        ],
        [
          const LLMTextStartPart(),
          const LLMTextDeltaPart('Done'),
          const LLMTextEndPart('Done'),
          const LLMFinishPart(
            _FakeChatResponse(
              providerMetadata: {
                'openai': {'id': 'resp_step_2'}
              },
            ),
          ),
        ],
      ]);

      final parts = await streamToolLoopParts(
        model: model,
        messages: [ChatMessage.user('hi')],
        tools: [getWeatherToolDefinition()],
        toolHandlers: {
          'get_weather': (input, options) {
            handlerCalls++;
            return {'temp': 70, 'city': 'SF'};
          },
        },
        repairToolCall: (toolCall,
            {required reason, errorMessage, validationErrors}) {
          repairCalls++;
          lastReason = reason;
          lastInput = toolCall.input;
          return '{"city":"SF"}';
        },
        maxSteps: 3,
      ).toList();

      expect(handlerCalls, equals(1));
      expect(repairCalls, equals(1));
      expect(lastReason, equals('invalid_json'));
      expect(lastInput, equals('{'));

      final toolResult = parts.whereType<LLMToolResultPart>().single.result;
      expect(toolResult.toolCallId, equals('call_bad_json'));
      expect(toolResult.isError, isFalse);
      expect(toolResult.result, equals({'temp': 70, 'city': 'SF'}));

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals('Done'));
    });

    test('repair hook failure preserves invalid_tool_call metadata', () async {
      var handlerCalls = 0;
      var repairCalls = 0;

      final model = _SequencedStreamChatModel([
        [
          LLMToolCallStartPart(
            const V3ToolCall(
              toolCallId: 'call_bad_json',
              toolName: 'get_weather',
              input: '{',
            ),
          ),
          const LLMToolCallEndPart('call_bad_json'),
          const LLMFinishPart(
            _FakeChatResponse(
              providerMetadata: {
                'openai': {'id': 'resp_step_1'}
              },
            ),
          ),
        ],
        [
          const LLMTextStartPart(),
          const LLMTextDeltaPart('Done'),
          const LLMTextEndPart('Done'),
          const LLMFinishPart(
            _FakeChatResponse(
              providerMetadata: {
                'openai': {'id': 'resp_step_2'}
              },
            ),
          ),
        ],
      ]);

      final parts = await streamToolLoopParts(
        model: model,
        messages: [ChatMessage.user('hi')],
        tools: [getWeatherToolDefinition()],
        toolHandlers: {
          'get_weather': (input, options) {
            handlerCalls++;
            return {'temp': 70};
          },
        },
        repairToolCall: (toolCall,
            {required reason, errorMessage, validationErrors}) {
          repairCalls++;
          return '{"city":';
        },
        maxSteps: 3,
      ).toList();

      expect(handlerCalls, equals(0));
      expect(repairCalls, equals(1));

      final toolResult = parts.whereType<LLMToolResultPart>().single.result;
      expect(toolResult.toolCallId, equals('call_bad_json'));
      expect(toolResult.isError, isTrue);
      expect(toolResult.metadata, isNotNull);
      expect(toolResult.metadata!['kind'], equals('invalid_tool_call'));
      expect(toolResult.metadata!['reason'], equals('invalid_json'));
      expect(toolResult.metadata!['repairAttempted'], isTrue);
      expect(toolResult.metadata!['repairedInput'], equals('{"city":'));

      final v3 = encodeV3StreamParts(parts);
      final toolResultV3 = v3.where((o) => o['type'] == 'tool-result').single;
      expect(toolResultV3.containsKey('providerMetadata'), isFalse);
    });

    test('skips execution and emits error tool result for schema mismatch',
        () async {
      var handlerCalls = 0;

      final model = _SequencedStreamChatModel([
        [
          LLMToolCallStartPart(
            const V3ToolCall(
              toolCallId: 'call_schema',
              toolName: 'get_weather',
              input: '{"city":123}',
            ),
          ),
          const LLMToolCallEndPart('call_schema'),
          const LLMFinishPart(
            _FakeChatResponse(
              providerMetadata: {
                'openai': {'id': 'resp_step_1'}
              },
            ),
          ),
        ],
        [
          const LLMTextStartPart(),
          const LLMTextDeltaPart('Done'),
          const LLMTextEndPart('Done'),
          const LLMFinishPart(
            _FakeChatResponse(
              providerMetadata: {
                'openai': {'id': 'resp_step_2'}
              },
            ),
          ),
        ],
      ]);

      final parts = await streamToolLoopParts(
        model: model,
        messages: [ChatMessage.user('hi')],
        tools: [getWeatherToolDefinition()],
        toolHandlers: {
          'get_weather': (input, options) {
            handlerCalls++;
            return {'temp': 70};
          },
        },
        maxSteps: 3,
      ).toList();

      expect(handlerCalls, equals(0));

      final toolResult = parts.whereType<LLMToolResultPart>().single.result;
      expect(toolResult.toolCallId, equals('call_schema'));
      expect(toolResult.isError, isTrue);
      expect(toolResult.result.toString(), contains('Parameter'));

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals('Done'));
    });

    test('repairs schema validation failure when repair hook is provided',
        () async {
      var handlerCalls = 0;
      var repairCalls = 0;
      String? lastReason;
      List<String>? lastErrors;

      final model = _SequencedStreamChatModel([
        [
          LLMToolCallStartPart(
            const V3ToolCall(
              toolCallId: 'call_schema',
              toolName: 'get_weather',
              input: '{"city":123}',
            ),
          ),
          const LLMToolCallEndPart('call_schema'),
          const LLMFinishPart(
            _FakeChatResponse(
              providerMetadata: {
                'openai': {'id': 'resp_step_1'}
              },
            ),
          ),
        ],
        [
          const LLMTextStartPart(),
          const LLMTextDeltaPart('Done'),
          const LLMTextEndPart('Done'),
          const LLMFinishPart(
            _FakeChatResponse(
              providerMetadata: {
                'openai': {'id': 'resp_step_2'}
              },
            ),
          ),
        ],
      ]);

      final parts = await streamToolLoopParts(
        model: model,
        messages: [ChatMessage.user('hi')],
        tools: [getWeatherToolDefinition()],
        toolHandlers: {
          'get_weather': (input, options) {
            handlerCalls++;
            return {'temp': 71, 'city': 'SF'};
          },
        },
        repairToolCall: (toolCall,
            {required reason, errorMessage, validationErrors}) {
          repairCalls++;
          lastReason = reason;
          lastErrors = validationErrors;
          return '{"city":"SF"}';
        },
        maxSteps: 3,
      ).toList();

      expect(handlerCalls, equals(1));
      expect(repairCalls, equals(1));
      expect(lastReason, equals('schema_validation_failed'));
      expect(lastErrors, isNotNull);
      expect(lastErrors, isNotEmpty);

      final toolResult = parts.whereType<LLMToolResultPart>().single.result;
      expect(toolResult.toolCallId, equals('call_schema'));
      expect(toolResult.isError, isFalse);
      expect(
        toolResult.result,
        equals({'temp': 71, 'city': 'SF'}),
      );

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals('Done'));
    });

    test('treats tools list as allowlist (unknown tool emits error result)',
        () async {
      var handlerCalls = 0;

      final model = _SequencedStreamChatModel([
        [
          LLMToolCallStartPart(
            const V3ToolCall(
              toolCallId: 'call_unknown',
              toolName: 'get_weather',
              input: '{"city":"SF"}',
            ),
          ),
          const LLMToolCallEndPart('call_unknown'),
          const LLMFinishPart(
            _FakeChatResponse(
              providerMetadata: {
                'openai': {'id': 'resp_step_1'}
              },
            ),
          ),
        ],
        [
          const LLMTextStartPart(),
          const LLMTextDeltaPart('Done'),
          const LLMTextEndPart('Done'),
          const LLMFinishPart(
            _FakeChatResponse(
              providerMetadata: {
                'openai': {'id': 'resp_step_2'}
              },
            ),
          ),
        ],
      ]);

      final parts = await streamToolLoopParts(
        model: model,
        messages: [ChatMessage.user('hi')],
        tools: const [],
        toolHandlers: {
          'get_weather': (input, options) {
            handlerCalls++;
            return {'temp': 70};
          },
        },
        maxSteps: 3,
      ).toList();

      expect(handlerCalls, equals(0));

      final toolResult = parts.whereType<LLMToolResultPart>().single.result;
      expect(toolResult.toolCallId, equals('call_unknown'));
      expect(toolResult.isError, isTrue);
      expect(toolResult.result.toString(), contains('No such tool'));

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals('Done'));
    });
  });
}
