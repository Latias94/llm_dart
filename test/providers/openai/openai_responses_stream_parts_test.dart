import 'dart:async';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:llm_dart_openai/responses.dart' as openai_responses;
import 'package:llm_dart_openai/client.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI Responses chatStreamParts', () {
    test('emits sources and provider tool parts for annotations and web search',
        () async {
      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o-search-preview',
        useResponsesAPI: true,
      );

      final client = _FakeOpenAIClient(config, const [
        'data: {"type":"response.created","response":{"id":"resp_1","model":"gpt-4o-search-preview","output":[]}}\n\n',
        'data: {"type":"response.output_item.done","output_index":0,"item":{"type":"web_search_call","id":"ws_1","status":"completed","action":{"type":"search","query":"test","sources":[{"type":"url","url":"https://example.com"}]}}}\n\n',
        'data: {"type":"response.output_text.annotation.added","annotation":{"type":"url_citation","url":"https://example.com","start_index":0,"end_index":4}}\n\n',
        'data: {"type":"response.output_text.delta","delta":"Hello"}\n\n',
        'data: [DONE]\n\n',
      ]);

      final responses = openai_responses.OpenAIResponses(client, config);

      final parts =
          await responses.chatStreamParts([ChatMessage.user('x')]).toList();

      expect(parts.whereType<LLMProviderMetadataPart>(), isEmpty);

      final responseMetadata =
          parts.whereType<LLMResponseMetadataPart>().single;
      expect(responseMetadata.id, equals('resp_1'));
      expect(responseMetadata.model, equals('gpt-4o-search-preview'));

      final sources = parts.whereType<LLMSourceUrlPart>().toList();
      expect(sources, hasLength(1));
      expect(sources.single.url, equals('https://example.com'));

      final toolInputs = parts.whereType<LLMToolInputStartPart>().toList();
      expect(toolInputs, hasLength(1));
      expect(toolInputs.single.id, equals('ws_1'));
      expect(toolInputs.single.toolName, equals('web_search'));

      expect(parts.whereType<LLMToolInputEndPart>(), hasLength(1));

      final calls = parts.whereType<LLMProviderToolCallPart>().toList();
      final results = parts.whereType<LLMProviderToolResultPart>().toList();
      expect(calls, hasLength(1));
      expect(results, hasLength(1));
      expect(calls.single.toolCallId, equals('ws_1'));
      expect(calls.single.toolName, equals('web_search'));
      expect(results.single.toolCallId, equals('ws_1'));
      expect(results.single.toolName, equals('web_search'));

      expect(parts.whereType<LLMFinishPart>(), hasLength(1));
      expect(parts.whereType<LLMTextDeltaPart>(), hasLength(1));
    });

    test('emits source-document parts for file citations (AI SDK parity)',
        () async {
      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        useResponsesAPI: true,
      );

      final client = _FakeOpenAIClient(config, const [
        'data: {"type":"response.created","response":{"id":"resp_1","model":"gpt-4o","output":[]}}\n\n',
        'data: {"type":"response.output_text.annotation.added","annotation":{"type":"file_citation","file_id":"file_1","filename":"notes.txt","index":0}}\n\n',
        'data: {"type":"response.output_text.delta","delta":"Hello"}\n\n',
        'data: [DONE]\n\n',
      ]);

      final responses = openai_responses.OpenAIResponses(client, config);
      final parts =
          await responses.chatStreamParts([ChatMessage.user('x')]).toList();

      final docs = parts.whereType<LLMSourceDocumentPart>().toList();
      expect(docs, hasLength(1));

      final doc = docs.single;
      expect(doc.mediaType, equals('text/plain'));
      expect(doc.title, equals('notes.txt'));
      expect(doc.filename, equals('notes.txt'));

      final meta = doc.providerMetadata?['openai'] as Map<String, dynamic>?;
      expect(meta, isNotNull);
      expect(meta!['type'], equals('file_citation'));
      expect(meta['fileId'], equals('file_1'));
      expect(meta['index'], equals(0));
    });

    test('finish part includes usage and finishReason (AI SDK parity)',
        () async {
      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        useResponsesAPI: true,
      );

      final client = _FakeOpenAIClient(config, const [
        'data: {"type":"response.created","response":{"id":"resp_1","model":"gpt-4o","output":[]}}\n\n',
        'data: {"type":"response.output_text.delta","delta":"Hello"}\n\n',
        'data: {"type":"response.completed","response":{"id":"resp_1","model":"gpt-4o","status":"completed","output":[],"usage":{"input_tokens":1,"output_tokens":2,"total_tokens":3}}}\n\n',
        'data: [DONE]\n\n',
      ]);

      final responses = openai_responses.OpenAIResponses(client, config);
      final parts =
          await responses.chatStreamParts([ChatMessage.user('x')]).toList();

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.usage, isNotNull);
      expect(finish.usage!.promptTokens, equals(1));
      expect(finish.usage!.completionTokens, equals(2));
      expect(finish.usage!.totalTokens, equals(3));

      expect(finish.finishReason, isNotNull);
      expect(finish.finishReason!.unified, equals(LLMUnifiedFinishReason.stop));
    });

    test('emits reasoning blocks with itemId-based blockIds (AI SDK parity)',
        () async {
      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-5-mini',
        useResponsesAPI: true,
      );

      final client = _FakeOpenAIClient(config, const [
        'data: {"type":"response.created","response":{"id":"resp_1","model":"gpt-5-mini","output":[]}}\n\n',
        'data: {"type":"response.output_item.added","output_index":0,"item":{"id":"rs_1","type":"reasoning","encrypted_content":"ENC"}}\n\n',
        'data: {"type":"response.reasoning_summary_part.added","item_id":"rs_1","summary_index":0}\n\n',
        'data: {"type":"response.reasoning_summary_text.delta","item_id":"rs_1","summary_index":0,"delta":"A"}\n\n',
        'data: {"type":"response.reasoning_summary_part.done","item_id":"rs_1","summary_index":0}\n\n',
        'data: {"type":"response.reasoning_summary_part.added","item_id":"rs_1","summary_index":1}\n\n',
        'data: {"type":"response.reasoning_summary_text.delta","item_id":"rs_1","summary_index":1,"delta":"B"}\n\n',
        'data: {"type":"response.reasoning_summary_part.done","item_id":"rs_1","summary_index":1}\n\n',
        'data: {"type":"response.completed","response":{"id":"resp_1","model":"gpt-5-mini","status":"completed","output":[]}}\n\n',
        'data: [DONE]\n\n',
      ]);

      final responses = openai_responses.OpenAIResponses(client, config);
      final parts =
          await responses.chatStreamParts([ChatMessage.user('x')]).toList();

      final starts = parts.whereType<LLMReasoningStartPart>().toList();
      expect(starts, hasLength(2));
      expect(starts[0].blockId, equals('rs_1:0'));
      expect(starts[1].blockId, equals('rs_1:1'));

      final startMeta =
          starts[0].providerMetadata?['openai'] as Map<String, dynamic>?;
      expect(startMeta, isNotNull);
      expect(startMeta!['itemId'], equals('rs_1'));
      expect(startMeta['reasoningEncryptedContent'], equals('ENC'));

      final deltas = parts.whereType<LLMReasoningDeltaPart>().toList();
      expect(deltas.map((d) => d.delta).join(), equals('AB'));

      final ends = parts.whereType<LLMReasoningEndPart>().toList();
      expect(ends, hasLength(2));
      expect(ends[0].blockId, equals('rs_1:0'));
      expect(ends[1].blockId, equals('rs_1:1'));
    });
  });
}

class _FakeOpenAIClient extends OpenAIClient {
  final List<String> _chunks;

  _FakeOpenAIClient(super.config, this._chunks);

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async* {
    for (final chunk in _chunks) {
      yield chunk;
    }
  }

  @override
  Future<({Stream<String> stream, Map<String, String> headers})>
      postStreamRawWithHeaders(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async {
    return (
      stream: postStreamRaw(endpoint, body, cancelToken: cancelToken),
      headers: const <String, String>{},
    );
  }
}
