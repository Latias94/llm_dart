library;

import 'dart:convert';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _FakeChatResponseWithFinishReason
    implements ChatResponseWithFinishReason {
  @override
  final LLMFinishReason? finishReason;

  @override
  final UsageInfo? usage;

  final Map<String, dynamic>? _providerMetadata;

  const _FakeChatResponseWithFinishReason({
    this.finishReason,
    this.usage,
    Map<String, dynamic>? providerMetadata,
  }) : _providerMetadata = providerMetadata;

  @override
  String? get text => null;

  @override
  String? get thinking => null;

  @override
  List<ToolCall>? get toolCalls => null;

  @override
  Map<String, dynamic>? get providerMetadata => _providerMetadata;
}

class _FakeStreamChatModel extends ChatCapability
    implements ChatStreamPartsCapability {
  final List<LLMStreamPart> parts;

  _FakeStreamChatModel(this.parts);

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

void main() {
  group('streamObject', () {
    const schema = ParametersSchema(
      schemaType: 'object',
      properties: {
        'city': ParameterProperty(
          propertyType: 'string',
          description: 'city',
        ),
        'temp': ParameterProperty(
          propertyType: 'number',
          description: 'temp',
        ),
      },
      required: ['city'],
    );

    test('parses final object from tool call arguments', () async {
      const usage =
          UsageInfo(promptTokens: 1, completionTokens: 2, totalTokens: 3);
      const finishReason = LLMFinishReason(
        unified: LLMUnifiedFinishReason.stop,
        raw: 'stop',
      );

      final model = _FakeStreamChatModel([
        LLMToolCallStartPart(
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(
              name: 'return_object',
              arguments: '{"city":"SF",',
            ),
          ),
        ),
        LLMToolCallDeltaPart(
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(
              name: '',
              arguments: '"temp":70}',
            ),
          ),
        ),
        const LLMToolCallEndPart('call_1'),
        LLMFinishPart(
          const _FakeChatResponseWithFinishReason(
            finishReason: finishReason,
            usage: usage,
            providerMetadata: {
              'openai': {'id': 'resp_1'}
            },
          ),
          usage: usage,
          finishReason: finishReason,
        ),
      ]);

      final result = streamObject(
        model: model,
        messages: [ChatMessage.user('hi')],
        schema: schema,
      );

      final partial = await result.partialObjectStream.toList();
      expect(partial, isNotEmpty);
      expect(partial.last, containsPair('city', 'SF'));

      final obj = await result.object;
      expect(obj, containsPair('city', 'SF'));
      expect(obj, containsPair('temp', 70));

      expect((await result.usage)?.totalTokens, equals(3));
      expect((await result.finishReason)?.unified,
          equals(LLMUnifiedFinishReason.stop));
      expect(await result.providerMetadata, contains('openai'));

      final finalResult = await result.finalResult;
      expect(finalResult.object, containsPair('city', 'SF'));
    });

    test('fails when object does not match schema', () async {
      final model = _FakeStreamChatModel([
        LLMToolCallStartPart(
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(
              name: 'return_object',
              arguments: '{"temp":70}',
            ),
          ),
        ),
        const LLMToolCallEndPart('call_1'),
        const LLMFinishPart(_FakeChatResponseWithFinishReason()),
      ]);

      final result = streamObject(
        model: model,
        messages: [ChatMessage.user('hi')],
        schema: schema,
      );

      expect(() async => await result.object, throwsA(isA<LLMError>()));
    });

    test('falls back to parsing a JSON object from text', () async {
      final model = _FakeStreamChatModel([
        const LLMTextStartPart(),
        const LLMTextDeltaPart('Here: '),
        const LLMTextDeltaPart('{"city":"SF","temp":70}'),
        const LLMTextEndPart('Here: {"city":"SF","temp":70}'),
        const LLMFinishPart(_FakeChatResponseWithFinishReason()),
      ]);

      final result = streamObject(
        model: model,
        messages: [ChatMessage.user('hi')],
        schema: schema,
      );

      final obj = await result.object;
      expect(obj, containsPair('city', 'SF'));
      expect(obj, containsPair('temp', 70));
    });

    test('emits best-effort partial objects only when valid JSON exists',
        () async {
      final model = _FakeStreamChatModel([
        LLMToolCallStartPart(
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(
              name: 'return_object',
              arguments: '{"city":"SF"',
            ),
          ),
        ),
        LLMToolCallDeltaPart(
          ToolCall(
            id: 'call_1',
            callType: 'function',
            function: FunctionCall(
              name: '',
              arguments: ',"temp":70}',
            ),
          ),
        ),
        const LLMToolCallEndPart('call_1'),
        const LLMFinishPart(_FakeChatResponseWithFinishReason()),
      ]);

      final result = streamObject(
        model: model,
        messages: [ChatMessage.user('hi')],
        schema: schema,
      );

      final partial = await result.partialObjectStream.toList();
      expect(partial.map(jsonEncode).toList(),
          contains(jsonEncode({'city': 'SF', 'temp': 70})));
    });
  });
}
