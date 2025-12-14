// ignore_for_file: avoid_print
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

/// 🖼️ Multi-modal Processing - Images, Audio, and Files
///
/// This example demonstrates how to process different types of media with AI:
/// - Image analysis and understanding
/// - Audio transcription and generation
/// - File handling and document processing
/// - Multi-modal conversations
///
/// Before running, set your API keys:
/// export OPENAI_API_KEY="your-key"
/// export ANTHROPIC_API_KEY="your-key"
/// export ELEVENLABS_API_KEY="your-key"
void main() async {
  print('🖼️ Multi-modal Processing - Images, Audio, and Files\n');

  // Get API keys
  final openaiKey = Platform.environment['OPENAI_API_KEY'] ?? 'sk-TESTKEY';
  final anthropicKey =
      Platform.environment['ANTHROPIC_API_KEY'] ?? 'sk-ant-TESTKEY';
  final elevenlabsKey =
      Platform.environment['ELEVENLABS_API_KEY'] ?? 'el-TESTKEY';

  // Demonstrate different multi-modal scenarios
  await demonstrateImageAnalysis(openaiKey);
  await demonstrateImageGeneration(openaiKey);
  await demonstrateAudioProcessing(openaiKey, elevenlabsKey);
  await demonstrateDocumentProcessing(anthropicKey);
  await demonstrateMultiModalConversation(openaiKey);

  print('\n✅ Multi-modal processing completed!');
}

/// Demonstrate image analysis with vision models
Future<void> demonstrateImageAnalysis(String apiKey) async {
  print('👁️  Image Analysis:\n');

  try {
    // Create vision-capable language model
    final model = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o') // Vision-capable model
        .temperature(0.7)
        .maxTokens(500)
        .buildLanguageModel();

    // Simulate image data (in real usage, load from file)
    final imageUrl =
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg';

    print('   Analyzing image: Nature boardwalk');

    // Use ChatPromptBuilder to create a structured multi-modal message
    final visionPrompt = ChatPromptBuilder.user()
        .text('What do you see in this image? Describe it in detail.')
        .imageUrl(imageUrl)
        .build();

    final messages = <ModelMessage>[visionPrompt];

    final response = await generateTextWithModel(
      model,
      promptMessages: List<ModelMessage>.from(messages),
    );
    print('   🤖 AI Analysis: ${response.text}');

    // Follow-up question about the image
    messages.add(
      ChatPromptBuilder.assistant().text(response.text ?? '').build(),
    );
    messages.add(
      ChatPromptBuilder.user()
          .text('What time of day do you think this photo was taken?')
          .build(),
    );

    final followUp = await generateTextWithModel(
      model,
      promptMessages: List<ModelMessage>.from(messages),
    );
    print('   🤖 Follow-up: ${followUp.text}');

    print('   ✅ Image analysis successful\n');
  } catch (e) {
    print('   ❌ Image analysis failed: $e\n');
  }
}

/// Demonstrate image generation with DALL-E
Future<void> demonstrateImageGeneration(String apiKey) async {
  print('🎨 Image Generation:\n');

  try {
    // Create provider with image generation capabilities
    final provider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('dall-e-3') // Use DALL-E 3 for high-quality images
        .build();

    // Check if provider supports image generation
    if (provider is! ImageGenerationCapability) {
      print('   ❌ Provider does not support image generation');
      return;
    }

    final imageProvider = provider as ImageGenerationCapability;

    // Example 1: Basic image generation
    print('   🖼️  Basic Generation:');
    final basicPrompt =
        'A futuristic city with flying cars at sunset, digital art';
    print('      Prompt: "$basicPrompt"');

    final basicImages = await imageProvider.generateImage(
      prompt: basicPrompt,
      model: 'dall-e-3',
      imageSize: '1024x1024',
    );

    print('      ✅ Generated ${basicImages.length} image(s):');
    for (int i = 0; i < basicImages.length; i++) {
      print('         Image ${i + 1}: ${basicImages[i]}');
    }

    // Example 2: Advanced generation with full configuration
    print('\n   ⚙️  Advanced Generation:');
    final advancedRequest = ImageGenerationRequest(
      prompt:
          'A serene mountain landscape with a crystal clear lake reflection, photorealistic',
      model: 'dall-e-3',
      size: '1792x1024', // Landscape format
      quality: 'hd',
      style: 'natural',
      responseFormat: 'url',
    );

    final advancedResponse =
        await imageProvider.generateImages(advancedRequest);
    print('      Model used: ${advancedResponse.model}');
    if (advancedResponse.revisedPrompt != null) {
      print('      Revised prompt: ${advancedResponse.revisedPrompt}');
    }

    print('      ✅ Generated ${advancedResponse.images.length} image(s):');
    for (int i = 0; i < advancedResponse.images.length; i++) {
      final image = advancedResponse.images[i];
      print('         Image ${i + 1}: ${image.url}');
      if (image.revisedPrompt != null) {
        print('         Revised: ${image.revisedPrompt}');
      }
    }

    // Example 3: Multiple images with DALL-E 2
    print('\n   🔢 Multiple Images (DALL-E 2):');
    final multiProvider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('dall-e-2') // DALL-E 2 supports multiple images
        .build() as ImageGenerationCapability;

    final multiImages = await multiProvider.generateImage(
      prompt: 'A cute robot assistant helping with daily tasks, cartoon style',
      model: 'dall-e-2',
      imageSize: '512x512',
      batchSize: 2, // Generate 2 images
    );

    print('      ✅ Generated ${multiImages.length} variations:');
    for (int i = 0; i < multiImages.length; i++) {
      print('         Variation ${i + 1}: ${multiImages[i]}');
    }

    // Show capabilities
    print('\n   🔍 Provider Capabilities:');
    print('      Supported sizes: ${imageProvider.getSupportedSizes()}');
    print('      Supported formats: ${imageProvider.getSupportedFormats()}');
    print('      Supports editing: ${imageProvider.supportsImageEditing}');
    print(
        '      Supports variations: ${imageProvider.supportsImageVariations}');

    print('\n   💡 Image Generation Features:');
    print('      • DALL-E 3: High quality, single image, enhanced prompts');
    print('      • DALL-E 2: Multiple images, editing, variations');
    print('      • Various sizes: Square, landscape, portrait');
    print('      • Quality options: Standard, HD (DALL-E 3)');
    print('      • Style options: Vivid, Natural (DALL-E 3)');
    print('   ✅ Image generation demonstrated\n');
  } catch (e) {
    print('   ❌ Image generation failed: $e\n');
  }
}

