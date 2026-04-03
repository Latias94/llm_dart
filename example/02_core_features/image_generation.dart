import 'dart:io';
import 'package:llm_dart/legacy.dart';

/// Image generation examples using ImageGenerationCapability interface
///
/// This example demonstrates:
/// - Basic image generation from text prompts
/// - Different image sizes and formats
/// - Provider capability detection
Future<void> main() async {
  print('🎨 Image Generation Examples\n');

  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null) {
    print('❌ Please set OPENAI_API_KEY environment variable');
    return;
  }

  try {
    final provider = await ai().openai().apiKey(apiKey).buildImageGeneration();

    await demonstrateBasicGeneration(provider, 'OpenAI DALL-E');
    await demonstrateAdvancedGeneration(provider, 'OpenAI DALL-E');
  } catch (e) {
    print('❌ Failed to initialize image generation: $e');
  }

  print('✅ Image generation examples completed!');
}

/// Demonstrate basic image generation
Future<void> demonstrateBasicGeneration(
    ImageGenerationCapability provider, String providerName) async {
  print('🎨 Basic Image Generation ($providerName):\n');

  try {
    final request = ImageGenerationRequest(
      prompt: 'A serene mountain landscape at sunset with a crystal clear lake',
      size: '1024x1024',
      count: 1,
    );

    final response = await provider.generateImages(request);

    print('   ✅ Generated ${response.images.length} image(s)');

    for (int i = 0; i < response.images.length; i++) {
      final image = response.images[i];
      print('   🖼️  Image ${i + 1}:');

      if (image.url != null) {
        print('      🔗 URL: ${image.url}');
      }

      if (image.revisedPrompt != null) {
        print('      📝 Revised prompt: ${image.revisedPrompt}');
      }
    }
  } catch (e) {
    print('   ❌ Basic generation failed: $e');
  }
  print('');
}

/// Demonstrate advanced image generation with detailed parameters
Future<void> demonstrateAdvancedGeneration(
    ImageGenerationCapability provider, String providerName) async {
  print('🚀 Advanced Image Generation ($providerName):\n');

  try {
    final request = ImageGenerationRequest(
      prompt:
          'A futuristic cyberpunk cityscape with neon lights, flying cars, and towering skyscrapers, highly detailed, digital art style',
      size: '1024x1024',
      count: 2,
      quality: 'hd',
      style: 'vivid',
      responseFormat: 'url',
    );

    final response = await provider.generateImages(request);

    print('   ✅ Generated ${response.images.length} images');

    for (int i = 0; i < response.images.length; i++) {
      final image = response.images[i];
      print('   🖼️  Image ${i + 1}:');

      if (image.url != null) {
        print('      🔗 URL: ${image.url}');
      }

      if (image.revisedPrompt != null) {
        print('      📝 Revised prompt: ${image.revisedPrompt}');
      }
    }

    // Display usage information if available
    if (response.usage != null) {
      print('   📊 Usage: ${response.usage}');
    }
  } catch (e) {
    print('   ❌ Advanced generation failed: $e');
  }
  print('');
}

/// Utility function to generate filename based on prompt
String generateFilename(String prompt, String provider) {
  final cleanPrompt = prompt
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
      .replaceAll(RegExp(r'\s+'), '_')
      .substring(0, prompt.length > 30 ? 30 : prompt.length);

  final cleanProvider = provider.toLowerCase().replaceAll(' ', '_');
  final timestamp = DateTime.now().millisecondsSinceEpoch;

  return '${cleanPrompt}_${cleanProvider}_$timestamp.png';
}
