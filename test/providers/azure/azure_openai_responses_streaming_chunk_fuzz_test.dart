import 'dart:convert';
import 'dart:math';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai_compatible/responses.dart' as openai_responses;
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';

String _sseData(Map<String, dynamic> json) => 'data: ${jsonEncode(json)}\n\n';

List<String> _splitRandom(String input, {required int seed, int maxLen = 11}) {
  final random = Random(seed);
  final chunks = <String>[];
  var i = 0;
  while (i < input.length) {
    final remaining = input.length - i;
    final size = min(remaining, 1 + random.nextInt(maxLen));
    chunks.add(input.substring(i, i + size));
    i += size;
  }
  return chunks;
}

void main() {
  group('Azure OpenAI Responses streaming fuzz (chunk boundaries)', () {
    test('buffers tool-input deltas that arrive before output_item.added',
        () async {
      const baseUrl = 'https://example.azure.com/openai/';
      const model = 'gpt-4.1-mini';

      final config = AzureOpenAIConfig(
        apiKey: 'test-key',
        baseUrl: baseUrl,
        model: model,
        useResponsesAPI: true,
        originalConfig: LLMConfig(
          baseUrl: baseUrl,
          model: model,
          providerTools: const [
            ProviderTool(
              id: 'azure.code_interpreter',
              name: 'codeExecution',
            ),
          ],
        ),
      );

      final toolId = 'ci_early_az';
      final code = 'print("hi")\n';

      final sse = [
        _sseData({
          'type': 'response.created',
          'response': {
            'id': 'resp_order_fuzz_az',
            'model': model,
            'status': 'in_progress',
            'created_at': 1739145600,
            'output': [],
          },
        }),

        // Out-of-order: tool input deltas arrive before output item metadata.
        _sseData({
          'type': 'response.code_interpreter_call_code.delta',
          'output_index': 0,
          'item_id': toolId,
          'delta': code,
        }),

        _sseData({
          'type': 'response.output_item.added',
          'output_index': 0,
          'item': {
            'id': toolId,
            'type': 'code_interpreter_call',
            'status': 'in_progress',
            'code': '',
            'container_id': 'cntr_az_1',
            'outputs': const [],
          },
        }),

        _sseData({
          'type': 'response.output_item.done',
          'output_index': 0,
          'item': {
            'id': toolId,
            'type': 'code_interpreter_call',
            'status': 'completed',
            'code': code,
            'container_id': 'cntr_az_1',
            'outputs': const [],
          },
        }),

        _sseData({
          'type': 'response.completed',
          'response': {
            'id': 'resp_order_fuzz_az',
            'model': model,
            'status': 'completed',
            'created_at': 1739145600,
            'usage': {
              'input_tokens': 10,
              'output_tokens': 5,
              'total_tokens': 15,
            },
            'output': [
              {
                'id': toolId,
                'type': 'code_interpreter_call',
                'status': 'completed',
                'code': code,
                'container_id': 'cntr_az_1',
                'outputs': const [],
              },
            ],
          },
        }),
        'data: [DONE]\n\n',
      ].join();

      for (final seed in [5, 13, 21]) {
        final client = FakeOpenAIClient(config)
          ..streamResponse =
              Stream<String>.fromIterable(_splitRandom(sse, seed: seed));
        final responses = openai_responses.OpenAIResponses(client, config);

        final parts =
            await responses.chatStreamParts([ChatMessage.user('Hi')]).toList();

        final starts = parts.whereType<LLMToolInputStartPart>().toList();
        final deltas = parts.whereType<LLMToolInputDeltaPart>().toList();
        final ends = parts.whereType<LLMToolInputEndPart>().toList();

        expect(starts.map((p) => p.id).toSet(), contains(toolId));
        expect(ends.map((p) => p.id).toSet(), contains(toolId));

        final startIndex = parts
            .indexWhere((p) => p is LLMToolInputStartPart && p.id == toolId);
        expect(startIndex, isNonNegative);
        for (final d in deltas.where((p) => p.id == toolId)) {
          expect(parts.indexOf(d), greaterThan(startIndex));
        }

        final providerCalls =
            parts.whereType<LLMProviderToolCallPart>().toList();
        final call = providerCalls.singleWhere((p) => p.toolCallId == toolId);
        expect(call.toolName, equals('codeExecution'));
        expect(call.providerExecuted, isTrue);
        expect(call.input, isA<String>());
        expect(call.input as String, contains('"code"'));
        expect(call.input as String, contains('print'));
      }
    });
  });
}
