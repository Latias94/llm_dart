// ignore_for_file: avoid_print
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_groq/llm_dart_groq.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

/// 🌊 Streaming Chat - Real-time Response Streaming
///
/// This example demonstrates how to handle real-time streaming responses:
/// - Processing stream parts as they arrive (recommended: `llm_dart_ai`)
/// - Building responsive user interfaces
/// - Handling different part types
/// - Error recovery and stream management
///
/// Before running, set your API key:
/// export OPENAI_API_KEY="your-key"
/// export GROQ_API_KEY="your-key"
void main() async {
  print('🌊 Streaming Chat - Real-time Response Streaming\n');

  registerGroq();
  registerAnthropic();
  registerOpenAI();

  // Get API key
  final apiKey = Platform.environment['GROQ_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set GROQ_API_KEY environment variable');
    return;
  }

  // Create AI provider (Groq is great for streaming due to speed)
  final provider = await LLMBuilder()
      .provider(groqProviderId)
      .apiKey(apiKey)
      .model('llama-3.1-8b-instant')
      .temperature(0.7)
      .maxTokens(500)
      .build();

  // Demonstrate different streaming scenarios
  await demonstrateBasicStreaming(provider);
  await demonstrateStreamEventTypes(provider);
  await demonstrateStreamingWithThinking(provider);
  await demonstrateStreamErrorHandling(provider);
  await demonstrateStreamPerformance(provider);

  print('\n✅ Streaming chat completed!');
}

/// Demonstrate basic streaming functionality
Future<void> demonstrateBasicStreaming(ChatCapability provider) async {
  print('⚡ Basic Streaming:\n');

  try {
    final prompt = Prompt(
      messages: [
        PromptMessage.user(
          'Count from 1 to 10 and explain each number briefly.',
        ),
      ],
    );

    print('   User: Count from 1 to 10 and explain each number briefly.');
    print('   AI: ');

    // Stream the response (recommended: llm_dart_ai task API)
    await for (final part in streamText(
      model: provider,
      promptIr: prompt,
    )) {
      switch (part) {
        case TextDeltaPart(delta: final delta):
          stdout.write(delta);
          break;
        case FinishPart():
          print('\n   ✅ Basic streaming successful\n');
          break;
        case ErrorPart(error: final error):
          print('\n   ❌ Stream error: $error\n');
          break;
        case ThinkingDeltaPart():
        case ToolCallDeltaPart():
          // Ignore for basic demo.
          break;
      }
    }
  } catch (e) {
    print('   ❌ Basic streaming failed: $e\n');
  }
}

/// Demonstrate different streaming part types
Future<void> demonstrateStreamEventTypes(ChatCapability provider) async {
  print('📡 Stream Part Types:\n');

  try {
    final prompt = Prompt(
      messages: [
        PromptMessage.user('Write a short poem about programming.'),
      ],
    );

    print('   User: Write a short poem about programming.');
    print('   Processing parts:\n');

    var textChunks = 0;
    var totalText = '';

    await for (final part in streamChatParts(
      model: provider,
      promptIr: prompt,
    )) {
      switch (part) {
        case LLMTextDeltaPart(:final delta):
          textChunks++;
          totalText += delta;
          print('   📝 Text chunk $textChunks: "$delta"');
          break;

        case LLMReasoningDeltaPart(:final delta):
          print('   🧠 Thinking: $delta');
          break;

        case LLMToolCallStartPart(:final toolCall):
          print('   🔧 Tool call started: ${toolCall.function.name}');
          break;

        case LLMToolCallDeltaPart(:final toolCall):
          print(
            '   🔧 Tool call delta: ${toolCall.function.name} '
            '(args+=${toolCall.function.arguments.length} chars)',
          );
          break;

        case LLMProviderMetadataPart(:final providerMetadata):
          print(
              '   🧾 Provider metadata keys: ${providerMetadata.keys.toList()}');
          break;

        case LLMFinishPart(:final response):
          print('\n   🏁 Finish part received');
          if (response.usage != null) {
            print('   📊 Usage: ${response.usage!.totalTokens} tokens');
          }
          break;

        case LLMErrorPart(:final error):
          print('   ❌ Error part: $error');
          break;

        case LLMTextStartPart():
        case LLMTextEndPart():
        case LLMReasoningStartPart():
        case LLMReasoningEndPart():
        case LLMToolCallEndPart():
        case LLMToolResultPart():
          // Ignore for this demo.
          break;
      }
    }

    print('\n   📈 Stream Statistics:');
    print('      • Total text chunks: $textChunks');
    print('      • Final text length: ${totalText.length} characters');
    print('   ✅ Part types demonstration successful\n');
  } catch (e) {
    print('   ❌ Part types demonstration failed: $e\n');
  }
}

/// Demonstrate streaming with thinking process (if supported)
Future<void> demonstrateStreamingWithThinking(ChatCapability provider) async {
  print('🧠 Streaming with Thinking Process:\n');

  try {
    // Try with a provider that supports thinking (switch to Anthropic if available)
    final anthropicKey = Platform.environment['ANTHROPIC_API_KEY'];
    ChatCapability thinkingProvider = provider;

    if (anthropicKey != null && anthropicKey.isNotEmpty) {
      thinkingProvider = await LLMBuilder()
          .provider(anthropicProviderId)
          .apiKey(anthropicKey)
          .model('claude-3-5-haiku-20241022')
          .temperature(0.7)
          .build();
    }

    final prompt = Prompt(
      messages: [
        PromptMessage.user('Solve this step by step: What is 15% of 240?'),
      ],
    );

    print('   User: Solve this step by step: What is 15% of 240?');
    print('   Processing with thinking:\n');

    var hasThinking = false;

    await for (final part in streamText(
      model: thinkingProvider,
      promptIr: prompt,
    )) {
      switch (part) {
        case ThinkingDeltaPart(delta: final delta):
          hasThinking = true;
          print('   🧠 Thinking: $delta');
          break;

        case TextDeltaPart(delta: final delta):
          stdout.write(delta);
          break;

        case FinishPart():
          print('\n');
          break;

        case ErrorPart(error: final error):
          print('   ❌ Error: $error');
          break;

        case ToolCallDeltaPart():
          // Ignore for this demo.
          break;
      }
    }

    if (hasThinking) {
      print('   ✅ Thinking process captured during streaming');
    } else {
      print(
          '   ℹ️  No thinking process available (provider may not support it)');
    }

    print('   ✅ Thinking demonstration completed\n');
  } catch (e) {
    print('   ❌ Thinking demonstration failed: $e\n');
  }
}

