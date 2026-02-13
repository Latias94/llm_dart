import 'dart:async';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:test/test.dart';

import '../utils/fakes/openai_fake_client.dart';

class _TextResponse implements ChatResponse {
  @override
  final String? text;

  @override
  final String? thinking;

  @override
  final List<ToolCall>? toolCalls;

  @override
  final UsageInfo? usage;

  @override
  final Map<String, dynamic>? providerMetadata;

  const _TextResponse({
    this.text,
    this.thinking,
    this.toolCalls,
    this.usage,
    this.providerMetadata,
  });
}

class _CallOptionsModel extends ChatCapability implements ChatCallOptionsCapability {
  bool calledPlain = false;
  bool calledWithOptions = false;
  LLMCallOptions? lastOptions;

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    calledPlain = true;
    return const _TextResponse(text: 'ok');
  }

  @override
  Future<ChatResponse> chatWithToolsWithCallOptions(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async {
    calledWithOptions = true;
    lastOptions = callOptions;
    return const _TextResponse(text: 'ok');
  }
}

class _StreamingCallOptionsModel
    extends ChatCapability
    implements ChatStreamPartsCallOptionsCapability {
  bool calledWithOptions = false;
  LLMCallOptions? lastOptions;

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    return const _TextResponse(text: 'ok');
  }

  @override
  Stream<LLMStreamPart> chatStreamPartsWithCallOptions(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async* {
    calledWithOptions = true;
    lastOptions = callOptions;
    yield const LLMTextStartPart(blockId: '0');
    yield const LLMTextDeltaPart('ok', blockId: '0');
    yield const LLMTextEndPart('ok', blockId: '0');
    yield LLMFinishPart(const _TextResponse(text: 'ok'));
  }
}

class _EmbeddingCallOptionsModel
    implements EmbeddingCapability, EmbeddingCallOptionsCapability {
  bool calledPlain = false;
  bool calledWithOptions = false;
  LLMCallOptions? lastOptions;

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancelToken? cancelToken,
  }) async {
    calledPlain = true;
    return const [
      [0.0]
    ];
  }

  @override
  Future<List<List<double>>> embedWithCallOptions(
    List<String> input, {
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async {
    calledWithOptions = true;
    lastOptions = callOptions;
    return const [
      [1.0]
    ];
  }
}

void main() {
  group('callOptions forwarding (llm_dart_ai)', () {
    test('generateText uses ChatCallOptionsCapability when callOptions set',
        () async {
      final model = _CallOptionsModel();

      final result = await generateText(
        model: model,
        messages: [ChatMessage.user('hi')],
        callOptions: const LLMCallOptions(
          headers: {'x-test': '1'},
          body: {'temperature': 0.123},
        ),
      );

      expect(result.text, equals('ok'));
      expect(model.calledPlain, isFalse);
      expect(model.calledWithOptions, isTrue);
      expect(model.lastOptions?.headers, equals({'x-test': '1'}));
      expect(model.lastOptions?.body, equals({'temperature': 0.123}));
    });

    test('streamChatParts uses ChatStreamPartsCallOptionsCapability when set',
        () async {
      final model = _StreamingCallOptionsModel();

      final parts = await streamChatParts(
        model: model,
        messages: [ChatMessage.user('hi')],
        callOptions: const LLMCallOptions(
          headers: {'x-test': '1'},
        ),
      ).toList();

      expect(parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join(),
          equals('ok'));
      expect(model.calledWithOptions, isTrue);
      expect(model.lastOptions?.headers, equals({'x-test': '1'}));
    });

    test('embed uses EmbeddingCallOptionsCapability when callOptions set',
        () async {
      final model = _EmbeddingCallOptionsModel();

      final vectors = await embed(
        model: model,
        input: const ['hi'],
        callOptions: const LLMCallOptions(headers: {'x-test': '1'}),
      );

      expect(vectors, equals(const [
        [1.0]
      ]));
      expect(model.calledPlain, isFalse);
      expect(model.calledWithOptions, isTrue);
      expect(model.lastOptions?.headers, equals({'x-test': '1'}));
    });
  });

  group('callOptions integration (OpenAI-compatible provider)', () {
    test('generateText merges callOptions.body into request payload', () async {
      const config = OpenAICompatibleConfig(
        providerId: 'openai',
        providerName: 'OpenAI',
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o-mini',
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = const {
          'id': 'chatcmpl_1',
          'model': 'gpt-4o-mini',
          'choices': [
            {
              'index': 0,
              'finish_reason': 'stop',
              'message': {'role': 'assistant', 'content': 'hi'},
            }
          ],
        };

      final provider = OpenAICompatibleChatProvider(
        client,
        config,
        const {LLMCapability.chat},
      );

      await generateText(
        model: provider,
        messages: [ChatMessage.user('x')],
        callOptions: const LLMCallOptions(
          headers: {'x-test': '1'},
          body: {'temperature': 0.123, 'model': 'override-model'},
        ),
      );

      expect(client.lastEndpoint, equals('chat/completions'));
      expect(client.lastRequestHeaders, equals({'x-test': '1'}));
      expect(client.lastJsonBody, isNotNull);
      expect(client.lastJsonBody!['temperature'], equals(0.123));
      expect(client.lastJsonBody!['model'], equals('override-model'));
    });

    test('embed forwards callOptions.headers/body into embeddings request',
        () async {
      const config = OpenAICompatibleConfig(
        providerId: 'openai',
        providerName: 'OpenAI',
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'text-embedding-3-small',
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = const {
          'data': [
            {
              'embedding': [0.1, 0.2]
            }
          ],
        };

      final provider = OpenAICompatibleChatEmbeddingProvider(
        client,
        config,
        const {LLMCapability.chat, LLMCapability.embedding},
      );

      final vectors = await embed(
        model: provider,
        input: const ['hello'],
        callOptions: const LLMCallOptions(
          headers: {'x-test': '1'},
          body: {'model': 'override-embedding-model'},
        ),
      );

      expect(vectors, equals(const [
        [0.1, 0.2]
      ]));
      expect(client.lastEndpoint, equals('embeddings'));
      expect(client.lastRequestHeaders, equals({'x-test': '1'}));
      expect(client.lastJsonBody, isNotNull);
      expect(client.lastJsonBody!['model'], equals('override-embedding-model'));
      expect(client.lastJsonBody!['input'], equals(const ['hello']));
    });
  });
}
