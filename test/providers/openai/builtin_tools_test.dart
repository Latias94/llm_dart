import 'package:test/test.dart';
import 'package:llm_dart_openai/builtin_tools.dart';
import 'package:llm_dart_openai/web_search_context_size.dart';

void main() {
  group('OpenAI Built-in Tools Tests', () {
    group('OpenAIWebSearchTool', () {
      test('should create web search tool with default values', () {
        const tool = OpenAIWebSearchTool();

        expect(tool.type, equals(OpenAIBuiltInToolType.webSearch));
      });

      test('should serialize to JSON correctly', () {
        const tool = OpenAIWebSearchTool();
        final json = tool.toJson();

        expect(json['type'], equals('web_search_preview'));
        expect(json.containsKey('search_context_size'), isFalse);
      });

      test('should serialize search_context_size when provided', () {
        const tool = OpenAIWebSearchTool(
          searchContextSize: OpenAIWebSearchContextSize.high,
        );
        final json = tool.toJson();

        expect(json['type'], equals('web_search_preview'));
        expect(json['search_context_size'], equals('high'));
      });

      test('should create via factory method', () {
        final tool = OpenAIBuiltInTools.webSearch();

        expect(tool, isA<OpenAIWebSearchTool>());
        expect(tool.type, equals(OpenAIBuiltInToolType.webSearch));
      });

      test('should have correct equality and hashCode', () {
        const tool1 = OpenAIWebSearchTool();
        const tool2 = OpenAIWebSearchTool();
        const tool3 = OpenAIWebSearchTool(
          searchContextSize: OpenAIWebSearchContextSize.high,
        );

        expect(tool1, equals(tool2));
        expect(tool1.hashCode, equals(tool2.hashCode));
        expect(tool1, isNot(equals(tool3)));
      });

      test('should have correct toString', () {
        const tool = OpenAIWebSearchTool();
        expect(
          tool.toString(),
          equals('OpenAIWebSearchTool(searchContextSize: null)'),
        );
      });
    });

    group('OpenAIFileSearchTool', () {
      test('should create file search tool with default values', () {
        const tool = OpenAIFileSearchTool();

        expect(tool.type, equals(OpenAIBuiltInToolType.fileSearch));
        expect(tool.vectorStoreIds, isNull);
        expect(tool.parameters, isNull);
      });

      test('should create file search tool with vector store IDs', () {
        const tool = OpenAIFileSearchTool(
          vectorStoreIds: ['vs_123', 'vs_456'],
        );

        expect(tool.type, equals(OpenAIBuiltInToolType.fileSearch));
        expect(tool.vectorStoreIds, equals(['vs_123', 'vs_456']));
      });

      test('should create file search tool with parameters', () {
        const tool = OpenAIFileSearchTool(
          parameters: {'max_results': 10, 'threshold': 0.8},
        );

        expect(tool.type, equals(OpenAIBuiltInToolType.fileSearch));
        expect(tool.parameters?['max_results'], equals(10));
        expect(tool.parameters?['threshold'], equals(0.8));
      });

      test('should serialize to JSON correctly', () {
        const tool = OpenAIFileSearchTool(
          vectorStoreIds: ['vs_789'],
          parameters: {'limit': 5},
        );
        final json = tool.toJson();

        expect(json['type'], equals('file_search'));
        expect(json['vector_store_ids'], equals(['vs_789']));
        expect(json['limit'], equals(5));
      });

      test('should serialize to JSON without optional fields', () {
        const tool = OpenAIFileSearchTool();
        final json = tool.toJson();

        expect(json['type'], equals('file_search'));
        expect(json.containsKey('vector_store_ids'), isFalse);
      });

      test('should create via factory method', () {
        final tool = OpenAIBuiltInTools.fileSearch(
          vectorStoreIds: ['vs_factory'],
          parameters: {'test': true},
        );

        expect(tool, isA<OpenAIFileSearchTool>());
        expect(tool.type, equals(OpenAIBuiltInToolType.fileSearch));
        expect(tool.vectorStoreIds, equals(['vs_factory']));
        expect(tool.parameters?['test'], isTrue);
      });

      test('should have correct equality and hashCode', () {
        const tool1 = OpenAIFileSearchTool(
          vectorStoreIds: ['vs_1'],
          parameters: {'param': 'value'},
        );
        const tool2 = OpenAIFileSearchTool(
          vectorStoreIds: ['vs_1'],
          parameters: {'param': 'value'},
        );
        const tool3 = OpenAIFileSearchTool(vectorStoreIds: ['vs_2']);

        expect(tool1, equals(tool2));
        expect(tool1.hashCode, equals(tool2.hashCode));
        expect(tool1, isNot(equals(tool3)));
      });
    });

    group('OpenAIComputerUseTool', () {
      test('should create computer use tool with required parameters', () {
        const tool = OpenAIComputerUseTool(
          displayWidth: 1920,
          displayHeight: 1080,
          environment: 'desktop',
        );

        expect(tool.type, equals(OpenAIBuiltInToolType.computerUse));
        expect(tool.displayWidth, equals(1920));
        expect(tool.displayHeight, equals(1080));
        expect(tool.environment, equals('desktop'));
        expect(tool.parameters, isNull);
      });

      test('should create computer use tool with parameters', () {
        const tool = OpenAIComputerUseTool(
          displayWidth: 1366,
          displayHeight: 768,
          environment: 'web',
          parameters: {'timeout': 30, 'retries': 3},
        );

        expect(tool.type, equals(OpenAIBuiltInToolType.computerUse));
        expect(tool.displayWidth, equals(1366));
        expect(tool.displayHeight, equals(768));
        expect(tool.environment, equals('web'));
        expect(tool.parameters?['timeout'], equals(30));
        expect(tool.parameters?['retries'], equals(3));
      });

      test('should serialize to JSON correctly', () {
        const tool = OpenAIComputerUseTool(
          displayWidth: 2560,
          displayHeight: 1440,
          environment: 'mobile',
          parameters: {'scale': 2.0},
        );
        final json = tool.toJson();

        expect(json['type'], equals('computer_use_preview'));
        expect(json['display_width'], equals(2560));
        expect(json['display_height'], equals(1440));
        expect(json['environment'], equals('mobile'));
        expect(json['scale'], equals(2.0));
      });

      test('should serialize to JSON without optional parameters', () {
        const tool = OpenAIComputerUseTool(
          displayWidth: 1024,
          displayHeight: 768,
          environment: 'tablet',
        );
        final json = tool.toJson();

        expect(json['type'], equals('computer_use_preview'));
        expect(json['display_width'], equals(1024));
        expect(json['display_height'], equals(768));
        expect(json['environment'], equals('tablet'));
        expect(json.containsKey('parameters'), isFalse);
      });

      test('should create via factory method', () {
        final tool = OpenAIBuiltInTools.computerUse(
          displayWidth: 800,
          displayHeight: 600,
          environment: 'embedded',
          parameters: {'touch': true},
        );

        expect(tool, isA<OpenAIComputerUseTool>());
        expect(tool.type, equals(OpenAIBuiltInToolType.computerUse));
        expect(tool.displayWidth, equals(800));
        expect(tool.displayHeight, equals(600));
        expect(tool.environment, equals('embedded'));
        expect(tool.parameters?['touch'], isTrue);
      });

      test('should have correct equality and hashCode', () {
        const tool1 = OpenAIComputerUseTool(
          displayWidth: 1920,
          displayHeight: 1080,
          environment: 'desktop',
          parameters: {'param': 'value'},
        );
        const tool2 = OpenAIComputerUseTool(
          displayWidth: 1920,
          displayHeight: 1080,
          environment: 'desktop',
          parameters: {'param': 'value'},
        );
        const tool3 = OpenAIComputerUseTool(
          displayWidth: 1366,
          displayHeight: 768,
          environment: 'web',
        );

        expect(tool1, equals(tool2));
        expect(tool1.hashCode, equals(tool2.hashCode));
        expect(tool1, isNot(equals(tool3)));
      });
    });

    group('Tool Type Enum', () {
      test('should have correct enum values', () {
        expect(
            OpenAIBuiltInToolType.webSearch.toString(), contains('webSearch'));
        expect(OpenAIBuiltInToolType.fileSearch.toString(),
            contains('fileSearch'));
        expect(OpenAIBuiltInToolType.computerUse.toString(),
            contains('computerUse'));
      });
    });

    group('Edge Cases', () {
      test('should handle empty vector store IDs in file search', () {
        const tool = OpenAIFileSearchTool(vectorStoreIds: []);
        final json = tool.toJson();

        expect(json['type'], equals('file_search'));
        // Empty list should not be included
        expect(json.containsKey('vector_store_ids'), isFalse);
      });

      test('should handle empty parameters in file search', () {
        const tool = OpenAIFileSearchTool(parameters: {});
        final json = tool.toJson();

        expect(json['type'], equals('file_search'));
        // Empty parameters should still be included
        expect(json.keys.length, equals(1)); // Only 'type'
      });

      test('should handle toString methods', () {
        const webTool = OpenAIWebSearchTool();
        const fileTool = OpenAIFileSearchTool(vectorStoreIds: ['vs_1']);
        const computerTool = OpenAIComputerUseTool(
          displayWidth: 1920,
          displayHeight: 1080,
          environment: 'test',
        );

        expect(webTool.toString(), isA<String>());
        expect(fileTool.toString(), contains('vs_1'));
        expect(computerTool.toString(), contains('1920'));
        expect(computerTool.toString(), contains('1080'));
        expect(computerTool.toString(), contains('test'));
      });
    });
  });
}
