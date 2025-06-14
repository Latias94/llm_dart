// ignore_for_file: avoid_print
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

/// 🔄 Anthropic Prompt Caching - Reduce Costs and Improve Performance
///
/// This example demonstrates Anthropic's prompt caching feature:
/// - Enable prompt caching via extensions
/// - Cache system prompts individually
/// - Cache tools for reuse
/// - Cache message content
/// - Monitor cache usage for cost optimization
///
/// Before running, set your API key:
/// export ANTHROPIC_API_KEY="your-anthropic-api-key"
Future<void> main() async {
  print('🔄 Anthropic Prompt Caching - Cost Optimization Example\n');

  // Get API key from environment
  final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (apiKey == null) {
    print('❌ Please set ANTHROPIC_API_KEY environment variable');
    return;
  }

  await demonstratePromptCaching(apiKey);

  print('\n✅ Anthropic prompt caching demonstration completed!');
}

/// Demonstrate prompt caching with system prompts, tools, and messages
Future<void> demonstratePromptCaching(String apiKey) async {
  print('💾 Prompt Caching Configuration:\n');

  try {
    // Create Anthropic provider with prompt caching enabled
    final provider = await ai()
        .anthropic()
        .apiKey(apiKey)
        .model('claude-3-5-sonnet-20241022') // Model that supports caching
        .systemPrompt(
            '''You are a helpful AI assistant with expertise in software development.
Your knowledge includes:
- Programming languages (Python, JavaScript, Dart, Flutter, etc.)
- Software architecture and design patterns
- Database design and optimization techniques
- Modern web development frameworks and libraries
- DevOps practices and deployment strategies
- Code review and quality assurance processes
- Performance optimization and debugging techniques

Always provide clear, practical, and actionable advice with specific examples.
Use code examples when helpful and explain concepts in an accessible way.''')
        .maxTokens(1500)
        .temperature(0.3)
        // Enable prompt caching via extensions
        .extension('promptCache',
            true) // This enables caching for system prompts, tools, and messages
        .build();

    print('   Configuration: Prompt caching enabled');
    print('   Model: claude-3-5-sonnet-20241022');
    print('   System prompt: Comprehensive development expertise');
    print('   Individual caching: Each system prompt cached separately\n');

    // First request - creates cache entries
    print('📤 First Request (Creating Cache Entries):\n');

    final initialMessages = [
      ChatMessage.system(
        'Additional context: You are assisting with a Flutter application that integrates multiple AI services using the llm_dart package.',
      ),
      ChatMessage.user(
        '''I'm building a Flutter mobile app that needs to integrate with multiple LLM providers (OpenAI, Anthropic, and local models).

I need guidance on these key areas:
1. Secure API key management and storage
2. Implementing robust retry logic with exponential backoff
3. Response caching strategies to minimize costs
4. Handling rate limits and API quotas
5. Error handling and graceful degradation
6. Performance optimization for mobile devices

Can you provide detailed recommendations with code examples for each area?''',
      ),
    ];

    final response1 = await provider.chat(initialMessages);

    print('   📝 Response Preview:');
    final responseText = response1.text ?? 'No response text';
    print(
        '   ${responseText.length > 200 ? "${responseText.substring(0, 200)}..." : responseText}\n');

    // Show cache usage for first request
    if (response1 is AnthropicChatResponse) {
      _displayCacheUsage('First Request', response1.cacheUsage);
    }

    // Follow-up request - should use cached content
    print('📤 Follow-up Request (Using Cached Content):\n');

    final followUpMessages = [
      ...initialMessages,
      ChatMessage.assistant(response1.text ?? ''),
      ChatMessage.user(
        'Thanks for the comprehensive overview! Now I need specific help implementing the exponential backoff retry logic. Can you provide a complete Dart implementation that works well with the llm_dart package?',
      ),
    ];

    final response2 = await provider.chat(followUpMessages);

    print('   📝 Follow-up Response Preview:');
    final followUpText = response2.text ?? 'No response text';
    print(
        '   ${followUpText.length > 200 ? "${followUpText.substring(0, 200)}..." : followUpText}\n');

    // Show cache usage for follow-up request
    if (response2 is AnthropicChatResponse) {
      _displayCacheUsage('Follow-up Request', response2.cacheUsage);
    }

    // Third request with long conversation history to demonstrate message caching
    print('📤 Third Request (Extended Conversation with Cached History):\n');

    final extendedMessages = [
      ...followUpMessages,
      ChatMessage.assistant(response2.text ?? ''),
      ChatMessage.user(
        'Excellent! Now I have one more question: How can I implement effective error boundaries in Flutter to handle LLM API failures gracefully? I want to ensure the user experience remains smooth even when APIs are down.',
      ),
    ];

    final response3 = await provider.chat(extendedMessages);

    print('   📝 Extended Conversation Response Preview:');
    final extendedText = response3.text ?? 'No response text';
    print(
        '   ${extendedText.length > 200 ? "${extendedText.substring(0, 200)}..." : extendedText}\n');

    // Show cache usage for extended conversation
    if (response3 is AnthropicChatResponse) {
      _displayCacheUsage('Extended Conversation', response3.cacheUsage);
    }

    // Example with multiple system prompts to show individual caching
    print(
        '📤 Fourth Request (Multiple System Prompts - Individual Caching):\n');

    final multiSystemMessages = [
      ChatMessage.system(
        'Core expertise: You are a Flutter development expert with deep knowledge of mobile app architecture.',
      ),
      ChatMessage.system(
        'Additional context: You are working with a team building a production Flutter app that needs enterprise-grade reliability.',
      ),
      ChatMessage.system(
        'Current focus: The team is particularly interested in AI integration patterns and best practices.',
      ),
      ChatMessage.user(
        'Given our Flutter app architecture, what are the best patterns for integrating multiple AI providers while maintaining code maintainability and testability?',
      ),
    ];

    final response4 = await provider.chat(multiSystemMessages);

    print('   📝 Multi-System Response Preview:');
    final multiSystemText = response4.text ?? 'No response text';
    print(
        '   ${multiSystemText.length > 200 ? "${multiSystemText.substring(0, 200)}..." : multiSystemText}\n');

    // Show cache usage for multiple system prompts
    if (response4 is AnthropicChatResponse) {
      _displayCacheUsage('Multiple System Prompts', response4.cacheUsage);
    }

    // Summary of caching benefits
    print('✨ Prompt Caching Benefits Summary:');
    print(
        '   💰 Cost Reduction: Cached tokens cost ~75% less than regular input tokens');
    print('   ⚡ Performance: Cached content is processed 2-5x faster');
    print('   🔄 Consistency: System prompts and tools are reused efficiently');
    print(
        '   📝 Individual Caching: Each system prompt cached separately for flexibility');
    print(
        '   🛠️  Tool Reuse: Complex tool definitions cached across requests');
    print(
        '   💾 Context Preservation: Long conversation histories cached for continuity');
    print(
        '   🔀 Granular Control: Mix cached and non-cached content as needed');

    print('\n📊 Caching Strategy Tips:');
    print('   • Use consistent system prompts across related conversations');
    print('   • Cache expensive context like documentation or guidelines');
    print(
        '   • Leverage individual system prompt caching for modular contexts');
    print('   • Monitor cache hit rates to optimize prompt design');
    print('   • Balance cache specificity with reusability');
  } catch (e) {
    print('   ❌ Error in prompt caching demonstration: $e');
  }
}

/// Display cache usage information in a formatted way
void _displayCacheUsage(String requestType, Map<String, dynamic>? cacheUsage) {
  if (cacheUsage != null) {
    final cacheCreation = cacheUsage['cache_creation_input_tokens'] ?? 0;
    final cacheRead = cacheUsage['cache_read_input_tokens'] ?? 0;

    print('   💾 Cache Usage ($requestType):');
    print('      📝 Cache creation tokens: $cacheCreation');
    print('      🔄 Cache read tokens: $cacheRead');

    if (cacheRead > 0) {
      print('      🎉 Cache HIT! Saved time and cost with cached content');
      final savings = cacheRead * 0.75; // Approximate 75% savings
      print('      💸 Estimated token savings: ~${savings.toInt()} tokens');
    } else if (cacheCreation > 0) {
      print('      📦 Cache MISS: Created new cache entries for future use');
    }

    if (cacheCreation > 0 && cacheRead > 0) {
      print(
          '      🔄 Mixed: Both creating new cache and reading existing cache');
    }

    print('');
  }
}
