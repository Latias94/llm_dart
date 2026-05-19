import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI Assistants thread models', () {
    test('thread requests encode messages, tool resources, metadata, extra',
        () {
      final request = OpenAICreateThreadRequest(
        messages: const [
          OpenAICreateThreadMessageRequest(
            content: 'Hello',
            attachments: [
              {
                'file_id': 'file_1',
                'tools': [
                  {'type': 'file_search'},
                ],
              },
            ],
            metadata: {'source': 'test'},
          ),
        ],
        toolResources: const OpenAIAssistantToolResources(
          fileSearch: OpenAIAssistantFileSearchResources(
            vectorStoreIds: ['vs_1'],
          ),
        ),
        metadata: const {'team': 'core'},
        extra: const {'native': true},
      );

      expect(request.toJson(), {
        'messages': [
          {
            'role': 'user',
            'content': 'Hello',
            'attachments': [
              {
                'file_id': 'file_1',
                'tools': [
                  {'type': 'file_search'},
                ],
              },
            ],
            'metadata': {'source': 'test'},
          },
        ],
        'tool_resources': {
          'file_search': {
            'vector_store_ids': ['vs_1'],
          },
        },
        'metadata': {'team': 'core'},
        'native': true,
      });
    });

    test('thread and message responses preserve raw provider JSON', () {
      final thread = OpenAIThread.fromJson(
        const {
          'id': 'thread_1',
          'object': 'thread',
          'created_at': 1700000000,
          'metadata': {'team': 'core'},
          'provider_owned': {'kept': true},
        },
      );
      expect(thread.id, 'thread_1');
      expect(thread.metadata, {'team': 'core'});
      expect(thread.toJson(), containsPair('provider_owned', {'kept': true}));

      final message = OpenAIThreadMessage.fromJson(
        const {
          'id': 'msg_1',
          'object': 'thread.message',
          'created_at': 1700000001,
          'thread_id': 'thread_1',
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': {'value': 'Hello'},
            },
          ],
          'attachments': [
            {'file_id': 'file_1'},
          ],
          'metadata': {'source': 'test'},
        },
      );

      expect(message.id, 'msg_1');
      expect(message.content.single['type'], 'text');
      expect(message.attachments.single['file_id'], 'file_1');
      expect(message.toJson(), containsPair('thread_id', 'thread_1'));
    });

    test('run and run step responses expose lifecycle metadata', () {
      final run = OpenAIThreadRun.fromJson(
        const {
          'id': 'run_1',
          'object': 'thread.run',
          'created_at': 1700000002,
          'thread_id': 'thread_1',
          'assistant_id': 'asst_1',
          'status': 'requires_action',
          'required_action': {
            'type': 'submit_tool_outputs',
          },
          'tools': [
            {'type': 'function'},
          ],
          'usage': {'total_tokens': 42},
        },
      );

      expect(run.status, 'requires_action');
      expect(run.requiredAction!['type'], 'submit_tool_outputs');
      expect(run.tools.single['type'], 'function');
      expect(run.usage!['total_tokens'], 42);

      final step = OpenAIRunStep.fromJson(
        const {
          'id': 'step_1',
          'object': 'thread.run.step',
          'created_at': 1700000003,
          'run_id': 'run_1',
          'assistant_id': 'asst_1',
          'thread_id': 'thread_1',
          'type': 'tool_calls',
          'status': 'completed',
          'step_details': {
            'type': 'tool_calls',
            'tool_calls': [],
          },
        },
      );

      expect(step.type, 'tool_calls');
      expect(step.stepDetails['type'], 'tool_calls');
      expect(step.toJson(), containsPair('id', 'step_1'));
    });

    test('list queries validate limits and encode filters', () {
      expect(
        const OpenAIListThreadMessagesQuery(
          limit: 10,
          order: 'asc',
          after: 'msg_0',
          runId: 'run_1',
        ).toQueryParameters(),
        {
          'limit': '10',
          'order': 'asc',
          'after': 'msg_0',
          'run_id': 'run_1',
        },
      );
      expect(
        const OpenAIListRunStepsQuery(
          limit: 5,
          include: [
            'step_details.tool_calls[*].file_search.results[*].content'
          ],
        ).toQueryParameters(),
        {
          'limit': '5',
          'include':
              'step_details.tool_calls[*].file_search.results[*].content',
        },
      );
      expect(
        () => const OpenAIListRunsQuery(limit: 0).toQueryParameters(),
        throwsArgumentError,
      );
    });
  });
}
