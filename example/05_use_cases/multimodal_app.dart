// ignore_for_file: avoid_print, deprecated_member_use
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart/legacy/chat.dart';

/// 🎭 Multimodal Application - Text, Image, and Audio Processing
///
/// This example demonstrates a comprehensive multimodal AI application:
/// - Image analysis and description
/// - Audio transcription and processing
/// - Text generation and analysis
/// - Cross-modal content creation
/// - Integrated workflow processing
///
/// Usage:
/// dart run multimodal_app.dart
/// dart run multimodal_app.dart --demo
/// dart run multimodal_app.dart --interactive
///
/// Before running, set your API keys:
/// export OPENAI_API_KEY="your-key"
/// export GROQ_API_KEY="your-key"
void main(List<String> arguments) async {
  print('🎭 Multimodal Application - Text, Image, and Audio Processing\n');

  final app = MultimodalApp();
  await app.run(arguments);
}

/// Comprehensive multimodal AI application
class MultimodalApp {
  late LLMBuilder _chatBuilder;
  ImageGenerationCapability? _imageProvider;
  AudioCapability? _audioProvider;

  bool _verbose = false;

  /// Run the multimodal application
  Future<void> run(List<String> arguments) async {
    try {
      // Parse arguments
      final mode = parseArguments(arguments);

      // Initialize AI providers
      await initializeProviders();

      // Run based on mode
      switch (mode) {
        case 'demo':
          await runDemo();
          break;
        case 'interactive':
          await runInteractive();
          break;
        default:
          await runDemo();
      }

      print('\n✅ Multimodal application completed!');
    } catch (e) {
      print('❌ Application error: $e');
      exit(1);
    }
  }

  /// Parse command-line arguments
  String parseArguments(List<String> arguments) {
    if (arguments.contains('--help')) {
      showHelp();
      exit(0);
    }

    if (arguments.contains('--verbose') || arguments.contains('-v')) {
      _verbose = true;
    }

    if (arguments.contains('--interactive')) {
      return 'interactive';
    }

    return 'demo';
  }

  /// Show help information
  void showHelp() {
    print('''
🎭 Multimodal Application - Text, Image, and Audio Processing

USAGE:
    dart run multimodal_app.dart [OPTIONS]

OPTIONS:
    --demo          Run demonstration mode (default)
    --interactive   Run interactive mode
    -v, --verbose   Verbose output
    --help          Show this help

FEATURES:
    📝 Text Analysis      - Content analysis and generation
    🖼️  Image Processing   - Image analysis and generation
    🎵 Audio Processing   - Transcription and synthesis
    🔄 Cross-modal        - Convert between different media types
    📊 Content Creation   - Integrated multimedia workflows

EXAMPLES:
    dart run multimodal_app.dart --demo
    dart run multimodal_app.dart --interactive --verbose
''');
  }

  /// Initialize AI providers
  Future<void> initializeProviders() async {
    print('🔧 Initializing multimodal AI providers...');

    try {
      // Initialize chat builder (Groq for fast text processing)
      final groqKey = Platform.environment['GROQ_API_KEY'] ?? 'gsk-TESTKEY';
      _chatBuilder = ai()
          .groq()
          .apiKey(groqKey)
          .model('llama-3.1-8b-instant')
          .temperature(0.7)
          .maxTokens(1000);

      // Validate configuration and API key
      await _chatBuilder.build();

      if (_verbose) {
        print('✅ Chat provider initialized (Groq)');
      }

      // Initialize OpenAI for image and audio capabilities
      final openaiKey = Platform.environment['OPENAI_API_KEY'] ?? 'sk-TESTKEY';

      // Use capability factory methods for type-safe initialization
      try {
        _imageProvider = await ai()
            .openai()
            .apiKey(openaiKey)
            .model('dall-e-3')
            .buildImageGeneration();
        if (_verbose) {
          print('✅ Image provider initialized (OpenAI DALL-E)');
        }
      } catch (e) {
        if (_verbose) {
          print('⚠️ Image generation not available: $e');
        }
      }

      try {
        _audioProvider = await ai().openai().apiKey(openaiKey).buildAudio();
        if (_verbose) {
          print('✅ Audio provider initialized (OpenAI Whisper)');
        }
      } catch (e) {
        if (_verbose) {
          print('⚠️ Audio processing not available: $e');
        }
      }

      print('🎉 All providers initialized successfully!\n');
    } catch (e) {
      throw Exception('Failed to initialize providers: $e');
    }
  }

