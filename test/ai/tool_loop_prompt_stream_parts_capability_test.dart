import 'package:test/test.dart';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

class _FakePromptToolStreamPartsModel extends ChatCapability
    implements PromptChatStreamPartsCapability {
  int chatWithToolsCalls = 0;
  int chatPromptStreamPartsCalls = 0;
  int _step = 0;
  final bool _useProviderToolCall;

  _FakePromptToolStreamPartsModel({bool useProviderToolCall = false})
      : _useProviderToolCall = useProviderToolCall;

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async {
    chatWithToolsCalls++;
    throw StateError(
      'chatWithTools should not be called for PromptChatStreamPartsCapability',
    );
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamParts(
    Prompt prompt, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    chatPromptStreamPartsCalls++;

    if (_step == 0) {
      _step++;
      if (_useProviderToolCall) {
        yield const LLMProviderToolCallPart(
          toolCallId: 'pt_1',
          toolName: 'computer',
          input: '{"action":"screenshot"}',
          providerExecuted: false,
        );
        yield LLMFinishPart(_FakeStreamResponse());
        return;
      }
      yield const LLMToolCallStartPart(
        ToolCall(
          id: 'toolu_1',
          callType: 'function',
          function: FunctionCall(
            name: 'get_weather',
            arguments: '{"location":"SF"}',
          ),
        ),
      );
      yield const LLMToolCallEndPart('toolu_1');

      yield LLMFinishPart(_FakeStreamResponse());
      return;
    }

    yield const LLMTextStartPart();
    yield const LLMTextDeltaPart('done');
    yield const LLMTextEndPart('done');
    yield LLMFinishPart(_FakeStreamResponse());
  }
}

class _FakeStreamResponse extends ChatResponse {
  _FakeStreamResponse();

  @override
  String? get text => null;

  @override
  List<ToolCall>? get toolCalls => null;
}

void main() {
  group('Tool loop PromptChatStreamPartsCapability', () {
    test('streamToolLoopParts(promptIr) prefers chatPromptStreamParts()',
        () async {
      final model = _FakePromptToolStreamPartsModel();

      final parts = await streamToolLoopParts(
        model: model,
        promptIr: Prompt(messages: [PromptMessage.user('hi')]),
        tools: [
          Tool.function(
            name: 'get_weather',
            description: 'Get weather for a location',
            parameters: ParametersSchema(
              schemaType: 'object',
              properties: {
                'location': ParameterProperty(
                  propertyType: 'string',
                  description: 'City name',
                ),
              },
              required: ['location'],
            ),
          ),
        ],
        toolHandlers: {
          'get_weather': (input, options) async => {'ok': true},
        },
      ).toList();

      expect(parts.whereType<LLMToolCallStartPart>(), isNotEmpty);
      expect(parts.whereType<LLMToolResultPart>(), isNotEmpty);

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals('done'));

      expect(model.chatWithToolsCalls, equals(0));
      expect(model.chatPromptStreamPartsCalls, greaterThanOrEqualTo(1));
    });

    test(
        'streamToolLoopParts(promptIr) executes provider-defined tool calls when providerExecuted=false',
        () async {
      final model = _FakePromptToolStreamPartsModel(useProviderToolCall: true);
      var handlerCalls = 0;

      final parts = await streamToolLoopParts(
        model: model,
        promptIr: Prompt(messages: [PromptMessage.user('hi')]),
        tools: const [],
        toolHandlers: {
          'computer': (input, options) async {
            handlerCalls++;
            expect(options.toolCallId, equals('pt_1'));
            expect(options.toolName, equals('computer'));
            expect(options.rawArguments, contains('screenshot'));
            return {'ok': true};
          },
        },
      ).toList();

      expect(handlerCalls, equals(1));
      expect(parts.whereType<LLMProviderToolCallPart>(), isNotEmpty);
      expect(parts.whereType<LLMToolResultPart>(), isNotEmpty);

      final toolResult = parts.whereType<LLMToolResultPart>().single.result;
      expect(toolResult.toolCallId, equals('pt_1'));
      expect(toolResult.isError, isFalse);
      expect(toolResult.result, equals({'ok': true}));

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals('done'));
    });

    test('streamToolLoopParts(promptIr) supports file reference parts',
        () async {
      final model = _FakePromptToolStreamPartsModel();

      final parts = await streamToolLoopParts(
        model: model,
        promptIr: const Prompt(
          messages: [
            PromptMessage(
              role: PromptRole.user,
              parts: [
                FileUrlPart(
                  mime: FileMime.pdf,
                  url: 'https://example.com/a.pdf',
                ),
                FileIdPart(
                  mime: FileMime.pdf,
                  id: 'files/123',
                ),
              ],
            ),
          ],
        ),
        tools: [
          Tool.function(
            name: 'get_weather',
            description: 'Get weather for a location',
            parameters: ParametersSchema(
              schemaType: 'object',
              properties: {
                'location': ParameterProperty(
                  propertyType: 'string',
                  description: 'City name',
                ),
              },
              required: ['location'],
            ),
          ),
        ],
        toolHandlers: {
          'get_weather': (input, options) async => {'ok': true},
        },
      ).toList();

      final finish = parts.whereType<LLMFinishPart>().last;
      expect(finish.response.text, equals('done'));

      expect(model.chatWithToolsCalls, equals(0));
      expect(model.chatPromptStreamPartsCalls, greaterThanOrEqualTo(1));
    });
  });
}
