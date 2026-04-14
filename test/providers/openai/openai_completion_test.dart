import 'package:llm_dart/core/capability.dart';
import 'package:llm_dart/providers/openai/client.dart';
import 'package:llm_dart/providers/openai/config.dart';
import 'package:llm_dart/src/compatibility/providers/openai/completion.dart';
import 'package:llm_dart/src/compatibility/providers/openai/openai_completion_support.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI completion compatibility shell', () {
    test('complete keeps request shaping and response parsing', () async {
      final client = _FakeOpenAIClient(
        const OpenAIConfig(apiKey: 'test-key', model: 'gpt-4o'),
      )..jsonResponse = {
          'choices': [
            {
              'message': {
                'role': 'assistant',
                'content': 'Completed text.',
              },
            },
          ],
          'usage': {
            'prompt_tokens': 3,
            'completion_tokens': 2,
            'total_tokens': 5,
          },
        };
      final completion = OpenAICompletion(client, client.config);

      final response = await completion.complete(
        const CompletionRequest(
          prompt: 'Say hi',
          maxTokens: 12,
          temperature: 0.4,
          topP: 0.8,
          stop: ['END'],
        ),
      );

      expect(client.lastJsonEndpoint, 'chat/completions');
      expect(client.lastJsonBody, {
        'model': 'gpt-4o',
        'messages': [
          {
            'role': 'user',
            'content': 'Say hi',
          },
        ],
        'stream': false,
        'max_tokens': 12,
        'temperature': 0.4,
        'top_p': 0.8,
        'stop': ['END'],
      });
      expect(response.text, 'Completed text.');
      expect(response.usage?.totalTokens, 5);
    });

    test('completeStream keeps SSE delta parsing', () async {
      final client = _FakeOpenAIClient(
        const OpenAIConfig(apiKey: 'test-key', model: 'gpt-4o'),
      )..streamChunks = [
          'data: {"choices":[{"delta":{"content":"Hello"}}]}\n\n',
          'data: {"choices":[{"delta":{"content":" world"}}]}\n\n',
        ];
      final completion = OpenAICompletion(client, client.config);

      final chunks = await completion
          .completeStream(
            const CompletionRequest(prompt: 'Stream please'),
          )
          .toList();

      expect(client.lastStreamEndpoint, 'chat/completions');
      expect(client.lastStreamBody?['stream'], isTrue);
      expect(chunks, ['Hello', ' world']);
    });
  });

  group('OpenAI completion support', () {
    const support = OpenAICompletionSupport();

    test('buildUseCaseRequest keeps code preset defaults', () {
      final request = support.buildUseCaseRequest(
        'Write code',
        CompletionUseCase.code,
      );

      expect(request.prompt, 'Write code');
      expect(request.temperature, 0.2);
      expect(request.topP, 0.1);
      expect(request.maxTokens, 1500);
      expect(request.stop, ['\n\n', '```']);
    });

    test('completeWithRetry retries and returns first success', () async {
      var attempts = 0;

      final response = await support.completeWithRetry(
        () async {
          attempts += 1;
          if (attempts < 2) {
            throw Exception('temporary');
          }
          return const CompletionResponse(text: 'ok');
        },
        maxRetries: 3,
        delay: Duration.zero,
      );

      expect(attempts, 2);
      expect(response.text, 'ok');
    });

    test('batchComplete keeps ordering across batches', () async {
      final seenPrompts = <String>[];

      final responses = await support.batchComplete(
        prompts: const ['a', 'b', 'c'],
        maxTokens: 10,
        temperature: 0.5,
        concurrency: 2,
        complete: (request) async {
          seenPrompts.add(request.prompt);
          return CompletionResponse(text: 'done:${request.prompt}');
        },
      );

      expect(seenPrompts, ['a', 'b', 'c']);
      expect(
        responses.map((response) => response.text).toList(),
        ['done:a', 'done:b', 'done:c'],
      );
    });

    test('token heuristics keep bounds and truncation stable', () {
      expect(support.estimateTokenCount('12345678'), 2);
      expect(
        support.isPromptWithinLimits('12345678', maxTokens: 1),
        isFalse,
      );
      expect(
        support.truncatePrompt('1234567890', maxTokens: 1),
        '1234',
      );
    });
  });
}

final class _FakeOpenAIClient extends OpenAIClient {
  Map<String, dynamic> jsonResponse = const {};
  List<String> streamChunks = const [];
  String? lastJsonEndpoint;
  Map<String, dynamic>? lastJsonBody;
  String? lastStreamEndpoint;
  Map<String, dynamic>? lastStreamBody;

  _FakeOpenAIClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    cancelToken,
  }) async {
    lastJsonEndpoint = endpoint;
    lastJsonBody = body;
    return jsonResponse;
  }

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> body, {
    cancelToken,
  }) async* {
    lastStreamEndpoint = endpoint;
    lastStreamBody = body;
    for (final chunk in streamChunks) {
      yield chunk;
    }
  }
}
