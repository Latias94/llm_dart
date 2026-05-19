import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI native tools', () {
    test('exports built-in tool foundation through the package entrypoint', () {
      const tool = OpenAIWebSearchTool();

      expect(tool, isA<OpenAIBuiltInTool>());
      expect(tool.type, OpenAIBuiltInToolType.webSearch);
      expect(OpenAIBuiltInTools.webSearch(), isA<OpenAIWebSearchTool>());
    });

    test('encodes provider-native Responses tools', () {
      expect(
        const OpenAIFileSearchTool(
          vectorStoreIds: ['vs_1'],
          parameters: {'max_num_results': 5},
        ).toJson(),
        {
          'type': 'file_search',
          'vector_store_ids': ['vs_1'],
          'max_num_results': 5,
        },
      );

      expect(
        const OpenAIComputerUseTool(
          displayWidth: 1024,
          displayHeight: 768,
          environment: 'browser',
        ).toJson(),
        {
          'type': 'computer_use_preview',
          'display_width': 1024,
          'display_height': 768,
          'environment': 'browser',
        },
      );

      expect(
        OpenAIBuiltInTools.imageGeneration(
          background: OpenAIImageBackground.transparent,
          inputFidelity: OpenAIImageGenerationInputFidelity.high,
          inputImageMask: OpenAIImageMask(
            imageUrl: Uri.parse('https://example.com/mask.png'),
          ),
          model: 'gpt-image-1',
          moderation: OpenAIImageGenerationModeration.auto,
          partialImages: 2,
          quality: OpenAIImageQuality.high,
          outputCompression: 80,
          outputFormat: OpenAIImageOutputFormat.webp,
          size: OpenAIImageGenerationSize.square1024,
        ).toJson(),
        {
          'type': 'image_generation',
          'background': 'transparent',
          'input_fidelity': 'high',
          'input_image_mask': {
            'image_url': 'https://example.com/mask.png',
          },
          'model': 'gpt-image-1',
          'moderation': 'auto',
          'partial_images': 2,
          'quality': 'high',
          'output_compression': 80,
          'output_format': 'webp',
          'size': '1024x1024',
        },
      );
    });

    test('encodes code interpreter and MCP tools', () {
      expect(
        OpenAIBuiltInTools.codeInterpreter(
          container: const OpenAICodeInterpreterAutoContainer(
            fileIds: ['file_1'],
          ),
        ).toJson(),
        {
          'type': 'code_interpreter',
          'container': {
            'type': 'auto',
            'file_ids': ['file_1'],
          },
        },
      );

      expect(
        OpenAIBuiltInTools.codeInterpreter(
          container: const OpenAICodeInterpreterContainerReference('ctr_1'),
        ).toJson(),
        {
          'type': 'code_interpreter',
          'container': 'ctr_1',
        },
      );

      expect(
        OpenAIBuiltInTools.mcp(
          serverLabel: 'docs',
          allowedTools: const OpenAIMcpAllowedTools.filter(
            readOnly: true,
            toolNames: ['search'],
          ),
          connectorId: 'connector_docs',
          headers: const {'x-env': 'test'},
          requireApproval:
              const OpenAIMcpApprovalPolicy.neverForTools(['search']),
        ).toJson(),
        {
          'type': 'mcp',
          'server_label': 'docs',
          'allowed_tools': {
            'read_only': true,
            'tool_names': ['search'],
          },
          'connector_id': 'connector_docs',
          'headers': {'x-env': 'test'},
          'require_approval': {
            'never': {
              'tool_names': ['search'],
            },
          },
        },
      );
    });
  });
}
