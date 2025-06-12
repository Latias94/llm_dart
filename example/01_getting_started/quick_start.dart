// ignore_for_file: avoid_print
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

/// Quick Start - Basic LLM Dart usage
///
/// Set environment variables before running:
/// export OPENAI_API_KEY="your-key"
/// export GROQ_API_KEY="your-key"
void main() async {
  print('LLM Dart Quick Start\n');

  await quickStartWithOpenAI();
  await quickStartWithGroq();
  await quickStartWithOllama();

  print('\n✅ Quick start completed!');
}

Future<void> quickStartWithOpenAI() async {
  print('Method 1: OpenAI');

  try {
    final apiKey = Platform.environment['OPENAI_API_KEY'] ?? 'sk-TESTKEY';

    final provider = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-4o-mini')
        .temperature(0.7)
        .build();

    final messages = [
      ChatMessage.user('Hello! Please introduce yourself in one sentence.')
    ];

    final response = await provider.chat(messages);

    print('   AI Reply: ${response.text}');
    print('   ✅ Success\n');
  } catch (e) {
    print('   ❌ Failed: $e');
    print('   Check OPENAI_API_KEY environment variable\n');
  }
}

Future<void> quickStartWithGroq() async {
  print('Method 2: Groq (fast)');

  try {
    final apiKey = Platform.environment['GROQ_API_KEY'] ?? 'gsk-TESTKEY';

    final provider = await ai()
        .groq()
        .apiKey(apiKey)
        .model('llama-3.1-8b-instant')
        .temperature(0.7)
        .build();

    final messages = [
      ChatMessage.user('What is the capital of France? Answer in one sentence.')
    ];

    final response = await provider.chat(messages);

    print('   AI Reply: ${response.text}');
    print('   ✅ Success\n');
  } catch (e) {
    print('   ❌ Failed: $e');
    print('   Check GROQ_API_KEY environment variable\n');
  }
}

Future<void> quickStartWithOllama() async {
  print('Method 3: Ollama (local)');

  try {
    final provider = await ai()
        .ollama()
        .baseUrl('http://localhost:11434')
        .model('llama3.2')
        .temperature(0.7)
        .build();

    final messages = [
      ChatMessage.user('Hello! Introduce yourself in one sentence.')
    ];

    final response = await provider.chat(messages);

    print('   AI Reply: ${response.text}');
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
/// - ai().openai() / ai().groq() / ai().ollama()
/// - ai().provider('provider-name')
/// - createProvider() convenience function
///
/// Configuration:
/// - apiKey, model, temperature, maxTokens
///
/// Messages:
/// - ChatMessage.user() / .system() / .assistant()
///
/// Response:
/// - response.text, response.usage, response.thinking
