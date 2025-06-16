import 'package:llm_dart/llm_dart.dart';

/// Example demonstrating MessageBuilder with Anthropic caching
/// 
/// This example shows how to use the MessageBuilder to create messages
/// with Anthropic-specific caching to reduce costs for repeated content.
/// 
/// Anthropic's caching feature allows you to cache frequently used content
/// like system prompts or large documents, which can significantly reduce
/// token costs for repetitive conversations.
/// 
/// To run this example:
/// ```bash
/// dart example/02_core_features/message_builder_cache.dart
/// ```
void main() async {
  print('=== MessageBuilder with Anthropic Caching Example ===\n');

  // Example 1: Basic message without caching
  final basicMessage = MessageBuilder.user()
      .text('What is quantum computing?')
      .build();

  print('1. Basic message:');
  print('   Content: ${basicMessage.content}');
  print('   Has extensions: ${basicMessage.extensions.isNotEmpty}');
  print('');

  // Example 2: System message with cached content
  final systemMessage = MessageBuilder.system()
      .text('You are a helpful AI assistant.')
      .anthropicConfig((anthropic) => anthropic
          .cachedText(
            'Here is a large document about quantum computing that you should reference:\n'
            '[LARGE DOCUMENT CONTENT - This would be cached for 1 hour]\n'
            'Quantum computing is a type of computation that harnesses the phenomena of quantum mechanics...',
            ttl: AnthropicCacheTtl.oneHour,
          ))
      .build();

  print('2. System message with cached content:');
  print('   Content preview: ${systemMessage.content.substring(0, 50)}...');
  print('   Has Anthropic extension: ${systemMessage.hasExtension('anthropic')}');
  print('   Extension data: ${systemMessage.getExtension('anthropic')}');
  print('');

  // Example 3: Mixed content with different cache TTLs
  final mixedMessage = MessageBuilder.user()
      .text('Based on the document provided, please answer:')
      .anthropicConfig((anthropic) => anthropic
          .cachedText(
            'Current context: This is a follow-up question in our conversation about quantum computing.',
            ttl: AnthropicCacheTtl.fiveMinutes,
          ))
      .text('What are the main advantages of quantum computers?')
      .build();

  print('3. Mixed message with short-term cache:');
  print('   Content: ${mixedMessage.content}');
  print('   Extensions: ${mixedMessage.extensions}');
  print('');

  // Example 4: Multiple content blocks via contentBlocks method
  final complexMessage = MessageBuilder.user()
      .anthropicConfig((anthropic) => anthropic
          .contentBlocks([
            {
              'type': 'text',
              'text': 'Long-term cached system prompt that rarely changes',
              'cache_control': {'type': 'ephemeral', 'ttl': 3600}
            },
            {
              'type': 'text',
              'text': 'Dynamic content that changes frequently'
            }
          ]))
      .text('What should I know about this topic?')
      .build();

  print('4. Complex message with multiple content blocks:');
  print('   Content: ${complexMessage.content}');
  print('   Anthropic blocks: ${complexMessage.getExtension<Map>('anthropic')?['contentBlocks']}');
  print('');

  // Example 5: Building a conversation with caching
  final conversation = [
    // System message with long-term cached instructions
    MessageBuilder.system()
        .anthropicConfig((anthropic) => anthropic
            .cachedText(
              'You are an expert quantum computing researcher. Use the provided research papers and documentation to answer questions accurately.',
              ttl: AnthropicCacheTtl.oneHour,
            ))
        .build(),

    // User message with context that might be reused
    MessageBuilder.user()
        .text('I need help understanding quantum algorithms.')
        .anthropicConfig((anthropic) => anthropic
            .cachedText(
              'Context: I am a computer science student with basic knowledge of linear algebra and probability.',
              ttl: AnthropicCacheTtl.fiveMinutes,
            ))
        .build(),
  ];

  print('5. Conversation with strategic caching:');
  for (int i = 0; i < conversation.length; i++) {
    final message = conversation[i];
    print('   Message ${i + 1} (${message.role}):');
    print('     Content: ${message.content.replaceAll('\n', ' ').substring(0, 60)}...');
    print('     Cached: ${message.hasExtension('anthropic')}');
  }

  print('\n=== Caching Strategy Tips ===');
  print('- Use oneHour TTL for: System prompts, large documents, static context');
  print('- Use fiveMinutes TTL for: Session context, temporary user state');
  print('- Regular text() calls are never cached');
  print('- Cached content appears in both content and extensions');
}