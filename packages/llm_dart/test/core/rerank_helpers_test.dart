import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('rerank helper', () {
    test('returns empty ranking for empty documents', () async {
      final result = await rerank(
        model: 'openai:text-embedding-3-small',
        query: 'test',
        documents: const [],
      );

      expect(result.query, equals('test'));
      expect(result.ranking, isEmpty);
    });

    // Note: end-to-end ranking behavior is covered by provider-specific
    // and integration tests that exercise the embedding providers. This
    // file focuses on the helper wiring and empty-input behavior.
  });
}
