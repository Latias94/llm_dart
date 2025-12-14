// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:typed_data';
import 'package:llm_dart/llm_dart.dart';

/// 🟣 Anthropic File Handling - File Management and Document Processing
///
/// This example demonstrates:
/// - File upload and management using Anthropic Files API
/// - Document processing and analysis with Claude
/// - File listing, retrieval, and deletion
/// - Multi-file analysis capabilities
///
/// **Note:** Anthropic Files API is currently in beta and requires
/// the `anthropic-beta: files-api-2025-04-14` header.
///
/// Before running, set your API key:
/// export ANTHROPIC_API_KEY="your-anthropic-api-key"
void main() async {
  print(
      '🟣 Anthropic File Handling - File Management and Document Processing\n');

  // Get API key
  final apiKey = Platform.environment['ANTHROPIC_API_KEY'] ?? 'sk-ant-TESTKEY';

  // Demonstrate file management capabilities
  await demonstrateFileManagement(apiKey);
  await demonstrateTextFileProcessing(apiKey);
  await demonstrateImageAnalysis(apiKey);
  await demonstratePDFProcessing(apiKey);
  await demonstrateMultiFileAnalysis(apiKey);
  await demonstrateDocumentComparison(apiKey);

  print('\n✅ Anthropic file handling completed!');
}

/// Demonstrate file management capabilities
Future<void> demonstrateFileManagement(String apiKey) async {
  print('📁 File Management API:\n');

  try {
    final provider = AnthropicProvider(
      AnthropicConfig(
        apiKey: apiKey,
        model: 'claude-sonnet-4-20250514',
      ),
    );

    // Example 1: Upload a text file
    print('   === Uploading a text file ===');
    final textContent = 'Hello, this is a test file for Anthropic Files API!';
    final textBytes = Uint8List.fromList(textContent.codeUnits);

    final uploadRequest = FileUploadRequest(
      file: textBytes,
      filename: 'test.txt',
    );

    final uploadedFile = await provider.uploadFile(uploadRequest);
    print('      Uploaded file: ${uploadedFile.filename}');
    print('      File ID: ${uploadedFile.id}');
    print('      Size: ${uploadedFile.sizeBytes} bytes');
    print('      MIME type: ${uploadedFile.mimeType}');
    print('      Created: ${uploadedFile.createdAt}');
    print('      Downloadable: ${uploadedFile.downloadable}');

    // Example 2: Upload file from bytes with automatic filename
    print('\n   === Uploading with automatic filename ===');
    final jsonContent = '{"message": "Hello from JSON file"}';
    final jsonBytes = jsonContent.codeUnits;

    final autoFile = await provider.uploadFileFromBytes(
      jsonBytes,
      filename: 'data.json',
    );
    print('      Auto-uploaded file: ${autoFile.filename} (${autoFile.id})');

    // Example 3: List all files
    print('\n   === Listing all files ===');
    final fileList = await provider.listFiles();
    print('      Total files: ${fileList.data.length}');
    print('      Has more: ${fileList.hasMore}');

    for (final file in fileList.data) {
      print('      - ${file.filename} (${file.id}) - ${file.sizeBytes} bytes');
    }

    // Example 4: List files with pagination
    print('\n   === Listing files with pagination ===');
    final paginatedQuery = FileListQuery(
      limit: 5,
      // beforeId: 'some-file-id',  // For pagination
      // afterId: 'some-file-id',   // For pagination
    );

    final paginatedList = await provider.listFiles(paginatedQuery);
    print('      Paginated results: ${paginatedList.data.length} files');
    if (paginatedList.firstId != null) {
      print('      First ID: ${paginatedList.firstId}');
    }
    if (paginatedList.lastId != null) {
      print('      Last ID: ${paginatedList.lastId}');
    }

    // Example 5: Get file metadata
    print('\n   === Getting file metadata ===');
    final metadata = await provider.retrieveFile(uploadedFile.id);
    print('      File metadata for ${metadata.filename}:');
    print('      - ID: ${metadata.id}');
    print('      - Size: ${metadata.sizeBytes} bytes');
    print('      - MIME type: ${metadata.mimeType}');
    print('      - Created: ${metadata.createdAt}');

    // Example 6: Download file content
    print('\n   === Downloading file content ===');
    final downloadedBytes = await provider.getFileContent(uploadedFile.id);
    final downloadedText = String.fromCharCodes(downloadedBytes);
    print('      Downloaded content: $downloadedText');

    // Example 7: Check if file exists
    print('\n   === Checking file existence ===');
    final exists = await provider.fileExists(uploadedFile.id);
    print('      File exists: $exists');

    final nonExistentExists = await provider.fileExists('non-existent-id');
    print('      Non-existent file exists: $nonExistentExists');

    // Example 8: Delete files
    print('\n   === Deleting files ===');
    final deleteResult1 = await provider.deleteFile(uploadedFile.id);
    print(
        '      Delete ${uploadedFile.filename}: ${deleteResult1.deleted ? "Success" : "Failed"}');

    final deleteResult2 = await provider.deleteFile(autoFile.id);
    print(
        '      Delete ${autoFile.filename}: ${deleteResult2.deleted ? "Success" : "Failed"}');

    print('   ✅ File management demonstration completed\n');
  } catch (e) {
    print('   ❌ File management failed: $e\n');
  }
}

