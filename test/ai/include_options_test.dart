library;

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _FakeMetadataResponse
    implements
        ChatResponse,
        ChatResponseWithRequestMetadata,
        ChatResponseWithResponseMetadata {
  @override
  final String? text;

  @override
  final LLMRequestMetadataPart? requestMetadata;

  @override
  final LLMResponseMetadataPart? responseMetadata;

  const _FakeMetadataResponse({
    this.text,
    this.requestMetadata,
    this.responseMetadata,
  });

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
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async =>
      response;
}

class _FakeStreamingModel extends ChatCapability
    implements ChatStreamPartsCapability {
  final Stream<LLMStreamPart> parts;

  _FakeStreamingModel(this.parts);

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
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
  group('IncludeOptions', () {
    test('generateText strips request/response bodies when disabled', () async {
      final model = _FakeNonStreamingModel(
        _FakeMetadataResponse(
          text: 'ok',
          requestMetadata: const LLMRequestMetadataPart(
            body: {'request': 'payload'},
          ),
          responseMetadata: LLMResponseMetadataPart(
            id: 'resp_1',
            model: 'm',
            body: const {'response': 'payload'},
          ),
        ),
      );

      final result = await generateText(
        model: model,
        messages: [ChatMessage.user('hi')],
        include: const IncludeOptions(
          requestBody: false,
          responseBody: false,
        ),
      );

      expect(result.requestMetadata, isNotNull);
      expect(result.requestMetadata!.body, isNull);

      expect(result.responseMetadata, isNotNull);
      expect(result.responseMetadata!.body, isNull);
    });

    test('streamText strips request/response bodies when disabled', () async {
      final model = _FakeStreamingModel(
        Stream<LLMStreamPart>.fromIterable([
          const LLMRequestMetadataPart(body: {'request': 'payload'}),
          LLMResponseMetadataPart(
            id: 'resp_1',
            model: 'm',
            body: const {'response': 'payload'},
          ),
          const LLMTextDeltaPart('ok'),
          const LLMFinishPart(_FakeMetadataResponse(text: 'ok')),
        ]),
      );

      final result = streamText(
        model: model,
        messages: [ChatMessage.user('hi')],
        include: const IncludeOptions(
          requestBody: false,
          responseBody: false,
        ),
      );

      final parts = await result.fullStream.toList();
      final req = parts.whereType<LLMRequestMetadataPart>().single;
      final resp = parts.whereType<LLMResponseMetadataPart>().single;
      expect(req.body, isNull);
      expect(resp.body, isNull);

      expect(await result.requestMetadata, isNotNull);
      expect((await result.requestMetadata)!.body, isNull);

      expect(await result.responseMetadata, isNotNull);
      expect((await result.responseMetadata)!.body, isNull);
    });
  });
}
