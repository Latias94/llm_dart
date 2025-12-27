import 'package:test/test.dart';

import 'package:llm_dart/llm_dart.dart';

class _FakeEmbeddingModel implements EmbeddingCapability {
  final List<List<double>> vectors;

  _FakeEmbeddingModel(this.vectors);

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancelToken? cancelToken,
  }) async {
    return vectors;
  }
}

void main() {
  group('rerankByEmbedding', () {
    test('ranks documents by cosine similarity', () async {
      // query + 3 docs
      final model = _FakeEmbeddingModel([
        [1, 0], // query
        [1, 0], // doc0: cosine=1.0
        [0.8, 0.6], // doc1: cosine=0.8
        [0, 1], // doc2: cosine=0.0
      ]);

      final result = await rerankByEmbedding(
        model: model,
        query: 'q',
        documents: const [
          RerankDocument(text: 'a'),
          RerankDocument(text: 'b'),
          RerankDocument(text: 'c'),
        ],
      );

      expect(result.results.map((r) => r.index).toList(), [0, 1, 2]);
      expect(result.results.first.score, closeTo(1.0, 1e-9));
    });

    test('applies topK', () async {
      final model = _FakeEmbeddingModel([
        [1, 0], // query
        [1, 0], // doc0
        [0, 1], // doc1
      ]);

      final result = await rerankByEmbedding(
        model: model,
        query: 'q',
        documents: const [
          RerankDocument(text: 'a'),
          RerankDocument(text: 'b'),
        ],
        topK: 1,
      );

      expect(result.results, hasLength(1));
      expect(result.results.single.index, equals(0));
    });
  });

  group('EmbeddingRerankAdapter', () {
    test('implements RerankCapability via embeddings', () async {
      final model = _FakeEmbeddingModel([
        [1, 0], // query
        [0, 1], // doc0
        [1, 0], // doc1
      ]);

      final reranker = EmbeddingRerankAdapter(model);
      final response = await reranker.rerank(
        const RerankRequest(
          query: 'q',
          documents: [
            RerankDocument(text: 'a'),
            RerankDocument(text: 'b'),
          ],
          topK: 1,
        ),
      );

      expect(response.results, hasLength(1));
      expect(response.results.single.index, equals(1));
    });
  });
}

