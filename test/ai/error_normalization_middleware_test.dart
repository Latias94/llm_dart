import 'dart:async';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _ThrowingChatModel extends ChatCapability
    implements ChatCallOptionsCapability, ChatStreamPartsCallOptionsCapability {
  final Object toThrow;

  _ThrowingChatModel(this.toThrow);

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) {
    throw StateError('chatWithTools should not be used in this test.');
  }

  @override
  Future<ChatResponse> chatWithToolsWithCallOptions(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async {
    throw toThrow;
  }

  @override
  Stream<LLMStreamPart> chatStreamPartsWithCallOptions(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async* {
    throw toThrow;
  }
}

void main() {
  group('ErrorNormalizationMiddleware', () {
    test('wraps unknown chat errors as GenericError', () async {
      final wrapped = wrapLanguageModelWithMiddleware(
        _ThrowingChatModel(StateError('boom')),
        middlewares: const [ErrorNormalizationMiddleware()],
      ) as ChatCallOptionsCapability;

      expect(
        () => wrapped.chatWithToolsWithCallOptions(
          [ChatMessage.user('hi')],
          null,
          callOptions: const LLMCallOptions(headers: {'X-Test': 'a'}),
        ),
        throwsA(isA<GenericError>()),
      );
    });

    test('yields LLMErrorPart for thrown streaming errors', () async {
      final wrapped = wrapLanguageModelWithMiddleware(
        _ThrowingChatModel(const TimeoutError('timeout')),
        middlewares: const [ErrorNormalizationMiddleware()],
      ) as ChatStreamPartsCallOptionsCapability;

      final parts = await wrapped.chatStreamPartsWithCallOptions(
        [ChatMessage.user('hi')],
        callOptions: const LLMCallOptions(headers: {'X-Test': 'a'}),
      ).toList();

      expect(parts.whereType<LLMErrorPart>(), hasLength(1));
      expect(
          (parts.whereType<LLMErrorPart>().single).error, isA<TimeoutError>());
    });
  });
}
