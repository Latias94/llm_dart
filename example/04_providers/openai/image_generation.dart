import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/openai.dart' as openai;

/// OpenAI Image Generation Example
///
/// This example demonstrates the stable OpenAI image-model surface for prompt
/// based image generation. Image editing and variations remain compatibility
/// oriented and are intentionally documented as boundary notes.
Future<void> main() async {
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null) {
    print('❌ Please set OPENAI_API_KEY environment variable');
    return;
  }

  print('🎨 OpenAI Image Generation Demo\n');

  await testDALLE3Generation(apiKey);
  await testDALLE2Generation(apiKey);
  await testImageEditingBoundary();
  await testImageVariationsBoundary();
  await testAdvancedFeatures();

  print('✅ OpenAI image generation demo completed!');
}

Future<void> testDALLE3Generation(String apiKey) async {
  print('🎨 DALL-E 3 Generation:');

  try {
    final imageModel = llm.AI.openai(apiKey: apiKey).imageModel('dall-e-3');
    print('   🔍 Stable model: ${imageModel.providerId}/${imageModel.modelId}');

    print('\n   🖼️  Basic Generation:');
    const basicPrompt =
        'A serene mountain landscape with a crystal clear lake reflection, photorealistic';
    print('      Prompt: "$basicPrompt"');

    final basicResult = await core.generateImage(
      model: imageModel,
      prompt: basicPrompt,
      count: 1,
      size: '1024x1024',
    );

    print('      ✅ Generated ${basicResult.images.length} image(s):');
    for (var index = 0; index < basicResult.images.length; index++) {
      final image = basicResult.images[index];
      print('         Image ${index + 1}: ${_describeGeneratedImage(image)}');
    }

    print('\n   ⚙️  Advanced Generation:');
    final advancedResult = await core.generateImage(
      model: imageModel,
      prompt:
          'A futuristic cyberpunk cityscape at night with neon lights and flying cars',
      count: 1,
      size: '1792x1024',
      callOptions: const core.CallOptions(
        providerOptions: openai.OpenAIImageOptions(
          quality: openai.OpenAIImageQuality.hd,
          style: openai.OpenAIImageStyle.vivid,
          responseFormat: openai.OpenAIImageResponseFormat.url,
        ),
      ),
    );

    final metadata = advancedResult.providerMetadata?.namespace('openai');
    if (metadata != null) {
      print('      Quality: ${metadata['quality'] ?? 'unknown'}');
      print('      Size: ${metadata['size'] ?? 'unknown'}');
      final revisedPrompts = metadata['revisedPrompts'];
      if (revisedPrompts is List && revisedPrompts.isNotEmpty) {
        print('      Revised prompt: ${revisedPrompts.first}');
      }
    }

    print('      ✅ Generated ${advancedResult.images.length} image(s):');
    for (var index = 0; index < advancedResult.images.length; index++) {
      final image = advancedResult.images[index];
      print('         Image ${index + 1}: ${_describeGeneratedImage(image)}');
    }

    print('   ✅ DALL-E 3 generation completed\n');
  } catch (error) {
    print('   ❌ DALL-E 3 generation failed: $error\n');
  }
}

Future<void> testDALLE2Generation(String apiKey) async {
  print('🎨 DALL-E 2 Generation:');

  try {
    final imageModel = llm.AI.openai(apiKey: apiKey).imageModel('dall-e-2');

    print('   🔢 Multiple Images Generation:');
    const multiPrompt =
        'A cute robot assistant helping with daily tasks, cartoon style';
    print('      Prompt: "$multiPrompt"');

    final multiResult = await core.generateImage(
      model: imageModel,
      prompt: multiPrompt,
      count: 2,
      size: '512x512',
    );

    print('      ✅ Generated ${multiResult.images.length} variation(s):');
    for (var index = 0; index < multiResult.images.length; index++) {
      final image = multiResult.images[index];
      print('         Variation ${index + 1}: ${_describeGeneratedImage(image)}');
    }

    print('   ✅ DALL-E 2 generation completed\n');
  } catch (error) {
    print('   ❌ DALL-E 2 generation failed: $error\n');
  }
}

Future<void> testImageEditingBoundary() async {
  print('✂️  Image Editing:');
  print('   ℹ️  Image editing remains compatibility-oriented in the current API.');
  print('   ℹ️  The stable `ImageModel` surface currently covers prompt-based');
  print('      generation, not file-based edit workflows.');
  print('   ✅ Boundary documented\n');
}

Future<void> testImageVariationsBoundary() async {
  print('🔄 Image Variations:');
  print('   ℹ️  Image variations remain compatibility-oriented in the current API.');
  print('   ℹ️  The stable `ImageModel` surface intentionally stays narrow until');
  print('      edit and variation request shapes are redesigned as provider-owned');
  print('      typed inputs.');
  print('   ✅ Boundary documented\n');
}

Future<void> testAdvancedFeatures() async {
  print('⚙️  Advanced Features:');

  print('   🎨 Style Options (OpenAIImageOptions.style):');
  print('      • vivid: Hyper-real and dramatic images');
  print('      • natural: More natural, less hyper-real images');

  print('\n   🔍 Quality Options (OpenAIImageOptions.quality):');
  print('      • standard: Standard quality');
  print('      • hd: High definition');
  print('      • auto / low / medium / high: Newer image-model quality hints');

  print('\n   📐 Size Options:');
  print('      • DALL-E 2: 256x256, 512x512, 1024x1024');
  print('      • DALL-E 3: 1024x1024, 1792x1024, 1024x1792');

  print('\n   💡 Stable Architecture Notes:');
  print('      • Use `AI.openai(...).imageModel(...)` for prompt-based generation');
  print('      • Use `core.generateImage(...)` as the shared app-facing helper');
  print('      • Keep OpenAI image controls inside `OpenAIImageOptions`');
  print('      • Do not force edit/variation flows into the shared image contract');

  print('   ✅ Advanced features overview completed\n');
}

String _describeGeneratedImage(core.GeneratedImage image) {
  if (image.uri != null) {
    return image.uri.toString();
  }

  if (image.bytes != null) {
    return '${image.bytes!.length} bytes (${image.mediaType ?? 'unknown format'})';
  }

  return 'empty image payload';
}
