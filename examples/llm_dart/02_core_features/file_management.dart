import 'dart:io';
import 'dart:typed_data';
import 'package:llm_dart/llm_dart.dart';

/// Comprehensive file management examples using the unified FileManagementCapability interface
///
/// This example demonstrates:
/// - File upload and download operations
/// - File listing and metadata retrieval
/// - File deletion and cleanup
/// - Different file types and purposes
/// - Provider capability detection
/// - Error handling for file operations
Future<void> main() async {
  print('📁 File Management Examples\n');

  // Example with providers that support file management
  final providers = [
    ('OpenAI', () => ai().openai().apiKey('your-openai-key')),
    ('Anthropic', () => ai().anthropic().apiKey('your-anthropic-key')),
  ];

  for (final (name, builderFactory) in providers) {
    print('📂 Testing $name File Management:');

    try {
      final provider = await builderFactory().buildFileManagement();
      await demonstrateFileFeatures(provider, name);
    } catch (e) {
      print('   ❌ Failed to initialize $name: $e\n');
    }
  }

  print('✅ File management examples completed!');
  print('💡 For provider-specific features, see:');
  print('   • example/04_providers/openai/file_management.dart');
  print('   • example/04_providers/anthropic/file_management.dart');
}

/// Helper function to parse purpose string to FilePurpose enum
FilePurpose _parsePurpose(String purpose) {
  return FilePurpose.fromString(purpose);
}

/// Demonstrate various file management features with a provider
Future<void> demonstrateFileFeatures(
    FileManagementCapability provider, String providerName) async {
  final uploadedFiles = <FileObject>[];

  try {
    // File upload examples
    final files = await demonstrateFileUploads(provider, providerName);
    uploadedFiles.addAll(files);

    // File listing
    await demonstrateFileListing(provider, providerName);

    // File metadata retrieval
    if (uploadedFiles.isNotEmpty) {
      await demonstrateFileRetrieval(
          provider, providerName, uploadedFiles.first);
    }

    // File content download
    if (uploadedFiles.isNotEmpty) {
      await demonstrateFileDownload(
          provider, providerName, uploadedFiles.first);
    }

    // File search and filtering
    await demonstrateFileSearch(provider, providerName);
  } finally {
    // Cleanup uploaded files
    await demonstrateFileCleanup(provider, providerName, uploadedFiles);
  }

  print('');
}

/// Demonstrate file upload operations
Future<List<FileObject>> demonstrateFileUploads(
    FileManagementCapability provider, String providerName) async {
  print('   📤 File Uploads:');

  final uploadedFiles = <FileObject>[];

  try {
    // Create sample files for testing
    await createSampleFiles();

    // Upload different types of files
    final fileUploads = [
      {
        'path': 'sample_document.txt',
        'purpose': 'assistants',
        'description': 'Sample text document for assistant training',
      },
      {
        'path': 'sample_data.jsonl',
        'purpose': 'fine-tune',
        'description': 'Training data for fine-tuning',
      },
      {
        'path': 'sample_image.txt', // Simulated image as text for demo
        'purpose': 'vision',
        'description': 'Sample image for vision tasks',
      },
    ];

    for (final upload in fileUploads) {
      try {
        print('      🔄 Uploading ${upload['path']}...');

        // Read file content as bytes
        final fileBytes = await File(upload['path']!).readAsBytes();

        final request = FileUploadRequest(
          file: Uint8List.fromList(fileBytes),
          purpose: _parsePurpose(upload['purpose']!),
          filename: upload['path']!,
        );

        final fileObject = await provider.uploadFile(request);
        uploadedFiles.add(fileObject);

        print('         ✅ Uploaded: ${fileObject.id}');
        print('         📊 Size: ${fileObject.sizeBytes} bytes');
        print('         🎯 Purpose: ${fileObject.purpose}');
        print('         📅 Created: ${fileObject.createdAt}');
      } catch (e) {
        print('         ❌ Upload failed: $e');
      }
    }

    print('      📈 Total uploaded: ${uploadedFiles.length} files');
  } catch (e) {
    print('      ❌ File upload demonstration failed: $e');
  }

  return uploadedFiles;
}