  /// Run demonstration mode
  Future<void> runDemo() async {
    print('🎬 Running Multimodal Demo...\n');

    await demonstrateTextAnalysis();
    await demonstrateImageGeneration();
    await demonstrateAudioProcessing();
    await demonstrateCrossModalWorkflow();
  }

  /// Run interactive mode
  Future<void> runInteractive() async {
    print('🎮 Interactive Multimodal Mode');
    print('Available commands: text, image, audio, workflow, quit\n');

    while (true) {
      stdout.write('🎭 Command: ');
      final input = stdin.readLineSync();

      if (input == null || input.toLowerCase() == 'quit') {
        break;
      }

      switch (input.toLowerCase()) {
        case 'text':
          await interactiveTextProcessing();
          break;
        case 'image':
          await interactiveImageProcessing();
          break;
        case 'audio':
          await interactiveAudioProcessing();
          break;
        case 'workflow':
          await interactiveWorkflow();
          break;
        default:
          print(
              '❓ Unknown command. Available: text, image, audio, workflow, quit');
      }
    }
  }

  /// Demonstrate text analysis capabilities
  Future<void> demonstrateTextAnalysis() async {
    print('📝 Text Analysis Demo:');

    final sampleTexts = [
      'The future of artificial intelligence looks incredibly promising with advances in multimodal AI.',
      'Climate change is one of the most pressing challenges of our time, requiring immediate action.',
      'The latest smartphone features an amazing camera and lightning-fast processor.',
    ];

    for (final text in sampleTexts) {
      print('   📄 Analyzing: "${text.substring(0, 50)}..."');

      try {
        final analysis = await analyzeText(text);
        print('   🔍 Analysis: ${analysis.substring(0, 100)}...\n');
      } catch (e) {
        print('   ❌ Analysis failed: $e\n');
      }
    }
  }

  /// Demonstrate image generation
  Future<void> demonstrateImageGeneration() async {
    print('🖼️ Image Generation Demo:');

    final prompts = [
      'A futuristic AI robot helping humans in a modern office',
      'A beautiful landscape with mountains and a serene lake',
      'An abstract representation of multimodal AI processing',
    ];

    for (final prompt in prompts) {
      print('   🎨 Generating: "$prompt"');

      try {
        await generateImage(prompt);
        print('   ✅ Image generated successfully\n');
      } catch (e) {
        print('   ❌ Generation failed: $e\n');
      }
    }
  }

  /// Demonstrate audio processing
  Future<void> demonstrateAudioProcessing() async {
    print('🎵 Audio Processing Demo:');

    // Simulate audio transcription
    final sampleAudioTexts = [
      'Hello, this is a sample audio transcription.',
      'Multimodal AI can process text, images, and audio together.',
      'The future of AI is incredibly exciting and full of possibilities.',
    ];

    for (final text in sampleAudioTexts) {
      print('   🎤 Simulating audio: "$text"');

      try {
        final processed = await processAudioText(text);
        print('   🔊 Processed: ${processed.substring(0, 80)}...\n');
      } catch (e) {
        print('   ❌ Processing failed: $e\n');
      }
    }
  }

  /// Demonstrate cross-modal workflow
  Future<void> demonstrateCrossModalWorkflow() async {
    print('🔄 Cross-Modal Workflow Demo:');

    final scenario = 'Create a social media post about sustainable technology';
    print('   📋 Scenario: $scenario');

    try {
      // Step 1: Generate text content
      print('   📝 Step 1: Generating text content...');
      final textContent = await generateContent(scenario);
      print('   ✅ Text: ${textContent.substring(0, 100)}...');

      // Step 2: Generate image based on text
      print('   🎨 Step 2: Generating matching image...');
      final imagePrompt = await createImagePrompt(textContent);
      await generateImage(imagePrompt);
      print('   ✅ Image generated');

      // Step 3: Create audio description
      print('   🎵 Step 3: Creating audio description...');
      final audioScript = await createAudioScript(textContent);
      print('   ✅ Audio script: ${audioScript.substring(0, 80)}...');

      print('   🎉 Cross-modal workflow completed!\n');
    } catch (e) {
      print('   ❌ Workflow failed: $e\n');
    }
  }

  /// Interactive text processing
  Future<void> interactiveTextProcessing() async {
    stdout.write('📝 Enter text to analyze: ');
    final text = stdin.readLineSync();

    if (text != null && text.isNotEmpty) {
      try {
        final analysis = await analyzeText(text);
        print('🔍 Analysis: $analysis\n');
      } catch (e) {
        print('❌ Analysis failed: $e\n');
      }
    }
  }