/// Demonstrate audio processing
Future<void> demonstrateAudioProcessing(
    String openaiKey, String elevenlabsKey) async {
  print('🎵 Audio Processing:\n');

  // First generate TTS with OpenAI for later transcription
  await demonstrateOpenAITextToSpeech(openaiKey);

  // Speech-to-text with OpenAI Whisper
  await demonstrateSpeechToText(openaiKey);

  // Text-to-speech with ElevenLabs
  await demonstrateTextToSpeech(elevenlabsKey);
}

/// Demonstrate OpenAI text-to-speech
Future<void> demonstrateOpenAITextToSpeech(String apiKey) async {
  print('   🎵 Text-to-Speech (OpenAI):');

  try {
    // Create OpenAI provider with audio capabilities
    final provider = await ai().openai().apiKey(apiKey).model('tts-1').build();

    // Check if provider supports audio capabilities
    if (provider is! AudioCapability) {
      print('      ❌ Provider does not support audio capabilities');
      return;
    }

    final audioProvider = provider as AudioCapability;

    // Get available voices
    final voices = await audioProvider.getVoices();
    print('      🎭 Available voices: ${voices.map((v) => v.name).join(', ')}');

    // Generate speech with OpenAI
    final text =
        'Hello! This is OpenAI text-to-speech for transcription testing.';
    print('      📝 Text: "$text"');
    print('      🔄 Generating speech...');

    final ttsResponse = await audioProvider.textToSpeech(TTSRequest(
      text: text,
      voice: 'alloy',
      format: 'mp3',
      speed: 1.0,
    ));

    // Save the audio file for later transcription
    await File('demo_tts.mp3').writeAsBytes(ttsResponse.audioData);
    print(
        '      ✅ Generated ${ttsResponse.audioData.length} bytes → demo_tts.mp3');
    print('      🎵 Voice: ${ttsResponse.voice ?? "alloy"}');
    print('      🤖 Model: ${ttsResponse.model ?? "tts-1"}');

    print('      ✅ OpenAI TTS demonstration completed\n');
  } catch (e) {
    print('      ❌ OpenAI TTS failed: $e\n');
  }
}

