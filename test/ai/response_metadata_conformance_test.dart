library;

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _FakeChatResponse implements ChatResponse {
  @override
  final String? text;

  @override
  String? get thinking => null;

  @override
  List<ToolCall>? get toolCalls => null;

  @override
  UsageInfo? get usage => null;

  @override
  Map<String, dynamic>? get providerMetadata => null;

  const _FakeChatResponse({this.text});
}

class _FakePartsModel extends ChatCapability
    implements ChatStreamPartsCapability {
  final Stream<LLMStreamPart> parts;

  _FakePartsModel(this.parts);

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) =>
      throw UnsupportedError('not used');

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) =>
      parts;
}

void main() {
  group('response-metadata conformance', () {
    test('ensures finish is last even if metadata arrives late', () async {
      final model = _FakePartsModel(
        Stream<LLMStreamPart>.fromIterable([
          const LLMTextStartPart(),
          const LLMTextDeltaPart('ok'),
          const LLMTextEndPart('ok'),
          const LLMFinishPart(_FakeChatResponse(text: 'ok')),
          LLMResponseMetadataPart(id: 'resp_1', model: 'm'),
          const LLMProviderMetadataPart({
            'openai': {'id': 'resp_1'}
          }),
        ]),
      );

      final parts = await streamChatParts(
        model: model,
        messages: [ChatMessage.user('hi')],
      ).toList();

      expect(parts.first, isA<LLMStreamStartPart>());
      expect(parts.whereType<LLMFinishPart>(), hasLength(1));
      expect(parts.last, isA<LLMFinishPart>());

      final responseMetadata =
          parts.whereType<LLMResponseMetadataPart>().single;
      final providerMetadata =
          parts.whereType<LLMProviderMetadataPart>().single;
      final finishIndex = parts.indexWhere((p) => p is LLMFinishPart);
      expect(parts.indexOf(responseMetadata), lessThan(finishIndex));
      expect(parts.indexOf(providerMetadata), lessThan(finishIndex));
    });

    test('collapses consecutive response-metadata parts into one', () async {
      final model = _FakePartsModel(
        Stream<LLMStreamPart>.fromIterable([
          LLMResponseMetadataPart(id: 'resp_1'),
          LLMResponseMetadataPart(model: 'm1'),
          const LLMTextDeltaPart('ok'),
          const LLMFinishPart(_FakeChatResponse(text: 'ok')),
        ]),
      );

      final parts = await streamChatParts(
        model: model,
        messages: [ChatMessage.user('hi')],
      ).toList();

      final metas = parts.whereType<LLMResponseMetadataPart>().toList();
      expect(metas, hasLength(1));
      expect(metas.single.id, equals('resp_1'));
      expect(metas.single.model, equals('m1'));
    });

    test('drops additional response-metadata parts later in stream', () async {
      final model = _FakePartsModel(
        Stream<LLMStreamPart>.fromIterable([
          LLMResponseMetadataPart(id: 'resp_1', model: 'm1'),
          const LLMTextDeltaPart('ok'),
          LLMResponseMetadataPart(id: 'resp_2', model: 'm2'),
          const LLMFinishPart(_FakeChatResponse(text: 'ok')),
        ]),
      );

      final parts = await streamChatParts(
        model: model,
        messages: [ChatMessage.user('hi')],
      ).toList();

      final metas = parts.whereType<LLMResponseMetadataPart>().toList();
      expect(metas, hasLength(1));
      expect(metas.single.id, equals('resp_1'));
      expect(metas.single.model, equals('m1'));
    });
  });

  group('provider-metadata conformance', () {
    test('collapses consecutive provider metadata parts into one', () async {
      final model = _FakePartsModel(
        Stream<LLMStreamPart>.fromIterable([
          const LLMProviderMetadataPart({
            'openai': {'id': 'resp_1'}
          }),
          const LLMProviderMetadataPart({
            'openai': {'model': 'gpt-test'}
          }),
          const LLMFinishPart(_FakeChatResponse(text: 'ok')),
        ]),
      );

      final parts = await streamChatParts(
        model: model,
        messages: [ChatMessage.user('hi')],
      ).toList();

      final metas = parts.whereType<LLMProviderMetadataPart>().toList();
      expect(metas, hasLength(1));
      expect(
        metas.single.providerMetadata,
        equals({
          'openai': {'id': 'resp_1', 'model': 'gpt-test'}
        }),
      );
    });

    test('drops duplicate provider metadata snapshots', () async {
      const snapshot = {
        'openai': {'id': 'resp_1', 'model': 'gpt-test'}
      };

      final model = _FakePartsModel(
        Stream<LLMStreamPart>.fromIterable([
          const LLMProviderMetadataPart(snapshot),
          const LLMTextDeltaPart('ok'),
          const LLMProviderMetadataPart(snapshot),
          const LLMFinishPart(_FakeChatResponse(text: 'ok')),
        ]),
      );

      final parts = await streamChatParts(
        model: model,
        messages: [ChatMessage.user('hi')],
      ).toList();

      final metas = parts.whereType<LLMProviderMetadataPart>().toList();
      expect(metas, hasLength(1));
      expect(metas.single.providerMetadata, equals(snapshot));
    });
  });
}