/// Demonstrate text file processing
Future<void> demonstrateTextFileProcessing(String apiKey) async {
  print('📄 Text File Processing:\n');

  try {
    final model = await ai()
        .anthropic()
        .apiKey(apiKey)
        .model('claude-sonnet-4-20250514')
        .temperature(0.3)
        .maxTokens(1500)
        .buildLanguageModel();

    // Create a sample text file
    const sampleText = '''
# Project Report: AI Implementation

## Executive Summary
Our company has successfully implemented an AI-powered customer service system
that has reduced response times by 60% and improved customer satisfaction scores
from 3.2 to 4.7 out of 5.

## Key Metrics
- Response time: Reduced from 24 hours to 9.6 hours
- Customer satisfaction: Improved from 3.2/5 to 4.7/5
- Cost savings: 35% reduction in support costs
- Resolution rate: Increased from 78% to 92%

## Challenges
1. Initial training data quality issues
2. Integration with legacy systems
3. Staff adaptation to new workflows

## Recommendations
- Continue monitoring performance metrics
- Expand AI implementation to other departments
- Invest in additional staff training
''';

    // Save sample file
    const filename = 'sample_report.txt';
    await File(filename).writeAsString(sampleText);

    print('   Processing text file: $filename');

    // Read and process the file
    final fileData = await File(filename).readAsBytes();

    final prompt = ChatPromptBuilder.user()
        .text('Please analyze this project report and provide insights:')
        .fileBytes(
          fileData,
          mime: FileMime.txt,
          filename: filename,
        )
        .text('''
Based on this report, please:
1. Summarize the key achievements
2. Identify potential risks or concerns
3. Suggest next steps for improvement
4. Rate the project success (1-10) with justification
''').build();

    final response = await generateTextWithModel(
      model,
      promptMessages: [prompt],
    );

    print('      ✅ File processed successfully');
    print('      File size: ${fileData.length} bytes');
    print('      Analysis: ${response.text}');

    // Clean up
    await File(filename).delete();

    print('   ✅ Text file processing demonstration completed\n');
  } catch (e) {
    print('   ❌ Text file processing failed: $e\n');
  }
}

/// Demonstrate image analysis
Future<void> demonstrateImageAnalysis(String apiKey) async {
  print('🖼️  Image Analysis:\n');

  try {
    final model = await ai()
        .anthropic()
        .apiKey(apiKey)
        .model('claude-sonnet-4-20250514')
        .temperature(0.4)
        .maxTokens(1000)
        .buildLanguageModel();

    // Create a simple test image (placeholder - in real use, you'd have actual images)
    print('   Note: This example shows the structure for image analysis.');
    print('   In a real application, you would provide actual image files.');

    // Example of how to process an image file
    const imagePath = 'sample_chart.png';

    // Check if image exists (for demo purposes)
    final imageFile = File(imagePath);
    if (await imageFile.exists()) {
      final imageData = await imageFile.readAsBytes();

      final prompt = ChatPromptBuilder.user()
          .text('Please analyze this image and describe what you see:')
          .fileBytes(
            imageData,
            mime: FileMime.png,
            filename: imagePath,
          )
          .text('''
Please provide:
1. A detailed description of the image
2. Any data or trends you can identify
3. Insights or conclusions you can draw
4. Suggestions for improvement if applicable
''').build();

      final response = await generateTextWithModel(
        model,
        promptMessages: [prompt],
      );

      print('      ✅ Image analyzed successfully');
      print('      Image size: ${imageData.length} bytes');
      print('      Analysis: ${response.text}');
    } else {
      print('      ℹ️  No sample image found. Here\'s how to analyze images:');
      print('      1. Load image file as bytes');
      print(
          '      2. Use ChatPromptBuilder.fileBytes to attach the file and specify the MIME type');
      print('      3. Include descriptive prompts for analysis');
      print('      4. Claude can analyze charts, diagrams, photos, etc.');
    }

    print('   ✅ Image analysis demonstration completed\n');
  } catch (e) {
    print('   ❌ Image analysis failed: $e\n');
  }
}

