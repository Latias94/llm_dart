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

void main() {
  group('ensureBlockEndsPart (via streamChatParts)', () {
    test('closes an open text block before finish', () async {
      final model = _FakeChatModel(const [
        LLMTextStartPart(),
        LLMTextDeltaPart('A'),
        LLMTextDeltaPart('B'),
        LLMFinishPart(_FakeChatResponse(text: 'AB')),
      ]);

      final parts = await streamChatParts(
        model: model,
        messages: [ChatMessage.user('hi')],
      ).toList();

      expect(parts.last, isA<LLMFinishPart>());
      expect(parts[parts.length - 2], isA<LLMTextEndPart>());

      final end = parts[parts.length - 2] as LLMTextEndPart;
      expect(end.text, equals('AB'));
      expect(end.blockId, isNotNull);
    });

    test('closes an open reasoning block before finish', () async {
      final model = _FakeChatModel(const [
        LLMReasoningStartPart(),
        LLMReasoningDeltaPart('x'),
        LLMFinishPart(_FakeChatResponse(text: 'ok')),
      ]);

      final parts = await streamChatParts(
        model: model,
        messages: [ChatMessage.user('hi')],
      ).toList();

      expect(parts.last, isA<LLMFinishPart>());
      expect(parts[parts.length - 2], isA<LLMReasoningEndPart>());

      final end = parts[parts.length - 2] as LLMReasoningEndPart;
      expect(end.thinking, equals('x'));
      expect(end.blockId, isNotNull);
    });

    test('does not duplicate an existing text-end', () async {
      final model = _FakeChatModel(const [
        LLMTextStartPart(),
        LLMTextDeltaPart('A'),
        LLMTextEndPart('A'),
        LLMFinishPart(_FakeChatResponse(text: 'A')),
      ]);

      final parts = await streamChatParts(
        model: model,
        messages: [ChatMessage.user('hi')],
      ).toList();

      expect(parts.whereType<LLMTextEndPart>(), hasLength(1));
    });

    test('closes previous text block before a new text-start', () async {
      final model = _FakeChatModel(const [
        LLMTextStartPart(),
        LLMTextDeltaPart('A'),
        LLMTextStartPart(),
        LLMTextDeltaPart('B'),
        LLMFinishPart(_FakeChatResponse(text: 'AB')),
      ]);

      final parts = await streamChatParts(
        model: model,
        messages: [ChatMessage.user('hi')],
      ).toList();

      final ends = parts.whereType<LLMTextEndPart>().toList();
      expect(ends, hasLength(2));
      expect(ends[0].text, equals('A'));
      expect(ends[1].text, equals('B'));
    });

    test('closes an open tool-input block before finish', () async {
      final model = _FakeChatModel(const [
        LLMToolInputStartPart(
          id: 'id-0',
          toolName: 'tool',
        ),
        LLMToolInputDeltaPart(
          id: 'id-0',
          delta: '{"a":1',
        ),
        LLMFinishPart(_FakeChatResponse(text: 'ok')),
      ]);

      final parts = await streamChatParts(
        model: model,
        messages: [ChatMessage.user('hi')],
      ).toList();

      expect(parts.last, isA<LLMFinishPart>());
      expect(parts[parts.length - 2], isA<LLMToolInputEndPart>());
      expect(
          (parts[parts.length - 2] as LLMToolInputEndPart).id, equals('id-0'));
    });
  });
}
