import 'dart:convert';

import 'package:llm_dart_openai/src/chat_completions/openai_chat_completions_language_model_route_adapter.dart';
import 'package:llm_dart_openai/src/responses/openai_responses_language_model_route_adapter.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI language model route stream adapters', () {
    test('labels malformed Responses SSE payloads with source', () {
      expect(
        const OpenAIResponsesLanguageModelRouteAdapter().decodeStreamEvents(
          stream: Stream.fromIterable([
            utf8.encode('data: {"broken":\n\n'),
          ]),
          includeRawChunks: false,
        ),
        emitsError(
          isA<TransportResponseFormatException>().having(
            (error) => error.message,
            'message',
            contains('OpenAI Responses stream API returned invalid JSON'),
          ),
        ),
      );
    });

    test('labels malformed Chat Completions SSE payloads with source', () {
      expect(
        const OpenAIChatCompletionsLanguageModelRouteAdapter()
            .decodeStreamEvents(
          stream: Stream.fromIterable([
            utf8.encode('data: ["not","object"]\n\n'),
          ]),
          includeRawChunks: false,
        ),
        emitsError(
          isA<TransportResponseFormatException>().having(
            (error) => error.message,
            'message',
            contains(
              'OpenAI Chat Completions stream API returned JSON that is not an object',
            ),
          ),
        ),
      );
    });
  });
}
