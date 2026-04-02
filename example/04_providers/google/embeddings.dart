import 'dart:io';
import 'dart:math' as math;

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/google.dart' as google;
import 'package:llm_dart/ai.dart' as llm;

/// Google Embeddings Examples
///
/// This example demonstrates the stable Google embedding-model surface.
Future<void> main() async {
  print('🔢 Google Embeddings Examples\n');

  final apiKey = Platform.environment['GOOGLE_API_KEY'];
  if (apiKey == null) {
    print('❌ Please set GOOGLE_API_KEY environment variable');
    return;
  }

  await demonstrateBasicEmbeddings(apiKey);
  await demonstrateBatchEmbeddings(apiKey);
  await demonstrateEmbeddingParameters(apiKey);
  await demonstrateSemanticSimilarity(apiKey);

  print('\n✅ Google embeddings examples completed!');
}

Future<void> demonstrateBasicEmbeddings(String apiKey) async {
  print('📊 Basic Embeddings:');

  try {
    final model = _createEmbeddingModel(apiKey);

    final singleEmbedding = await core.embed(
      model: model,
      value: 'Hello, world!',
    );
    print(
        '   ✅ Single embedding: ${singleEmbedding.embedding.length} dimensions');

    final multipleEmbeddings = await core.embedMany(
      model: model,
      values: const [
        'The quick brown fox jumps over the lazy dog',
        'Machine learning is transforming technology',
        'Google provides powerful embedding models',
      ],
    );

    print(
      '   ✅ Multiple embeddings: ${multipleEmbeddings.embeddings.length} texts processed',
    );
    for (var index = 0; index < multipleEmbeddings.embeddings.length; index++) {
      print(
        '      Text ${index + 1}: ${multipleEmbeddings.embeddings[index].length} dimensions',
      );
    }
  } catch (error) {
    print('   ❌ Basic embeddings failed: $error');
  }

  print('');
}

Future<void> demonstrateBatchEmbeddings(String apiKey) async {
  print('📦 Batch Processing:');

  try {
    final model = _createEmbeddingModel(apiKey);
    final texts = const [
      'Artificial intelligence is revolutionizing industries',
      'Natural language processing enables human-computer interaction',
      'Deep learning models can understand complex patterns',
      'Vector embeddings capture semantic meaning',
      'Google\'s embedding models provide high-quality representations',
      'Text similarity can be computed using cosine distance',
      'Semantic search improves information retrieval',
      'Machine learning requires large datasets for training',
    ];

    final embeddings = await core.embedMany(
      model: model,
      values: texts,
    );
    print(
        '   ✅ Batch processing: ${embeddings.embeddings.length} embeddings generated');
    print('   📏 Embedding dimensions: ${embeddings.embeddings.first.length}');

    final allValues = embeddings.embeddings.expand((entry) => entry).toList();
    final mean = allValues.reduce((a, b) => a + b) / allValues.length;
    final variance = allValues
            .map((value) => (value - mean) * (value - mean))
            .reduce((a, b) => a + b) /
        allValues.length;

    print(
      '   📈 Statistics: mean=${mean.toStringAsFixed(4)}, std=${math.sqrt(variance).toStringAsFixed(4)}',
    );
  } catch (error) {
    print('   ❌ Batch processing failed: $error');
  }

  print('');
}

Future<void> demonstrateEmbeddingParameters(String apiKey) async {
  print('⚙️  Google-Specific Parameters:');

  try {
    final model = _createEmbeddingModel(apiKey);

    final similarityEmbedding = await core.embed(
      model: model,
      value: 'Document for semantic similarity',
      dimensions: 512,
      callOptions: const core.CallOptions(
        providerOptions: google.GoogleEmbedOptions(
          taskType: 'SEMANTIC_SIMILARITY',
        ),
      ),
    );

    print('   ✅ Task-specific embedding generated');
    print('   📏 Reduced dimensions: ${similarityEmbedding.embedding.length}');

    final retrievalEmbeddings = await core.embedMany(
      model: model,
      values: const [
        'This is a technical document about machine learning algorithms.',
      ],
      callOptions: const core.CallOptions(
        providerOptions: google.GoogleEmbedOptions(
          taskType: 'RETRIEVAL_DOCUMENT',
          title: 'Technical Documentation',
        ),
      ),
    );

    print(
      '   ✅ Retrieval embeddings with title: ${retrievalEmbeddings.embeddings.first.length} dimensions',
    );
  } catch (error) {
    print('   ❌ Parameter demonstration failed: $error');
  }

  print('');
}

Future<void> demonstrateSemanticSimilarity(String apiKey) async {
  print('🎯 Semantic Similarity:');

  try {
    final model = _createEmbeddingModel(apiKey);
    const texts = [
      'The cat sat on the mat',
      'A feline rested on the rug',
      'Dogs are loyal pets',
      'Machine learning algorithms',
    ];

    final result = await core.embedMany(
      model: model,
      values: texts,
      callOptions: const core.CallOptions(
        providerOptions: google.GoogleEmbedOptions(
          taskType: 'SEMANTIC_SIMILARITY',
        ),
      ),
    );

    print('   📊 Similarity Matrix:');
    print(
      '      ${texts.map((text) => text.substring(0, 15).padRight(15)).join(' | ')}',
    );
    print('      ${'-' * (15 * texts.length + (texts.length - 1) * 3)}');

    for (var rowIndex = 0; rowIndex < texts.length; rowIndex++) {
      final row = <String>[];
      for (var columnIndex = 0; columnIndex < texts.length; columnIndex++) {
        final similarity = cosineSimilarity(
          result.embeddings[rowIndex],
          result.embeddings[columnIndex],
        );
        row.add(similarity.toStringAsFixed(3).padLeft(15));
      }
      print('      ${row.join(' | ')}');
    }

    var maxSimilarity = 0.0;
    var bestI = 0;
    var bestJ = 0;
    for (var i = 0; i < texts.length; i++) {
      for (var j = i + 1; j < texts.length; j++) {
        final similarity =
            cosineSimilarity(result.embeddings[i], result.embeddings[j]);
        if (similarity > maxSimilarity) {
          maxSimilarity = similarity;
          bestI = i;
          bestJ = j;
        }
      }
    }

    print('   🏆 Most similar pair (${maxSimilarity.toStringAsFixed(3)}):');
    print('      "${texts[bestI]}"');
    print('      "${texts[bestJ]}"');
  } catch (error) {
    print('   ❌ Similarity calculation failed: $error');
  }
}

core.EmbeddingModel _createEmbeddingModel(String apiKey) {
  return llm.AI
      .google(
        apiKey: apiKey,
      )
      .embeddingModel('text-embedding-004');
}

double cosineSimilarity(List<double> a, List<double> b) {
  if (a.length != b.length) {
    throw ArgumentError('Vectors must have the same length');
  }

  var dotProduct = 0.0;
  var normA = 0.0;
  var normB = 0.0;

  for (var index = 0; index < a.length; index++) {
    dotProduct += a[index] * b[index];
    normA += a[index] * a[index];
    normB += b[index] * b[index];
  }

  if (normA == 0 || normB == 0) {
    return 0;
  }

  return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
}
