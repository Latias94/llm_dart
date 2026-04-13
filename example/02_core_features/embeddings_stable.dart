import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;

Future<void> main() async {
  final model = llm.AI
      .openai(
        apiKey: 'your-openai-key',
      )
      .embeddingModel('text-embedding-3-small');

  final single = await core.embed(
    model: model,
    value: 'Dart is optimized for client apps.',
  );

  print('singleDimensions=${single.embedding.length}');

  final batch = await core.embedMany(
    model: model,
    values: const [
      'Flutter renders with widgets.',
      'Embeddings help semantic retrieval.',
    ],
  );

  print('batchCount=${batch.embeddings.length}');
}
