import 'dart:async';

import 'package:llm_dart/llm_dart.dart';

/// Example demonstrating the built-in chat logging middleware.
///
/// This example shows how to:
/// - Configure an LLMLogger for llm_dart (optional)
/// - Attach the chat logging middleware to a provider/model
/// - Run a simple chat and a streaming chat with logs enabled
Future<void> main() async {
  // Create a chat logging middleware with default options.
  // By default this logs provider/model, usage, warnings and metadata but
  // not full message content to avoid leaking sensitive data.
  final loggingMiddleware = createChatLoggingMiddleware(
    options: const LoggingOptions(
      logRequestInfo: true,
      logMessages: false, // set to true for debugging prompts
      logThinking: true, // log reasoning/thinking content when available
      logToolCalls: true,
      logUsage: true,
      logMetadata: true,
      maxTextLength: 200,
    ),
  );

  // Build an OpenAI LanguageModel with the logging middleware attached.
  //
  // Replace "YOUR_OPENAI_API_KEY" with your real API key or read it from
  // environment variables in a real application.
  final model = await ai()
      .openai()
      .apiKey('YOUR_OPENAI_API_KEY')
      // If you don't pass `logger:` to createChatLoggingMiddleware, it will
      // use the logger configured on the model (via LLMConfigKeys.logger).
      .extension(
        LLMConfigKeys.logger,
        const ConsoleLLMLogger(name: 'llm_dart.chat'),
      )
      .middlewares([loggingMiddleware])
      .model('gpt-4o-mini')
      .buildLanguageModel();

  // === Non-streaming chat example (prompt-first) ===
  final messages = <ModelMessage>[
    ModelMessage.systemText('You are a helpful assistant.'),
    ModelMessage.userText('Explain what middlewares do in llm_dart.'),
  ];

  final response = await generateTextPromptWithModel(
    model,
    messages: messages,
  );

  // ignore: avoid_print
  print('--- Non-streaming response ---');
  // ignore: avoid_print
  print(response.text);

  // === Streaming chat example (prompt-first) ===
  final streamMessages = <ModelMessage>[
    ModelMessage.systemText('You are a helpful assistant.'),
    ModelMessage.userText('Stream a short response about logging.'),
  ];

  // ignore: avoid_print
  print('\n--- Streaming response ---');
  final buffer = StringBuffer();

  await for (final event in streamTextWithModel(
    model,
    promptMessages: streamMessages,
  )) {
    if (event is TextDeltaEvent) {
      buffer.write(event.delta);
    }
  }

  // ignore: avoid_print
  print(buffer.toString());
}