/// Demonstrate stream error handling
Future<void> demonstrateStreamErrorHandling(ChatCapability provider) async {
  print('🛡️  Stream Error Handling:\n');

  try {
    // Create a provider with invalid settings to trigger errors
    final invalidProvider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey('invalid-key') // Invalid API key
        .model('gpt-4o-mini')
        .build();

    final prompt = Prompt(
      messages: [
        PromptMessage.user('This should fail due to invalid API key.'),
      ],
    );

    print('   Testing error handling with invalid API key...');

    await for (final part in streamText(
      model: invalidProvider,
      promptIr: prompt,
    )) {
      switch (part) {
        case TextDeltaPart(delta: final delta):
          print('   📝 Unexpected text: $delta');
          break;

        case ErrorPart(error: final error):
          print('   ✅ Caught error in stream: ${error.runtimeType}');
          print('   📝 Error message: $error');
          break;

        case FinishPart():
          print('   ❌ Unexpected completion');
          break;

        case ThinkingDeltaPart():
        case ToolCallDeltaPart():
          // Ignore for this demo.
          break;
      }
    }
  } catch (e) {
    print('   ✅ Caught exception: ${e.runtimeType}');
    print('   📝 Exception message: $e');
  }

  print('\n   💡 Error Handling Best Practices:');
  print('      • Always wrap stream processing in try-catch');
  print('      • Handle ErrorPart within the stream');
  print('      • Implement retry logic for transient errors');
  print('      • Provide user feedback for stream interruptions');
  print('   ✅ Error handling demonstration completed\n');
}

/// Demonstrate stream performance characteristics
Future<void> demonstrateStreamPerformance(ChatCapability provider) async {
  print('🚀 Stream Performance:\n');

  try {
    final prompt = Prompt(
      messages: [
        PromptMessage.user(
          'Write a detailed explanation of machine learning in 200 words.',
        ),
      ],
    );

    print(
        '   User: Write a detailed explanation of machine learning in 200 words.');
    print('   Measuring performance...\n');

    final stopwatch = Stopwatch()..start();
    var firstChunkTime = 0;
    var chunkCount = 0;
    var totalChars = 0;
    final chunkTimes = <int>[];

    await for (final part in streamText(
      model: provider,
      promptIr: prompt,
    )) {
      switch (part) {
        case TextDeltaPart(delta: final delta):
          chunkCount++;
          totalChars += delta.length;

          if (firstChunkTime == 0) {
            firstChunkTime = stopwatch.elapsedMilliseconds;
            print('   ⚡ First chunk received: ${firstChunkTime}ms');
          }

          chunkTimes.add(stopwatch.elapsedMilliseconds);
          break;

        case FinishPart():
          stopwatch.stop();
          break;

        case ErrorPart(error: final error):
          print('   ❌ Performance test error: $error');
          return;

        case ThinkingDeltaPart():
        case ToolCallDeltaPart():
          // Ignore for this demo.
          break;
      }
    }

    final totalTime = stopwatch.elapsedMilliseconds;
    final avgChunkInterval = chunkTimes.length > 1
        ? (totalTime - firstChunkTime) / (chunkTimes.length - 1)
        : 0;

    print('\n   📊 Performance Metrics:');
    print('      • Time to first chunk: ${firstChunkTime}ms');
    print('      • Total response time: ${totalTime}ms');
    print('      • Total chunks: $chunkCount');
    print('      • Total characters: $totalChars');
    print(
        '      • Average chunk interval: ${avgChunkInterval.toStringAsFixed(1)}ms');
    print(
        '      • Characters per second: ${(totalChars * 1000 / totalTime).toStringAsFixed(1)}');

    print('\n   💡 Performance Benefits:');
    print('      • Reduced perceived latency (first chunk arrives quickly)');
    print('      • Better user experience (progressive content display)');
    print('      • Ability to process content as it arrives');
    print('      • Early error detection and handling');

    print('   ✅ Performance demonstration completed\n');
  } catch (e) {
    print('   ❌ Performance demonstration failed: $e\n');
  }
}

/// 🎯 Key Streaming Concepts Summary:
///
/// Recommended stream surface (Vercel-style):
/// - `streamText`: stable legacy-friendly parts (`TextDeltaPart`, `FinishPart`, ...)
/// - `streamChatParts`: richer parts with block boundaries + provider metadata
///
/// Benefits:
/// - Reduced perceived latency
/// - Real-time user feedback
/// - Progressive content display
/// - Better error handling
///
/// Best Practices:
/// 1. Handle all event types appropriately
/// 2. Implement proper error handling
/// 3. Measure and optimize performance
/// 4. Provide user feedback during streaming
/// 5. Consider buffering for UI updates
///
/// Next Steps:
/// - tool_calling.dart: Function calling and execution
/// - structured_output.dart: JSON schema responses
/// - error_handling.dart: Production-ready error management
