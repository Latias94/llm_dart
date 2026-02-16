import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

import '../utils/fixture_replay.dart';
import '../utils/fakes/fakes.dart';

class _SequencedAnthropicStreamModel
    implements
        ChatCapability,
        ChatStreamPartsCapability,
        ModelIdentityCapability {
  final AnthropicChat _chat;
  final FakeAnthropicClient _client;
  final List<Stream<String>> _sessions;

  var _index = 0;

  _SequencedAnthropicStreamModel({
    required AnthropicChat chat,
    required FakeAnthropicClient client,
    required List<Stream<String>> sessions,
  })  : _chat = chat,
        _client = client,
        _sessions = sessions;

  int get callCount => _index;

  @override
  String get providerId => _chat.providerId;

  @override
  String get modelId => _chat.modelId;

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) =>
      throw UnsupportedError('Use chatStreamParts in this test');

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) =>
      throw UnsupportedError('Use chatStreamParts in this test');

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    if (_index >= _sessions.length) {
      throw StateError('No more fixture sessions configured for fake model');
    }

    _client.streamResponse = _sessions[_index++];

    return _chat.chatStreamParts(
      messages,
      providerTools: providerTools,
      tools: tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) =>
      throw UnsupportedError('not used');
}

void main() {
  group('Anthropic tool loop deferred tool search (fixture)', () {
    test('streams provider tool call + deferred result across steps', () async {
      const fixturePath =
          'test/fixtures/anthropic/messages/anthropic-tool-search-deferred-regex.chunks.txt';

      final sessions = sseStreamsFromChunkFileSplitByTerminalEvent(
        fixturePath,
        isTerminalEvent: isAnthropicMessagesTerminalEvent,
      );
      expect(sessions, hasLength(3));

      final config = AnthropicConfig(
        apiKey: 'test-key',
        providerId: 'anthropic',
        model: 'claude-sonnet-4-5-20250929',
        baseUrl: 'https://api.anthropic.com/v1/',
        stream: true,
      );

      final client = FakeAnthropicClient(config);
      final chat = AnthropicChat(client, config);
      final model = _SequencedAnthropicStreamModel(
        chat: chat,
        client: client,
        sessions: sessions,
      );

      final parts = await streamToolLoopParts(
        model: model,
        messages: [ChatMessage.user('hi')],
        providerTools: const [
          ProviderTool(
            id: 'anthropic.tool_search_regex_20251119',
            name: 'tool_search',
            supportsDeferredResults: true,
          ),
        ],
        toolHandlers: {
          'readNoteTree': (input, options) => const {'ok': true},
          'executeEditorOperation': (input, options) => const {'ok': true},
        },
        maxSteps: 10,
      ).toList();

      expect(model.callCount, equals(3));

      final providerToolCalls =
          parts.whereType<LLMProviderToolCallPart>().toList();
      expect(providerToolCalls, isNotEmpty);
      expect(
        providerToolCalls.any((p) => p.toolName == 'tool_search'),
        isTrue,
      );

      final providerToolResults =
          parts.whereType<LLMProviderToolResultPart>().toList();
      expect(providerToolResults, isNotEmpty);
      expect(
        providerToolResults.any((p) => p.toolName == 'tool_search'),
        isTrue,
      );

      final localToolCalls = parts
          .whereType<LLMToolCallStartPart>()
          .map((p) => p.toolCall)
          .toList();
      final readCallId = localToolCalls
          .firstWhere((c) => c.function.name == 'readNoteTree')
          .id;
      final editCallId = localToolCalls
          .firstWhere((c) => c.function.name == 'executeEditorOperation')
          .id;

      final toolResults = parts.whereType<LLMToolResultPart>().toList();
      final resultIds = toolResults.map((p) => p.result.toolCallId).toSet();
      expect(resultIds, containsAll([readCallId, editCallId]));

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, isNotNull);
      expect(finish.response.text!, contains("I've successfully complete"));
    });
  });
}
