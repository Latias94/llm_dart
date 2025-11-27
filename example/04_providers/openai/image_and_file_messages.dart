/// Example demonstrating image and file message handling with OpenAI
///
/// This example shows how to send images and files to OpenAI using both
/// Chat Completions API and Responses API formats.
///
/// ## Key Features:
/// - Image messages with base64 encoding
/// - Image URL messages
/// - File messages (PDF, documents, etc.)
/// - Mixed content (text + image/file in same message)
/// - Support for both Chat Completions API and Responses API
///
/// ## Before running:
/// ```bash
/// export OPENAI_API_KEY="your-key"
/// dart run example/04_providers/openai/image_and_file_messages.dart
/// ```
library;

import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

void main() async {
  print('=== OpenAI Image and File Messages Examples ===\n');

  // Get API key from environment
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null) {
    print('Please set OPENAI_API_KEY environment variable');
    print('Skipping API examples...\n');
    return;
  }

  // Example 1: Image URL with Chat Completions API
  await imageUrlChatCompletionsExample(apiKey);

  // Example 2: Image URL with Responses API
  await imageUrlResponsesAPIExample(apiKey);

  // Example 3: Base64 encoded image with Chat Completions API
  await base64ImageExample(apiKey);

  // Example 4: Mixed content - text + image in same message
  await mixedContentExample(apiKey);

  // Example 5: File message (PDF) with Chat Completions API
  await fileMessageExample(apiKey);

  // Example 6: File message with Responses API
  await fileMessageResponsesAPIExample(apiKey);

  print('\n✅ All examples completed!');
}

/// Example 1: Image URL with Chat Completions API (default, prompt-first)
Future<void> imageUrlChatCompletionsExample(String apiKey) async {
  print('--- Example 1: Image URL with Chat Completions API ---');

  try {
    final model = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o')
        .temperature(0.7)
        .maxTokens(300)
        .buildLanguageModel();

    // Build a structured prompt: text + image URL.
    final prompt = ChatPromptBuilder.user()
        .text('Describe this image in one sentence.')
        .imageUrl(
          'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Cat03.jpg/481px-Cat03.jpg',
        )
        .build();

    print('Sending image URL with text prompt...');
    final result = await generateTextWithModel(
      model,
      promptMessages: [prompt],
    );
    print('Response: ${result.text}\n');
  } catch (e) {
    print('Error: $e\n');
  }
}

/// Example 2: Image URL with Responses API
Future<void> imageUrlResponsesAPIExample(String apiKey) async {
  print('--- Example 2: Image URL with Responses API ---');

  try {
    final model = await ai()
        .openai((openai) => openai.useResponsesAPI())
        .apiKey(apiKey)
        .model('gpt-4o')
        .temperature(0.7)
        .buildLanguageModel();

    // Same structured prompt; the library handles format differences automatically.
    final prompt = ChatPromptBuilder.user()
        .text('What animal is this?')
        .imageUrl(
          'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Cat03.jpg/481px-Cat03.jpg',
        )
        .build();

    print('Sending image URL with Responses API...');
    final result = await generateTextWithModel(
      model,
      promptMessages: [prompt],
    );
    print('Response: ${result.text}\n');
  } catch (e) {
    print('Error: $e\n');
  }
}

/// Example 3: Base64 encoded image with Chat Completions API
Future<void> base64ImageExample(String apiKey) async {
  print('--- Example 3: Base64 Encoded Image ---');

  try {
    // Check if we have a local image file
    final imageFile = File('Cat03.jpg');
    if (!await imageFile.exists()) {
      print('⚠️  Cat03.jpg not found, skipping this example');
      print(
          '   Download an image and save it as Cat03.jpg to test this feature\n');
      return;
    }

    final model = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o')
        .temperature(0.7)
        .maxTokens(300)
        .buildLanguageModel();

    // Read image file
    final imageBytes = await imageFile.readAsBytes();
    print('Loaded image: ${imageBytes.length} bytes');

    // Build a prompt with base64-encoded image bytes.
    final prompt = ChatPromptBuilder.user()
        .text('Describe this cat in detail.')
        .imageBytes(
          imageBytes,
          mime: ImageMime.jpeg,
          filename: 'Cat03.jpg',
        )
        .build();

    print('Sending base64 encoded image...');
    final result = await generateTextWithModel(
      model,
      promptMessages: [prompt],
    );
    print('Response: ${result.text}\n');
  } catch (e) {
    print('Error: $e\n');
  }
}

/// Example 4: Mixed content - text + image in same message
Future<void> mixedContentExample(String apiKey) async {
  print('--- Example 4: Mixed Content (Text + Image) ---');

  try {
    final model = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o')
        .temperature(0.7)
        .maxTokens(400)
        .buildLanguageModel();

    // Build a mixed-content prompt: image URL + detailed question text.
    final prompt = ChatPromptBuilder.user()
        .imageUrl(
          'https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg',
        )
        .text(
          'Look at this image and answer: What time of day was this photo likely taken? '
          'Explain your reasoning.',
        )
        .build();

    print('Sending image with detailed question...');
    final result = await generateTextWithModel(
      model,
      promptMessages: [prompt],
    );
    print('Response: ${result.text}\n');
  } catch (e) {
    print('Error: $e\n');
  }
}

