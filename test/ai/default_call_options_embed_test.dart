import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _CapturingCallOptionsEmbeddingModel
    implements EmbeddingCallOptionsCapability, EmbeddingCapability {
  LLMCallOptions? lastCallOptions;

  @override
  Future<EmbeddingResponse> embed(
    List<String> input, {
    CancelToken? cancelToken,
  }) {
    throw StateError('embed should not be used in this test.');
  }

  @override
  Future<EmbeddingResponse> embedWithCallOptions(
    List<String> input, {
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async {
    lastCallOptions = callOptions;
    return const EmbeddingResponse(
      embeddings: [
        [0.0, 1.0],
      ],
    );
  }
}

void main() {
  group('embed defaultCallOptions', () {
    test('uses defaultCallOptions when per-call callOptions is empty',
        () async {
      final model = _CapturingCallOptionsEmbeddingModel();

      final result = await embedMany(
        model: model,
        values: const ['hi'],
        defaultCallOptions: const LLMCallOptions(headers: {'X-Test': 'a'}),
      );

      expect(result.embeddings, hasLength(1));
      expect(model.lastCallOptions, isNotNull);
      expect(model.lastCallOptions!.headers, equals({'X-Test': 'a'}));
    });
  });
}
