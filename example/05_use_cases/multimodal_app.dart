// ignore_for_file: avoid_print
import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;

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
  late core.LanguageModel _chatModel;
  core.ImageModel? _imageModel;
  core.SpeechModel? _speechModel;

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
      final groqKey = Platform.environment['GROQ_API_KEY'];
      final openaiKey = Platform.environment['OPENAI_API_KEY'];

      if (groqKey != null && groqKey.isNotEmpty) {
        _chatModel = llm
            .groq(
              apiKey: groqKey,
            )
            .chatModel('llama-3.3-70b-versatile');
      } else if (openaiKey != null && openaiKey.isNotEmpty) {
        _chatModel = llm
            .openai(
              apiKey: openaiKey,
            )
            .chatModel('gpt-4.1-mini');
      } else {
        throw StateError(
          'Set GROQ_API_KEY or OPENAI_API_KEY to initialize the chat model.',
        );
      }

      if (_verbose) {
        print(
          '✅ Chat model initialized (${_chatModel.providerId}/${_chatModel.modelId})',
        );
      }

      if (openaiKey != null && openaiKey.isNotEmpty) {
        try {
          _imageModel = llm
              .openai(
                apiKey: openaiKey,
              )
              .imageModel('dall-e-3');
          if (_verbose) {
            print(
              '✅ Image model initialized (${_imageModel!.providerId}/${_imageModel!.modelId})',
            );
          }
        } catch (e) {
          if (_verbose) {
            print('⚠️ Image generation not available: $e');
          }
        }

        try {
          _speechModel = llm
              .openai(
                apiKey: openaiKey,
              )
              .speechModel('gpt-4o-mini-tts');
          if (_verbose) {
            print(
              '✅ Speech model initialized (${_speechModel!.providerId}/${_speechModel!.modelId})',
            );
          }
        } catch (e) {
          if (_verbose) {
            print('⚠️ Speech generation not available: $e');
          }
        }
      } else if (_verbose) {
        print(
            '⚠️ OpenAI media models unavailable because OPENAI_API_KEY is not set');
      }

      print('🎉 Models initialized successfully!\n');
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

    final sampleAudioTexts = [
      'Hello, this is a sample audio transcription.',
      'Multimodal AI can process text, images, and audio together.',
      'The future of AI is incredibly exciting and full of possibilities.',
    ];

    for (final text in sampleAudioTexts) {
      print('   🎤 Processing text for narration: "$text"');

      try {
        final processed = await processAudioText(text);
        print('   🔊 Processed: ${processed.substring(0, 80)}...');
        await synthesizeAudioPreview(processed);
        print('');
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
      print('   📝 Step 1: Generating text content...');
      final textContent = await generateContent(scenario);
      print('   ✅ Text: ${textContent.substring(0, 100)}...');

      print('   🎨 Step 2: Generating matching image...');
      final imagePrompt = await createImagePrompt(textContent);
      await generateImage(imagePrompt);
      print('   ✅ Image generated');

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
        print('🔊 Processed: $processed');
        await synthesizeAudioPreview(processed);
        print('');
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
    return await _runTextTask(
      system:
          'Analyze the given text and provide insights about its tone, key themes, sentiment, and main message. Be concise and informative.',
      user: text,
      maxOutputTokens: 220,
    );
  }

  /// Generate content based on prompt
  Future<String> generateContent(String prompt) async {
    return await _runTextTask(
      system:
          'Generate engaging, creative content based on the given prompt. Make it informative and appealing.',
      user: prompt,
      maxOutputTokens: 260,
    );
  }

  /// Generate image from prompt
  Future<void> generateImage(String prompt) async {
    if (_imageModel == null) {
      print('   ⚠️ Image generation not available (OpenAI API key required)');
      return;
    }

    final response = await core.generateImage(
      model: _imageModel!,
      prompt: prompt,
      count: 1,
      size: '1024x1024',
    );

    if (response.images.isNotEmpty) {
      if (_verbose) {
        print('   🖼️ Image URI: ${response.images.first.uri}');
      }
    } else {
      throw Exception('No images generated');
    }
  }

  /// Create image prompt from text content
  Future<String> createImagePrompt(String textContent) async {
    return await _runTextTask(
      system:
          'Based on the given text content, create a detailed image generation prompt that would create a visually appealing image to accompany the text. Focus on visual elements, style, and mood.',
      user: textContent,
      maxOutputTokens: 180,
    );
  }

  /// Process audio text for narration
  Future<String> processAudioText(String text) async {
    if (_speechModel != null && _verbose) {
      print('   🎵 Speech model available for narration preview');
    }

    return await _runTextTask(
      system:
          'Process the given text for audio narration. Improve clarity, add appropriate pauses, and suggest tone and emphasis. Return the optimized script.',
      user: text,
      maxOutputTokens: 220,
    );
  }

  /// Create audio script from text content
  Future<String> createAudioScript(String textContent) async {
    return await _runTextTask(
      system:
          'Convert the given text content into an engaging audio script suitable for narration. Add appropriate pauses, emphasis, and speaking directions.',
      user: textContent,
      maxOutputTokens: 220,
    );
  }

  Future<void> synthesizeAudioPreview(String script) async {
    if (_speechModel == null) {
      if (_verbose) {
        print('   ⚠️ Speech synthesis not available');
      }
      return;
    }

    final result = await core.generateSpeech(
      model: _speechModel!,
      text: script,
      voice: 'alloy',
    );

    if (_verbose) {
      print(
        '   🎧 Generated ${result.audioBytes.length} audio bytes (${result.mediaType ?? 'unknown media type'})',
      );
    }
  }

  Future<String> _runTextTask({
    required String system,
    required String user,
    int maxOutputTokens = 220,
  }) async {
    final result = await core.generateTextCall(
      model: _chatModel,
      prompt: [
        core.SystemPromptMessage.text(system),
        core.UserPromptMessage.text(user),
      ],
      options: core.GenerateTextOptions(
        temperature: 0.7,
        maxOutputTokens: maxOutputTokens,
      ),
    );

    return result.text;
  }
}
