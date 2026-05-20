import 'dart:convert';

import 'package:llm_dart_openai/src/openai_chat_completions_codec.dart';
import 'package:llm_dart_openai/src/openai_language_model_call_routing.dart';
import 'package:llm_dart_openai/src/openai_language_model_stream.dart';
import 'package:llm_dart_openai/src/openai_responses_codec.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('decodeOpenAILanguageModelStreamEvents', () {
    test('labels malformed Responses SSE payloads with source', () {
      expect(
        decodeOpenAILanguageModelStreamEvents(
          route: OpenAIRequestRoute.responses,
          stream: Stream.fromIterable([
            utf8.encode('data: {"broken":\n\n'),
          ]),
          includeRawChunks: false,
          responsesCodec: const OpenAIResponsesCodec(),
          chatCompletionsCodec: const OpenAIChatCompletionsCodec(),
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
        decodeOpenAILanguageModelStreamEvents(
          route: OpenAIRequestRoute.chatCompletions,
          stream: Stream.fromIterable([
            utf8.encode('data: ["not","object"]\n\n'),
          ]),
          includeRawChunks: false,
          responsesCodec: const OpenAIResponsesCodec(),
          chatCompletionsCodec: const OpenAIChatCompletionsCodec(),
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
