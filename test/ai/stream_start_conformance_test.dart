library;

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/google.dart';
import 'package:test/test.dart';

import '../utils/fakes/google_fake_client.dart';

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

class _FakePartsModel
    implements ChatCapability, ChatStreamPartsCapability, ProviderCapabilities {
  final Stream<LLMStreamPart> parts;

  _FakePartsModel(this.parts);

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) =>
      throw UnsupportedError('not used');

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

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) =>
      throw UnsupportedError('not used');

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
      };

  @override
  bool supports(LLMCapability capability) =>
      supportedCapabilities.contains(capability);
}

void main() {
  group('stream-start conformance', () {
    test('streamChatParts does not duplicate provider stream-start', () async {
      final model = _FakePartsModel(
        Stream<LLMStreamPart>.fromIterable(const [
          LLMStreamStartPart(
            warnings: [
              {'type': 'unsupported', 'feature': 'demo'},
            ],
          ),
          LLMTextDeltaPart('ok'),
          LLMFinishPart(_FakeChatResponse(text: 'ok')),
        ]),
      );

      final parts = await streamChatParts(
        model: model,
        messages: [ChatMessage.user('hi')],
      ).toList();

      expect(parts.first, isA<LLMStreamStartPart>());
      expect(parts.whereType<LLMStreamStartPart>(), hasLength(1));
      expect(
        (parts.first as LLMStreamStartPart).warnings,
        equals([
          {'type': 'unsupported', 'feature': 'demo'},
        ]),
      );
    });

    test('streamToolLoopParts does not duplicate provider stream-start',
        () async {
      final model = _FakePartsModel(
        Stream<LLMStreamPart>.fromIterable([
          const LLMStreamStartPart(
            warnings: [
              {'type': 'unsupported', 'feature': 'demo'},
            ],
          ),
          const LLMFinishPart(_FakeChatResponse(text: 'ok')),
        ]),
      );

      final parts = await streamToolLoopParts(
        model: model,
        messages: [ChatMessage.user('hi')],
        toolHandlers: const <String, ToolCallHandler>{},
        maxSteps: 1,
      ).toList();

      expect(parts.first, isA<LLMStreamStartPart>());
      expect(parts.whereType<LLMStreamStartPart>(), hasLength(1));
      expect(
        (parts.first as LLMStreamStartPart).warnings,
        equals([
          {'type': 'unsupported', 'feature': 'demo'},
        ]),
      );
    });

    test(
        'Google provider stream-start warnings pass through llm_dart_ai wrapper',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-2.5-flash',
        providerOptions: const {
          'google': {
            'webSearchEnabled': true,
          },
        },
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = FakeGoogleClient(config)
        ..streamResponse = Stream<String>.fromIterable(const [
          'data: {"modelVersion":"gemini-2.5-flash","candidates":[{"content":{"parts":[{"text":"ok"}]}}]}\n\n',
          'data: {"candidates":[{"content":{"parts":[{"text":""}]},"finishReason":"STOP"}]}\n\n',
        ]);
      final chat = GoogleChat(client, config);

      final parts = await streamChatParts(
        model: chat,
        messages: [ChatMessage.user('hi')],
        tools: [
          Tool.function(
            name: 'testFunction',
            description: 'Test',
            parameters: const ParametersSchema(
              schemaType: 'object',
              properties: {},
              required: [],
            ),
          ),
        ],
      ).toList();

      expect(parts.first, isA<LLMStreamStartPart>());
      expect(parts.whereType<LLMStreamStartPart>(), hasLength(1));
      expect(
        (parts.first as LLMStreamStartPart).warnings,
        equals([
          {
            'type': 'unsupported',
            'feature': 'combination of function and provider-defined tools',
          },
        ]),
      );
    });
  });
}
