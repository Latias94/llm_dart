library;

import 'dart:convert';

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
    this.text,
    this.thinking,
    this.toolCalls,
    this.usage,
    Map<String, dynamic>? providerMetadata,
  }) : _providerMetadata = providerMetadata;

  @override
  Map<String, dynamic>? get providerMetadata => _providerMetadata;
}

class _FakeChatResponseWithFinishReason extends _FakeChatResponse
    implements ChatResponseWithFinishReason {
  @override
  final LLMFinishReason? finishReason;

  const _FakeChatResponseWithFinishReason({
    super.text,
    super.thinking,
    super.toolCalls,
    super.usage,
    super.providerMetadata,
    this.finishReason,
  });
}

class _FakeChatModel extends ChatCapability
    implements ChatStreamPartsCapability {
  final List<LLMStreamPart> parts;

  _FakeChatModel(this.parts);

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    throw UnsupportedError('chatWithTools not used in this test');
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    for (final part in parts) {
      yield part;
    }
  }
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
    CancelToken? cancelToken,
  }) async {
    throw UnsupportedError('chatWithTools not used in this test');
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
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
  group('streamText', () {
    test('aggregates text and exposes finalResult', () async {
      final usage =
          UsageInfo(promptTokens: 1, completionTokens: 2, totalTokens: 3);
      const finishReason = LLMFinishReason(
        unified: LLMUnifiedFinishReason.stop,
        raw: 'stop',
      );
      const warnings = [
        {'type': 'warning', 'message': 'test warning'}
      ];

      final model = _FakeChatModel([
        const LLMStreamStartPart(warnings: warnings),
        const LLMTextStartPart(),
        const LLMTextDeltaPart('Hel'),
        const LLMTextDeltaPart('lo'),
        const LLMTextEndPart('Hello'),
        LLMProviderMetadataPart(const {
          'openai': {'id': 'resp_1'}
        }),
        LLMFinishPart(
          _FakeChatResponse(
            text: 'Hello',
            usage: usage,
            providerMetadata: const {
              'openai': {'id': 'resp_1'}
            },
          ),
          usage: usage,
          finishReason: finishReason,
        ),
      ]);

      final result = streamText(
        model: model,
        messages: [ChatMessage.user('hi')],
      );

      final partsFuture = result.fullStream.toList();

      expect(await result.warnings, equals(warnings));
      expect(await result.text, equals('Hello'));
      expect((await result.usage)?.totalTokens, equals(3));
      expect((await result.totalUsage)?.totalTokens, equals(3));
      expect((await result.finishReason)?.unified,
          equals(LLMUnifiedFinishReason.stop));
      expect(await result.providerMetadata, contains('openai'));
      expect(await result.steps, hasLength(1));

      final finalResult = await result.finalResult;
      expect(finalResult.text, equals('Hello'));
      expect(finalResult.finishReason?.unified,
          equals(LLMUnifiedFinishReason.stop));
      expect(finalResult.usage?.totalTokens, equals(3));
      expect(finalResult.providerMetadata, contains('openai'));

      final parts = await partsFuture;
      expect(parts.first, isA<LLMStreamStartPart>());
      expect(parts.last, isA<LLMFinishPart>());
    });

    test('toolSet path exposes steps and totalUsage', () async {
      final usage1 =
          UsageInfo(promptTokens: 1, completionTokens: 2, totalTokens: 3);
      final usage2 =
          UsageInfo(promptTokens: 10, completionTokens: 20, totalTokens: 30);

      const finishReasonToolCalls = LLMFinishReason(
        unified: LLMUnifiedFinishReason.toolCalls,
        raw: 'tool_calls',
      );

      const finishReasonStop = LLMFinishReason(
        unified: LLMUnifiedFinishReason.stop,
        raw: 'stop',
      );

      final model = _SequencedStreamChatModel([
        [
          const LLMTextStartPart(),
          const LLMTextDeltaPart('Need '),
          LLMToolCallStartPart(
            ToolCall(
              id: 'call_1',
              callType: 'function',
              function: FunctionCall(name: 'get_weather', arguments: '{'),
            ),
          ),
          LLMToolCallDeltaPart(
            ToolCall(
              id: 'call_1',
              callType: 'function',
              function: FunctionCall(name: '', arguments: '"city":"SF"}'),
            ),
          ),
          const LLMTextEndPart('Need '),
          const LLMToolCallEndPart('call_1'),
          LLMFinishPart(
            _FakeChatResponseWithFinishReason(
              usage: usage1,
              finishReason: finishReasonToolCalls,
              providerMetadata: const {
                'openai': {'id': 'resp_step_1'}
              },
            ),
          ),
        ],
        [
          const LLMTextStartPart(),
          const LLMTextDeltaPart('Done'),
          const LLMTextEndPart('Done'),
          LLMFinishPart(
            _FakeChatResponseWithFinishReason(
              text: 'Done',
              usage: usage2,
              finishReason: finishReasonStop,
              providerMetadata: const {
                'openai': {'id': 'resp_step_2'}
              },
            ),
          ),
        ],
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

      final result = streamText(
        model: model,
        messages: [ChatMessage.user('hi')],
        toolSet: toolSet,
        maxSteps: 5,
      );

      final parts = await result.fullStream.toList();
      expect(await result.warnings, isEmpty);
      expect(parts.whereType<LLMStepStartPart>(), hasLength(2));
      expect(parts.whereType<LLMStepFinishPart>(), hasLength(2));

      // AI SDK semantics: `text` is from the last step.
      expect(await result.text, equals('Done'));

      final steps = await result.steps;
      expect(steps, hasLength(2));
      expect(steps[0].toolCalls, hasLength(1));
      expect(steps[0].toolResults, hasLength(1));
      expect(jsonDecode(steps[0].toolResults.single.content),
          equals({'temp': 70}));
      expect(steps[1].toolCalls, isEmpty);

      final totalUsage = await result.totalUsage;
      expect(totalUsage?.totalTokens, equals(33));
    });

    test('yields error part when model lacks parts-first streaming', () async {
      final model = _NonPartsModel();

      final result = streamText(
        model: model,
        messages: [ChatMessage.user('hi')],
      );

      final parts = await result.fullStream.toList();
      expect(parts.whereType<LLMErrorPart>(), hasLength(1));
      expect(() async => await result.text, throwsA(isA<LLMError>()));
      expect(() async => await result.warnings, throwsA(isA<LLMError>()));
      expect(() async => await result.steps, throwsA(isA<LLMError>()));
    });
  });
}

class _NonPartsModel extends ChatCapability {
  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    return const _FakeChatResponse(text: 'nope');
  }
}
