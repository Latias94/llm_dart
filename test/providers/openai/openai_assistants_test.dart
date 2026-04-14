import 'package:llm_dart/models/assistant_models.dart';
import 'package:llm_dart/models/tool_models.dart';
import 'package:llm_dart/providers/openai/client.dart';
import 'package:llm_dart/providers/openai/config.dart';
import 'package:llm_dart/src/compatibility/providers/openai/assistants.dart';
import 'package:llm_dart/src/compatibility/providers/openai/openai_assistant_support.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI assistants compatibility shell', () {
    test('listAssistants keeps query shaping and response parsing', () async {
      final client = _FakeOpenAIClient(
        const OpenAIConfig(apiKey: 'test-key', model: 'gpt-4o'),
      )..getResponses['assistants?limit=20&order=desc&after=cursor%201'] = {
          'object': 'list',
          'data': [
            {
              'id': 'asst_1',
              'created_at': 123,
              'model': 'gpt-4o',
              'name': 'Planner',
              'tools': const [],
            },
          ],
          'has_more': false,
        };
      final assistants = OpenAIAssistants(client, client.config);

      final response = await assistants.listAssistants(
        const ListAssistantsQuery(
          limit: 20,
          order: 'desc',
          after: 'cursor 1',
        ),
      );

      expect(
        client.lastGetEndpoint,
        'assistants?limit=20&order=desc&after=cursor%201',
      );
      expect(response.data, hasLength(1));
      expect(response.data.single.id, 'asst_1');
      expect(response.data.single.name, 'Planner');
    });

    test('cloneAssistant keeps cloned metadata and original tool wiring',
        () async {
      final client = _FakeOpenAIClient(
        const OpenAIConfig(apiKey: 'test-key', model: 'gpt-4o'),
      )
        ..getResponses['assistants/asst_1'] = {
          'id': 'asst_1',
          'created_at': 123,
          'model': 'gpt-4o',
          'name': 'Researcher',
          'description': 'Original assistant',
          'instructions': 'Think carefully.',
          'metadata': {
            'team': 'core',
          },
          'tools': [
            {'type': 'code_interpreter'},
          ],
        }
        ..postResponses['assistants'] = {
          'id': 'asst_clone',
          'created_at': 456,
          'model': 'gpt-4o',
          'name': 'Researcher Copy',
          'tools': [
            {'type': 'code_interpreter'},
          ],
        };
      final assistants = OpenAIAssistants(client, client.config);

      final cloned = await assistants.cloneAssistant(
        'asst_1',
        newName: 'Researcher Copy',
        additionalMetadata: const {'env': 'test'},
      );

      expect(client.lastGetEndpoint, 'assistants/asst_1');
      expect(client.lastPostJsonEndpoint, 'assistants');
      expect(client.lastPostJsonBody, isNotNull);
      expect(client.lastPostJsonBody!['name'], 'Researcher Copy');
      expect(client.lastPostJsonBody!['description'], 'Original assistant');
      expect(client.lastPostJsonBody!['instructions'], 'Think carefully.');
      expect(client.lastPostJsonBody!['tools'], [
        {'type': 'code_interpreter'},
      ]);
      final metadata =
          client.lastPostJsonBody!['metadata'] as Map<String, dynamic>;
      expect(metadata['team'], 'core');
      expect(metadata['env'], 'test');
      expect(metadata['cloned_from'], 'asst_1');
      expect(metadata['cloned_at'], isA<String>());
      expect(cloned.id, 'asst_clone');
    });
  });

  group('OpenAI assistant support', () {
    const support = OpenAIAssistantSupport();

    test('searchAssistants filters by name, model, tool, and metadata', () {
      final assistants = [
        Assistant(
          id: 'asst_1',
          createdAt: 1,
          name: 'Planner Alpha',
          model: 'gpt-4o',
          tools: const [CodeInterpreterTool()],
          metadata: const {'team': 'core'},
        ),
        Assistant(
          id: 'asst_2',
          createdAt: 2,
          name: 'Research Beta',
          model: 'gpt-4o-mini',
          tools: const [
            AssistantFunctionTool(
              function: FunctionObject(name: 'lookup'),
            ),
          ],
          metadata: const {'team': 'labs'},
        ),
      ];

      final filtered = support.searchAssistants(
        assistants,
        namePattern: 'planner',
        model: 'gpt-4o',
        requiredTools: const ['code_interpreter'],
        metadataFilters: const {'team': 'core'},
      );

      expect(filtered.map((assistant) => assistant.id), ['asst_1']);
    });

    test('buildImportRequest parses tool JSON and stamps import metadata', () {
      final request = support.buildImportRequest({
        'model': 'gpt-4o',
        'name': 'Imported assistant',
        'description': 'Imported from config',
        'instructions': 'Be helpful.',
        'tools': [
          {'type': 'code_interpreter'},
          {
            'type': 'function',
            'function': {
              'name': 'lookup_weather',
              'description': 'Look up weather',
            },
          },
        ],
        'metadata': {
          'source': 'fixture',
        },
      });

      expect(request.model, 'gpt-4o');
      expect(request.name, 'Imported assistant');
      expect(request.tools, hasLength(2));
      expect(request.tools!.first, isA<CodeInterpreterTool>());
      expect(request.tools!.last, isA<AssistantFunctionTool>());
      expect(
        (request.tools!.last as AssistantFunctionTool).function.name,
        'lookup_weather',
      );
      expect(request.metadata!['source'], 'fixture');
      expect(request.metadata!['imported_at'], isA<String>());
    });
  });
}

final class _FakeOpenAIClient extends OpenAIClient {
  final Map<String, Map<String, dynamic>> getResponses = {};
  final Map<String, Map<String, dynamic>> postResponses = {};
  final Map<String, Map<String, dynamic>> deleteResponses = {};
  String? lastGetEndpoint;
  String? lastPostJsonEndpoint;
  Map<String, dynamic>? lastPostJsonBody;
  String? lastDeleteEndpoint;

  _FakeOpenAIClient(super.config);

  @override
  Future<Map<String, dynamic>> get(
    String endpoint, {
    cancelToken,
  }) async {
    lastGetEndpoint = endpoint;
    return getResponses[endpoint] ?? const {};
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    cancelToken,
  }) async {
    lastPostJsonEndpoint = endpoint;
    lastPostJsonBody = body;
    return postResponses[endpoint] ?? const {};
  }

  @override
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    cancelToken,
  }) async {
    lastDeleteEndpoint = endpoint;
    return deleteResponses[endpoint] ?? const {};
  }
}