/// Demonstrate speech-to-text
Future<void> demonstrateSpeechToText(String apiKey) async {
  print('   🎤 Speech-to-Text (Whisper):');

  try {
    // Create OpenAI provider with audio capabilities
    final provider =
        await ai().openai().apiKey(apiKey).model('whisper-1').build();

    // Check if provider supports audio capabilities
    if (provider is! AudioCapability) {
      print('      ❌ Provider does not support audio capabilities');
      return;
    }

    final audioProvider = provider as AudioCapability;

    // Get supported languages
    final languages = await audioProvider.getSupportedLanguages();
    print('      🌍 Supported languages: ${languages.length} languages');

    // Check if we have a generated TTS file to transcribe
    final ttsFile = File('demo_tts.mp3');
    if (await ttsFile.exists()) {
      print('      🔄 Transcribing generated audio...');

      // Basic transcription
      final transcription =
          await audioProvider.speechToText(STTRequest.fromFile(
        'demo_tts.mp3',
        model: 'whisper-1',
        includeWordTiming: true,
        responseFormat: 'verbose_json',
      ));

      print('      📝 Transcription: "${transcription.text}"');
      print(
          '      🌍 Detected language: ${transcription.language ?? "unknown"}');
      print('      ⏱️  Duration: ${transcription.duration ?? "unknown"}s');

      if (transcription.words != null && transcription.words!.isNotEmpty) {
        print('      📊 Word timing (first 3 words):');
        for (final word in transcription.words!.take(3)) {
          print('         "${word.word}" (${word.start}s - ${word.end}s)');
        }
      }

      // Test convenience method
      final quickTranscription =
          await audioProvider.transcribeFile('demo_tts.mp3');
      print('      ✅ Quick transcription: "$quickTranscription"');
    } else {
      print('      ⚠️  No audio file found for transcription test');
      print('      💡 Generate TTS audio first to test transcription');
    }

    print('      ✅ Speech-to-text demonstration completed');
  } catch (e) {
    print('      ❌ Speech-to-text failed: $e');
  }
}

/// Demonstrate text-to-speech
Future<void> demonstrateTextToSpeech(String apiKey) async {
  print('\n   🔊 Text-to-Speech (ElevenLabs):');

  try {
    // Create ElevenLabs provider with audio capabilities
    final provider = await ai()
        .elevenlabs((elevenlabs) =>
            elevenlabs.voiceId('JBFqnCBsd6RMkjVDRZzb')) // Default voice
        .apiKey(apiKey)
        .build();

    // Check if provider supports audio capabilities
    if (provider is! AudioCapability) {
      print('      ❌ Provider does not support audio capabilities');
      return;
    }

    final audioProvider = provider as AudioCapability;

    // Get available voices
    final voices = await audioProvider.getVoices();
    print('      🎭 Available voices: ${voices.length} voices');
    if (voices.isNotEmpty) {
      print(
          '         First few: ${voices.take(3).map((v) => v.name).join(', ')}');
    }

    // Generate speech with ElevenLabs
    final text =
        'Hello! This is a demonstration of ElevenLabs text-to-speech synthesis.';
    print('      📝 Text: "$text"');
    print('      🔄 Generating speech...');

    final ttsResponse = await audioProvider.textToSpeech(TTSRequest(
      text: text,
      voice: voices.isNotEmpty ? voices.first.id : null,
      model: 'eleven_multilingual_v2',
    ));

    // Save the audio file
    await File('demo_elevenlabs.mp3').writeAsBytes(ttsResponse.audioData);
    print(
        '      ✅ Generated ${ttsResponse.audioData.length} bytes → demo_elevenlabs.mp3');
    print('      🎵 Voice: ${ttsResponse.voice ?? "default"}');
    print('      🤖 Model: ${ttsResponse.model ?? "default"}');

    // Test convenience method
    final quickSpeech =
        await audioProvider.speech('Quick test with ElevenLabs');
    await File('demo_elevenlabs_quick.mp3').writeAsBytes(quickSpeech);
    print(
        '      ✅ Quick speech: ${quickSpeech.length} bytes → demo_elevenlabs_quick.mp3');

    print('      ✅ Text-to-speech demonstration completed\n');
  } catch (e) {
    print('      ❌ Text-to-speech failed: $e\n');
  }
}

/// Demonstrate document processing
Future<void> demonstrateDocumentProcessing(String apiKey) async {
  print('📄 Document Processing:\n');

  try {
    // Create language model for document analysis
    final model = await ai()
        .anthropic()
        .apiKey(apiKey)
        .model('claude-sonnet-4-20250514')
        .temperature(0.3)
        .maxTokens(1000)
        .buildLanguageModel();

    // Simulate document content
    final documentContent = '''
QUARTERLY BUSINESS REPORT - Q3 2024

Executive Summary:
Our company achieved significant growth in Q3 2024, with revenue increasing by 25% 
compared to the previous quarter. Key highlights include:

- Total Revenue: \$2.5M (up from \$2.0M in Q2)
- New Customer Acquisitions: 150 customers
- Customer Retention Rate: 92%
- Product Development: Launched 2 new features

Challenges:
- Increased competition in the market
- Supply chain delays affecting 15% of orders
- Need for additional technical staff

Recommendations:
1. Invest in marketing to maintain competitive edge
2. Diversify supplier base to reduce delays
3. Hire 5 additional engineers by end of Q4
''';

    print('   Processing business report...');

    final messages = <ModelMessage>[
      ChatPromptBuilder.system()
          .text(
              'You are a business analyst. Analyze documents and provide insights.')
          .build(),
      ChatPromptBuilder.user()
          .text(
              'Please analyze this quarterly report and provide key insights:\n\n$documentContent')
          .build(),
    ];

    final response = await generateTextWithModel(
      model,
      promptMessages: List<ModelMessage>.from(messages),
    );
    print('   🤖 Document Analysis: ${response.text}');

    // Follow-up analysis
    messages.add(
      ChatPromptBuilder.assistant().text(response.text ?? '').build(),
    );
    messages.add(
      ChatPromptBuilder.user()
          .text(
              'What are the top 3 priorities for the next quarter based on this report?')
          .build(),
    );

    final priorities = await generateTextWithModel(
      model,
      promptMessages: List<ModelMessage>.from(messages),
    );
    print('\n   🎯 Priority Analysis: ${priorities.text}');

    print('   ✅ Document processing successful\n');
  } catch (e) {
    print('   ❌ Document processing failed: $e\n');
  }
}

