import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/google.dart' as google;
import 'package:llm_dart/ai.dart' as llm;

/// Google Image Generation Examples
///
/// This example demonstrates the stable Google image-model surface:
/// 1. Gemini image generation through `imageModel(...)`
/// 2. Imagen generation through `imageModel(...)`
///
/// Image editing remains compatibility oriented and is called out explicitly
/// instead of being forced into the shared `ImageModel` contract.
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
      '⚠️  Note: Imagen 3 requires a paid account and may not be available in all regions.',
    );
    await demonstrateImagenGeneration(apiKey);
    demonstrateImageEditingBoundary();
  } catch (error) {
    print('❌ Error: $error');
  }
}

Future<void> demonstrateGeminiImageGeneration(String apiKey) async {
  print('🔮 Gemini Image Generation');
  print('=' * 50);

  try {
    final imageModel = llm.AI
        .google(
          apiKey: apiKey,
        )
        .imageModel('gemini-2.5-flash-image');

    print('   📋 Stable model: ${imageModel.providerId}/${imageModel.modelId}');
    print('   ℹ️  Gemini image models currently support only count=1');

    const prompt =
        'A futuristic robot assistant helping in a modern kitchen, digital art style, warm lighting, detailed';
    print('\n   🎨 Generating image with Gemini...');
    print('      Prompt: "$prompt"');

    final result = await core.generateImage(
      model: imageModel,
      prompt: prompt,
      callOptions: const core.CallOptions(
        providerOptions: google.GoogleImageOptions(
          aspectRatio: google.GoogleImageAspectRatio.landscape16x9,
          safetySettings: [
            google.GoogleSafetySetting(
              category: google.GoogleHarmCategory.harassment,
              threshold: google.GoogleHarmBlockThreshold.blockOnlyHigh,
            ),
          ],
        ),
      ),
    );

    print('      ✅ Generated ${result.images.length} image(s)');
    for (var index = 0; index < result.images.length; index++) {
      final image = result.images[index];
      if (image.bytes != null) {
        final filename = 'gemini_generated_${index + 1}.png';
        await File(filename).writeAsBytes(image.bytes!);
        print(
          '         Image ${index + 1}: Saved as $filename (${image.bytes!.length} bytes)',
        );
      } else {
        print('         Image ${index + 1}: Empty image payload');
      }
    }

    final metadata = result.providerMetadata?.namespace('google');
    if (metadata != null) {
      print('      API: ${metadata['generationApi'] ?? 'unknown'}');
      print('      Model version: ${metadata['modelVersion'] ?? 'unknown'}');

      final revisedPrompts = metadata['revisedPrompts'];
      if (revisedPrompts is List && revisedPrompts.isNotEmpty) {
        print('      Revised prompt: ${revisedPrompts.first}');
      }

      final finishReasons = metadata['finishReasons'];
      if (finishReasons is List && finishReasons.isNotEmpty) {
        print('      Finish reason: ${finishReasons.first}');
      }
    }
  } catch (error) {
    print('   ❌ Gemini generation failed: $error');
  }
}

Future<void> demonstrateImagenGeneration(String apiKey) async {
  print('\n🖼️  Imagen 3 Generation');
  print('=' * 50);

  try {
    final imageModel = llm.AI
        .google(
          apiKey: apiKey,
        )
        .imageModel('imagen-3.0-generate-002');

    const prompt =
        'A serene mountain landscape at sunset, with a crystal clear lake reflecting the mountains, photorealistic style, high detail';
    print('   🎨 Generating image with Imagen 3...');
    print('      Prompt: "$prompt"');

    final result = await core.generateImage(
      model: imageModel,
      prompt: prompt,
      count: 2,
      callOptions: const core.CallOptions(
        providerOptions: google.GoogleImageOptions(
          aspectRatio: google.GoogleImageAspectRatio.square1x1,
          personGeneration: google.GooglePersonGeneration.allowAdult,
        ),
      ),
    );

    print('      ✅ Generated ${result.images.length} image(s)');
    for (var index = 0; index < result.images.length; index++) {
      final image = result.images[index];
      if (image.bytes != null) {
        final filename = 'imagen_generated_${index + 1}.png';
        await File(filename).writeAsBytes(image.bytes!);
        print(
          '         Image ${index + 1}: Saved as $filename (${image.bytes!.length} bytes)',
        );
      } else {
        print('         Image ${index + 1}: Empty image payload');
      }
    }

    final metadata = result.providerMetadata?.namespace('google');
    if (metadata != null) {
      print('      API: ${metadata['generationApi'] ?? 'unknown'}');
    }
  } catch (error) {
    print('   ❌ Imagen generation failed: $error');
  }
}

void demonstrateImageEditingBoundary() {
  print('\n✂️  Image Editing Boundary');
  print('=' * 50);
  print('   ℹ️  Google image editing remains compatibility oriented today.');
  print('   ℹ️  The stable `ImageModel` contract intentionally covers prompt-');
  print('      based generation only, not file-based edit requests.');
  print(
      '   ℹ️  This avoids baking unfinished edit/variation request shapes into');
  print('      the shared abstraction too early.');
}