/// Demonstrate PDF processing
Future<void> demonstratePDFProcessing(String apiKey) async {
  print('📋 PDF Processing:\n');

  try {
    // Create a sample PDF content (as text for demonstration)
    const pdfContent = '''
RESEARCH PAPER: The Impact of AI on Modern Business

Abstract:
This paper examines the transformative effects of artificial intelligence
on contemporary business practices across various industries.

1. Introduction
Artificial Intelligence (AI) has emerged as a revolutionary force in the
business world, fundamentally altering how companies operate, make decisions,
and interact with customers.

2. Methodology
We conducted surveys with 500 businesses across 10 industries and analyzed
performance metrics before and after AI implementation.

3. Results
- 78% of businesses reported improved efficiency
- 65% saw cost reductions within 12 months
- 82% improved customer satisfaction scores
- 45% increased revenue growth

4. Discussion
The data suggests that AI adoption correlates strongly with business
performance improvements across multiple metrics.

5. Conclusion
AI implementation, when properly executed, provides significant competitive
advantages and operational improvements for modern businesses.
''';

    print('   Processing PDF-like document content...');

    // Simulate PDF processing
    final pdfBytes = Uint8List.fromList(pdfContent.codeUnits);

    final model = await ai()
        .anthropic()
        .apiKey(apiKey)
        .model('claude-sonnet-4-20250514')
        .temperature(0.3)
        .maxTokens(2000)
        .buildLanguageModel();

    final prompt = ChatPromptBuilder.user()
        .text(
            'Please analyze this research paper and provide a comprehensive review:')
        .fileBytes(
          pdfBytes,
          mime: FileMime.pdf,
          filename: 'research_paper.pdf',
        )
        .text('''
Please provide:
1. A concise summary of the paper's main findings
2. Critical analysis of the methodology
3. Assessment of the conclusions' validity
4. Suggestions for future research directions
5. Overall quality rating (1-10) with justification
''').build();

    final response = await generateTextWithModel(
      model,
      promptMessages: [prompt],
    );

    print('      ✅ PDF content processed successfully');
    print('      Content size: ${pdfBytes.length} bytes');
    print('      Analysis: ${response.text}');

    print('   ✅ PDF processing demonstration completed\n');
  } catch (e) {
    print('   ❌ PDF processing failed: $e\n');
  }
}

/// Demonstrate multi-file analysis
Future<void> demonstrateMultiFileAnalysis(String apiKey) async {
  print('📚 Multi-File Analysis:\n');

  try {
    // Create multiple sample files
    const file1Content = '''
Q1 Sales Report:
- Revenue: \$2.5M
- Growth: +15% YoY
- Top product: Widget A (45% of sales)
- Customer acquisition: 1,200 new customers
''';

    const file2Content = '''
Q2 Sales Report:
- Revenue: \$2.8M
- Growth: +12% YoY
- Top product: Widget B (38% of sales)
- Customer acquisition: 1,450 new customers
''';

    const file3Content = '''
Q3 Sales Report:
- Revenue: \$3.1M
- Growth: +18% YoY
- Top product: Widget A (42% of sales)
- Customer acquisition: 1,680 new customers
''';

    // Save files
    await File('q1_report.txt').writeAsString(file1Content);
    await File('q2_report.txt').writeAsString(file2Content);
    await File('q3_report.txt').writeAsString(file3Content);

    print('   Analyzing multiple quarterly reports...');

    // Process multiple files
    final file1Data = await File('q1_report.txt').readAsBytes();
    final file2Data = await File('q2_report.txt').readAsBytes();
    final file3Data = await File('q3_report.txt').readAsBytes();

    final model = await ai()
        .anthropic()
        .apiKey(apiKey)
        .model('claude-sonnet-4-20250514')
        .temperature(0.3)
        .maxTokens(2000)
        .buildLanguageModel();

    final prompt = ChatPromptBuilder.user()
        .text(
            'Please analyze these quarterly sales reports and provide insights:')
        .fileBytes(
          file1Data,
          mime: FileMime.txt,
          filename: 'q1_report.txt',
        )
        .fileBytes(
          file2Data,
          mime: FileMime.txt,
          filename: 'q2_report.txt',
        )
        .fileBytes(
          file3Data,
          mime: FileMime.txt,
          filename: 'q3_report.txt',
        )
        .text('''
Based on these three quarterly reports, please:
1. Identify trends across the quarters
2. Analyze product performance patterns
3. Evaluate customer acquisition trends
4. Predict Q4 performance
5. Recommend strategic actions
''').build();

    final response = await generateTextWithModel(
      model,
      promptMessages: [prompt],
    );

    print('      ✅ Multi-file analysis completed');
    print('      Files processed: 3');
    print(
        '      Total data: ${file1Data.length + file2Data.length + file3Data.length} bytes');
    print('      Analysis: ${response.text}');

    // Clean up
    await File('q1_report.txt').delete();
    await File('q2_report.txt').delete();
    await File('q3_report.txt').delete();

    print('   ✅ Multi-file analysis demonstration completed\n');
  } catch (e) {
    print('   ❌ Multi-file analysis failed: $e\n');
  }
}

