// ignore_for_file: avoid_print
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

/// 🧩 High-level Text Generation - generateText & streamText
///
/// This example shows how to use the LLMBuilder convenience helpers:
/// - generateText: simple one-shot or multi-turn text generation
/// - streamText: streaming responses with delta events
/// - ChatPromptBuilder: structured prompts with multiple parts
///
/// It is provider-agnostic and works with any chat-capable provider.
///
/// Before running, set your API key:
/// export OPENAI_API_KEY="your-key"
void main() async {
  print('🧩 High-level Text Generation (generateText / streamText)\n');

  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set OPENAI_API_KEY before running this example.');
    return;
  }

  // Create a reusable builder for OpenAI chat models.
  final builder = ai()
      .openai()
      .apiKey(apiKey)
      .model('gpt-4o-mini')
      .temperature(0.7)
      .maxTokens(400);

  // Validate configuration and API key once.
  await builder.build();

  await basicGenerateText(builder);
  await conversationWithMessages(builder);
  await structuredPromptWithBuilder(builder);
  await streamingExample(builder);

  print('\n✅ generateText / streamText examples completed!');
}

/// Simple one-shot text generation using the prompt parameter.
Future<void> basicGenerateText(LLMBuilder builder) async {
  print('🔤 Basic generateText:\n');

  final result = await builder.generateText(
    prompt: 'Give me three bullet-point tips for learning Dart effectively.',
  );

  print(
      '🧑‍💻 Prompt: Give me three bullet-point tips for learning Dart effectively.');
  print('🤖 Result:\n${result.text}\n');

  if (result.usage != null) {
    final usage = result.usage!;
    print(
        '📊 Tokens: total=${usage.totalTokens}, prompt=${usage.promptTokens}, completion=${usage.completionTokens}\n');
  }
}

/// Multi-turn conversation by passing a full message history.
Future<void> conversationWithMessages(LLMBuilder builder) async {
  print('💬 Multi-turn conversation with generateText:\n');

  final history = <ChatMessage>[
    ChatMessage.system(
        'You are a concise and friendly assistant. Keep answers under 3 sentences.'),
    ChatMessage.user('What is a Future in Dart?'),
    ChatMessage.assistant(
        'A Future represents a value that will be available at some time in the future, '
        'typically the result of an asynchronous operation.'),
    ChatMessage.user('How is it typically used?'),
  ];

  final result = await builder.generateText(messages: history);

  print('User: How is it typically used?');
  print('AI  : ${result.text}\n');
}

/// Using ChatPromptBuilder + ChatMessage.fromPromptMessage for structured prompts.
Future<void> structuredPromptWithBuilder(LLMBuilder builder) async {
  print('🧱 Structured prompt with ChatPromptBuilder:\n');

  final prompt = ChatPromptBuilder.user()
      .text(
          'You will receive a short product description. Rewrite it as a catchy, friendly tagline.')
      .text(
          'A mobile app that helps you track your daily habits and stay motivated.')
      .build();

  final result = await builder.generateText(
    messages: [ChatMessage.fromPromptMessage(prompt)],
  );

  print('📝 Structured prompt description included as multiple parts.');
  print('🔗 Tagline:\n${result.text}\n');
}

/// Streaming responses using streamText and handling delta events.
Future<void> streamingExample(LLMBuilder builder) async {
  print('🌊 Streaming with streamText:\n');

  final prompt =
      'Write a short, two-paragraph story about a developer learning Dart and building their first AI app.';

  stdout.writeln('🧑‍💻 Prompt: $prompt\n');
  stdout.write('🤖 Streaming response:\n');

  final buffer = StringBuffer();

  await for (final event in builder.streamText(prompt: prompt)) {
    switch (event) {
      case ThinkingDeltaEvent():
        // For providers with visible reasoning, you could render this separately.
        // Here we ignore the delta to keep output simple.
        break;
      case TextDeltaEvent(delta: final delta):
        stdout.write(delta);
        buffer.write(delta);
        break;
      case CompletionEvent(response: final response):
        if (response.usage != null) {
          final usage = response.usage!;
          stdout.write('\n\n📊 Tokens: ${usage.totalTokens} total\n');
        } else {
          stdout.write('\n\n✅ Streaming complete.\n');
        }
        break;
      case ToolCallDeltaEvent():
        // Not used in this example.
        break;
      case ErrorEvent(error: final error):
        stdout.write('\n❌ Streaming error: $error\n');
        break;
    }
  }

  print('\n'); // final newline
}
