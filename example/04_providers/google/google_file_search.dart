import 'dart:io';

import 'package:llm_dart/llm_dart.dart';

/// Google Gemini File Search example.
///
/// This example shows how to:
/// - Configure Gemini 2.5 with the `file_search` tool.
/// - Run a simple RAG-style query over a File Search store.
///
/// Reference: https://ai.google.dev/gemini-api/docs/file-search
Future<void> main() async {
  print('📄 Google Gemini File Search Example\n');

  final apiKey = Platform.environment['GOOGLE_API_KEY'];
  if (apiKey == null) {
    print('❌ Please set GOOGLE_API_KEY environment variable');
    print('   Get your API key from: https://aistudio.google.com/app/apikey');
    return;
  }

  final storeName = Platform.environment['GOOGLE_FILE_SEARCH_STORE'];
  if (storeName == null) {
    print('❌ Please set GOOGLE_FILE_SEARCH_STORE environment variable');
    print('   Example: fileSearchStores/my-file-search-store-123');
    return;
  }

  try {
    final model = await ai()
        .google((google) => google.fileSearch(
              fileSearchStoreNames: [storeName],
              topK: 8,
            ))
        .apiKey(apiKey)
        // File Search is supported on Gemini 2.5 models.
        .model('gemini-2.5-flash')
        .buildLanguageModel();

    final messages = <ModelMessage>[
      ModelMessage.systemText(
        'You are a helpful assistant that answers questions using the '
        'documents available in the configured File Search store.',
      ),
      ModelMessage.userText(
        '根据知识库回答：请简要说明本项目的架构设计要点。',
      ),
    ];

    final response = await generateTextPromptWithModel(
      model,
      messages: messages,
    );

    print('=== File Search Response ===');
    print(response.text);

    final meta = response.metadata;
    if (meta != null) {
      print('\n--- Call Metadata ---');
      print('provider: ${meta.provider}, model: ${meta.model}');
      print('providerMetadata: ${meta.providerMetadata}');
    }
  } catch (e) {
    print('❌ Error while calling Gemini File Search: $e');
  }
}
