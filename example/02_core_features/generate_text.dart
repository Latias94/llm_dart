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

  // Create a reusable model for OpenAI chat models.
  final model = await ai()
      .openai()
      .apiKey(apiKey)
      .model('gpt-4o-mini')
      .temperature(0.7)
      .maxTokens(400)
      .buildLanguageModel();

  await basicGenerateText(model);
  await conversationWithMessages(model);
  await structuredPromptWithBuilder(model);
  await streamingExample(model);

  print('\n✅ generateText / streamText examples completed!');
}

/// Simple one-shot text generation using the prompt parameter.
Future<void> basicGenerateText(LanguageModel model) async {
  print('🔤 Basic generateText:\n');

  final prompt = ChatPromptBuilder.user()
      .text('Give me three bullet-point tips for learning Dart effectively.')
      .build();

  final result = await generateTextWithModel(
    model,
    promptMessages: [prompt],
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
Future<void> conversationWithMessages(LanguageModel model) async {
  print('💬 Multi-turn conversation with generateText:\n');

  final history = <ModelMessage>[
    ChatPromptBuilder.system()
        .text(
            'You are a concise and friendly assistant. Keep answers under 3 sentences.')
        .build(),
    ChatPromptBuilder.user().text('What is a Future in Dart?').build(),
    ChatPromptBuilder.assistant()
        .text(
            'A Future represents a value that will be available at some time in the future, '
            'typically the result of an asynchronous operation.')
        .build(),
    ChatPromptBuilder.user().text('How is it typically used?').build(),
  ];

  final result = await generateTextWithModel(
    model,
    promptMessages: history,
  );

  print('User: How is it typically used?');
  print('AI  : ${result.text}\n');
}

/// Structured prompts with ChatPromptBuilder + promptMessages.
Future<void> structuredPromptWithBuilder(LanguageModel model) async {
  print('🧱 Structured prompt with ChatPromptBuilder:\n');

  final prompt = ChatPromptBuilder.user()
      .text(
          'You will receive a short product description. Rewrite it as a catchy, friendly tagline.')
      .text(
          'A mobile app that helps you track your daily habits and stay motivated.')
      .build();

  final result = await generateTextWithModel(
    model,
    promptMessages: [prompt],
  );

  print('📝 Structured prompt description included as multiple parts.');
  print('🔗 Tagline:\n${result.text}\n');
}

/// Streaming responses using high-level stream parts.
Future<void> streamingExample(LanguageModel model) async {
  print('🌊 Streaming with streamTextParts:\n');

  final prompt =
      'Write a short, two-paragraph story about a developer learning Dart and building their first AI app.';

  stdout.writeln('🧑‍💻 Prompt: $prompt\n');
  stdout.write('🤖 Streaming response:\n');

  final buffer = StringBuffer();

  await for (final part in streamTextPartsWithModel(
    model,
    promptMessages: [
      ChatPromptBuilder.user().text(prompt).build(),
    ],
  )) {
    switch (part) {
      case StreamThinkingDelta():
        // For providers with visible reasoning, you could render this separately.
        // Here we ignore the delta to keep output simple.
        break;
      case StreamTextDelta(delta: final delta):
        stdout.write(delta);
        buffer.write(delta);
        break;
      case StreamFinish(result: final result):
        if (result.usage != null) {
          final usage = result.usage!;
          stdout.write('\n\n📊 Tokens: ${usage.totalTokens} total\n');
        } else {
          stdout.write('\n\n✅ Streaming complete.\n');
        }
        break;
      default:
        // Tool parts and other events are not used in this simple example.
        break;
    }
  }

  print('\n'); // final newline
}
