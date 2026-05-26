// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart' as core;
import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart' as elevenlabs_pkg;
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as anthropic;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

/// Stable multimodal processing examples built on shared prompt parts and
/// shared media helpers.
///
/// This example demonstrates:
/// - multimodal prompts with `TextPromptPart`, `ImagePromptPart`, and `FilePromptPart`
/// - shared `generateImage(...)`, `generateSpeech(...)`, and `transcribe(...)`
/// - app-owned conversation state that Flutter chat UIs can reuse directly
Future<void> main() async {
  print('Stable multimodal processing examples\n');

  final openAIKey = Platform.environment['OPENAI_API_KEY'];
  if (openAIKey == null || openAIKey.isEmpty) {
    print('Set OPENAI_API_KEY to run the shared multimodal examples.');
    return;
  }

  final anthropicKey = Platform.environment['ANTHROPIC_API_KEY'];
  final elevenLabsKey = Platform.environment['ELEVENLABS_API_KEY'];

  await demonstrateImageAnalysis(openAIKey);
  await demonstrateImageGeneration(openAIKey);
  await demonstrateAudioProcessing(openAIKey, elevenLabsKey);
  await demonstrateDocumentProcessing(openAIKey, anthropicKey);
  await demonstrateMultiModalConversation(openAIKey);

  print('Completed stable multimodal examples.');
  print(
      'Keep provider-native transport or storage details in provider-specific');
  print(
      'appendices when shared prompt parts and media helpers are not enough.');
}

Future<void> demonstrateImageAnalysis(String apiKey) async {
  print('Image analysis:');

  final model = openai
      .openai(
        apiKey: apiKey,
      )
      .chatModel('gpt-4o');

  try {
    final result = await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage(
          parts: [
            const core.TextPromptPart(
              'What do you see in this image? Describe it in detail.',
            ),
            core.ImagePromptPart(
              mediaType: 'image/jpeg',
              data: core.FileUrlData(
                Uri.parse(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg',
                ),
              ),
            ),
          ],
        ),
      ],
      options: const core.GenerateTextOptions(
        temperature: 0.3,
        maxOutputTokens: 320,
      ),
    );

    print('  Analysis: ${result.text}');

    final followUp = await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage(
          parts: [
            const core.TextPromptPart(
              'What do you see in this image? Describe it in detail.',
            ),
            core.ImagePromptPart(
              mediaType: 'image/jpeg',
              data: core.FileUrlData(
                Uri.parse(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg',
                ),
              ),
            ),
          ],
        ),
        core.AssistantPromptMessage.text(result.text),
        core.UserPromptMessage.text(
          'What time of day does the photo appear to have been taken?',
        ),
      ],
      options: const core.GenerateTextOptions(
        temperature: 0.3,
        maxOutputTokens: 180,
      ),
    );

    print('  Follow-up: ${followUp.text}');
  } catch (error) {
    print('  Failed: $error');
  }

  print('');
}

Future<void> demonstrateImageGeneration(String apiKey) async {
  print('Image generation:');

  final model = openai
      .openai(
        apiKey: apiKey,
      )
      .imageModel('dall-e-3');

  try {
    final result = await core.generateImage(
      model: model,
      prompt:
          'A futuristic city with flying cars at sunset, cinematic digital art',
      size: '1024x1024',
    );

    print('  Generated ${result.images.length} image(s)');
    for (var index = 0; index < result.images.length; index++) {
      final description = await _describeGeneratedImage(
        image: result.images[index],
        outputPrefix: 'multimodal_generated_${index + 1}',
      );
      print('    ${index + 1}. $description');
    }
  } catch (error) {
    print('  Failed: $error');
  }

  print('');
}

Future<void> demonstrateAudioProcessing(
  String openAIKey,
  String? elevenLabsKey,
) async {
  print('Audio processing:');

  final speechModel = openai
      .openai(
        apiKey: openAIKey,
      )
      .speechModel('gpt-4o-mini-tts');
  final transcriptionModel = openai
      .openai(
        apiKey: openAIKey,
      )
      .transcriptionModel('whisper-1');

  try {
    final speech = await core.generateSpeech(
      model: speechModel,
      text:
          'Hello from the stable multimodal example. This audio sample will be transcribed immediately afterwards.',
      voice: 'alloy',
    );
    const openAIPath = 'multimodal_openai_sample.mp3';
    await File(openAIPath).writeAsBytes(speech.audioBytes);
    print('  OpenAI speech saved to $openAIPath');

    final transcription = await core.transcribe(
      model: transcriptionModel,
      audioBytes: speech.audioBytes,
      mediaType: speech.mediaType ?? 'audio/mpeg',
    );
    print('  Transcription: ${transcription.text}');

    if (elevenLabsKey != null && elevenLabsKey.isNotEmpty) {
      final elevenLabsSpeech = await core.generateSpeech(
        model: elevenlabs_pkg.ElevenLabs(
          apiKey: elevenLabsKey,
        ).speechModel('eleven_multilingual_v2'),
        text:
            'This is an ElevenLabs sample generated from the same shared API.',
      );
      const elevenLabsPath = 'multimodal_elevenlabs_sample.mp3';
      await File(elevenLabsPath).writeAsBytes(elevenLabsSpeech.audioBytes);
      print('  ElevenLabs speech saved to $elevenLabsPath');
    }
  } catch (error) {
    print('  Failed: $error');
  }

  print('');
}

