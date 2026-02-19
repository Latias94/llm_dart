import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _FakeChatResponse implements ChatResponse {
  @override
  final String? text;

  @override
  final List<ToolCall>? toolCalls;

  const _FakeChatResponse({this.text}) : toolCalls = null;

  @override
  String? get thinking => null;

  @override
  UsageInfo? get usage => null;

  @override
  Map<String, dynamic>? get providerMetadata => null;
}

class _FakeChatModel implements ChatCapability {
  final ChatResponse response;

  const _FakeChatModel(this.response);

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async =>
      response;

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) =>
      chatWithTools(messages, null, providerTools: providerTools);

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async =>
      'summary';
}

class _FakeImageModel extends ImageGenerationCapability {
  final ImageGenerationResponse response;

  _FakeImageModel(this.response);

  @override
  Future<ImageGenerationResponse> generateImages(
    ImageGenerationRequest request,
  ) async =>
      response;

  @override
  Future<ImageGenerationResponse> editImage(ImageEditRequest request) async =>
      response;

  @override
  Future<ImageGenerationResponse> createVariation(
    ImageVariationRequest request,
  ) async =>
      response;

  @override
  List<String> getSupportedSizes() => const [];

  @override
  List<String> getSupportedFormats() => const [];
}

class _FakeAudioModel
    implements TextToSpeechCapability, SpeechToTextCapability {
  final TTSResponse ttsResponse;
  final STTResponse sttResponse;

  const _FakeAudioModel({
    required this.ttsResponse,
    required this.sttResponse,
  });

  @override
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    CancelToken? cancelToken,
  }) async =>
      ttsResponse;

  @override
  Future<STTResponse> speechToText(
    STTRequest request, {
    CancelToken? cancelToken,
  }) async =>
      sttResponse;
}

class _FakeVideoModel implements ExperimentalVideoGenerationCapability {
  final ExperimentalVideoGenerationResponse response;

  const _FakeVideoModel(this.response);

  @override
  Future<ExperimentalVideoGenerationResponse> generateVideos(
    ExperimentalVideoGenerationRequest request, {
    CancelToken? cancelToken,
  }) async =>
      response;
}

void main() {
  group('AI SDK-style no-output errors', () {
    test('GenerateTextResult.output throws NoOutputGeneratedError', () {
      final result = GenerateTextResult(
        rawResponse: const _FakeChatResponse(text: null),
        text: null,
      );
      expect(() => result.output, throwsA(isA<NoOutputGeneratedError>()));
    });

    test('generateObject throws NoObjectGeneratedError when no output',
        () async {
      final schema = Schema.params(
        properties: {
          'ok': Schema.string('ok'),
        },
        required: ['ok'],
      );

      final model = _FakeChatModel(const _FakeChatResponse(text: null));

      await expectLater(
        () => generateObject(
          model: model,
          messages: [ChatMessage.user('hi')],
          schema: schema,
        ),
        throwsA(isA<NoObjectGeneratedError>()),
      );
    });

    test('generateImage throws NoImageGeneratedError when empty', () async {
      final model = _FakeImageModel(
        const ImageGenerationResponse(images: []),
      );

      await expectLater(
        () => generateImage(
          model: model,
          prompt: const GenerateImagePrompt.text('cat'),
        ),
        throwsA(isA<NoImageGeneratedError>()),
      );
    });

    test('generateSpeech throws NoSpeechGeneratedError when empty', () async {
      final model = _FakeAudioModel(
        ttsResponse: const TTSResponse(audioData: []),
        sttResponse: const STTResponse(text: 'ignored'),
      );

      await expectLater(
        () => generateSpeechFromText(model: model, text: 'hi'),
        throwsA(isA<NoSpeechGeneratedError>()),
      );
    });

    test('transcribe throws NoTranscriptGeneratedError when empty', () async {
      final model = _FakeAudioModel(
        ttsResponse: const TTSResponse(audioData: [1]),
        sttResponse: const STTResponse(text: '   '),
      );

      await expectLater(
        () => transcribeFromAudioBytes(model: model, audioData: const [0]),
        throwsA(isA<NoTranscriptGeneratedError>()),
      );
    });

    test('experimentalGenerateVideo throws NoVideoGeneratedError when empty',
        () async {
      final model = _FakeVideoModel(
        const ExperimentalVideoGenerationResponse(videos: []),
      );

      await expectLater(
        () => experimentalGenerateVideo(
          model: model,
          request: const ExperimentalVideoGenerationRequest(prompt: 'hi'),
        ),
        throwsA(isA<NoVideoGeneratedError>()),
      );
    });
  });
}