  /// Interactive image processing
  Future<void> interactiveImageProcessing() async {
    stdout.write('🎨 Enter image description: ');
    final prompt = stdin.readLineSync();

    if (prompt != null && prompt.isNotEmpty) {
      try {
        await generateImage(prompt);
        print('✅ Image generated successfully!\n');
      } catch (e) {
        print('❌ Generation failed: $e\n');
      }
    }
  }

  /// Interactive audio processing
  Future<void> interactiveAudioProcessing() async {
    stdout.write('🎵 Enter text for audio processing: ');
    final text = stdin.readLineSync();

    if (text != null && text.isNotEmpty) {
      try {
        final processed = await processAudioText(text);
        print('🔊 Processed: $processed\n');
      } catch (e) {
        print('❌ Processing failed: $e\n');
      }
    }
  }

  /// Interactive workflow
  Future<void> interactiveWorkflow() async {
    stdout.write('🔄 Enter workflow scenario: ');
    final scenario = stdin.readLineSync();

    if (scenario != null && scenario.isNotEmpty) {
      try {
        print('🔄 Processing workflow...');

        final textContent = await generateContent(scenario);
        print('📝 Generated text content');

        final imagePrompt = await createImagePrompt(textContent);
        await generateImage(imagePrompt);
        print('🎨 Generated image');

        final audioScript = await createAudioScript(textContent);
        print('🎵 Created audio script: ${audioScript.substring(0, 50)}...');

        print('✅ Workflow completed successfully!\n');
      } catch (e) {
        print('❌ Workflow failed: $e\n');
      }
    }
  }

  /// Analyze text content
  Future<String> analyzeText(String text) async {
    final messages = [
      ChatMessage.system(
          'Analyze the given text and provide insights about its tone, key themes, sentiment, and main message. Be concise and informative.'),
      ChatMessage.user(text),
    ];

    final result = await _chatBuilder.generateText(messages: messages);
    return result.text ?? 'Analysis not available';
  }

  /// Generate content based on prompt
  Future<String> generateContent(String prompt) async {
    // Use ChatPromptBuilder to construct a structured user prompt with
    // multiple text parts (instruction + user-provided scenario).
    final structuredPrompt = ChatPromptBuilder.user()
        .text(
            'Generate engaging, creative content based on the following scenario. '
            'Make it informative, appealing, and suitable for a social media post or short article.')
        .text(prompt)
        .build();

    final result = await _chatBuilder.generateText(
      messages: [ChatMessage.fromPromptMessage(structuredPrompt)],
    );
    return result.text ?? 'Content generation failed';
  }

  /// Generate image from prompt
  Future<void> generateImage(String prompt) async {
    if (_imageProvider == null) {
      print('   ⚠️ Image generation not available (OpenAI API key required)');
      return;
    }

    final request = ImageGenerationRequest(
      prompt: prompt,
      count: 1,
      size: '1024x1024',
    );

    final response = await _imageProvider!.generateImages(request);

    if (response.images.isNotEmpty) {
      if (_verbose) {
        print('   🖼️ Image URL: ${response.images.first.url}');
      }
    } else {
      throw Exception('No images generated');
    }
  }

  /// Create image prompt from text content
  Future<String> createImagePrompt(String textContent) async {
    final messages = [
      ChatMessage.system(
          'Based on the given text content, create a detailed image generation prompt that would create a visually appealing image to accompany the text. Focus on visual elements, style, and mood.'),
      ChatMessage.user(textContent),
    ];

    final result = await _chatBuilder.generateText(messages: messages);
    return result.text ?? 'A generic illustration';
  }

  /// Process audio text (simulated audio processing)
  Future<String> processAudioText(String text) async {
    // In a real implementation, this would use _audioProvider for actual TTS/STT
    if (_audioProvider != null) {
      // Could use _audioProvider.textToSpeech() here for real audio processing
      print('   🎵 Audio provider available for real processing');
    }

    final messages = [
      ChatMessage.system(
          'Process the given text for audio narration. Improve clarity, add appropriate pauses, and suggest tone and emphasis. Return the optimized script.'),
      ChatMessage.user(text),
    ];

    final result = await _chatBuilder.generateText(messages: messages);
    return result.text ?? 'Audio processing not available';
  }

  /// Create audio script from text content
  Future<String> createAudioScript(String textContent) async {
    final messages = [
      ChatMessage.system(
          'Convert the given text content into an engaging audio script suitable for narration. Add appropriate pauses, emphasis, and speaking directions.'),
      ChatMessage.user(textContent),
    ];

    final result = await _chatBuilder.generateText(messages: messages);
    return result.text ?? 'Audio script generation failed';
  }
}
