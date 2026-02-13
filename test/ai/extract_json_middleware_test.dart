library;

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _FakeChatResponse implements ChatResponse {
  @override
  final String? text;

  const _FakeChatResponse({this.text});

  @override
  List<ToolCall>? get toolCalls => null;

  @override
  String? get thinking => null;

  @override
  UsageInfo? get usage => null;

  @override
  Map<String, dynamic>? get providerMetadata => null;
}

class _FakeNonStreamingModel extends ChatCapability {
  final ChatResponse response;

  _FakeNonStreamingModel(this.response);

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    return response;
  }
}

class _FakeStreamingModel extends ChatCapability
    implements ChatStreamPartsCapability {
  final Stream<LLMStreamPart> parts;

  _FakeStreamingModel(this.parts);

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    throw UnsupportedError('not used');
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) =>
      parts;
}

void main() {
  group('ExtractJsonMiddleware', () {
    test('strips markdown json fence in non-streaming text', () async {
      final model = wrapLanguageModelWithMiddleware(
        _FakeNonStreamingModel(
          const _FakeChatResponse(text: '```json\n{"value":"test"}\n```'),
        ),
        middlewares: [
          ExtractJsonMiddleware(),
        ],
      );

      final result = await generateText(
        model: model,
        messages: [ChatMessage.user('hi')],
      );

      expect(result.text, equals('{"value":"test"}'));
    });

    test('uses custom transform', () async {
      final model = wrapLanguageModelWithMiddleware(
        _FakeNonStreamingModel(
          const _FakeChatResponse(text: 'PREFIX{\"value\":1}SUFFIX'),
        ),
        middlewares: [
          ExtractJsonMiddleware(
            transform: (t) =>
                t.replaceAll('PREFIX', '').replaceAll('SUFFIX', ''),
          ),
        ],
      );

      final result = await generateText(
        model: model,
        messages: [ChatMessage.user('hi')],
      );

      expect(result.text, equals('{"value":1}'));
    });

    test('strips fences in streaming text deltas', () async {
      final wrapped = wrapLanguageModelWithMiddleware(
        _FakeStreamingModel(
          Stream<LLMStreamPart>.fromIterable([
            const LLMTextStartPart(blockId: '1'),
            const LLMTextDeltaPart('```json\n', blockId: '1'),
            const LLMTextDeltaPart('{"value":"test"}', blockId: '1'),
            const LLMTextDeltaPart('\n```', blockId: '1'),
            const LLMTextEndPart('```json\n{"value":"test"}\n```',
                blockId: '1'),
            const LLMFinishPart(_FakeChatResponse(text: 'ok')),
          ]),
        ),
        middlewares: [
          ExtractJsonMiddleware(),
        ],
      );

      final result = streamText(
        model: wrapped,
        messages: [ChatMessage.user('hi')],
      );

      final fullStreamFuture = result.fullStream.toList();
      expect(await result.text, equals('{"value":"test"}'));

      final parts = await fullStreamFuture;
      final combined =
          parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join();
      expect(combined, equals('{"value":"test"}'));
      expect(combined.contains('```'), isFalse);
    });
  });
}
