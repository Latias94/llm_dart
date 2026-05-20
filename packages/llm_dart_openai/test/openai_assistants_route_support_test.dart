import 'package:llm_dart_openai/src/assistants/openai_assistants_route_support.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIAssistantsRouteSupport', () {
    const routes = OpenAIAssistantsRouteSupport(
      baseUrl: 'https://api.openai.com/v1',
    );

    test('builds assistant list and item routes with query and encoded ids',
        () {
      expect(
        routes
            .assistantsUri(
              const OpenAIListAssistantsQuery(
                limit: 20,
                order: 'desc',
                after: 'cursor 1',
              ),
            )
            .toString(),
        'https://api.openai.com/v1/assistants?limit=20&order=desc&after=cursor+1',
      );
      expect(
        routes.assistantUri(' asst / 1 ').toString(),
        'https://api.openai.com/v1/assistants/asst%20%2F%201',
      );
    });

    test('builds nested thread message run and step routes', () {
      expect(
        routes
            .threadMessagesUri(
              'thread 1',
              const OpenAIListThreadMessagesQuery(
                limit: 10,
                runId: 'run_1',
              ),
            )
            .toString(),
        'https://api.openai.com/v1/threads/thread%201/messages?limit=10&run_id=run_1',
      );
      expect(
        routes.cancelThreadRunUri('thread 1', 'run/1').toString(),
        'https://api.openai.com/v1/threads/thread%201/runs/run%2F1/cancel',
      );
      expect(
        routes.threadRunStepUri('thread 1', 'run/1', 'step 1').toString(),
        'https://api.openai.com/v1/threads/thread%201/runs/run%2F1/steps/step%201',
      );
    });

    test('rejects empty resource ids with parameter names', () {
      expect(
        () => routes.threadRunUri(' ', 'run_1'),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'threadId')
              .having(
                (error) => error.message,
                'message',
                contains('OpenAI thread ID'),
              ),
        ),
      );
      expect(
        () => routes.threadRunStepUri('thread_1', 'run_1', ''),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'stepId',
          ),
        ),
      );
    });
  });
}
