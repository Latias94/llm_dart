// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;

/// OpenAI multimodal prompt examples using the stable shared prompt-part model.
///
/// The stable surface uses `TextPromptPart`, `ImagePromptPart`, and
/// `FilePromptPart`. OpenAI transport differences such as Chat Completions vs
/// Responses formatting stay internal to the provider implementation.
Future<void> main() async {
  print('=== OpenAI Image and File Message Examples ===\n');

  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Please set OPENAI_API_KEY environment variable');
    return;
  }

  await imageUrlExample(apiKey);
  await base64ImageExample(apiKey);
  await mixedContentExample(apiKey);
  await pdfFileMessageExample(apiKey);
  await genericFileMessageExample(apiKey);
  explainStableBoundary();

  print('\n✅ All examples completed!');
}

Future<void> imageUrlExample(String apiKey) async {
  print('--- Example 1: Image URL Prompt Part ---');

  try {
    final response = await _generate(
      apiKey: apiKey,
      prompt: [
        core.UserPromptMessage(
          parts: [
            const core.TextPromptPart('Describe this image in one sentence.'),
            core.ImagePromptPart(
              mediaType: 'image/jpeg',
              uri: Uri.parse(
                'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Cat03.jpg/481px-Cat03.jpg',
              ),
            ),
          ],
        ),
      ],
      maxOutputTokens: 300,
    );

    print('Response: ${response.text}\n');
  } catch (error) {
    print('Error: $error\n');
  }
}

Future<void> base64ImageExample(String apiKey) async {
  print('--- Example 2: Local Image Bytes ---');

  try {
    final imageFile = File('Cat03.jpg');
    if (!await imageFile.exists()) {
      print('⚠️  Cat03.jpg not found, skipping this example');
      print('   Download an image and save it as Cat03.jpg to test it\n');
      return;
    }

    final imageBytes = await imageFile.readAsBytes();
    print('Loaded image: ${imageBytes.length} bytes');

    final response = await _generate(
      apiKey: apiKey,
      prompt: [
        core.UserPromptMessage(
          parts: [
            const core.TextPromptPart('Describe this cat in detail.'),
            core.ImagePromptPart(
              mediaType: 'image/jpeg',
              bytes: imageBytes,
            ),
          ],
        ),
      ],
      maxOutputTokens: 320,
    );

    print('Response: ${response.text}\n');
  } catch (error) {
    print('Error: $error\n');
  }
}

Future<void> mixedContentExample(String apiKey) async {
  print('--- Example 3: Mixed Text + Image ---');

  try {
    final response = await _generate(
      apiKey: apiKey,
      prompt: [
        core.UserPromptMessage(
          parts: [
            const core.TextPromptPart(
              'Look at this image and answer: What time of day was this photo '
              'likely taken? Explain your reasoning.',
            ),
            core.ImagePromptPart(
              mediaType: 'image/jpeg',
              uri: Uri.parse(
                'https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg',
              ),
            ),
          ],
        ),
      ],
      maxOutputTokens: 400,
    );

    print('Response: ${response.text}\n');
  } catch (error) {
    print('Error: $error\n');
  }
}

Future<void> pdfFileMessageExample(String apiKey) async {
  print('--- Example 4: PDF File Prompt Part ---');

  try {
    final pdfFile = File('sample.pdf');
    if (!await pdfFile.exists()) {
      print('⚠️  sample.pdf not found, skipping this example');
      print('   Create a PDF file named sample.pdf to test it\n');
      return;
    }

    final pdfBytes = await pdfFile.readAsBytes();
    print('Loaded PDF: ${pdfBytes.length} bytes');

    final response = await _generate(
      apiKey: apiKey,
      prompt: [
        core.UserPromptMessage(
          parts: [
            const core.TextPromptPart(
              'Summarize the content of this PDF document.',
            ),
            core.FilePromptPart(
              mediaType: 'application/pdf',
              filename: 'sample.pdf',
              bytes: pdfBytes,
            ),
          ],
        ),
      ],
      maxOutputTokens: 500,
    );

    print('Response: ${response.text}\n');
  } catch (error) {
    print('Error: $error\n');
  }
}

Future<void> genericFileMessageExample(String apiKey) async {
  print('--- Example 5: Generic File Prompt Part ---');

  try {
    final textFile = File('sample.txt');
    if (!await textFile.exists()) {
      await textFile.writeAsString('''
This is a sample document for testing file prompt functionality.

Key Points:
1. File prompt parts support various formats
2. OpenAI provider transport details stay internal
3. Mixed text + file prompts are supported
''');
      print('Created sample.txt for demonstration');
    }

    final fileBytes = await textFile.readAsBytes();
    print('Loaded file: ${fileBytes.length} bytes');

    final response = await _generate(
      apiKey: apiKey,
      prompt: [
        core.UserPromptMessage(
          parts: [
            const core.TextPromptPart(
              'What are the key points in this document?',
            ),
            core.FilePromptPart(
              mediaType: 'text/plain',
              filename: 'sample.txt',
              bytes: fileBytes,
            ),
          ],
        ),
      ],
      maxOutputTokens: 280,
    );

    print('Response: ${response.text}\n');
  } catch (error) {
    print('Error: $error\n');
  }
}

void explainStableBoundary() {
  print('--- Stable Boundary Notes ---');
  print(
      '• Use prompt parts, not provider-specific message builders, in new code.');
  print(
      '• OpenAI-specific wire formats remain internal implementation details.');
  print(
      '• This stable prompt model is what Flutter-facing chat UIs should keep');
  print('  in local state, persistence, and replay flows.');
}

core.LanguageModel _model(String apiKey) {
  return llm.AI
      .openai(
        apiKey: apiKey,
      )
      .chatModel('gpt-4o');
}

Future<core.GenerateTextCallResult<dynamic>> _generate({
  required String apiKey,
  required List<core.PromptMessage> prompt,
  required int maxOutputTokens,
}) {
  return core.generateTextCall(
    model: _model(apiKey),
    prompt: prompt,
    options: core.GenerateTextOptions(
      temperature: 0.7,
      maxOutputTokens: maxOutputTokens,
    ),
  );
}
