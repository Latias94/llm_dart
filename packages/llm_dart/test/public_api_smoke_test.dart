import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Public API smoke', () {
    test('root entrypoints stay available', () {
      // Prompt-first message model.
      final messages = <ModelMessage>[
        ModelMessage.systemText('You are a helpful assistant.'),
        ChatPromptBuilder.user().text('Hello').build(),
      ];
      expect(messages, hasLength(2));

      // Tools.
      final tool = Tool.function(
        name: 'ping',
        description: 'Ping tool',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: const {},
          required: const [],
        ),
      );
      expect(tool.function.name, equals('ping'));

      // Builder shortcuts (compile-time / API surface guard).
      ai()
          .openai()
          .anthropic()
          .google()
          .deepseek()
          .ollama()
          .xai()
          .phind()
          .groq()
          .openRouter()
          .deepseekOpenAI()
          .groqOpenAI()
          .xaiOpenAI()
          .googleOpenAI()
          .phindOpenAI()
          .githubCopilot()
          .togetherAI()
          .elevenlabs();

      // Model-centric factories (Vercel AI-style).
      final openai = createOpenAI(apiKey: 'test-key');
      final openaiModel = openai.chat('gpt-4o-mini');
      expect(openaiModel, isA<LanguageModel>());

      final anthropic = createAnthropic(apiKey: 'test-key');
      final anthropicModel = anthropic.chat('claude-3-haiku-20240307');
      expect(anthropicModel, isA<LanguageModel>());

      final google = createGoogleGenerativeAI(apiKey: 'test-key');
      final googleModel = google.chat('gemini-1.5-flash');
      expect(googleModel, isA<LanguageModel>());

      final deepseek = createDeepSeek(apiKey: 'test-key');
      final deepseekModel = deepseek.chat('deepseek-chat');
      expect(deepseekModel, isA<LanguageModel>());

      final groq = createGroq(apiKey: 'test-key');
      final groqModel = groq.chat('llama-3.1-8b-instant');
      expect(groqModel, isA<LanguageModel>());

      final xai = createXAI(apiKey: 'test-key');
      final xaiModel = xai.chat('grok-3');
      expect(xaiModel, isA<LanguageModel>());

      final phind = createPhind(apiKey: 'test-key');
      final phindModel = phind.chat('phind-code-1');
      expect(phindModel, isA<LanguageModel>());

      // Audio factory (speech models).
      final elevenlabs = createElevenLabs(apiKey: 'test-key');
      final tts = elevenlabs.speech('eleven_multilingual_v2');
      expect(tts, isA<AudioCapability>());

      // Audio helpers (model-only) should remain available from the bundle.
      Future<List<int>> Function(
        AudioCapability, {
        required String text,
        CancellationToken? cancelToken,
      }) ttsHelper = generateSpeechWithModel;
      expect(ttsHelper, isNotNull);

      Future<String> Function(
        AudioCapability, {
        required List<int> audio,
        CancellationToken? cancelToken,
      }) sttHelper = transcribeWithModel;
      expect(sttHelper, isNotNull);

      // Embedding helpers (model-only).
      final embedding = openai.textEmbedding('text-embedding-3-small');
      expect(embedding, isA<EmbeddingCapability>());

      Future<List<List<double>>> Function(
        EmbeddingCapability, {
        required List<String> input,
        CancellationToken? cancelToken,
      }) embedHelper = embedWithModel;
      expect(embedHelper, isNotNull);

      Future<RerankResult> Function({
        required EmbeddingCapability model,
        required String query,
        required List<String> documents,
        int? topN,
        CancellationToken? cancelToken,
      }) rerankHelper = rerankWithModel;
      expect(rerankHelper, isNotNull);

      // Image helpers (model-only).
      final imageModel = openai.imageModel('gpt-image-1');
      expect(imageModel, isA<ImageGenerationCapability>());

      Future<ImageGenerationResponse> Function(
        ImageGenerationCapability, {
        required String prompt,
        String? modelId,
        String? negativePrompt,
        String? size,
        int? count,
        int? seed,
        int? steps,
        double? guidanceScale,
        bool? enhancePrompt,
        String? style,
        String? quality,
        String? responseFormat,
        String? user,
      }) imageHelper = generateImageWithModel;
      expect(imageHelper, isNotNull);

      // Streaming structured output helper (model-only).
      StreamObjectResult<Map<String, dynamic>> Function({
        required LanguageModel model,
        required OutputSpec<Map<String, dynamic>> output,
        String? prompt,
        ModelMessage? structuredPrompt,
        List<ModelMessage>? promptMessages,
        CancellationToken? cancelToken,
        LanguageModelCallOptions? options,
      }) streamObjectHelper = streamObjectWithModel<Map<String, dynamic>>;
      expect(streamObjectHelper, isNotNull);
    });
  });
}