/// Demonstrate multi-modal conversation
Future<void> demonstrateMultiModalConversation(String apiKey) async {
  print('🔄 Multi-modal Conversation:\n');

  try {
    // Create vision-capable language model
    final model = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o')
        .temperature(0.7)
        .maxTokens(800)
        .buildLanguageModel();

    // Start conversation with text
    var messages = <ModelMessage>[
      ChatPromptBuilder.user()
          .text('I\'m planning a garden. Can you help me choose plants?')
          .build(),
    ];

    var response = await generateTextWithModel(
      model,
      promptMessages: List<ModelMessage>.from(messages),
    );
    print('   User: I\'m planning a garden. Can you help me choose plants?');
    print('   🤖 AI: ${response.text}\n');

    // Add image to conversation using ChatPromptBuilder for a multi-part message
    messages.add(
      ChatPromptBuilder.assistant().text(response.text ?? '').build(),
    );
    final backyardPrompt = ChatPromptBuilder.user()
        .text(
            'Here\'s a photo of my backyard. What do you think would work well here?')
        .imageUrl(
          'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=800',
        )
        .build();
    messages.add(backyardPrompt);

    response = await generateTextWithModel(
      model,
      promptMessages: List<ModelMessage>.from(messages),
    );
    print('   User: [Shares backyard photo] What would work well here?');
    print('   🤖 AI: ${response.text}\n');

    // Continue with text-only follow-up
    messages.add(
      ChatPromptBuilder.assistant().text(response.text ?? '').build(),
    );
    messages.add(
      ChatPromptBuilder.user()
          .text(
              'I prefer low-maintenance plants. Any specific recommendations?')
          .build(),
    );

    response = await generateTextWithModel(
      model,
      promptMessages: List<ModelMessage>.from(messages),
    );
    print(
        '   User: I prefer low-maintenance plants. Any specific recommendations?');
    print('   🤖 AI: ${response.text}');

    print('\n   💡 Multi-modal Conversation Features:');
    print('      • Seamless mixing of text and images');
    print('      • Context maintained across modalities');
    print('      • AI can reference previous images');
    print('      • Natural conversation flow');
    print('   ✅ Multi-modal conversation successful\n');
  } catch (e) {
    print('   ❌ Multi-modal conversation failed: $e\n');
  }
}

/// 🎯 Key Multi-modal Concepts Summary:
///
/// Image Processing:
/// - Vision models (GPT-4o, Claude 3.5 Sonnet)
/// - Image analysis and description
/// - Visual question answering
/// - Image generation (DALL-E 2, DALL-E 3)
/// - Image editing with masks (DALL-E 2)
/// - Image variations (DALL-E 2)
///
/// Audio Processing:
/// - Speech-to-text (Whisper)
/// - Text-to-speech (OpenAI TTS, ElevenLabs)
/// - Audio analysis and transcription
/// - Voice synthesis and cloning
///
/// Document Processing:
/// - Text extraction and analysis
/// - Document summarization
/// - Content understanding
/// - Structured data extraction
///
/// Multi-modal Conversations:
/// - Mixing text, images, and audio
/// - Context preservation across modalities
/// - Natural interaction patterns
/// - Cross-modal references
///
/// Best Practices:
/// 1. Choose appropriate models for each modality
/// 2. Optimize file sizes for faster processing
/// 3. Handle different media formats gracefully
/// 4. Maintain context across modal switches
/// 5. Implement proper error handling for media
///
/// Technical Considerations:
/// - File size limits and compression
/// - Supported formats and encodings
/// - Processing time and costs
/// - Quality vs speed trade-offs
///
/// Next Steps:
/// - custom_providers.dart: Build custom AI providers
/// - performance_optimization.dart: Optimize for production
/// - ../04_providers/openai/vision_example.dart: OpenAI vision features
