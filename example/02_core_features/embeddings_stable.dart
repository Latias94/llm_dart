import 'package:llm_dart/ai.dart' as llm;
import 'package:llm_dart/core.dart' as core;

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
