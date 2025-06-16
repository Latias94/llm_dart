import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('Message Builder Tests', () {
    group('ContentBlock Interface', () {
      test('UniversalTextBlock should implement ContentBlock correctly', () {
        const block = UniversalTextBlock('test content');

        expect(block.displayText, equals('test content'));
        expect(block.providerId, equals('universal'));
        expect(
            block.toJson(),
            equals({
              'type': 'text',
              'text': 'test content',
            }));
      });

      test('AnthropicTextBlock should implement ContentBlock correctly', () {
        final block = AnthropicTextBlock(
          'cached content',
          cacheControl: const AnthropicCacheControl.ephemeral(
              ttl: AnthropicCacheTtl.oneHour),
        );

        expect(block.displayText, equals('cached content'));
        expect(block.providerId, equals('anthropic'));
        expect(
            block.toJson(),
            equals({
              'type': 'text',
              'text': 'cached content',
              'cache_control': {
                'type': 'ephemeral',
                'ttl': 3600,
              },
            }));
      });

      test('AnthropicToolUseBlock should implement ContentBlock correctly', () {
        const block = AnthropicToolUseBlock(
          id: 'call_123',
          name: 'search_tool',
          input: {'query': 'test'},
        );

        expect(block.displayText, equals('[Tool: search_tool]'));
        expect(block.providerId, equals('anthropic'));
        expect(
            block.toJson(),
            equals({
              'type': 'tool_use',
              'id': 'call_123',
              'name': 'search_tool',
              'input': {'query': 'test'},
            }));
      });

      test('OpenAIImageBlock should implement ContentBlock correctly', () {
        const block =
            OpenAIImageBlock('https://example.com/image.png', detail: 'high');

        expect(block.displayText, equals('[Image]'));
        expect(block.providerId, equals('openai'));
        expect(
            block.toJson(),
            equals({
              'type': 'image_url',
              'image_url': {
                'url': 'https://example.com/image.png',
                'detail': 'high',
              },
            }));
      });
    });

    group('MessageBuilder Basic Functionality', () {
      test('should create simple text message', () {
        final message = MessageBuilder.user().text('Hello, world!').build();

        expect(message.role, equals(ChatRole.user));
        expect(message.content, equals('Hello, world!'));
        expect(message.extensions, isEmpty);
      });

      test('should create message with name', () {
        final message = MessageBuilder.system()
            .name('assistant')
            .text('System message')
            .build();

        expect(message.role, equals(ChatRole.system));
        expect(message.name, equals('assistant'));
        expect(message.content, equals('System message'));
      });

      test('should create message for different roles', () {
        final userMessage = MessageBuilder.user().text('User text').build();
        final assistantMessage =
            MessageBuilder.assistant().text('Assistant text').build();
        final systemMessage =
            MessageBuilder.system().text('System text').build();

        expect(userMessage.role, equals(ChatRole.user));
        expect(assistantMessage.role, equals(ChatRole.assistant));
        expect(systemMessage.role, equals(ChatRole.system));
      });
    });

    group('Anthropic-Specific Features', () {
      test('should create cached text message', () {
        final message = MessageBuilder.system()
            .anthropic((anthropic) => anthropic.cachedText('Cached content',
                ttl: AnthropicCacheTtl.fiveMinutes))
            .build();

        expect(message.role, equals(ChatRole.system));
        expect(message.content, equals('Cached content'));
        expect(message.hasExtension('anthropic'), isTrue);

        final anthropicData =
            message.getExtension<Map<String, dynamic>>('anthropic');
        expect(anthropicData, isNotNull);

        final contentBlocks = anthropicData!['contentBlocks'] as List<dynamic>;
        expect(contentBlocks, hasLength(1));

        final block = contentBlocks.first as Map<String, dynamic>;
        expect(block['type'], equals('text'));
        expect(block['text'], equals('Cached content'));
        expect(block['cache_control']['ttl'], equals(300));
      });

      test('should create tool use message', () {
        final message = MessageBuilder.assistant()
            .anthropic((anthropic) => anthropic.toolUse(
                  id: 'call_456',
                  name: 'web_search',
                  input: {'query': 'AI news', 'limit': 5},
                ))
            .build();

        expect(message.content, equals('[Tool: web_search]'));

        final anthropicData =
            message.getExtension<Map<String, dynamic>>('anthropic');
        final contentBlocks = anthropicData!['contentBlocks'] as List<dynamic>;
        final block = contentBlocks.first as Map<String, dynamic>;

        expect(block['type'], equals('tool_use'));
        expect(block['id'], equals('call_456'));
        expect(block['name'], equals('web_search'));
        expect(block['input'], equals({'query': 'AI news', 'limit': 5}));
      });

      test('should create tool result message', () {
        final message = MessageBuilder.user()
            .anthropic((anthropic) => anthropic.toolResult(
                  toolUseId: 'call_456',
                  content: 'Search results here...',
                  isError: false,
                ))
            .build();

        expect(message.content, equals('Search results here...'));

        final anthropicData =
            message.getExtension<Map<String, dynamic>>('anthropic');
        final contentBlocks = anthropicData!['contentBlocks'] as List<dynamic>;
        final block = contentBlocks.first as Map<String, dynamic>;

        expect(block['type'], equals('tool_result'));
        expect(block['tool_use_id'], equals('call_456'));
        expect(block['content'], equals('Search results here...'));
        expect(block['is_error'], equals(false));
      });

      test('should handle complex content blocks', () {
        final message = MessageBuilder.user()
            .anthropic((anthropic) => anthropic.contentBlocks([
                  {
                    'type': 'text',
                    'text': 'First block',
                    'cache_control': {'type': 'ephemeral', 'ttl': 3600}
                  },
                  {
                    'type': 'tool_use',
                    'id': 'call_789',
                    'name': 'calculate',
                    'input': {'expression': '2 + 2'}
                  }
                ]))
            .build();

        expect(message.content, equals('First block\n[Tool: calculate]'));

        final anthropicData =
            message.getExtension<Map<String, dynamic>>('anthropic');
        final contentBlocks = anthropicData!['contentBlocks'] as List<dynamic>;
        expect(contentBlocks, hasLength(2));
      });
    });

    group('OpenAI-Specific Features', () {
      test('should create image message', () {
        final message = MessageBuilder.user()
            .openai((openai) =>
                openai.image('https://example.com/photo.jpg', detail: 'low'))
            .build();

        expect(message.content, equals('[Image]'));

        final openaiData = message.getExtension<Map<String, dynamic>>('openai');
        final contentBlocks = openaiData!['contentBlocks'] as List<dynamic>;
        final block = contentBlocks.first as Map<String, dynamic>;

        expect(block['type'], equals('image_url'));
        expect(
            block['image_url']['url'], equals('https://example.com/photo.jpg'));
        expect(block['image_url']['detail'], equals('low'));
      });

      test('should create text with image message', () {
        final message = MessageBuilder.user()
            .openai((openai) => openai.textWithImage(
                  'What do you see?',
                  'https://example.com/image.png',
                ))
            .build();

        expect(message.content, equals('What do you see?\n[Image]'));

        final openaiData = message.getExtension<Map<String, dynamic>>('openai');
        final contentBlocks = openaiData!['contentBlocks'] as List<dynamic>;
        expect(contentBlocks, hasLength(2));

        final textBlock = contentBlocks[0] as Map<String, dynamic>;
        expect(textBlock['type'], equals('text'));
        expect(textBlock['text'], equals('What do you see?'));

        final imageBlock = contentBlocks[1] as Map<String, dynamic>;
        expect(imageBlock['type'], equals('image_url'));
      });
    });

    group('Mixed Content Features', () {
      test('should combine universal and provider-specific content', () {
        final message = MessageBuilder.user()
            .text('Universal text')
            .anthropic((anthropic) => anthropic.cachedText('Cached text'))
            .openai((openai) => openai.image('https://example.com/img.jpg'))
            .build();

        expect(message.content, contains('Universal text'));
        expect(message.content, contains('Cached text'));
        expect(message.content, contains('[Image]'));

        expect(message.hasExtension('anthropic'), isTrue);
        expect(message.hasExtension('openai'), isTrue);
      });

      test('should handle multiple content blocks from same provider', () {
        final message = MessageBuilder.assistant()
            .anthropic((anthropic) => anthropic.toolUse(
                id: 'call_1',
                name: 'tool1',
                input: {}).toolUse(id: 'call_2', name: 'tool2', input: {}))
            .build();

        final anthropicData =
            message.getExtension<Map<String, dynamic>>('anthropic');
        final contentBlocks = anthropicData!['contentBlocks'] as List<dynamic>;
        expect(contentBlocks, hasLength(2));
      });
    });

    group('ChatMessage Extensions', () {
      test('should support getExtension method', () {
        final message = ChatMessage(
          role: ChatRole.user,
          messageType: const TextMessage(),
          content: 'Test',
          extensions: {'test_key': 'test_value'},
        );

        expect(message.getExtension<String>('test_key'), equals('test_value'));
        expect(message.getExtension<String>('missing_key'), isNull);
      });

      test('should support hasExtension method', () {
        final message = ChatMessage(
          role: ChatRole.user,
          messageType: const TextMessage(),
          content: 'Test',
          extensions: {'existing_key': 'value'},
        );

        expect(message.hasExtension('existing_key'), isTrue);
        expect(message.hasExtension('missing_key'), isFalse);
      });

      test('should support withExtension method', () {
        final originalMessage = ChatMessage(
          role: ChatRole.user,
          messageType: const TextMessage(),
          content: 'Test',
          extensions: {'key1': 'value1'},
        );

        final newMessage = originalMessage.withExtension('key2', 'value2');

        expect(newMessage.extensions['key1'], equals('value1'));
        expect(newMessage.extensions['key2'], equals('value2'));
        expect(originalMessage.extensions.containsKey('key2'), isFalse);
      });

      test('should support withExtensions method', () {
        final originalMessage = ChatMessage(
          role: ChatRole.user,
          messageType: const TextMessage(),
          content: 'Test',
          extensions: {'key1': 'value1'},
        );

        final newMessage = originalMessage.withExtensions({
          'key2': 'value2',
          'key3': 'value3',
        });

        expect(newMessage.extensions['key1'], equals('value1'));
        expect(newMessage.extensions['key2'], equals('value2'));
        expect(newMessage.extensions['key3'], equals('value3'));
      });
    });

    group('AnthropicCacheControl', () {
      test('should create ephemeral cache control with TTL', () {
        const cacheControl =
            AnthropicCacheControl.ephemeral(ttl: AnthropicCacheTtl.oneHour);

        expect(cacheControl.type, equals('ephemeral'));
        expect(cacheControl.ttl, equals(AnthropicCacheTtl.oneHour));

        final json = cacheControl.toJson();
        expect(json['type'], equals('ephemeral'));
        expect(json['ttl'], equals(3600));
      });

      test('should create ephemeral cache control without TTL', () {
        const cacheControl = AnthropicCacheControl.ephemeral();

        expect(cacheControl.type, equals('ephemeral'));
        expect(cacheControl.ttl, isNull);

        final json = cacheControl.toJson();
        expect(json['type'], equals('ephemeral'));
        expect(json.containsKey('ttl'), isFalse);
      });
    });

    group('AnthropicCacheTtl', () {
      test('should have correct TTL values', () {
        expect(AnthropicCacheTtl.fiveMinutes.seconds, equals(300));
        expect(AnthropicCacheTtl.oneHour.seconds, equals(3600));
      });
    });
  });
}
