import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAICustomPart', () {
    test('parses image_generation_call content parts', () {
      final parsed = OpenAICustomPart.tryParseContentPart(
        CustomContentPart(
          kind: OpenAIImageGenerationCallCustomPart.customKind,
          data: {
            'id': 'img_1',
            'result': 'AAEC',
          },
          providerMetadata: ProviderMetadata.forNamespace(
            'openai',
            {
              'itemId': 'img_1',
            },
          ),
        ),
      );

      expect(parsed, isA<OpenAIImageGenerationCallCustomPart>());
      final imagePart = parsed! as OpenAIImageGenerationCallCustomPart;
      expect(imagePart.itemId, 'img_1');
      expect(imagePart.hasImage, isTrue);
      expect(imagePart.decodeImageBytes(), [0, 1, 2]);
      expect(
        imagePart.toGeneratedFile(filename: 'result.png')?.filename,
        'result.png',
      );
    });

    test('parses partial image custom events', () {
      final parsed = OpenAICustomPart.tryParseEvent(
        CustomEvent(
          kind: OpenAIImageGenerationPartialCustomPart.customKind,
          data: {
            'item_id': 'img_1',
            'output_index': 2,
            'partial_image_b64': 'AQID',
          },
          providerMetadata: ProviderMetadata.forNamespace(
            'openai',
            {
              'itemId': 'img_1',
              'outputIndex': 2,
            },
          ),
        ),
      );

      expect(parsed, isA<OpenAIImageGenerationPartialCustomPart>());
      final partial = parsed! as OpenAIImageGenerationPartialCustomPart;
      expect(partial.itemId, 'img_1');
      expect(partial.outputIndex, 2);
      expect(partial.decodeImageBytes(), [1, 2, 3]);
    });

    test('parses mcp_list_tools content parts', () {
      final parsed = OpenAICustomPart.tryParseContentPart(
        CustomContentPart(
          kind: OpenAIMcpListToolsCustomPart.customKind,
          data: {
            'id': 'mcp_tools_1',
            'server_label': 'zip1',
            'tools': [
              {
                'name': 'create_short_url',
                'description': 'Create a short URL',
              },
              {
                'name': 'get_status',
              },
            ],
          },
          providerMetadata: ProviderMetadata.forNamespace(
            'openai',
            {
              'itemId': 'mcp_tools_1',
              'serverLabel': 'zip1',
            },
          ),
        ),
      );

      expect(parsed, isA<OpenAIMcpListToolsCustomPart>());
      final mcpPart = parsed! as OpenAIMcpListToolsCustomPart;
      expect(mcpPart.itemId, 'mcp_tools_1');
      expect(mcpPart.serverLabel, 'zip1');
      expect(mcpPart.toolCount, 2);
      expect(mcpPart.toolNames, ['create_short_url', 'get_status']);
      expect(mcpPart.hasError, isFalse);
    });

    test('parses code_interpreter_call custom content parts', () {
      final parsed = OpenAICustomPart.tryParseContentPart(
        CustomContentPart(
          kind: OpenAICodeInterpreterCallCustomPart.customKind,
          data: {
            'id': 'ci_1',
            'code': 'print("hi")',
            'container_id': 'cntr_1',
            'outputs': [
              {
                'type': 'logs',
                'logs': 'hi',
              },
            ],
          },
          providerMetadata: ProviderMetadata.forNamespace(
            'openai',
            {
              'itemId': 'ci_1',
              'containerId': 'cntr_1',
              'outputCount': 1,
            },
          ),
        ),
      );

      expect(parsed, isA<OpenAICodeInterpreterCallCustomPart>());
      final codePart = parsed! as OpenAICodeInterpreterCallCustomPart;
      expect(codePart.itemId, 'ci_1');
      expect(codePart.containerId, 'cntr_1');
      expect(codePart.code, 'print("hi")');
      expect(codePart.outputCount, 1);
      expect(codePart.logs, ['hi']);
    });

    test('parses tool search custom content parts', () {
      final call = OpenAICustomPart.tryParseContentPart(
        CustomContentPart(
          kind: OpenAIToolSearchCallCustomPart.customKind,
          data: {
            'id': 'tsc_1',
            'execution': 'client',
            'call_id': 'call_1',
            'arguments': {
              'goal': 'Find a tool',
            },
          },
          providerMetadata: ProviderMetadata.forNamespace(
            'openai',
            {
              'itemId': 'tsc_1',
              'execution': 'client',
              'callId': 'call_1',
            },
          ),
        ),
      );
      expect(call, isA<OpenAIToolSearchCallCustomPart>());
      final callPart = call! as OpenAIToolSearchCallCustomPart;
      expect(callPart.itemId, 'tsc_1');
      expect(callPart.callId, 'call_1');
      expect(callPart.execution, 'client');
      expect(callPart.providerExecuted, isFalse);

      final output = OpenAICustomPart.tryParseContentPart(
        CustomContentPart(
          kind: OpenAIToolSearchOutputCustomPart.customKind,
          data: {
            'id': 'tso_1',
            'execution': 'client',
            'call_id': 'call_1',
            'tools': [
              {
                'type': 'function',
                'name': 'get_weather',
              },
            ],
          },
          providerMetadata: ProviderMetadata.forNamespace(
            'openai',
            {
              'itemId': 'tso_1',
              'execution': 'client',
              'callId': 'call_1',
              'toolCount': 1,
            },
          ),
        ),
      );
      expect(output, isA<OpenAIToolSearchOutputCustomPart>());
      final outputPart = output! as OpenAIToolSearchOutputCustomPart;
      expect(outputPart.itemId, 'tso_1');
      expect(outputPart.callId, 'call_1');
      expect(outputPart.execution, 'client');
      expect(outputPart.toolCount, 1);
      expect(outputPart.toolNames, ['get_weather']);
    });
  });
}
