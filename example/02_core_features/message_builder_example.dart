// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';

/// Example demonstrating the new MessageBuilder system
///
/// This example shows how to use the fluent message builder API
/// to create messages with provider-specific content blocks.
void main() async {
  print('=== MessageBuilder System Demo ===\n');

  // Example 1: Simple universal message
  print('1. Universal text message:');
  final universalMessage = MessageBuilder.user().text('Hello, world!').build();

  print('Role: ${universalMessage.role}');
  print('Content: ${universalMessage.content}');
  print('Extensions: ${universalMessage.extensions}');
  print('');

  // Example 2: Anthropic-specific cached content
  print('2. Anthropic message with cached content:');
  final anthropicMessage = MessageBuilder.system()
      .anthropic((anthropic) => anthropic.cachedText(
          'You are a helpful AI assistant...',
          ttl: AnthropicCacheTtl.oneHour))
      .build();

  print('Role: ${anthropicMessage.role}');
  print('Content: ${anthropicMessage.content}');
  print('Extensions: ${jsonEncode(anthropicMessage.extensions)}');
  print('');

  // Example 3: Tool use message
  print('3. Anthropic tool use message:');
  final toolUseMessage = MessageBuilder.assistant()
      .anthropic((anthropic) => anthropic.toolUse(
            id: 'call_123',
            name: 'search_web',
            input: {'query': 'latest AI news'},
          ))
      .build();

  print('Role: ${toolUseMessage.role}');
  print('Content: ${toolUseMessage.content}');
  print('Extensions: ${jsonEncode(toolUseMessage.extensions)}');
  print('');

  // Example 4: Mixed content (universal + provider-specific)
  print('4. Mixed content message:');
  final mixedMessage = MessageBuilder.user()
      .text('Universal text that works everywhere')
      .anthropic((anthropic) => anthropic.cachedText(
          'Anthropic-specific cached content',
          ttl: AnthropicCacheTtl.fiveMinutes))
      .openai((openai) =>
          openai.image('https://example.com/image.png', detail: 'high'))
      .build();

  print('Role: ${mixedMessage.role}');
  print('Content: ${mixedMessage.content}');
  print('Extensions: ${jsonEncode(mixedMessage.extensions)}');
  print('');

  // Example 5: Complex content blocks
  print('5. Complex Anthropic content blocks:');
  final complexMessage = MessageBuilder.user()
      .anthropic((anthropic) => anthropic.contentBlocks([
            {
              'type': 'text',
              'text': 'Analyze this document:',
              'cache_control': {'type': 'ephemeral', 'ttl': 3600}
            },
            {'type': 'text', 'text': '[LARGE DOCUMENT CONTENT]'}
          ]))
      .text('What are the key points?')
      .build();

  print('Role: ${complexMessage.role}');
  print('Content: ${complexMessage.content}');
  print('Extensions: ${jsonEncode(complexMessage.extensions)}');
  print('');

  // Example 6: Tool result message
  print('6. Tool result message:');
  final toolResultMessage = MessageBuilder.user()
      .anthropic((anthropic) => anthropic.toolResult(
            toolUseId: 'call_123',
            content: 'Found 10 articles about AI advancements...',
          ))
      .build();

  print('Role: ${toolResultMessage.role}');
  print('Content: ${toolResultMessage.content}');
  print('Extensions: ${jsonEncode(toolResultMessage.extensions)}');
  print('');

  // Example 7: OpenAI with image
  print('7. OpenAI message with image:');
  final openaiImageMessage = MessageBuilder.user()
      .openai((openai) => openai.textWithImage(
          'What do you see in this image?', 'https://example.com/photo.jpg',
          detail: 'high'))
      .build();

  print('Role: ${openaiImageMessage.role}');
  print('Content: ${openaiImageMessage.content}');
  print('Extensions: ${jsonEncode(openaiImageMessage.extensions)}');
  print('');

  print('=== MessageBuilder Demo Complete ===');
}
