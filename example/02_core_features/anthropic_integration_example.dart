// ignore_for_file: avoid_print

import 'dart:io';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart/providers/anthropic/anthropic.dart';

/// Example demonstrating how to use the Anthropic message builder
/// with real API calls and advanced features.
/// 
/// This example shows:
/// - Cached system messages for performance
/// - Tool usage with message builder
/// - Complex content block scenarios
/// - Real API integration patterns
void main() async {
  print('=== Anthropic Integration Example ===\n');

  // Check for API key
  final apiKey = Platform.environment['ANTHROPIC_API_KEY'] ?? '';
  if (apiKey.isEmpty) {
    print('⚠️  ANTHROPIC_API_KEY environment variable not set.');
    print('   This example requires a real Anthropic API key to run.');
    print('   Set it with: export ANTHROPIC_API_KEY="your-key-here"');
    return;
  }

  // Create provider
  final provider = createAnthropicProvider(
    apiKey: apiKey,
    model: 'claude-3-5-sonnet-20241022',
    maxTokens: 1000,
    temperature: 0.7,
  );

  print('✅ Provider created successfully\n');

  // Example 1: Basic cached system message
  await _demonstrateCachedSystemMessage(provider);
  
  // Example 2: Complex content blocks
  await _demonstrateComplexContentBlocks(provider);
  
  // Example 3: Tool usage scenario
  await _demonstrateToolUsage(provider);
  
  // Example 4: Streaming with caching
  await _demonstrateStreamingWithCaching(provider);

  print('\n=== All Examples Completed ===');
}

/// Demonstrate cached system message usage
Future<void> _demonstrateCachedSystemMessage(AnthropicProvider provider) async {
  print('📝 Example 1: Cached System Message\n');

  // Create a cached system message for better performance
  final systemMessage = MessageBuilder.system()
      .anthropic((anthropic) => anthropic.cachedText(
            'You are a helpful coding assistant specialized in Dart programming. '
            'Provide clear, concise explanations with practical examples. '
            'Focus on best practices and modern Dart features.',
            ttl: AnthropicCacheTtl.fiveMinutes,
          ))
      .build();

  final userMessage = MessageBuilder.user()
      .text('Explain the benefits of using sealed classes in Dart')
      .build();

  print('🔄 Sending request with cached system message...');
  
  try {
    final response = await provider.chat([systemMessage, userMessage]);
    
    print('✅ Response received!');
    print('📊 Input tokens: ${response.usage?.promptTokens}');
    print('📊 Output tokens: ${response.usage?.completionTokens}');
    print('📝 Response: ${response.text?.substring(0, 200)}...\n');
  } catch (e) {
    print('❌ Error: $e\n');
  }
}

/// Demonstrate complex content blocks with mixed caching
Future<void> _demonstrateComplexContentBlocks(AnthropicProvider provider) async {
  print('🏗️  Example 2: Complex Content Blocks\n');

  // Create a message with multiple content blocks and different cache settings
  final complexMessage = MessageBuilder.system()
      .anthropic((anthropic) => anthropic.contentBlocks([
        {
          'type': 'text',
          'text': 'You are a software architecture expert.',
          'cache_control': {'type': 'ephemeral', 'ttl': 3600} // 1 hour cache
        },
        {
          'type': 'text',
          'text': 'Current project context:\n'
                 '- Building a messaging system for LLM providers\n'
                 '- Using Dart with modular architecture\n'
                 '- Implementing caching and performance optimizations'
        }
      ]))
      .build();

  final userMessage = MessageBuilder.user()
      .text('What are the key architectural patterns I should consider for this messaging system?')
      .build();

  print('🔄 Sending request with complex content blocks...');
  
  try {
    final response = await provider.chat([complexMessage, userMessage]);
    
    print('✅ Response received!');
    print('📝 Architecture advice: ${response.text?.substring(0, 250)}...\n');
  } catch (e) {
    print('❌ Error: $e\n');
  }
}

