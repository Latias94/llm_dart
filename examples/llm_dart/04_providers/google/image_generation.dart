import 'dart:io';
import 'dart:convert';
import 'package:llm_dart/llm_dart.dart';

/// Google Image Generation Examples
///
/// This example demonstrates Google's image generation capabilities using:
/// 1. Gemini 2.0 Flash Preview Image Generation (conversational approach)
/// 2. Imagen 3 (dedicated image generation model)
///
/// Google's image generation features:
/// - Text-to-image generation
/// - Image editing through conversational prompts
/// - Image variations
/// - Multiple aspect ratios support
/// - Base64 image data output
///
/// Reference: https://ai.google.dev/gemini-api/docs/image-generation
Future<void> main() async {
  print('🎨 Google Image Generation Examples\n');

  final apiKey = Platform.environment['GOOGLE_API_KEY'];
  if (apiKey == null) {
    print('❌ Please set GOOGLE_API_KEY environment variable');
    print('   Get your API key from: https://aistudio.google.com/app/apikey');
    return;
  }

  try {
    await demonstrateGeminiImageGeneration(apiKey);
    print(
        '⚠️  Note: Imagen 3 requires a paid account and may not be available in all regions.');
    await demonstrateImagenGeneration(apiKey);
    await demonstrateImageEditing(apiKey);
  } catch (e) {
    print('❌ Error: $e');
  }
}

/// Demonstrate Gemini 2.0 Flash Preview Image Generation
Future<void> demonstrateGeminiImageGeneration(String apiKey) async {
  print('🔮 Gemini 2.0 Flash Preview Image Generation');
  print('=' * 50);

  try {
    // Create Google provider for Gemini image generation
    final imageProvider = await ai()
        .google((google) => google
            .enableImageGeneration(true)
            .responseModalities(['TEXT', 'IMAGE']))
        .apiKey(apiKey)
        .model('gemini-2.0-flash-preview-image-generation')
        .buildImageGeneration();

    print('   📋 Provider capabilities:');
    print('      Supported sizes: ${imageProvider.getSupportedSizes()}');
    print('      Supported formats: ${imageProvider.getSupportedFormats()}');
    print('      Supports editing: ${imageProvider.supportsImageEditing}');
    print(
        '      Supports variations: ${imageProvider.supportsImageVariations}');

    // Generate image with Gemini
    print('\n   🎨 Generating image with Gemini...');
    final prompt = 'A futuristic robot assistant helping in a modern kitchen, '
        'digital art style, warm lighting, detailed';
    print('      Prompt: "$prompt"');

    final images = await imageProvider.generateImage(
      prompt: prompt,
      batchSize: 1,
    );

    print('      ✅ Generated ${images.length} image(s)');
    for (int i = 0; i < images.length; i++) {
      final imageData = images[i];
      if (imageData.startsWith('data:image/')) {
        // Extract base64 data and save to file
        final base64Data = imageData.split(',')[1];
        final bytes = base64Decode(base64Data);
        final filename = 'gemini_generated_${i + 1}.png';
        await File(filename).writeAsBytes(bytes);
        print(
            '         Image ${i + 1}: Saved as $filename (${bytes.length} bytes)');
      } else {
        print('         Image ${i + 1}: $imageData');
      }
    }
  } catch (e) {
    print('   ❌ Gemini generation failed: $e');
  }
}

/// Demonstrate Imagen 3 generation
Future<void> demonstrateImagenGeneration(String apiKey) async {
  print('\n🖼️  Imagen 3 Generation');
  print('=' * 50);

  try {
    // Create Google provider for Imagen 3
    final imageProvider = await ai()
        .google()
        .apiKey(apiKey)
        .model('imagen-3.0-generate-002')
        .buildImageGeneration();

    // Generate image with Imagen 3
    print('   🎨 Generating image with Imagen 3...');
    final prompt = 'A serene mountain landscape at sunset, '
        'with a crystal clear lake reflecting the mountains, '
        'photorealistic style, high detail';
    print('      Prompt: "$prompt"');

    final response = await imageProvider.generateImages(
      ImageGenerationRequest(
        prompt: prompt,
        count: 2,
        size: '1:1', // Square aspect ratio
      ),
    );

    print('      ✅ Generated ${response.images.length} image(s)');
    print('      Model used: ${response.model}');

    for (int i = 0; i < response.images.length; i++) {
      final image = response.images[i];
      if (image.data != null) {
        final filename = 'imagen_generated_${i + 1}.png';
        await File(filename).writeAsBytes(image.data!);
        print(
            '         Image ${i + 1}: Saved as $filename (${image.data!.length} bytes)');
        print('            Format: ${image.format}');
      }
    }
  } catch (e) {
    print('   ❌ Imagen generation failed: $e');
  }
}

/// Demonstrate image editing with Gemini
Future<void> demonstrateImageEditing(String apiKey) async {
  print('\n✂️  Image Editing with Gemini');
  print('=' * 50);

  try {
    // First, generate a base image
    final imageProvider = await ai()
        .google((google) => google
            .enableImageGeneration(true)
            .responseModalities(['TEXT', 'IMAGE']))
        .apiKey(apiKey)
        .model('gemini-2.0-flash-preview-image-generation')
        .buildImageGeneration();

    print('   🎨 Generating base image...');
    final basePrompt = 'A simple cartoon cat sitting on a chair';
    print('      Base prompt: "$basePrompt"');

    final baseImages = await imageProvider.generateImage(
      prompt: basePrompt,
      batchSize: 1,
    );

    if (baseImages.isNotEmpty) {
      // Extract image data for editing
      final baseImageData = baseImages[0];
      if (baseImageData.startsWith('data:image/')) {
        final base64Data = baseImageData.split(',')[1];
        final bytes = base64Decode(base64Data);

        // Save base image
        await File('base_image.png').writeAsBytes(bytes);
        print('      ✅ Base image saved as base_image.png');

        // Edit the image
        print('\n   ✏️  Editing the image...');
        final editPrompt =
            'Add a red hat to the cat and change the chair to blue';
        print('      Edit prompt: "$editPrompt"');

        final editResponse = await imageProvider.editImage(
          ImageEditRequest(
            image: ImageInput.fromBytes(bytes, format: 'png'),
            prompt: editPrompt,
            count: 1,
          ),
        );

        print(
            '      ✅ Generated ${editResponse.images.length} edited image(s)');
        if (editResponse.revisedPrompt != null) {
          print('      Revised prompt: "${editResponse.revisedPrompt}"');
        }

        for (int i = 0; i < editResponse.images.length; i++) {
          final image = editResponse.images[i];
          if (image.data != null) {
            final filename = 'edited_image_${i + 1}.png';
            await File(filename).writeAsBytes(image.data!);
            print('         Edited image ${i + 1}: Saved as $filename');
          }
        }
      }
    }
  } catch (e) {
    print('   ❌ Image editing failed: $e');
  }
}
