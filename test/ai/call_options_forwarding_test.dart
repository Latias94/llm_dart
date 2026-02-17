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
  })  : thinking = null,
        toolCalls = null,
        usage = null,
        providerMetadata = null;
}

class _CallOptionsModel extends ChatCapability
    implements ChatCallOptionsCapability {
  bool calledPlain = false;
  bool calledWithOptions = false;
  LLMCallOptions? lastOptions;

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async {
    calledPlain = true;
    return const _TextResponse(text: 'ok');
  }

  @override
  Future<ChatResponse> chatWithToolsWithCallOptions(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async {
    calledWithOptions = true;
    lastOptions = callOptions;
    return const _TextResponse(text: 'ok');
  }
}

class _StreamingCallOptionsModel extends ChatCapability
    implements ChatStreamPartsCallOptionsCapability {
  bool calledWithOptions = false;
  LLMCallOptions? lastOptions;

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async {
    return const _TextResponse(text: 'ok');
  }

  @override
  Stream<LLMStreamPart> chatStreamPartsWithCallOptions(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
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

class _TtsCallOptionsModel
    implements TextToSpeechCapability, TextToSpeechCallOptionsCapability {
  bool calledPlain = false;
  bool calledWithOptions = false;
  LLMCallOptions? lastOptions;

  @override
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    CancelToken? cancelToken,
  }) async {
    calledPlain = true;
    return const TTSResponse(audioData: <int>[1], contentType: 'audio/mpeg');
  }

  @override
  Future<TTSResponse> textToSpeechWithCallOptions(
    TTSRequest request, {
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async {
    calledWithOptions = true;
    lastOptions = callOptions;
    return const TTSResponse(audioData: <int>[1], contentType: 'audio/mpeg');
  }
}

class _SttCallOptionsModel
    implements SpeechToTextCapability, SpeechToTextCallOptionsCapability {
  bool calledPlain = false;
  bool calledWithOptions = false;
  LLMCallOptions? lastOptions;

  @override
  Future<STTResponse> speechToText(
    STTRequest request, {
    CancelToken? cancelToken,
  }) async {
    calledPlain = true;
    return const STTResponse(text: 'ok');
  }

  @override
  Future<STTResponse> speechToTextWithCallOptions(
    STTRequest request, {
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async {
    calledWithOptions = true;
    lastOptions = callOptions;
    return const STTResponse(text: 'ok');
  }
}

class _ImageCallOptionsModel
    implements ImageGenerationCapability, ImageGenerationCallOptionsCapability {
  bool calledPlain = false;
  bool calledWithOptions = false;
  LLMCallOptions? lastOptions;

  @override
  Future<ImageGenerationResponse> generateImages(
    ImageGenerationRequest request,
  ) async {
    calledPlain = true;
    return const ImageGenerationResponse(
      images: <GeneratedImage>[
        GeneratedImage(url: 'https://example.com/a.png')
      ],
    );
  }

  @override
  Future<ImageGenerationResponse> generateImagesWithCallOptions(
    ImageGenerationRequest request, {
    required LLMCallOptions callOptions,
  }) async {
    calledWithOptions = true;
    lastOptions = callOptions;
    return const ImageGenerationResponse(
      images: <GeneratedImage>[
        GeneratedImage(url: 'https://example.com/a.png')
      ],
    );
  }

  @override
  Future<ImageGenerationResponse> editImage(ImageEditRequest request) =>
      throw UnimplementedError();

  @override
  Future<ImageGenerationResponse> editImageWithCallOptions(
    ImageEditRequest request, {
    required LLMCallOptions callOptions,
  }) =>
      throw UnimplementedError();

  @override
  Future<ImageGenerationResponse> createVariation(
          ImageVariationRequest request) =>
      throw UnimplementedError();

  @override
  Future<ImageGenerationResponse> createVariationWithCallOptions(
    ImageVariationRequest request, {
    required LLMCallOptions callOptions,
  }) =>
      throw UnimplementedError();

  @override
  List<String> getSupportedSizes() => const <String>[];

  @override
  List<String> getSupportedFormats() => const <String>[];

  @override
  bool get supportsImageEditing => true;

  @override
  bool get supportsImageVariations => true;
}

class _EmbeddingCallOptionsModel
    implements EmbeddingCapability, EmbeddingCallOptionsCapability {
  bool calledPlain = false;
  bool calledWithOptions = false;
  LLMCallOptions? lastOptions;

  @override
  Future<EmbeddingResponse> embed(
    List<String> input, {
    CancelToken? cancelToken,
  }) async {
    calledPlain = true;
    return const EmbeddingResponse(
      embeddings: [
        [0.0],
      ],
    );
  }

  @override
  Future<EmbeddingResponse> embedWithCallOptions(
    List<String> input, {
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async {
    calledWithOptions = true;
    lastOptions = callOptions;
    return const EmbeddingResponse(
      embeddings: [
        [1.0],
      ],
    );
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

    test('generateText injects toolChoice/parallelToolCalls via callOptions',
        () async {
      final model = _CallOptionsModel();

      final result = await generateText(
        model: model,
        messages: [ChatMessage.user('hi')],
        toolChoice: const AnyToolChoice(),
        parallelToolCalls: false,
      );

      expect(result.text, equals('ok'));
      expect(model.calledPlain, isFalse);
      expect(model.calledWithOptions, isTrue);
      expect(
        model.lastOptions?.body,
        equals({'tool_choice': 'required', 'parallel_tool_calls': false}),
      );
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

    test('streamChatParts injects toolChoice via callOptions', () async {
      final model = _StreamingCallOptionsModel();

      final parts = await streamChatParts(
        model: model,
        messages: [ChatMessage.user('hi')],
        toolChoice: const NoneToolChoice(),
      ).toList();

      expect(
        parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join(),
        equals('ok'),
      );
      expect(model.calledWithOptions, isTrue);
      expect(model.lastOptions?.body, equals({'tool_choice': 'none'}));
    });

    test('embed uses EmbeddingCallOptionsCapability when callOptions set',
        () async {
      final model = _EmbeddingCallOptionsModel();

      final result = await embedMany(
        model: model,
        values: const ['hi'],
        callOptions: const LLMCallOptions(headers: {'x-test': '1'}),
      );

      expect(
          result.embeddings,
          equals(const [
            [1.0]
          ]));
      expect(model.calledPlain, isFalse);
      expect(model.calledWithOptions, isTrue);
      expect(model.lastOptions?.headers, equals({'x-test': '1'}));
    });

    test('generateSpeech uses TextToSpeechCallOptionsCapability when set',
        () async {
      final model = _TtsCallOptionsModel();

      await generateSpeech(
        model: model,
        request: const TTSRequest(text: 'hi'),
        callOptions: const LLMCallOptions(headers: {'x-test': '1'}),
      );

      expect(model.calledPlain, isFalse);
      expect(model.calledWithOptions, isTrue);
      expect(model.lastOptions?.headers, equals({'x-test': '1'}));
    });

    test('transcribe uses SpeechToTextCallOptionsCapability when set',
        () async {
      final model = _SttCallOptionsModel();

      await transcribe(
        model: model,
        request: const STTRequest(audioData: <int>[1, 2]),
        callOptions: const LLMCallOptions(headers: {'x-test': '1'}),
      );

      expect(model.calledPlain, isFalse);
      expect(model.calledWithOptions, isTrue);
      expect(model.lastOptions?.headers, equals({'x-test': '1'}));
    });

    test('generateImage uses ImageGenerationCallOptionsCapability when set',
        () async {
      final model = _ImageCallOptionsModel();

      await generateImage(
        model: model,
        prompt: const GenerateImagePrompt.text('hi'),
        callOptions: const LLMCallOptions(headers: {'x-test': '1'}),
      );

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

      final result = await embedMany(
        model: provider,
        values: const ['hello'],
        callOptions: const LLMCallOptions(
          headers: {'x-test': '1'},
          body: {'model': 'override-embedding-model'},
        ),
      );

      expect(
          result.embeddings,
          equals(const [
            [0.1, 0.2]
          ]));
      expect(client.lastEndpoint, equals('embeddings'));
      expect(client.lastRequestHeaders, equals({'x-test': '1'}));
      expect(client.lastJsonBody, isNotNull);
      expect(client.lastJsonBody!['model'], equals('override-embedding-model'));
      expect(client.lastJsonBody!['input'], equals(const ['hello']));
    });
  });

  group('callOptions integration (OpenAI-style audio/images modules)', () {
    test('textToSpeech forwards callOptions.headers/body', () async {
      const config = OpenAICompatibleConfig(
        providerId: 'openai',
        providerName: 'OpenAI',
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o-mini',
      );

      final client = FakeOpenAIClient(config);
      final audio = OpenAIStyleAudio(client, config);

      await generateSpeech(
        model: audio,
        request: const TTSRequest(text: 'hi'),
        callOptions: const LLMCallOptions(
          headers: {'x-test': '1'},
          body: {'model': 'override-tts-model'},
        ),
      );

      expect(client.lastEndpoint, equals('audio/speech'));
      expect(client.lastRequestHeaders, equals({'x-test': '1'}));
      expect(client.lastJsonBody?['model'], equals('override-tts-model'));
    });

    test('transcribe forwards callOptions.headers and merges callOptions.body',
        () async {
      const config = OpenAICompatibleConfig(
        providerId: 'openai',
        providerName: 'OpenAI',
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o-mini',
      );

      final client = FakeOpenAIClient(config)
        ..formResponse = const {'text': 'hello'};
      final audio = OpenAIStyleAudio(client, config);

      await transcribe(
        model: audio,
        request: const STTRequest(
          audioData: <int>[1, 2, 3],
          language: 'en',
        ),
        callOptions: const LLMCallOptions(
          headers: {'x-test': '1'},
          body: {'language': 'zh', 'temperature': 0.123},
        ),
      );

      expect(client.lastEndpoint, equals('audio/transcriptions'));
      expect(client.lastRequestHeaders, equals({'x-test': '1'}));

      final fields = client.lastFormData?.fields ?? const [];
      final asMap = <String, String>{for (final e in fields) e.key: e.value};
      expect(asMap['language'], equals('zh'));
      expect(asMap['temperature'], equals('0.123'));
    });

    test('generateImages forwards callOptions.headers/body', () async {
      const config = OpenAICompatibleConfig(
        providerId: 'openai',
        providerName: 'OpenAI',
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o-mini',
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = const {
          'data': [
            {'url': 'https://example.com/1.png'}
          ],
        };
      final images = OpenAIStyleImages(client, config);

      await generateImage(
        model: images,
        prompt: const GenerateImagePrompt.text('hi'),
        callOptions: const LLMCallOptions(
          headers: {'x-test': '1'},
          body: {'model': 'override-image-model'},
        ),
      );

      expect(client.lastEndpoint, equals('images/generations'));
      expect(client.lastRequestHeaders, equals({'x-test': '1'}));
      expect(client.lastJsonBody?['model'], equals('override-image-model'));
    });
  });
}
