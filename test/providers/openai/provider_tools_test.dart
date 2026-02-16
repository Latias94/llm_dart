import 'package:llm_dart_openai/provider_tools.dart';
import 'package:llm_dart_openai/web_search_context_size.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIProviderTools', () {
    test('webSearch creates ProviderTool with stable id', () {
      final tool = OpenAIProviderTools.webSearch(
          contextSize: OpenAIWebSearchContextSize.high);

      expect(tool.id, equals('openai.web_search_preview'));
      expect(tool.name, equals('webSearch'));
      expect(tool.options['searchContextSize'], equals('high'));
    });

    test('webSearchFull creates ProviderTool with stable id', () {
      final tool = OpenAIProviderTools.webSearchFull(
        allowedDomains: const ['example.com'],
        externalWebAccess: true,
        contextSize: OpenAIWebSearchContextSize.low,
        userLocation: const {'country': 'US'},
      );

      expect(tool.id, equals('openai.web_search'));
      expect(tool.name, equals('webSearch'));
      expect(
        (tool.options['filters'] as Map)['allowedDomains'],
        equals(['example.com']),
      );
      expect(tool.options['externalWebAccess'], isTrue);
      expect(tool.options['searchContextSize'], equals('low'));
      expect(tool.options['userLocation'], equals(const {'country': 'US'}));
    });

    test('fileSearch creates ProviderTool with stable id', () {
      final tool = OpenAIProviderTools.fileSearch(
        vectorStoreIds: const ['vs_123'],
        maxNumResults: 5,
      );

      expect(tool.id, equals('openai.file_search'));
      expect(tool.name, equals('fileSearch'));
      expect(tool.options['vectorStoreIds'], equals(['vs_123']));
      expect(tool.options['maxNumResults'], equals(5));
    });

    test('computerUse creates ProviderTool with stable id', () {
      final tool = OpenAIProviderTools.computerUse(
        displayWidth: 1024,
        displayHeight: 768,
        environment: 'browser',
        parameters: const {'timeout': 30},
      );

      expect(tool.id, equals('openai.computer_use'));
      expect(tool.name, equals('computerUse'));
      expect(tool.options['displayWidth'], equals(1024));
      expect(tool.options['displayHeight'], equals(768));
      expect(tool.options['environment'], equals('browser'));
      expect(tool.options['timeout'], equals(30));
    });

    test('codeInterpreter creates ProviderTool with stable id', () {
      final tool = OpenAIProviderTools.codeInterpreter(
        container: {
          'fileIds': ['file_1']
        },
      );

      expect(tool.id, equals('openai.code_interpreter'));
      expect(tool.name, equals('codeExecution'));
      expect(tool.options['container'], isA<Map>());
    });

    test('imageGeneration creates ProviderTool with stable id', () {
      final tool = OpenAIProviderTools.imageGeneration(size: '1024x1024');

      expect(tool.id, equals('openai.image_generation'));
      expect(tool.name, equals('generateImage'));
      expect(tool.options['size'], equals('1024x1024'));
    });

    test('mcp creates ProviderTool with stable id', () {
      final tool = OpenAIProviderTools.mcp(serverLabel: 'test');

      expect(tool.id, equals('openai.mcp'));
      expect(tool.name, equals('mcp'));
      expect(tool.options['serverLabel'], equals('test'));
    });

    test('shell/localShell/applyPatch create ProviderTools with stable ids',
        () {
      expect(OpenAIProviderTools.shell().id, equals('openai.shell'));
      expect(OpenAIProviderTools.localShell().id, equals('openai.local_shell'));
      expect(OpenAIProviderTools.applyPatch().id, equals('openai.apply_patch'));
    });
  });
}
