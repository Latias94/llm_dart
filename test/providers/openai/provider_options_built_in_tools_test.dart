import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI providerOptions builtInTools', () {
    test('should parse builtInTools from providerOptions JSON', () async {
      final provider = await ai()
          .provider('openai')
          .apiKey('test-key')
          .model('gpt-4o')
          .providerOptions('openai', {
        'useResponsesAPI': true,
        'builtInTools': [
          {'type': 'web_search_preview', 'search_context_size': 'high'},
          {
            'type': 'file_search',
            'vector_store_ids': ['vs_123']
          },
          {
            'type': 'computer_use_preview',
            'display_width': 1024,
            'display_height': 768,
            'environment': 'browser',
            'timeout': 30,
          },
        ],
      }).build();

      final openaiProvider = provider as OpenAIProvider;
      expect(openaiProvider.config.useResponsesAPI, isTrue);
      expect(openaiProvider.config.builtInTools, isNotNull);
      expect(openaiProvider.config.builtInTools!, hasLength(3));

      expect(
          openaiProvider.config.builtInTools![0], isA<OpenAIWebSearchTool>());
      expect(
          openaiProvider.config.builtInTools![1], isA<OpenAIFileSearchTool>());
      expect(
          openaiProvider.config.builtInTools![2], isA<OpenAIComputerUseTool>());

      final webTool =
          openaiProvider.config.builtInTools![0] as OpenAIWebSearchTool;
      expect(
          webTool.searchContextSize, equals(OpenAIWebSearchContextSize.high));

      final computerTool =
          openaiProvider.config.builtInTools![2] as OpenAIComputerUseTool;
      expect(computerTool.displayWidth, equals(1024));
      expect(computerTool.displayHeight, equals(768));
      expect(computerTool.environment, equals('browser'));
      expect(computerTool.parameters, containsPair('timeout', 30));
    });

    test(
        'webSearchEnabled enables Responses API and injects web_search_preview',
        () async {
      final provider = await ai()
          .provider('openai')
          .apiKey('test-key')
          .model('gpt-4o')
          .providerOptions('openai', {
        'webSearchEnabled': true,
        'webSearch': const {'search_context_size': 'high'},
      }).build();

      final openaiProvider = provider as OpenAIProvider;
      expect(openaiProvider.config.useResponsesAPI, isTrue);
      expect(openaiProvider.config.builtInTools, isNotNull);
      expect(openaiProvider.config.builtInTools!, isNotEmpty);

      final webTool = openaiProvider.config.builtInTools!
          .whereType<OpenAIWebSearchTool>()
          .single;
      expect(
          webTool.searchContextSize, equals(OpenAIWebSearchContextSize.high));
    });

    test('fileSearchEnabled injects file_search tool and enables Responses API',
        () async {
      final provider = await ai()
          .provider('openai')
          .apiKey('test-key')
          .model('gpt-4o')
          .providerOptions('openai', {
        'fileSearchEnabled': true,
        'fileSearch': {
          'vectorStoreIds': ['vs_123'],
          'max_num_results': 5,
        },
      }).build();

      final openaiProvider = provider as OpenAIProvider;
      expect(openaiProvider.config.useResponsesAPI, isTrue);

      final tool = openaiProvider.config.builtInTools!
          .whereType<OpenAIFileSearchTool>()
          .single;
      expect(tool.vectorStoreIds, equals(['vs_123']));
      expect(tool.parameters, containsPair('max_num_results', 5));
    });

    test(
        'computerUseEnabled injects computer_use tool and enables Responses API',
        () async {
      final provider = await ai()
          .provider('openai')
          .apiKey('test-key')
          .model('gpt-4o')
          .providerOptions('openai', {
        'computerUseEnabled': true,
        'computerUse': {
          'displayWidth': 1024,
          'displayHeight': 768,
          'environment': 'browser',
          'timeout': 30,
        },
      }).build();

      final openaiProvider = provider as OpenAIProvider;
      expect(openaiProvider.config.useResponsesAPI, isTrue);

      final tool = openaiProvider.config.builtInTools!
          .whereType<OpenAIComputerUseTool>()
          .single;
      expect(tool.displayWidth, equals(1024));
      expect(tool.displayHeight, equals(768));
      expect(tool.environment, equals('browser'));
      expect(tool.parameters, containsPair('timeout', 30));
    });

    test('providerTools injects Responses built-in tools', () async {
      final provider = await ai()
          .provider('openai')
          .apiKey('test-key')
          .model('gpt-4o')
          .providerTools(
        const [
          ProviderTool(
            id: 'openai.web_search_preview',
            options: {'search_context_size': 'high'},
          ),
        ],
      ).build();

      final openaiProvider = provider as OpenAIProvider;
      expect(openaiProvider.config.useResponsesAPI, isTrue);
      expect(openaiProvider.config.builtInTools, isNotNull);

      final webTool = openaiProvider.config.builtInTools!
          .whereType<OpenAIWebSearchTool>()
          .single;
      expect(
          webTool.searchContextSize, equals(OpenAIWebSearchContextSize.high));

      // The SDK does not rewrite models; if a built-in tool requires a specific
      // model, OpenAI should return an API error and the caller can adjust.
      expect(openaiProvider.config.model, equals('gpt-4o'));
    });
  });
}