/// Demonstrate document comparison
Future<void> demonstrateDocumentComparison(String apiKey) async {
  print('🔍 Document Comparison:\n');

  try {
    // Create two versions of a document
    const version1 = '''
Company Policy: Remote Work Guidelines

1. Eligibility: All full-time employees
2. Schedule: Flexible hours between 8 AM - 6 PM
3. Equipment: Company provides laptop and monitor
4. Communication: Daily check-ins required
5. Performance: Monthly reviews
''';

    const version2 = '''
Company Policy: Remote Work Guidelines

1. Eligibility: All employees (full-time and part-time)
2. Schedule: Core hours 10 AM - 3 PM, flexible otherwise
3. Equipment: Company provides laptop, monitor, and desk setup
4. Communication: Weekly team meetings, daily check-ins optional
5. Performance: Quarterly reviews with goal-setting
6. Training: Mandatory remote work training for all participants
''';

    // Save both versions
    await File('policy_v1.txt').writeAsString(version1);
    await File('policy_v2.txt').writeAsString(version2);

    print('   Comparing two versions of company policy...');

    final v1Data = await File('policy_v1.txt').readAsBytes();
    final v2Data = await File('policy_v2.txt').readAsBytes();

    final model = await ai()
        .anthropic()
        .apiKey(apiKey)
        .model('claude-sonnet-4-20250514')
        .temperature(0.2) // Lower for analytical comparison
        .maxTokens(1500)
        .buildLanguageModel();

    final prompt = ChatPromptBuilder.user()
        .text('Please compare these two versions of our remote work policy:')
        .fileBytes(
          v1Data,
          mime: FileMime.txt,
          filename: 'policy_v1.txt',
        )
        .fileBytes(
          v2Data,
          mime: FileMime.txt,
          filename: 'policy_v2.txt',
        )
        .text('''
Please provide:
1. Key differences between the versions
2. Analysis of which changes are improvements
3. Potential issues with the new version
4. Recommendations for further refinements
5. Overall assessment of the policy evolution
''').build();

    final response = await generateTextWithModel(
      model,
      promptMessages: [prompt],
    );

    print('      ✅ Document comparison completed');
    print('      Documents compared: 2 versions');
    print('      Analysis: ${response.text}');

    // Clean up
    await File('policy_v1.txt').delete();
    await File('policy_v2.txt').delete();

    print('   ✅ Document comparison demonstration completed\n');
  } catch (e) {
    print('   ❌ Document comparison failed: $e\n');
  }
}

/// 🎯 Key Anthropic File Handling Concepts Summary:
///
/// File Management API:
/// - Upload files: uploadFile(FileUploadRequest) or uploadFileFromBytes()
/// - List files: listFiles([FileListQuery?])
/// - Get metadata: retrieveFile(String fileId)
/// - Download content: getFileContent(String fileId)
/// - Delete files: deleteFile(String fileId)
/// - Check existence: fileExists(String fileId)
///
/// Supported File Types:
/// - Text files (.txt, .md, .csv)
/// - PDF documents
/// - Images (PNG, JPEG, GIF, WebP)
/// - JSON and structured data files
///
/// File Processing Capabilities:
/// - Document analysis and summarization
/// - Multi-file comparison and synthesis
/// - Image analysis and description
/// - Data extraction from structured documents
/// - Cross-document pattern recognition
///
/// Best Practices:
/// - Use `AnthropicProvider(AnthropicConfig(...))` for full file management access
/// - Use appropriate MIME types for files
/// - Provide context with file uploads
/// - Use lower temperature for analytical tasks
/// - Break down complex analysis into steps
/// - Clean up uploaded files after processing
///
/// Configuration Tips:
/// - claude-3-5-sonnet: Best for document analysis
/// - Lower temperature (0.2-0.4): More focused analysis
/// - Higher max_tokens: Allow detailed analysis
/// - Structured prompts: Guide analysis direction
///
/// Use Cases:
/// - Legal document review
/// - Research paper analysis
/// - Business report processing
/// - Image and chart analysis
/// - Multi-document synthesis
/// - File storage and retrieval systems
///
/// Next Steps:
/// - Try other provider examples for comparison
/// - Explore advanced multi-modal capabilities
/// - Implement real-world file processing workflows
