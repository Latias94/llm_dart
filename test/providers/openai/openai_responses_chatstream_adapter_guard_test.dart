// ignore_for_file: deprecated_member_use
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:llm_dart_openai/client.dart';
import 'package:llm_dart_openai/responses.dart' as openai_responses;
import 'package:test/test.dart';

class _ThrowingStreamClient extends OpenAIClient {
  _ThrowingStreamClient(super.config);

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) {
    throw StateError('postStreamRaw must not be called by chatStream');
  }
}

class _FakeChatResponse implements ChatResponse {
  @override
  final String? text;

  const _FakeChatResponse({this.text});

  @override
  String? get thinking => null;

  @override
  List<ToolCall>? get toolCalls => null;

  @override
  UsageInfo? get usage => null;

  @override
  Map<String, dynamic>? get providerMetadata => null;
}

class _AdapterOnlyResponses extends openai_responses.OpenAIResponses {
  bool didCallChatStreamParts = false;

  _AdapterOnlyResponses(super.client, super.config);

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    didCallChatStreamParts = true;
    yield const LLMTextDeltaPart('hi');
    yield const LLMFinishPart(_FakeChatResponse(text: 'hi'));
  }
}

void main() {
  group('OpenAI Responses chatStream adapter guard', () {
    test('chatStream is derived from chatStreamParts', () async {
      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-5-mini',
        useResponsesAPI: true,
      );

      final client = _ThrowingStreamClient(config);
      final responses = _AdapterOnlyResponses(client, config);

      final events =
          await responses.chatStream([ChatMessage.user('x')]).toList();

      expect(responses.didCallChatStreamParts, isTrue);
      expect(events.whereType<TextDeltaEvent>().single.delta, equals('hi'));
      expect(events.whereType<CompletionEvent>(), hasLength(1));
    });
  });
}
