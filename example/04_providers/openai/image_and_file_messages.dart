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

/// Example 1: Image URL with Chat Completions API (default)
Future<void> imageUrlChatCompletionsExample(String apiKey) async {
  print('--- Example 1: Image URL with Chat Completions API ---');

  try {
    final provider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o')
        .temperature(0.7)
        .maxTokens(300)
        .build();

    // Use ChatMessage.imageUrl() to send an image URL with text
    final messages = [
      ChatMessage.imageUrl(
        role: ChatRole.user,
        url:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Cat03.jpg/481px-Cat03.jpg',
        content: 'Describe this image in one sentence.',
      ),
    ];

    print('Sending image URL with text prompt...');
    final response = await provider.chat(messages);
    print('Response: ${response.text}\n');
  } catch (e) {
    print('Error: $e\n');
  }
}

/// Example 2: Image URL with Responses API
Future<void> imageUrlResponsesAPIExample(String apiKey) async {
  print('--- Example 2: Image URL with Responses API ---');

  try {
    final provider = await ai()
        .openai((openai) => openai.useResponsesAPI())
        .apiKey(apiKey)
        .model('gpt-4o')
        .temperature(0.7)
        .build();

    // Same API - the library handles format differences automatically
    final messages = [
      ChatMessage.imageUrl(
        role: ChatRole.user,
        url:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Cat03.jpg/481px-Cat03.jpg',
        content: 'What animal is this?',
      ),
    ];

    print('Sending image URL with Responses API...');
    final response = await provider.chat(messages);
    print('Response: ${response.text}\n');
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

    final provider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o')
        .temperature(0.7)
        .maxTokens(300)
        .build();

    // Read image file
    final imageBytes = await imageFile.readAsBytes();
    print('Loaded image: ${imageBytes.length} bytes');

    // Use ChatMessage.image() to send base64 encoded image
    final messages = [
      ChatMessage.image(
        role: ChatRole.user,
        data: imageBytes,
        mime: ImageMime.jpeg,
        content: 'Describe this cat in detail.',
      ),
    ];

    print('Sending base64 encoded image...');
    final response = await provider.chat(messages);
    print('Response: ${response.text}\n');
  } catch (e) {
    print('Error: $e\n');
  }
}

/// Example 4: Mixed content - text + image in same message
Future<void> mixedContentExample(String apiKey) async {
  print('--- Example 4: Mixed Content (Text + Image) ---');

  try {
    final provider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o')
        .temperature(0.7)
        .maxTokens(400)
        .build();

    // The 'content' parameter allows you to add text alongside the image
    final messages = [
      ChatMessage.imageUrl(
        role: ChatRole.user,
        url:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg',
        content:
            'Look at this image and answer: What time of day was this photo likely taken? Explain your reasoning.',
      ),
    ];

    print('Sending image with detailed question...');
    final response = await provider.chat(messages);
    print('Response: ${response.text}\n');
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

    final provider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o')
        .temperature(0.7)
        .maxTokens(500)
        .build();

    // Read PDF file
    final pdfBytes = await pdfFile.readAsBytes();
    print('Loaded PDF: ${pdfBytes.length} bytes');

    // Use ChatMessage.pdf() convenience method
    final messages = [
      ChatMessage.pdf(
        role: ChatRole.user,
        data: pdfBytes,
        content: 'Summarize the content of this PDF document.',
      ),
    ];

    print('Sending PDF file...');
    final response = await provider.chat(messages);
    print('Response: ${response.text}\n');
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

    // Use ChatMessage.file() for generic file types
    final messages = [
      ChatMessage.file(
        role: ChatRole.user,
        data: fileBytes,
        mime: FileMime.txt,
        content: 'What are the key points in this document?',
      ),
    ];

    print('Sending file with Responses API...');
    final response = await provider.chat(messages);
    print('Response: ${response.text}\n');
  } catch (e) {
    print('Error: $e\n');
  }
}

/// 🎯 Key Concepts Summary:
///
/// ## Image Messages:
///
/// ### 1. Image URL Messages (ChatMessage.imageUrl)
/// - Send images via URL
/// - No file upload needed
/// - Supports public URLs
/// - Can include text prompt in 'content' parameter
///
/// ### 2. Base64 Image Messages (ChatMessage.image)
/// - Send local image files
/// - Automatically base64 encoded
/// - Supported formats: JPEG, PNG, GIF, WebP
/// - Can include text prompt in 'content' parameter
///
/// ## File Messages:
///
/// ### 1. Generic File Messages (ChatMessage.file)
/// - Send any file type
/// - Specify MIME type with FileMime enum
/// - Automatically base64 encoded
/// - Can include text prompt in 'content' parameter
///
/// ### 2. PDF Messages (ChatMessage.pdf)
/// - Convenience method for PDF files
/// - Automatically sets correct MIME type
/// - Same functionality as ChatMessage.file with FileMime.pdf
///
/// ## API Format Differences:
///
/// The library automatically handles format differences between:
/// - **Chat Completions API** (default): Uses nested object format
/// - **Responses API**: Uses flat format with different type names
///
/// You don't need to worry about these differences - just use the same
/// ChatMessage methods and the library handles the conversion!
///
/// ## Mixed Content:
///
/// All image and file message methods support the 'content' parameter:
/// ```dart
/// ChatMessage.imageUrl(
///   role: ChatRole.user,
///   url: 'https://example.com/image.jpg',
///   content: 'Your text prompt here',  // Optional but recommended
/// )
/// ```
///
/// This creates a message with both text and media content, allowing you
/// to provide specific instructions or questions about the image/file.
