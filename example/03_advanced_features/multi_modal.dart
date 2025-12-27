// ignore_for_file: avoid_print
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

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

  registerOpenAI();
  registerAnthropic();
  registerElevenLabs();

  // Get API keys
  final openaiKey = Platform.environment['OPENAI_API_KEY'];
  final anthropicKey = Platform.environment['ANTHROPIC_API_KEY'];
  final elevenlabsKey = Platform.environment['ELEVENLABS_API_KEY'];

  // Demonstrate different multi-modal scenarios
  if (openaiKey != null && openaiKey.isNotEmpty) {
    await demonstrateImageAnalysis(openaiKey);
    await demonstrateImageGeneration(openaiKey);
    await demonstrateAudioProcessing(openaiKey, elevenlabsKey);
    await demonstrateMultiModalConversation(openaiKey);
  } else {
    print('⚠️  Skipped OpenAI demos: set OPENAI_API_KEY');
  }

  if (anthropicKey != null && anthropicKey.isNotEmpty) {
    await demonstrateDocumentProcessing(anthropicKey);
  } else {
    print('⚠️  Skipped Anthropic demo: set ANTHROPIC_API_KEY');
  }

  print('\n✅ Multi-modal processing completed!');
}

/// Demonstrate image analysis with vision models
Future<void> demonstrateImageAnalysis(String apiKey) async {
  print('👁️  Image Analysis:\n');

  try {
    // Create vision-capable provider
    final provider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(apiKey)
        .model('gpt-4o') // Vision-capable model
        .temperature(0.7)
        .maxTokens(500)
        .build();

    // Simulate image data (in real usage, load from file)
    final imageUrl =
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg';

    print('   Analyzing image: Nature boardwalk');

    // Create message with image
    final messages = [
      ChatMessage.imageUrl(
        role: ChatRole.user,
        url: imageUrl,
        content: 'What do you see in this image? Describe it in detail.',
      )
    ];

    final response = await generateText(model: provider, messages: messages);
    print('   🤖 AI Analysis: ${response.text}');

    // Follow-up question about the image
    messages.add(ChatMessage.assistant(response.text ?? ''));
    messages.add(ChatMessage.user(
        'What time of day do you think this photo was taken?'));

    final followUp = await generateText(model: provider, messages: messages);
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
    final imageProvider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(apiKey)
        .model('dall-e-3')
        .buildImageGeneration();

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
    final multiProvider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(apiKey)
        .model('dall-e-2')
        .buildImageGeneration();

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
    String openaiKey, String? elevenlabsKey) async {
  print('🎵 Audio Processing:\n');

  // First generate TTS with OpenAI for later transcription
  await demonstrateOpenAITextToSpeech(openaiKey);

  // Speech-to-text with OpenAI Whisper
  await demonstrateSpeechToText(openaiKey);

  // Text-to-speech with ElevenLabs
  if (elevenlabsKey != null && elevenlabsKey.isNotEmpty) {
    await demonstrateTextToSpeech(elevenlabsKey);
  } else {
    print('   ⚠️  Skipped ElevenLabs TTS: set ELEVENLABS_API_KEY');
  }
}

/// Demonstrate OpenAI text-to-speech
Future<void> demonstrateOpenAITextToSpeech(String apiKey) async {
  print('   🎵 Text-to-Speech (OpenAI):');

  try {
    // Create OpenAI provider with audio capabilities
    final audioProvider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(apiKey)
        .model('tts-1')
        .buildAudio();

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
    final audioProvider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(apiKey)
        .model('whisper-1')
        .buildAudio();

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
    final audioProvider = await LLMBuilder()
        .provider(elevenLabsProviderId)
        .apiKey(apiKey)
        .providerOption('elevenlabs', 'voiceId', 'JBFqnCBsd6RMkjVDRZzb')
        .buildAudio();

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
    // Create provider for document analysis
    final provider = await LLMBuilder()
        .provider(anthropicProviderId)
        .apiKey(apiKey)
        .model('claude-sonnet-4-20250514')
        .temperature(0.3)
        .maxTokens(1000)
        .build();

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

    final messages = [
      ChatMessage.system(
          'You are a business analyst. Analyze documents and provide insights.'),
      ChatMessage.user(
          'Please analyze this quarterly report and provide key insights:\n\n$documentContent'),
    ];

    final response = await generateText(model: provider, messages: messages);
    print('   🤖 Document Analysis: ${response.text}');

    // Follow-up analysis
    messages.add(ChatMessage.assistant(response.text ?? ''));
    messages.add(ChatMessage.user(
        'What are the top 3 priorities for the next quarter based on this report?'));

    final priorities = await generateText(model: provider, messages: messages);
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
    // Create vision-capable provider
    final provider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(apiKey)
        .model('gpt-4o')
        .temperature(0.7)
        .maxTokens(800)
        .build();

    // Start conversation with text
    var messages = [
      ChatMessage.user('I\'m planning a garden. Can you help me choose plants?')
    ];

    var response = await generateText(model: provider, messages: messages);
    print('   User: I\'m planning a garden. Can you help me choose plants?');
    print('   🤖 AI: ${response.text}\n');

    // Add image to conversation
    messages.add(ChatMessage.assistant(response.text ?? ''));
    messages.add(ChatMessage.imageUrl(
      role: ChatRole.user,
      url: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=800',
      content:
          'Here\'s a photo of my backyard. What do you think would work well here?',
    ));

    response = await generateText(model: provider, messages: messages);
    print('   User: [Shares backyard photo] What would work well here?');
    print('   🤖 AI: ${response.text}\n');

    // Continue with text-only follow-up
    messages.add(ChatMessage.assistant(response.text ?? ''));
    messages.add(ChatMessage.user(
        'I prefer low-maintenance plants. Any specific recommendations?'));

    response = await generateText(model: provider, messages: messages);
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
