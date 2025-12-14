import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

/// OpenAI Image Generation Example
///
/// This example demonstrates OpenAI's DALL-E image generation capabilities
/// including basic generation, advanced configuration, image editing, and variations.
///
/// **New Feature**: Uses the buildImageGeneration() capability factory method for
/// type-safe provider building without runtime type casting.
Future<void> main() async {
  // Get API key from environment
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null) {
    print('❌ Please set OPENAI_API_KEY environment variable');
    return;
  }

  print('🎨 OpenAI Image Generation Demo\n');

  // Test different DALL-E models
  await testDALLE3Generation(apiKey);
  await testDALLE2Generation(apiKey);
  await testImageEditing(apiKey);
  await testImageVariations(apiKey);
  await testAdvancedFeatures(apiKey);

  print('✅ OpenAI image generation demo completed!');
}

/// Test DALL-E 3 image generation
Future<void> testDALLE3Generation(String apiKey) async {
  print('🎨 DALL-E 3 Generation:');

  try {
    // Create OpenAI provider for DALL-E 3 using buildImageGeneration()
    // This provides compile-time type safety and eliminates runtime type casting
    final imageProvider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('dall-e-3')
        .buildImageGeneration(); // Type-safe image generation capability building

    // Display capabilities
    print('   🔍 Supported sizes: ${imageProvider.getSupportedSizes()}');
    print('   📋 Supported formats: ${imageProvider.getSupportedFormats()}');
    print('   ✂️  Supports editing: ${imageProvider.supportsImageEditing}');
    print(
        '   🔄 Supports variations: ${imageProvider.supportsImageVariations}');

    // Example 1: Basic generation
    print('\n   🖼️  Basic Generation:');
    final basicPrompt =
        'A serene mountain landscape with a crystal clear lake reflection, photorealistic';
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
          'A futuristic cyberpunk cityscape at night with neon lights and flying cars',
      model: 'dall-e-3',
      size: '1792x1024', // Landscape format
      quality: 'hd',
      style: 'vivid',
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

    print('   ✅ DALL-E 3 generation completed\n');
  } catch (e) {
    print('   ❌ DALL-E 3 generation failed: $e\n');
  }
}

/// Test DALL-E 2 image generation
Future<void> testDALLE2Generation(String apiKey) async {
  print('🎨 DALL-E 2 Generation:');

  try {
    // Create OpenAI provider for DALL-E 2 using buildImageGeneration()
    final imageProvider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('dall-e-2')
        .buildImageGeneration(); // Type-safe image generation capability building

    // Example: Multiple images with DALL-E 2
    print('   🔢 Multiple Images Generation:');
    final multiPrompt =
        'A cute robot assistant helping with daily tasks, cartoon style';
    print('      Prompt: "$multiPrompt"');

    final multiImages = await imageProvider.generateImage(
      prompt: multiPrompt,
      model: 'dall-e-2',
      imageSize: '512x512',
      batchSize: 2, // Generate 2 images
    );

    print('      ✅ Generated ${multiImages.length} variations:');
    for (int i = 0; i < multiImages.length; i++) {
      print('         Variation ${i + 1}: ${multiImages[i]}');
    }

    print('   ✅ DALL-E 2 generation completed\n');
  } catch (e) {
    print('   ❌ DALL-E 2 generation failed: $e\n');
  }
}

/// Test image editing capabilities
Future<void> testImageEditing(String apiKey) async {
  print('✂️  Image Editing:');

  try {
    // Create provider for image editing using buildImageGeneration()
    final imageProvider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('dall-e-2') // Only DALL-E 2 supports editing
        .buildImageGeneration(); // Type-safe image generation capability building

    if (!imageProvider.supportsImageEditing) {
      print('   ⏭️  Skipping - image editing not supported');
      return;
    }

    print('   💡 Image editing requires DALL-E 2 and image files');
    print('   📝 To test editing:');
    print('      1. Prepare a PNG image (1024x1024 or smaller)');
    print(
        '      2. Optionally create a mask image (transparent areas will be edited)');
    print('      3. Use ImageEditRequest with image and mask data');
    print('   ✅ Image editing capability confirmed\n');
  } catch (e) {
    print('   ❌ Image editing test failed: $e\n');
  }
}

/// Test image variations
Future<void> testImageVariations(String apiKey) async {
  print('🔄 Image Variations:');

  try {
    // Create provider for image variations using buildImageGeneration()
    final imageProvider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('dall-e-2') // Only DALL-E 2 supports variations
        .buildImageGeneration(); // Type-safe image generation capability building

    if (!imageProvider.supportsImageVariations) {
      print('   ⏭️  Skipping - image variations not supported');
      return;
    }

    print('   💡 Image variations require DALL-E 2 and source image');
    print('   📝 To test variations:');
    print('      1. Prepare a PNG image (1024x1024 or smaller)');
    print('      2. Use ImageVariationRequest with image data');
    print('      3. Generate multiple variations of the source image');
    print('   ✅ Image variations capability confirmed\n');
  } catch (e) {
    print('   ❌ Image variations test failed: $e\n');
  }
}

/// Test advanced features and configurations
Future<void> testAdvancedFeatures(String apiKey) async {
  print('⚙️  Advanced Features:');

  try {
    // Test different configurations
    print('   🎨 Style Options (DALL-E 3):');
    print('      • vivid: Hyper-real and dramatic images');
    print('      • natural: More natural, less hyper-real images');

    print('\n   🔍 Quality Options (DALL-E 3):');
    print('      • standard: Standard quality (faster, cheaper)');
    print('      • hd: High definition (slower, more expensive)');

    print('\n   📐 Size Options:');
    print('      • DALL-E 2: 256x256, 512x512, 1024x1024');
    print('      • DALL-E 3: 1024x1024, 1792x1024, 1024x1792');

    print('\n   🔢 Batch Options:');
    print('      • DALL-E 2: 1-10 images per request');
    print('      • DALL-E 3: 1 image per request');

    print('\n   💡 Best Practices:');
    print('      • Use descriptive, detailed prompts');
    print('      • Specify art style, lighting, composition');
    print('      • DALL-E 3 automatically enhances prompts');
    print('      • Use DALL-E 2 for multiple variations');
    print('      • Use DALL-E 3 for highest quality single images');

    print('   ✅ Advanced features overview completed\n');
  } catch (e) {
    print('   ❌ Advanced features test failed: $e\n');
  }
}
