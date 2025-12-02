import 'dart:io';

import 'package:llm_dart/llm_dart.dart'
    hide GoogleClient, GoogleConfig, GoogleFilesClient;
import 'package:llm_dart_google/llm_dart_google.dart'
    show GoogleClient, GoogleConfig, GoogleFilesClient;

/// Google Gemini Files API + File Search RAG example.
///
/// This example shows how to:
/// - Upload a local file to the Gemini Files API.
/// - Use the uploaded file in a chat request via file_search.
///
/// Note: This uses the low-level llm_dart_google package directly for the
/// upload step, and then uses the high-level llm_dart builder for chat.
Future<void> main() async {
  print('📚 Google Gemini Files + RAG Example\n');

  final apiKey = Platform.environment['GOOGLE_API_KEY'];
  if (apiKey == null) {
    print('❌ Please set GOOGLE_API_KEY environment variable');
    return;
  }

  final storeName = Platform.environment['GOOGLE_FILE_SEARCH_STORE'];
  if (storeName == null) {
    print('❌ Please set GOOGLE_FILE_SEARCH_STORE environment variable');
    print('   Example: fileSearchStores/my-file-search-store-123');
    return;
  }

  final filePath =
      Platform.environment['GEMINI_RAG_FILE'] ?? 'sample_rag_document.pdf';

  if (!File(filePath).existsSync()) {
    print('⚠️  RAG file not found: $filePath');
    print(
        '    Set GEMINI_RAG_FILE or place sample_rag_document.pdf next to this file.');
    return;
  }

  // === 1) Upload file via low-level Files API helper ===
  final ragBytes = await File(filePath).readAsBytes();

  final lowLevelConfig = GoogleConfig(
    apiKey: apiKey,
    model: 'gemini-2.5-flash',
  );
  final googleClient = GoogleClient(lowLevelConfig);
  final filesClient = GoogleFilesClient(googleClient);

  print('⬆️  Uploading RAG document to Gemini Files API...');
  final uploaded = await filesClient.uploadBytes(
    data: ragBytes,
    mimeType: 'application/pdf',
    displayName: filePath,
  );
  print('   ✅ Uploaded file: ${uploaded.name} (${uploaded.displayName})');

  // === 2) Build high-level LanguageModel with File Search enabled ===
  final model = await ai()
      .google((google) => google.fileSearch(
            fileSearchStoreNames: [storeName],
            topK: 12,
          ))
      .apiKey(apiKey)
      .model('gemini-2.5-flash')
      .buildLanguageModel();

  // For this example we rely on File Search store contents;
  // the uploaded file can be associated with the store using
  // Google Console or additional management APIs.

  final messages = <ModelMessage>[
    ModelMessage.systemText(
      '你是一个帮助阅读文档的助手，请结合文件搜索结果回答问题，并尽量引用原文中的表述。',
    ),
    ModelMessage.userText(
      '请根据知识库中的文档，简要说明系统的核心模块和它们之间的关系。',
    ),
  ];

  final response = await generateTextPromptWithModel(
    model,
    messages: messages,
  );

  print('=== RAG Response ===');
  print(response.text);

  final meta = response.metadata;
  if (meta != null) {
    print('\n--- Call Metadata ---');
    print('provider: ${meta.provider}, model: ${meta.model}');
    print('providerMetadata: ${meta.providerMetadata}');
  }
}