/// Demonstrate tool usage with message builder
Future<void> _demonstrateToolUsage(AnthropicProvider provider) async {
  print('🔧 Example 3: Tool Usage Scenario\n');

  // Define a simple calculation tool
  final calculatorTool = Tool.function(
    name: 'calculate',
    description: 'Perform mathematical calculations',
    parameters: ParametersSchema(
      schemaType: 'object',
      properties: {
        'expression': ParameterProperty(
          propertyType: 'string',
          description: 'Mathematical expression to evaluate',
        ),
      },
      required: ['expression'],
    ),
  );

  final systemMessage = MessageBuilder.system()
      .anthropic((anthropic) => anthropic.cachedText(
            'You are a helpful math assistant. Use the calculate tool for any mathematical operations.',
            ttl: AnthropicCacheTtl.fiveMinutes,
          ))
      .build();

  final userMessage = MessageBuilder.user()
      .text('What is the compound interest on \$1000 at 5% annually for 3 years?')
      .build();

  print('🔄 Sending request with tool capability...');
  
  try {
    final response = await provider.chatWithTools([systemMessage, userMessage], [calculatorTool]);
    
    print('✅ Response received!');
    
    if (response.toolCalls?.isNotEmpty == true) {
      print('🔧 Tool called: ${response.toolCalls!.first.function.name}');
      print('📝 Tool arguments: ${response.toolCalls!.first.function.arguments}');
      
      // Simulate tool result using message builder
      final toolResult = MessageBuilder.user()
          .anthropic((anthropic) => anthropic.toolResult(
                toolUseId: response.toolCalls!.first.id,
                content: 'Result: \$1157.63 (calculated: 1000 × (1.05)³)',
              ))
          .build();

      // Send follow-up with tool result
      final assistantMessage = response.toolCalls?.isNotEmpty == true
          ? ChatMessage.assistant('')  // Tool calls have no text content
          : ChatMessage.assistant(response.text ?? '');
      
      final followUpMessages = [systemMessage, userMessage, assistantMessage, toolResult];
      final finalResponse = await provider.chat(followUpMessages);
      
      print('📊 Final response: ${finalResponse.text?.substring(0, 200)}...\n');
    } else {
      print('📝 Direct response: ${response.text?.substring(0, 200)}...\n');
    }
  } catch (e) {
    print('❌ Error: $e\n');
  }
}

/// Demonstrate streaming with cached messages
Future<void> _demonstrateStreamingWithCaching(AnthropicProvider provider) async {
  print('📡 Example 4: Streaming with Caching\n');

  final streamingSystem = MessageBuilder.system()
      .anthropic((anthropic) => anthropic.cachedText(
            'You are a creative storyteller. Tell engaging, detailed stories with vivid descriptions.',
            ttl: AnthropicCacheTtl.fiveMinutes,
          ))
      .build();

  final userMessage = MessageBuilder.user()
      .text('Tell me a short story about a message that travels through a complex distributed system')
      .build();

  print('🔄 Starting streaming request...');
  
  try {
    var accumulatedText = '';
    var wordCount = 0;
    
    await for (final event in provider.chatStream([streamingSystem, userMessage])) {
      switch (event) {
        case TextDeltaEvent():
          accumulatedText += event.delta;
          // Count words for progress indication
          wordCount = accumulatedText.split(' ').length;
          if (wordCount % 20 == 0) {
            print('📝 Progress: $wordCount words...');
          }
          
        case ThinkingDeltaEvent():
          print('🤔 Model is thinking...');
          
        case ToolCallDeltaEvent():
          print('🔧 Tool call: ${event.toolCall.function.name}');
          
        case CompletionEvent():
          print('✅ Streaming completed!');
          print('📊 Total words: $wordCount');
          print('📖 Story preview:');
          print('   ${accumulatedText.substring(0, 200)}...\n');
          break;
          
        case ErrorEvent():
          print('❌ Streaming error: ${event.error}');
          break;
      }
    }
  } catch (e) {
    print('❌ Error: $e\n');
  }
}