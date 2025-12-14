import 'package:llm_dart/llm_dart.dart';

/// Example demonstrating MessageBuilder with Anthropic caching
///
/// **⚠️ ANTHROPIC ONLY**: This caching feature is currently only supported
/// by Anthropic providers. Other providers will ignore the caching configuration.
///
/// This example shows how to use the MessageBuilder to create messages
/// with Anthropic-specific caching to reduce costs for repeated content.
///
/// Anthropic's caching feature allows you to cache frequently used content
/// like system prompts or large documents, which can significantly reduce
/// token costs for repetitive conversations.
///
/// **IMPORTANT - New Cache API:**
/// The new caching API uses `.cache()` followed by `.text()`:
/// - Call `.anthropicConfig((config) => config.cache())` to prepare caching
/// - The next `.text()` call will apply the content to the cached block
/// - Content appears in BOTH message.content AND extensions
/// - This is intentional for universal provider compatibility
/// - Each creates separate content blocks in the API request
/// - Regular content becomes standard text blocks
/// - Cached content becomes text blocks with cache_control
///
/// **Best Practices:**
/// - Use `.text()` for content that doesn't need caching
/// - Use `.cache()` followed by `.text()` for content that should be cached
/// - Each `.cache()` call applies to the next `.text()` call only
///
/// To run this example:
/// ```bash
/// dart example/02_core_features/message_builder_cache.dart
/// ```
void main() async {
  print('=== MessageBuilder with Anthropic Caching Example ===\n');

  // Example 1: Basic message without caching
  final basicMessage =
      MessageBuilder.user().text('What is quantum computing?').build();

  print('1. Basic message:');
  final basicText =
      basicMessage.parts.whereType<TextContentPart>().map((p) => p.text).join();
  print('   Text: $basicText');
  print('   Has provider options: ${basicMessage.providerOptions.isNotEmpty}');
  print('');

  // Example 2: System message with cached content
  final systemMessage = MessageBuilder.system()
      .text('You are a helpful AI assistant.')
      .anthropicConfig(
          (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
      .text(
          'Here is a large document about quantum computing that you should reference:\n'
          '[LARGE DOCUMENT CONTENT - This would be cached for 1 hour]\n'
          'Quantum computing is a type of computation that harnesses the phenomena of quantum mechanics...')
      .build();

  print('2. System message with cached content:');
  final systemText = systemMessage.parts
      .whereType<TextContentPart>()
      .map((p) => p.text)
      .join();
  print('   Text preview: ${systemText.substring(0, 50)}...');
  print(
      '   Has Anthropic options: ${systemMessage.providerOptions.containsKey('anthropic')}');
  print('   Anthropic options: ${systemMessage.providerOptions['anthropic']}');
  print('');

  // Example 3: Mixed content with different cache TTLs
  // IMPORTANT: This creates 3 separate content blocks in the API request:
  // 1. "Based on the document provided, please answer:" (regular text)
  // 2. "Current context: ..." (cached text with 5m TTL)
  // 3. "What are the main advantages of quantum computers?" (regular text)
  final mixedMessage = MessageBuilder.user()
      .text('Based on the document provided, please answer:')
      .anthropicConfig(
          (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
      .text(
          'Current context: This is a follow-up question in our conversation about quantum computing.')
      .text('What are the main advantages of quantum computers?')
      .build();

  print('3. Mixed message with short-term cache:');
  final mixedText =
      mixedMessage.parts.whereType<TextContentPart>().map((p) => p.text).join();
  print('   Text: $mixedText');
  print('   Provider options: ${mixedMessage.providerOptions}');
  print('');

  // Example 4: Multiple content blocks via contentBlocks method
  final complexMessage = MessageBuilder.user()
      .anthropicConfig((anthropic) => anthropic.contentBlocks([
            {
              'type': 'text',
              'text': 'Long-term cached system prompt that rarely changes',
              'cache_control': {'type': 'ephemeral', 'ttl': '1h'}
            },
            {'type': 'text', 'text': 'Dynamic content that changes frequently'}
          ]))
      .text('What should I know about this topic?')
      .build();

  print('4. Complex message with multiple content blocks:');
  final complexText = complexMessage.parts
      .whereType<TextContentPart>()
      .map((p) => p.text)
      .join();
  print('   Text: $complexText');
  print(
      '   Anthropic blocks: ${(complexMessage.providerOptions['anthropic'] as Map?)?['contentBlocks']}');
  print('');

  // Example 5: Building a conversation with caching
  final conversation = [
    // System message with long-term cached instructions
    MessageBuilder.system()
        .anthropicConfig(
            (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour))
        .text(
            'You are an expert quantum computing researcher. Use the provided research papers and documentation to answer questions accurately.')
        .build(),

    // User message with context that might be reused
    MessageBuilder.user()
        .text('I need help understanding quantum algorithms.')
        .anthropicConfig(
            (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.fiveMinutes))
        .text(
            'Context: I am a computer science student with basic knowledge of linear algebra and probability.')
        .build(),
  ];

  print('5. Conversation with strategic caching:');
  for (int i = 0; i < conversation.length; i++) {
    final message = conversation[i];
    print('   Message ${i + 1} (${message.role}):');
    final text =
        message.parts.whereType<TextContentPart>().map((p) => p.text).join();
    print('     Text: ${text.replaceAll('\n', ' ').substring(0, 60)}...');
    print('     Cached: ${message.providerOptions.containsKey('anthropic')}');
  }

  // Example 6: Tool caching (Anthropic only)
  print('\n6. Tool caching example:');
  print('   **⚠️ ANTHROPIC ONLY**: Tool caching is provider-specific');

  // Define some example tools
  final tools = [
    Tool.function(
      name: 'search_documents',
      description: 'Search through knowledge base',
      parameters: ParametersSchema(
        schemaType: 'object',
        properties: {
          'query': ParameterProperty(
            propertyType: 'string',
            description: 'Search query',
          ),
        },
        required: ['query'],
      ),
    ),
    Tool.function(
      name: 'get_weather',
      description: 'Get current weather',
      parameters: ParametersSchema(
        schemaType: 'object',
        properties: {
          'location': ParameterProperty(
            propertyType: 'string',
            description: 'City name',
          ),
        },
        required: ['location'],
      ),
    ),
  ];

  print('   Tools defined: ${tools.map((t) => t.function.name).join(', ')}');
  print('   Usage - Message level (unified approach):');
  print('   ```dart');
  print('   final message = MessageBuilder.system()');
  print('       .text("You are a helpful assistant.")');
  print('       .tools([tool1, tool2, tool3])  // ← Add tools to message');
  print(
      '       .anthropicConfig((anthropic) => anthropic.cache()) // ← Cache the tools');
  print('       .text("Use the provided tools to help users.")');
  print('       .build();');
  print('   ```');
  print(
      '   Result: Unified caching interface - cache applies to tools AND text');

  // Example 7: Demonstrate the new unified approach
  print('\n7. NEW: Unified message-level tool caching:');
  final unifiedMessage = MessageBuilder.system()
      .text('You are a research assistant with access to these tools:')
      .anthropicConfig((anthropic) => anthropic.cache(
          ttl: AnthropicCacheTtl.oneHour)) // Cache configuration
      .tools(tools) // ← These tools will be cached
      .text('Use these tools to help users with research tasks.')
      .build();

  final unifiedText = unifiedMessage.parts
      .whereType<TextContentPart>()
      .map((p) => p.text)
      .join();
  print('   Message text: $unifiedText');
  print(
      '   Provider options keys: ${unifiedMessage.providerOptions.keys.join(', ')}');
  print(
      '   ✓ Cache configuration applies to subsequent content (tools in this case)');
  print('   ✓ More intuitive: .cache() applies to what comes after it');
  print('   ✓ Follows the same pattern as text caching');

  print('\n=== Caching Strategy Tips ===');
  print('📝 Message Caching:');
  print(
      '- Use oneHour TTL for: System prompts, large documents, static context');
  print('- Use fiveMinutes TTL for: Session context, temporary user state');
  print('- Regular text() calls are never cached');
  print('- Use .cache() followed by .text() for cached content');
  print('- Cached content appears in both content and extensions');
  print('');
  print('🔧 Tool Caching:');
  print(
      '- .tools([...]) method works for ALL providers (OpenAI, Anthropic, etc.)');
  print('- .anthropicConfig().cache() method is ANTHROPIC-ONLY');
  print(
      '- Use MessageBuilder.tools().anthropicConfig().cache() for unified caching');
  print('- Cache applies to tools AND subsequent text content');
  print('- Use oneHour TTL for stable tool sets');
  print('- Use fiveMinutes TTL for frequently changing tools');
}