Future<void> demonstrateDocumentProcessing(
  String openAIKey,
  String? anthropicKey,
) async {
  print('Document processing:');

  final core.LanguageModel model;
  if (anthropicKey != null && anthropicKey.isNotEmpty) {
    model = anthropic
        .anthropic(
          apiKey: anthropicKey,
        )
        .chatModel('claude-sonnet-4-5');
  } else {
    model = openai
        .openai(
          apiKey: openAIKey,
        )
        .chatModel('gpt-4.1-mini');
  }

  const documentContent = '''
QUARTERLY BUSINESS REPORT - Q3 2024

Executive Summary:
Revenue increased by 25% compared to the previous quarter.

Highlights:
- Total Revenue: \$2.5M
- New Customer Acquisitions: 150
- Customer Retention Rate: 92%
- Product Development: 2 major launches

Challenges:
- Increased market competition
- Supply chain delays affecting 15% of orders
- Need for additional technical staff

Recommendations:
1. Invest in marketing
2. Diversify supplier base
3. Hire 5 additional engineers
''';

  try {
    final result = await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage(
          parts: [
            const core.TextPromptPart(
              'Analyze this quarterly report and summarize the most important insights.',
            ),
            core.FilePromptPart(
              mediaType: 'text/plain',
              filename: 'quarterly_report.txt',
              data: core.FileBytesData(utf8.encode(documentContent)),
            ),
          ],
        ),
      ],
      options: const core.GenerateTextOptions(
        temperature: 0.2,
        maxOutputTokens: 420,
      ),
    );

    print('  Analysis: ${result.text}');
  } catch (error) {
    print('  Failed: $error');
  }

  print('');
}

Future<void> demonstrateMultiModalConversation(String apiKey) async {
  print('Multi-modal conversation:');

  final model = openai
      .openai(
        apiKey: apiKey,
      )
      .chatModel('gpt-4o');

  final conversation = <core.PromptMessage>[
    core.UserPromptMessage.text(
      'I am planning a garden. Can you help me choose plants?',
    ),
  ];

  try {
    var response = await core.generateTextCall(
      model: model,
      prompt: conversation,
      options: const core.GenerateTextOptions(
        temperature: 0.6,
        maxOutputTokens: 220,
      ),
    );
    print('  Assistant: ${response.text}');

    conversation
      ..add(core.AssistantPromptMessage.text(response.text))
      ..add(
        core.UserPromptMessage(
          parts: [
            const core.TextPromptPart(
              'Here is a photo of my backyard. What would work well here?',
            ),
            core.ImagePromptPart(
              mediaType: 'image/jpeg',
              data: core.FileUrlData(
                Uri.parse(
                  'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=800',
                ),
              ),
            ),
          ],
        ),
      );

    response = await core.generateTextCall(
      model: model,
      prompt: conversation,
      options: const core.GenerateTextOptions(
        temperature: 0.6,
        maxOutputTokens: 260,
      ),
    );
    print('  Assistant after image: ${response.text}');

    conversation
      ..add(core.AssistantPromptMessage.text(response.text))
      ..add(
        core.UserPromptMessage.text(
          'I prefer low-maintenance plants. Any specific recommendations?',
        ),
      );

    response = await core.generateTextCall(
      model: model,
      prompt: conversation,
      options: const core.GenerateTextOptions(
        temperature: 0.6,
        maxOutputTokens: 220,
      ),
    );
    print('  Assistant follow-up: ${response.text}');
  } catch (error) {
    print('  Failed: $error');
  }

  print('');
}

Future<String> _describeGeneratedImage({
  required core.GeneratedImage image,
  required String outputPrefix,
}) async {
  if (image.uri case final uri?) {
    return uri.toString();
  }

  if (image.bytes case final bytes?) {
    final extension = _fileExtensionForMediaType(image.mediaType);
    final outputPath = '$outputPrefix.$extension';
    await File(outputPath).writeAsBytes(bytes);
    return '$outputPath (${bytes.length} bytes, ${image.mediaType ?? 'unknown'})';
  }

  return 'empty image payload';
}

String _fileExtensionForMediaType(String? mediaType) {
  return switch (mediaType) {
    'image/jpeg' => 'jpg',
    'image/webp' => 'webp',
    'image/gif' => 'gif',
    _ => 'png',
  };
}
