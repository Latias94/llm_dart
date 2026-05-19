import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI native tools', () {
    test('exports built-in tool foundation through the package entrypoint', () {
      const tool = OpenAIWebSearchTool();

      expect(tool, isA<OpenAIBuiltInTool>());
      expect(tool.type, OpenAIBuiltInToolType.webSearch);
      expect(OpenAIBuiltInTools.webSearch(), isA<OpenAIWebSearchTool>());
      expect(OpenAIBuiltInTools.localShell(), isA<OpenAILocalShellTool>());
      expect(OpenAIBuiltInTools.applyPatch(), isA<OpenAIApplyPatchTool>());
      expect(OpenAIBuiltInTools.toolSearch(), isA<OpenAIToolSearchTool>());
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

    test('encodes shell, tool search, apply patch, and custom tools', () {
      expect(OpenAIBuiltInTools.localShell().toJson(), {
        'type': 'local_shell',
      });

      expect(
        OpenAIBuiltInTools.shell(
          environment: OpenAIShellContainerAutoEnvironment(
            fileIds: const ['file_1'],
            memoryLimit: OpenAIShellMemoryLimit.fourGb,
            networkPolicy: OpenAIShellAllowlistNetworkPolicy(
              allowedDomains: const ['example.com'],
              domainSecrets: const [
                OpenAIShellDomainSecret(
                  domain: 'example.com',
                  name: 'API_KEY',
                  value: 'secret_ref',
                ),
              ],
            ),
            skills: const [
              OpenAIShellSkillReference(
                providerReference: ProviderReference({'openai': 'skill_1'}),
              ),
              OpenAIShellInlineSkill(
                name: 'lint',
                description: 'Run lint checks.',
                source: OpenAIShellInlineSkillSource.base64Zip(
                  data: 'UEsDBAo=',
                ),
              ),
            ],
          ),
        ).toJson(),
        {
          'type': 'shell',
          'environment': {
            'type': 'container_auto',
            'file_ids': ['file_1'],
            'memory_limit': '4g',
            'network_policy': {
              'type': 'allowlist',
              'allowed_domains': ['example.com'],
              'domain_secrets': [
                {
                  'domain': 'example.com',
                  'name': 'API_KEY',
                  'value': 'secret_ref',
                },
              ],
            },
            'skills': [
              {
                'type': 'skill_reference',
                'skill_id': 'skill_1',
                'version': 'latest',
              },
              {
                'type': 'inline',
                'name': 'lint',
                'description': 'Run lint checks.',
                'source': {
                  'type': 'base64',
                  'media_type': 'application/zip',
                  'data': 'UEsDBAo=',
                },
              },
            ],
          },
        },
      );

      expect(
        OpenAIBuiltInTools.shell(
          environment: const OpenAIShellContainerReferenceEnvironment('ctr_1'),
        ).toJson(),
        {
          'type': 'shell',
          'environment': {
            'type': 'container_reference',
            'container_id': 'ctr_1',
          },
        },
      );

      expect(
        OpenAIBuiltInTools.shell(
          environment: const OpenAIShellLocalEnvironment(
            skills: [
              OpenAIShellLocalSkill(
                name: 'local',
                description: 'Use local files.',
                path: '/tmp/skill',
              ),
            ],
          ),
        ).toJson(),
        {
          'type': 'shell',
          'environment': {
            'type': 'local',
            'skills': [
              {
                'name': 'local',
                'description': 'Use local files.',
                'path': '/tmp/skill',
              },
            ],
          },
        },
      );

      expect(OpenAIBuiltInTools.applyPatch().toJson(), {
        'type': 'apply_patch',
      });

      expect(
        OpenAIBuiltInTools.toolSearch(
          execution: OpenAIToolSearchExecution.client,
          description: 'Load tools on demand.',
          parameters: const {
            'type': 'object',
            'properties': {
              'query': {'type': 'string'},
            },
          },
        ).toJson(),
        {
          'type': 'tool_search',
          'execution': 'client',
          'description': 'Load tools on demand.',
          'parameters': {
            'type': 'object',
            'properties': {
              'query': {'type': 'string'},
            },
          },
        },
      );

      expect(
        OpenAIBuiltInTools.custom(
          name: 'grammar',
          description: 'Emit a grammar-constrained command.',
          format: const OpenAICustomToolGrammarFormat(
            syntax: OpenAICustomToolGrammarSyntax.lark,
            definition: 'start: /[a-z]+/',
          ),
        ).toJson(),
        {
          'type': 'custom',
          'name': 'grammar',
          'description': 'Emit a grammar-constrained command.',
          'format': {
            'type': 'grammar',
            'syntax': 'lark',
            'definition': 'start: /[a-z]+/',
          },
        },
      );
    });
  });
}
