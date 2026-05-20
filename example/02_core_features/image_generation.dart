// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart_google/llm_dart_google.dart' as google;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

/// Stable image generation example across OpenAI and Google image models.
///
/// This example demonstrates:
/// - shared `generateImage(...)` helpers
/// - model selection through stable provider/model factories
/// - provider-native image options carried via `CallOptions.providerOptions`
Future<void> main() async {
  print('Stable image generation examples\n');

  final imageModels = _collectImageModels();
  if (imageModels.isEmpty) {
    print('No image models are configured.');
    print('Set OPENAI_API_KEY and/or GOOGLE_API_KEY.');
    return;
  }

  for (final entry in imageModels) {
    await _demonstrateImageGeneration(entry);
  }

  print('Completed stable image generation examples.');
  print('For provider-specific image boundaries, see:');
  print('  - example/04_providers/openai/image_generation.dart');
  print('  - example/04_providers/google/image_generation.dart');
}

List<_ImageDemoEntry> _collectImageModels() {
  final entries = <_ImageDemoEntry>[];

  final openAIKey = Platform.environment['OPENAI_API_KEY'];
  if (openAIKey != null && openAIKey.isNotEmpty) {
    entries.add(
      _ImageDemoEntry(
        label: 'OpenAI DALL-E 3',
        model: openai
            .openai(
              apiKey: openAIKey,
            )
            .imageModel('dall-e-3'),
        prompt:
            'A serene mountain landscape at sunset with a crystal clear lake reflection, photorealistic style',
        count: 1,
        size: '1024x1024',
        callOptions: const core.CallOptions(
          providerOptions: openai.OpenAIImageOptions(
            quality: openai.OpenAIImageQuality.hd,
            style: openai.OpenAIImageStyle.vivid,
            responseFormat: openai.OpenAIImageResponseFormat.url,
          ),
        ),
      ),
    );
  }

  final googleKey = Platform.environment['GOOGLE_API_KEY'];
  if (googleKey != null && googleKey.isNotEmpty) {
    entries.add(
      _ImageDemoEntry(
        label: 'Google Gemini Image',
        model: google
            .google(
              apiKey: googleKey,
            )
            .imageModel('gemini-2.5-flash-image'),
        prompt:
            'A futuristic robot assistant helping in a modern kitchen, detailed digital art, warm lighting',
        count: 1,
        callOptions: const core.CallOptions(
          providerOptions: google.GoogleImageOptions(
            aspectRatio: google.GoogleImageAspectRatio.landscape16x9,
          ),
        ),
      ),
    );
  }

  return entries;
}

Future<void> _demonstrateImageGeneration(_ImageDemoEntry entry) async {
  print(entry.label);
  print('  Model: ${entry.model.providerId}/${entry.model.modelId}');
  print('  Prompt: ${entry.prompt}');

  try {
    final result = await core.generateImage(
      model: entry.model,
      prompt: entry.prompt,
      count: entry.count,
      size: entry.size,
      callOptions: entry.callOptions,
    );

    print('  Generated ${result.images.length} image(s)');
    for (var index = 0; index < result.images.length; index++) {
      final image = result.images[index];
      final description = await _describeImage(
        label: entry.label,
        providerId: entry.model.providerId,
        image: image,
        index: index,
      );
      print('    ${index + 1}. $description');
    }

    final usage = result.usage;
    if (usage != null && usage.isNotEmpty) {
      print(
        '  Usage: input=${usage.inputTokens ?? '-'}, '
        'output=${usage.outputTokens ?? '-'}, '
        'total=${usage.totalTokens ?? '-'}',
      );
    }

    final responseMetadata = result.responseMetadata;
    if (responseMetadata != null) {
      final requestId = _lookupHeader(
        responseMetadata.headers,
        'x-request-id',
      );
      print('  Response model: ${responseMetadata.modelId}');
      if (requestId != null && requestId.isNotEmpty) {
        print('  Request ID: $requestId');
      }
    }

    final metadata = result.providerMetadata?.namespace(entry.model.providerId);
    if (metadata != null && metadata.isNotEmpty) {
      print('  Provider metadata keys: ${metadata.keys.join(', ')}');
    }
  } catch (error) {
    print('  Failed: $error');
  } finally {
    print('');
  }
}

Future<String> _describeImage({
  required String label,
  required String providerId,
  required core.GeneratedImage image,
  required int index,
}) async {
  if (image.uri != null) {
    return image.uri.toString();
  }

  if (image.bytes != null) {
    final extension = _fileExtensionForMediaType(image.mediaType);
    final safeLabel =
        label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').trim();
    final outputPath = '${safeLabel}_${index + 1}.$extension';
    await File(outputPath).writeAsBytes(image.bytes!);

    return '$outputPath (${image.bytes!.length} bytes, ${image.mediaType ?? providerId})';
  }

  return 'empty image payload';
}

String? _lookupHeader(Map<String, String> headers, String name) {
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) {
      return entry.value;
    }
  }

  return null;
}

String _fileExtensionForMediaType(String? mediaType) {
  return switch (mediaType) {
    'image/jpeg' => 'jpg',
    'image/webp' => 'webp',
    'image/gif' => 'gif',
    _ => 'png',
  };
}

final class _ImageDemoEntry {
  final String label;
  final core.ImageModel model;
  final String prompt;
  final int count;
  final String? size;
  final core.CallOptions callOptions;

  const _ImageDemoEntry({
    required this.label,
    required this.model,
    required this.prompt,
    this.count = 1,
    this.size,
    this.callOptions = const core.CallOptions(),
  });
}
