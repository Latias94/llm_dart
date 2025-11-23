import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('OpenAI Responses API Configuration', () {
    test('should create OpenAI config with Responses API enabled', () {
      final config = OpenAIConfig(
        apiKey: 'test-key',
        model: 'gpt-4o',
        useResponsesAPI: true,
      );

      expect(config.useResponsesAPI, isTrue);
      expect(config.previousResponseId, isNull);
      expect(config.builtInTools, isNull);
    });

    test('should create OpenAI config with built-in tools', () {
      final webSearchTool = OpenAIBuiltInTools.webSearch();
      final fileSearchTool = OpenAIBuiltInTools.fileSearch(
        vectorStoreIds: ['vs_123'],
        parameters: {'max_results': 5},
      );

      final config = OpenAIConfig(
        apiKey: 'test-key',
        model: 'gpt-4o',
        useResponsesAPI: true,
        builtInTools: [webSearchTool, fileSearchTool],
      );

      expect(config.builtInTools, hasLength(2));
      expect(config.builtInTools![0], isA<OpenAIWebSearchTool>());
      expect(config.builtInTools![1], isA<OpenAIFileSearchTool>());
    });

    test('should create OpenAI config with previous response ID', () {
      final config = OpenAIConfig(
        apiKey: 'test-key',
        model: 'gpt-4o',
        useResponsesAPI: true,
        previousResponseId: 'resp_123',
      );

      expect(config.previousResponseId, equals('resp_123'));
    });

    test('should build provider with Responses API using builder', () async {
      final provider = await ai()
          .openai((openai) => openai
              .useResponsesAPI()
              .webSearchTool()
              .fileSearchTool(vectorStoreIds: ['vs_123']))
          .apiKey('test-key')
          .model('gpt-4o')
          .build();

      expect(provider, isA<OpenAIProvider>());

      // Access the config through the provider
      final openaiProvider = provider as OpenAIProvider;
      expect(openaiProvider.config.useResponsesAPI, isTrue);
      expect(openaiProvider.config.builtInTools, hasLength(2));
    });

    group('Built-in Tools', () {
      test('should create web search tool correctly', () {
        final tool = OpenAIBuiltInTools.webSearch();
        final json = tool.toJson();

        expect(json['type'], equals('web_search'));
        expect(tool.type, equals(OpenAIBuiltInToolType.webSearch));
      });

      test('should create file search tool correctly', () {
        final tool = OpenAIBuiltInTools.fileSearch(
          vectorStoreIds: ['vs_123', 'vs_456'],
          parameters: {'max_results': 10},
        );
        final json = tool.toJson();

        expect(json['type'], equals('file_search'));
        expect(json['vector_store_ids'], equals(['vs_123', 'vs_456']));
        expect(json['max_results'], equals(10));
        expect(tool.type, equals(OpenAIBuiltInToolType.fileSearch));
      });

      test('should create computer use tool correctly', () {
        final tool = OpenAIBuiltInTools.computerUse(
          displayWidth: 1024,
          displayHeight: 768,
          environment: 'browser',
          parameters: {'timeout': 30},
        );
        final json = tool.toJson();

        expect(json['type'], equals('computer_use_preview'));
        expect(json['display_width'], equals(1024));
        expect(json['display_height'], equals(768));
        expect(json['environment'], equals('browser'));
        expect(json['timeout'], equals(30));
        expect(tool.type, equals(OpenAIBuiltInToolType.computerUse));
      });

      test('should handle tool equality correctly', () {
        final tool1 = OpenAIBuiltInTools.webSearch();
        final tool2 = OpenAIBuiltInTools.webSearch();
        final tool3 = OpenAIBuiltInTools.fileSearch();

        expect(tool1, equals(tool2));
        expect(tool1, isNot(equals(tool3)));
        expect(tool1.hashCode, equals(tool2.hashCode));
      });

      test('should handle file search tool with no parameters', () {
        final tool = OpenAIBuiltInTools.fileSearch();
        final json = tool.toJson();

        expect(json['type'], equals('file_search'));
        expect(json.containsKey('vector_store_ids'), isFalse);
      });
    });

    group('Builder Methods', () {
      test('should accumulate multiple built-in tools', () async {
        final provider = await ai()
            .openai((openai) => openai
                    .useResponsesAPI()
                    .webSearchTool()
                    .fileSearchTool(vectorStoreIds: ['vs_123']).computerUseTool(
                  displayWidth: 1024,
                  displayHeight: 768,
                  environment: 'browser',
                ))
            .apiKey('test-key')
            .model('gpt-4o')
            .build();

        final openaiProvider = provider as OpenAIProvider;
        expect(openaiProvider.config.builtInTools, hasLength(3));

        final tools = openaiProvider.config.builtInTools!;
        expect(tools[0], isA<OpenAIWebSearchTool>());
        expect(tools[1], isA<OpenAIFileSearchTool>());
        expect(tools[2], isA<OpenAIComputerUseTool>());
      });

      test('should set previous response ID correctly', () async {
        final provider = await ai()
            .openai((openai) =>
                openai.useResponsesAPI().previousResponseId('resp_123'))
            .apiKey('test-key')
            .model('gpt-4o')
            .build();

        final openaiProvider = provider as OpenAIProvider;
        expect(openaiProvider.config.previousResponseId, equals('resp_123'));
      });
    });

    group('Config Validation', () {
      test('should handle copyWith for Responses API fields', () {
        final originalConfig = OpenAIConfig(
          apiKey: 'test-key',
          model: 'gpt-4o',
          useResponsesAPI: false,
        );

        final updatedConfig = originalConfig.copyWith(
          useResponsesAPI: true,
          previousResponseId: 'resp_123',
          builtInTools: [OpenAIBuiltInTools.webSearch()],
        );

        expect(updatedConfig.useResponsesAPI, isTrue);
        expect(updatedConfig.previousResponseId, equals('resp_123'));
        expect(updatedConfig.builtInTools, hasLength(1));

        // Original should remain unchanged
        expect(originalConfig.useResponsesAPI, isFalse);
        expect(originalConfig.previousResponseId, isNull);
        expect(originalConfig.builtInTools, isNull);
      });

      test('should handle equality with Responses API fields', () {
        final config1 = OpenAIConfig(
          apiKey: 'test-key',
          model: 'gpt-4o',
          useResponsesAPI: true,
          previousResponseId: 'resp_123',
        );

        final config2 = OpenAIConfig(
          apiKey: 'test-key',
          model: 'gpt-4o',
          useResponsesAPI: true,
          previousResponseId: 'resp_123',
        );

        final config3 = OpenAIConfig(
          apiKey: 'test-key',
          model: 'gpt-4o',
          useResponsesAPI: false,
        );

        expect(config1, equals(config2));
        expect(config1, isNot(equals(config3)));
        expect(config1.hashCode, equals(config2.hashCode));
      });
    });
  });
}