/// Demonstrate file listing operations
Future<void> demonstrateFileListing(
    FileManagementCapability provider, String providerName) async {
  print('   📋 File Listing:');

  try {
    // List all files
    print('      🔄 Listing all files...');
    final allFiles = await provider.listFiles();

    print('      📊 Total files: ${allFiles.data.length}');

    if (allFiles.data.isNotEmpty) {
      print('      📁 Recent files:');
      for (final file in allFiles.data.take(5)) {
        final sizeKB = (file.sizeBytes / 1024).toStringAsFixed(1);
        print('         • ${file.filename} (${file.id}) - ${sizeKB}KB');
      }
    }

    // List files with filtering
    print('      🔍 Filtering by purpose...');
    final assistantFiles = await provider.listFiles(
      FileListQuery(purpose: FilePurpose.assistants, limit: 10),
    );

    print('      🤖 Assistant files: ${assistantFiles.data.length}');

    // Pagination example
    if (allFiles.hasMore == true) {
      print('      📄 Demonstrating pagination...');
      final nextPage = await provider.listFiles(
        FileListQuery(after: allFiles.lastId, limit: 5),
      );
      print('         📋 Next page: ${nextPage.data.length} files');
    }
  } catch (e) {
    print('      ❌ File listing failed: $e');
  }
}

/// Demonstrate file metadata retrieval
Future<void> demonstrateFileRetrieval(FileManagementCapability provider,
    String providerName, FileObject file) async {
  print('   🔍 File Metadata Retrieval:');

  try {
    print('      🔄 Retrieving metadata for ${file.id}...');

    final retrievedFile = await provider.retrieveFile(file.id);

    print('      ✅ File Details:');
    print('         📄 Name: ${retrievedFile.filename}');
    print('         🆔 ID: ${retrievedFile.id}');
    print('         📊 Size: ${retrievedFile.sizeBytes} bytes');
    print('         🎯 Purpose: ${retrievedFile.purpose}');
    print('         📅 Created: ${retrievedFile.createdAt}');
    print('         🏷️  Status: ${retrievedFile.status}');

    if (retrievedFile.statusDetails != null) {
      print('         📝 Status Details: ${retrievedFile.statusDetails}');
    }
  } catch (e) {
    print('      ❌ File retrieval failed: $e');
  }
}

/// Demonstrate file content download
Future<void> demonstrateFileDownload(FileManagementCapability provider,
    String providerName, FileObject file) async {
  print('   📥 File Content Download:');

  try {
    print('      🔄 Downloading content for ${file.filename}...');

    final content = await provider.getFileContent(file.id);

    print('      ✅ Downloaded: ${content.length} bytes');

    // Save downloaded content
    final downloadPath = 'downloaded_${file.filename}';
    await File(downloadPath).writeAsBytes(content);
    print('      💾 Saved to: $downloadPath');

    // Display content preview (if text)
    if (file.filename.endsWith('.txt') || file.filename.endsWith('.jsonl')) {
      final textContent = String.fromCharCodes(content);
      final preview = textContent.length > 100
          ? '${textContent.substring(0, 100)}...'
          : textContent;
      print('      👀 Preview: $preview');
    }
  } catch (e) {
    print('      ❌ File download failed: $e');
  }
}

/// Demonstrate file search and filtering
Future<void> demonstrateFileSearch(
    FileManagementCapability provider, String providerName) async {
  print('   🔎 File Search & Filtering:');

  try {
    // Search by different criteria
    final searchCriteria = [
      {'purpose': 'assistants', 'description': 'Assistant files'},
      {'purpose': 'fine-tune', 'description': 'Fine-tuning files'},
      {'purpose': 'vision', 'description': 'Vision files'},
    ];

    for (final criteria in searchCriteria) {
      final purpose = criteria['purpose']!;
      final description = criteria['description']!;

      print('      🔍 Searching $description...');

      final results = await provider.listFiles(
        FileListQuery(purpose: _parsePurpose(purpose), limit: 20),
      );

      print('         📊 Found: ${results.data.length} files');

      if (results.data.isNotEmpty) {
        // Calculate total size
        final totalBytes =
            results.data.fold<int>(0, (sum, file) => sum + file.sizeBytes);
        final totalMB = (totalBytes / (1024 * 1024)).toStringAsFixed(2);
        print('         📦 Total size: ${totalMB}MB');

        // Show newest file
        final newest = results.data.first;
        print('         🆕 Newest: ${newest.filename} (${newest.createdAt})');
      }
    }
  } catch (e) {
    print('      ❌ File search failed: $e');
  }
}