/// Example 5: File message (PDF) with Chat Completions API
Future<void> fileMessageExample(String apiKey) async {
  print('--- Example 5: File Message (PDF) ---');

  try {
    // Check if we have a local PDF file
    final pdfFile = File('sample.pdf');
    if (!await pdfFile.exists()) {
      print('⚠️  sample.pdf not found, skipping this example');
      print('   Create a PDF file named sample.pdf to test this feature\n');
      return;
    }

    final model = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o')
        .temperature(0.7)
        .maxTokens(500)
        .buildLanguageModel();

    // Read PDF file
    final pdfBytes = await pdfFile.readAsBytes();
    print('Loaded PDF: ${pdfBytes.length} bytes');

    // Build a prompt with the PDF file as a document part.
    final prompt = ChatPromptBuilder.user()
        .text('Summarize the content of this PDF document.')
        .fileBytes(
          pdfBytes,
          mime: FileMime.pdf,
          filename: 'sample.pdf',
        )
        .build();

    print('Sending PDF file...');
    final result = await generateTextWithModel(
      model,
      promptMessages: [prompt],
    );
    print('Response: ${result.text}\n');
  } catch (e) {
    print('Error: $e\n');
  }
}

/// Example 6: File message with Responses API
Future<void> fileMessageResponsesAPIExample(String apiKey) async {
  print('--- Example 6: File Message with Responses API ---');

  try {
    // Check if we have a local file
    final textFile = File('sample.txt');
    if (!await textFile.exists()) {
      // Create a sample text file for demonstration
      await textFile.writeAsString('''
This is a sample document for testing file upload functionality.

Key Points:
1. File messages support various formats
2. Both Chat Completions API and Responses API are supported
3. The library handles format conversion automatically

Technical Details:
- Files are base64 encoded for transmission
- MIME types are automatically detected
- Mixed content (text + file) is supported
''');
      print('Created sample.txt for demonstration');
    }

    final provider = await ai()
        .openai((openai) => openai.useResponsesAPI())
        .apiKey(apiKey)
        .model('gpt-4o')
        .temperature(0.7)
        .maxTokens(300)
        .build();

    // Read file
    final fileBytes = await textFile.readAsBytes();
    print('Loaded file: ${fileBytes.length} bytes');

    // Use ChatPromptBuilder for generic file types.
    final prompt = ChatPromptBuilder.user()
        .text('What are the key points in this document?')
        .fileBytes(
          fileBytes,
          mime: FileMime.txt,
          filename: 'sample.txt',
        )
        .build();

    print('Sending file with Responses API...');
    final model = await ai()
        .openai((openai) => openai.useResponsesAPI())
        .apiKey(apiKey)
        .model('gpt-4o')
        .temperature(0.7)
        .maxTokens(300)
        .buildLanguageModel();

    final result = await generateTextWithModel(
      model,
      promptMessages: [prompt],
    );
    print('Response: ${result.text}\n');
  } catch (e) {
    print('Error: $e\n');
  }
}

/// 🎯 Key Concepts Summary:
///
/// ## Image Messages:
///
/// ### 1. Image URL Messages (ChatPromptBuilder.imageUrl)
/// - Send images via URL
/// - No file upload needed
/// - Supports public URLs
/// - Combine with `.text(...)` for instructions
///
/// ### 2. Base64 Image Messages (ChatPromptBuilder.imageBytes)
/// - Send local image files
/// - Automatically base64 encoded by providers
/// - Supported formats: JPEG, PNG, GIF, WebP (depending on provider)
/// - Combine with `.text(...)` for prompts
///
/// ## File Messages:
///
/// ### 1. Generic File Messages (ChatPromptBuilder.fileBytes)
/// - Send any file type
/// - Specify MIME type with FileMime enum
/// - Providers base64 encode as needed
/// - Combine with `.text(...)` for instructions
///
/// ### 2. PDF Messages (ChatPromptBuilder.fileBytes + FileMime.pdf)
/// - Use `FileMime.pdf` for PDF files
/// - Same functionality as generic file messages with explicit MIME
///
/// ## API Format Differences:
///
/// The library automatically handles format differences between:
/// - **Chat Completions API** (default): Uses nested object format
/// - **Responses API**: Uses flat format with different type names
///
/// You don't need to worry about these differences - just build
/// structured prompts with `ChatPromptBuilder` / `ModelMessage` and
/// let the library handle the conversion!
///
/// ## Mixed Content:
///
/// All image and file message methods support the 'content' parameter:
/// ```dart
/// final prompt = ChatPromptBuilder.user()
///     .imageUrl('https://example.com/image.jpg')
///     .text('Your text prompt here')
///     .build();
/// ```
///
/// This creates a prompt with both text and media content, allowing you
/// to provide specific instructions or questions about the image/file.
