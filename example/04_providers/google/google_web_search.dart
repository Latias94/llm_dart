import 'dart:io';

import 'package:llm_dart/llm_dart.dart';

/// Google Gemini web search example using the unified WebSearchConfig.
///
/// This example shows how to:
/// - Enable Google Search grounding via `enableWebSearch()`
/// - Ask a real-time question that benefits from web search
/// - Inspect call-level metadata (provider/model/flags) via `callMetadata`
Future<void> main() async {
  final apiKey =
      Platform.environment['GOOGLE_API_KEY'] ?? 'YOUR_GOOGLE_API_KEY';

  if (apiKey == 'YOUR_GOOGLE_API_KEY') {
    // ignore: avoid_print
    print(
      'Please set GOOGLE_API_KEY in your environment or replace YOUR_GOOGLE_API_KEY.',
    );
  }

  // Build a Gemini 2.5 provider with Google Search grounding enabled.
  final provider = await ai()
      .google()
      .apiKey(apiKey)
      // Use a Gemini 2.x model that supports the `google_search` tool.
      .model('gemini-2.5-flash')
      // Unified web search configuration (works across providers).
      .enableWebSearch()
      .build();

  final messages = <ChatMessage>[
    ChatMessage.system(
      'You are a helpful assistant. Use real-time information when needed.',
    ),
    ChatMessage.user(
      'Who won the UEFA Euro 2024 final, and where was it played?',
    ),
  ];

  final response = await provider.chat(messages);

  // ignore: avoid_print
  print('=== Gemini Web Search Response ===');
  // ignore: avoid_print
  print(response.text);

  final meta = response.callMetadata;
  if (meta != null) {
    // ignore: avoid_print
    print('\n--- Call Metadata ---');
    // ignore: avoid_print
    print('provider: ${meta.provider}, model: ${meta.model}');
    // ignore: avoid_print
    print('providerMetadata: ${meta.providerMetadata}');
  }
}