/// Demonstrate file cleanup operations
Future<void> demonstrateFileCleanup(FileManagementCapability provider,
    String providerName, List<FileObject> files) async {
  print('   🗑️  File Cleanup:');

  if (files.isEmpty) {
    print('      ℹ️  No files to clean up');
    return;
  }

  try {
    print('      🔄 Cleaning up ${files.length} uploaded files...');

    int deletedCount = 0;
    for (final file in files) {
      try {
        final result = await provider.deleteFile(file.id);
        if (result.deleted) {
          deletedCount++;
          print('         ✅ Deleted: ${file.filename}');
        } else {
          print('         ❌ Failed to delete: ${file.filename}');
        }
      } catch (e) {
        print('         ❌ Delete error for ${file.filename}: $e');
      }
    }

    print(
        '      📊 Cleanup summary: $deletedCount/${files.length} files deleted');
  } catch (e) {
    print('      ❌ File cleanup failed: $e');
  }
}

/// Create sample files for testing
Future<void> createSampleFiles() async {
  // Create sample text document
  await File('sample_document.txt').writeAsString('''
This is a sample document for testing file upload functionality.

It contains multiple paragraphs and demonstrates how text files
can be uploaded to AI providers for various purposes such as:

1. Assistant training data
2. Knowledge base content
3. Document analysis
4. Content generation

The file management system should handle this content properly
and maintain file integrity during upload and download operations.
''');

  // Create sample JSONL file for fine-tuning
  await File('sample_data.jsonl').writeAsString('''
{"prompt": "What is machine learning?", "completion": "Machine learning is a subset of AI that enables computers to learn from data."}
{"prompt": "Explain neural networks", "completion": "Neural networks are computing systems inspired by biological neural networks."}
{"prompt": "What is deep learning?", "completion": "Deep learning uses neural networks with multiple layers to model complex patterns."}
''');

  // Create sample "image" file (as text for demo)
  await File('sample_image.txt').writeAsString('''
[This would be binary image data in a real scenario]
Image metadata:
- Format: PNG
- Dimensions: 1024x768
- Color depth: 24-bit
- Purpose: Vision model training
''');
}

/// Utility class for file management operations
class FileManagementUtils {
  /// Get human-readable file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// Validate file for upload
  static bool isValidForUpload(String filePath, String purpose) {
    final file = File(filePath);
    if (!file.existsSync()) return false;

    final size = file.lengthSync();
    const maxSize = 100 * 1024 * 1024; // 100MB limit

    return size <= maxSize;
  }

  /// Get recommended purpose based on file extension
  static String getRecommendedPurpose(String filename) {
    final extension = filename.split('.').last.toLowerCase();

    switch (extension) {
      case 'txt':
      case 'md':
      case 'pdf':
        return 'assistants';
      case 'jsonl':
        return 'fine-tune';
      case 'png':
      case 'jpg':
      case 'jpeg':
        return 'vision';
      default:
        return 'assistants';
    }
  }

  /// Clean up temporary files
  static Future<void> cleanupTempFiles() async {
    final tempFiles = [
      'sample_document.txt',
      'sample_data.jsonl',
      'sample_image.txt',
    ];

    for (final filename in tempFiles) {
      final file = File(filename);
      if (await file.exists()) {
        await file.delete();
      }
    }

    // Clean up downloaded files
    final currentDir = Directory.current;
    await for (final entity in currentDir.list()) {
      if (entity is File && entity.path.contains('downloaded_')) {
        await entity.delete();
      }
    }
  }
}
