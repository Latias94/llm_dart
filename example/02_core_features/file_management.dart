// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/models/file_models.dart';
import 'package:llm_dart/providers/anthropic/anthropic.dart'
    as anthropic_compat;
import 'package:llm_dart/providers/openai/openai.dart' as openai_compat;

/// File handling has two distinct layers in the current architecture:
/// - stable prompt-time local file parts for shared chat flows
/// - provider-owned remote file lifecycle APIs for persistent workspace storage
///
/// This example shows both paths and keeps the provider-owned lifecycle calls
/// explicit instead of presenting them as a stable shared facade.
/// For Flutter chat attachment UX, the default path should usually stay local
/// until a provider-specific remote workspace is actually required.
Future<void> main() async {
  print('File Management Boundary Example\n');

  final openAIApiKey = Platform.environment['OPENAI_API_KEY'];
  if (openAIApiKey != null && openAIApiKey.isNotEmpty) {
    await demonstrateStablePromptFilePath(openAIApiKey);
    await demonstrateOpenAIFileBoundary(openAIApiKey);
  } else {
    print('Skipping OpenAI sections because OPENAI_API_KEY is not set.\n');
  }

  final anthropicApiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (anthropicApiKey != null && anthropicApiKey.isNotEmpty) {
    await demonstrateAnthropicFileBoundary(anthropicApiKey);
  } else {
    print(
      'Skipping Anthropic file lifecycle because ANTHROPIC_API_KEY is not set.\n',
    );
  }

  explainBoundary();

  print('\nFile management example completed.');
}

Future<void> demonstrateStablePromptFilePath(String apiKey) async {
  print('=== Stable Local File Prompt Path ===\n');

  final sampleFile = await _writeSampleTextFile(
    'stable_file_prompt_example.txt',
    '''
Release Notes Draft

- Local attachments should stay app-owned by default.
- Tool replay now keeps explicit tool call IDs.
- Provider remote files should be treated as explicit boundary APIs.
''',
  );

  try {
    final fileBytes = await sampleFile.readAsBytes();
    final model = llm.AI.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');

    final result = await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage(
          parts: [
            const core.TextPromptPart(
              'Summarize this release note file into three short bullets.',
            ),
            core.FilePromptPart(
              mediaType: 'text/plain',
              filename: 'stable_file_prompt_example.txt',
              bytes: fileBytes,
            ),
          ],
        ),
      ],
      options: const core.GenerateTextOptions(
        temperature: 0.2,
        maxOutputTokens: 200,
      ),
    );

    print(result.text);
    print('');
  } finally {
    await _deleteIfExists(sampleFile);
  }
}

Future<void> demonstrateOpenAIFileBoundary(String apiKey) async {
  print('=== Provider-Owned OpenAI File Lifecycle Boundary ===\n');

  final sampleFile = await _writeSampleTextFile(
    'openai_file_lifecycle_example.txt',
    '''
Provider-owned files are useful when an application needs remote persistence,
assistant resources, or provider-managed retrieval workflows.
''',
  );

  final fileClient = openai_compat.createOpenAIProvider(
    apiKey: apiKey,
    model: 'gpt-4o',
  );

  FileObject? uploadedFile;

  try {
    uploadedFile = await fileClient.uploadFile(
      FileUploadRequest(
        file: await sampleFile.readAsBytes(),
        filename: sampleFile.uri.pathSegments.last,
        purpose: FilePurpose.assistants,
      ),
    );

    print('Uploaded file: ${uploadedFile.id}');
    print('Purpose: ${uploadedFile.purpose?.value ?? '<none>'}');
    print('Size: ${uploadedFile.sizeBytes} bytes');

    final listed = await fileClient.listFiles(
      const FileListQuery(
        limit: 5,
        purpose: FilePurpose.assistants,
      ),
    );
    print('Recent assistant files returned: ${listed.data.length}');

    final retrieved = await fileClient.retrieveFile(uploadedFile.id);
    print('Retrieved filename: ${retrieved.filename}');

    final content = await fileClient.getFileContent(uploadedFile.id);
    print('Downloaded bytes: ${content.length}');
  } finally {
    if (uploadedFile != null) {
      final deleted = await fileClient.deleteFile(uploadedFile.id);
      print('Deleted temporary OpenAI file: ${deleted.deleted}');
    }
    await _deleteIfExists(sampleFile);
  }

  print('');
}

Future<void> demonstrateAnthropicFileBoundary(String apiKey) async {
  print('=== Provider-Owned Anthropic File Lifecycle Boundary ===\n');

  final sampleFile = await _writeSampleTextFile(
    'anthropic_file_lifecycle_example.txt',
    '''
Anthropic file handling is provider-owned and currently beta-oriented.
Keep the integration boundary explicit in application code.
''',
  );

  final fileClient = anthropic_compat.createAnthropicProvider(
    apiKey: apiKey,
    model: 'claude-sonnet-4-20250514',
  );

  FileObject? uploadedFile;

  try {
    uploadedFile = await fileClient.uploadFile(
      FileUploadRequest(
        file: await sampleFile.readAsBytes(),
        filename: sampleFile.uri.pathSegments.last,
      ),
    );

    print('Uploaded file: ${uploadedFile.id}');
    print('MIME type: ${uploadedFile.mimeType ?? '<none>'}');
    print('Downloadable: ${uploadedFile.downloadable}');

    final listed = await fileClient.listFiles(
      const FileListQuery(limit: 5),
    );
    print('Recent Anthropic files returned: ${listed.data.length}');

    final retrieved = await fileClient.retrieveFile(uploadedFile.id);
    print('Retrieved filename: ${retrieved.filename}');

    final content = await fileClient.getFileContent(uploadedFile.id);
    print('Downloaded bytes: ${content.length}');
  } finally {
    if (uploadedFile != null) {
      final deleted = await fileClient.deleteFile(uploadedFile.id);
      print('Deleted temporary Anthropic file: ${deleted.deleted}');
    }
    await _deleteIfExists(sampleFile);
  }

  print('');
}

void explainBoundary() {
  print('=== Boundary Notes ===\n');
  print(
    '• Stable app code should usually keep local files in app or Flutter '
    'storage and pass them through `FilePromptPart` only when a model call '
    'needs them.',
  );
  print(
    '• Keep attachment preview, retry, removal, and local caching in your app '
    'layer; only upload provider-side when product requirements need '
    'persistent retrieval or workspace storage.',
  );
  print(
    '• Remote file lifecycle APIs are provider-owned because persistence, '
    'purpose fields, indexing, and later retrieval semantics differ by provider.',
  );
  print(
    '• OpenAI and Anthropic file flows may share method names in compatibility '
    'layers, but they are not a stable cross-provider contract.',
  );
  print(
    '• Isolate provider-side file persistence behind provider-specific adapters '
    'in production applications.',
  );
}

Future<File> _writeSampleTextFile(String filename, String content) async {
  final file = File(filename);
  await file.writeAsString(content.trim());
  return file;
}

Future<void> _deleteIfExists(File file) async {
  if (await file.exists()) {
    await file.delete();
  }
}
