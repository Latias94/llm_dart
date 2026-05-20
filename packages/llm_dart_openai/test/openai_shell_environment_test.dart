import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI shell environment', () {
    test('encodes container auto environment with network policy and skills',
        () {
      final environment = OpenAIShellContainerAutoEnvironment(
        fileIds: const ['file_1'],
        memoryLimit: OpenAIShellMemoryLimit.sixteenGb,
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
      );

      expect(environment.toJson(), {
        'type': 'container_auto',
        'file_ids': ['file_1'],
        'memory_limit': '16g',
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
      });
    });

    test('rejects an empty shell network allowlist', () {
      expect(
        () => OpenAIShellAllowlistNetworkPolicy(allowedDomains: const []),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('package facade still exports split shell environment types', () {
      final tool = OpenAIBuiltInTools.shell(
        environment: const OpenAIShellLocalEnvironment(
          skills: [
            OpenAIShellLocalSkill(
              name: 'local',
              description: 'Use local files.',
              path: '/tmp/skill',
            ),
          ],
        ),
      );

      expect(tool.environment, isA<OpenAIShellLocalEnvironment>());
      expect(tool.toJson(), {
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
      });
    });
  });
}
