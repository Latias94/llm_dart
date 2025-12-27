// ignore_for_file: avoid_print
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_groq/llm_dart_groq.dart';
import 'package:llm_dart_ollama/llm_dart_ollama.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

/// Quick Start - Basic LLM Dart usage
///
/// Set environment variables before running:
/// export OPENAI_API_KEY="your-key"
/// export GROQ_API_KEY="your-key"
void main() async {
  print('LLM Dart Quick Start\n');

  registerOpenAI();
  registerGroq();
  registerOllama();

  await quickStartWithOpenAI();
  await quickStartWithGroq();
  await quickStartWithOllama();

  print('\n✅ Quick start completed!');
}

Future<void> quickStartWithOpenAI() async {
  print('Method 1: OpenAI');

  try {
    final apiKey = Platform.environment['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print('   ⚠️  Skipped: Please set OPENAI_API_KEY environment variable\n');
      return;
    }

    final provider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .temperature(0.7)
        .build();

    final prompt = Prompt(
      messages: [
        PromptMessage.user('Hello! Please introduce yourself in one sentence.'),
      ],
    );

    final result = await generateText(model: provider, promptIr: prompt);

    print('   AI Reply: ${result.text}');
    print('   ✅ Success\n');
  } catch (e) {
    print('   ❌ Failed: $e');
    print('   Check OPENAI_API_KEY environment variable\n');
  }
}

Future<void> quickStartWithGroq() async {
  print('Method 2: Groq (fast)');

  try {
    final apiKey = Platform.environment['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print('   ⚠️  Skipped: Please set GROQ_API_KEY environment variable\n');
      return;
    }

    final provider = await LLMBuilder()
        .provider(groqProviderId)
        .apiKey(apiKey)
        .model('llama-3.1-8b-instant')
        .temperature(0.7)
        .build();

    final prompt = Prompt(
      messages: [
        PromptMessage.user(
          'What is the capital of France? Answer in one sentence.',
        ),
      ],
    );

    final result = await generateText(model: provider, promptIr: prompt);

    print('   AI Reply: ${result.text}');
    print('   ✅ Success\n');
  } catch (e) {
    print('   ❌ Failed: $e');
    print('   Check GROQ_API_KEY environment variable\n');
  }
}

Future<void> quickStartWithOllama() async {
  print('Method 3: Ollama (local)');

  try {
    final provider = await LLMBuilder()
        .provider(ollamaProviderId)
        .baseUrl('http://localhost:11434')
        .model('llama3.2')
        .temperature(0.7)
        .build();

    final prompt = Prompt(
      messages: [
        PromptMessage.user('Hello! Introduce yourself in one sentence.'),
      ],
    );

    final result = await generateText(model: provider, promptIr: prompt);

    print('   AI Reply: ${result.text}');
    print('   ✅ Success\n');
  } catch (e) {
    print('   ❌ Failed: $e');
    print('   Ensure Ollama is running: ollama serve');
    print('   Install model: ollama pull llama3.2\n');
  }
}

/// Key Points:
///
/// Provider creation:
/// - `LLMBuilder().provider(providerId)`
/// - providers must be registered (e.g. `registerOpenAI()`)
///
/// Configuration:
/// - apiKey, model, temperature, maxTokens
///
/// Messages:
/// - Prompt/parts (recommended): `PromptMessage.*` / `PromptPart`
/// - Legacy: `ChatMessage.user()` / `.system()` / `.assistant()`
///
/// Response:
/// - response.text, response.usage, response.thinking
