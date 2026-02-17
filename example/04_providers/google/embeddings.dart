import 'dart:io';
import 'dart:math' as math;

import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_google/llm_dart_google.dart';

/// Google Embeddings Examples
///
/// This example demonstrates how to use Google's text embedding models
/// through the unified EmbeddingCapability interface.
///
/// Google provides high-quality text embeddings through the Gemini API
/// with models like text-embedding-004.
Future<void> main() async {
  print('🔢 Google Embeddings Examples\n');

  registerGoogle();

  final apiKey = Platform.environment['GOOGLE_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('⚠️  Skipped: Please set GOOGLE_API_KEY environment variable');
    return;
  }

  await demonstrateBasicEmbeddings(apiKey);
  await demonstrateBatchEmbeddings(apiKey);
  await demonstrateEmbeddingParameters(apiKey);
  await demonstrateSemanticSimilarity(apiKey);

  print('\n✅ Google embeddings examples completed!');
}

/// Demonstrate basic embedding generation
Future<void> demonstrateBasicEmbeddings(String apiKey) async {
  print('📊 Basic Embeddings:');

  try {
    final provider = await LLMBuilder()
        .provider(googleProviderId)
        .apiKey(apiKey)
        .model('text-embedding-004')
        .buildEmbedding();

    // Single text embedding
    final singleResponse = await provider.embed(['Hello, world!']);
    print(
        '   ✅ Single embedding: ${singleResponse.embeddings.first.length} dimensions');

    // Multiple texts
    final multipleResponse = await provider.embed([
      'The quick brown fox jumps over the lazy dog',
      'Machine learning is transforming technology',
      'Google provides powerful embedding models',
    ]);
    final multipleEmbeddings = multipleResponse.embeddings;

    print(
        '   ✅ Multiple embeddings: ${multipleEmbeddings.length} texts processed');
    for (int i = 0; i < multipleEmbeddings.length; i++) {
      print('      Text ${i + 1}: ${multipleEmbeddings[i].length} dimensions');
    }
  } catch (e) {
    print('   ❌ Basic embeddings failed: $e');
  }

  print('');
}

/// Demonstrate batch embedding processing
Future<void> demonstrateBatchEmbeddings(String apiKey) async {
  print('📦 Batch Processing:');

  try {
    final provider = await LLMBuilder()
        .provider(googleProviderId)
        .apiKey(apiKey)
        .model('text-embedding-004')
        .buildEmbedding();

    // Large batch of texts
    final texts = [
      'Artificial intelligence is revolutionizing industries',
      'Natural language processing enables human-computer interaction',
      'Deep learning models can understand complex patterns',
      'Vector embeddings capture semantic meaning',
      'Google\'s embedding models provide high-quality representations',
      'Text similarity can be computed using cosine distance',
      'Semantic search improves information retrieval',
      'Machine learning requires large datasets for training',
    ];

    final response = await provider.embed(texts);
    final embeddings = response.embeddings;
    print('   ✅ Batch processing: ${embeddings.length} embeddings generated');
    print('   📏 Embedding dimensions: ${embeddings.first.length}');

    // Calculate some statistics
    final allValues = embeddings.expand((e) => e).toList();
    final mean = allValues.reduce((a, b) => a + b) / allValues.length;
    final variance =
        allValues.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
            allValues.length;

    print('   📈 Statistics: mean=${mean.toStringAsFixed(4)}, '
        'std=${math.sqrt(variance).toStringAsFixed(4)}');
  } catch (e) {
    print('   ❌ Batch processing failed: $e');
  }

  print('');
}

/// Demonstrate Google-specific embedding parameters
Future<void> demonstrateEmbeddingParameters(String apiKey) async {
  print('⚙️  Google-Specific Parameters:');

  try {
    // Using task type for better embeddings
    final provider = await LLMBuilder()
        .provider(googleProviderId)
        .apiKey(apiKey)
        .model('text-embedding-004')
        .option('embeddingTaskType', 'SEMANTIC_SIMILARITY')
        .option('embeddingDimensions', 512) // Reduced dimensions
        .buildEmbedding();

    final response = await provider.embed([
      'Document for semantic similarity',
      'Another document for comparison',
    ]);

    print('   ✅ Task-specific embeddings generated');
    print('   📏 Reduced dimensions: ${response.embeddings.first.length}');

    // For retrieval tasks
    final retrievalProvider = await LLMBuilder()
        .provider(googleProviderId)
        .apiKey(apiKey)
        .model('text-embedding-004')
        .option('embeddingTaskType', 'RETRIEVAL_DOCUMENT')
        .option('embeddingTitle', 'Technical Documentation')
        .buildEmbedding();

    final docResponse = await retrievalProvider.embed([
      'This is a technical document about machine learning algorithms.',
    ]);

    print(
        '   ✅ Retrieval embeddings with title: ${docResponse.embeddings.first.length} dimensions');
  } catch (e) {
    print('   ❌ Parameter demonstration failed: $e');
  }

  print('');
}

/// Demonstrate semantic similarity calculations
Future<void> demonstrateSemanticSimilarity(String apiKey) async {
  print('🎯 Semantic Similarity:');

  try {
    final provider = await LLMBuilder()
        .provider(googleProviderId)
        .apiKey(apiKey)
        .model('text-embedding-004')
        .option('embeddingTaskType', 'SEMANTIC_SIMILARITY')
        .buildEmbedding();

    final texts = [
      'The cat sat on the mat',
      'A feline rested on the rug',
      'Dogs are loyal pets',
      'Machine learning algorithms',
    ];

    final response = await provider.embed(texts);
    final embeddings = response.embeddings;

    print('   📊 Similarity Matrix:');
    print(
        '      ${texts.map((t) => t.substring(0, 15).padRight(15)).join(' | ')}');
    print('      ${'-' * (15 * texts.length + (texts.length - 1) * 3)}');

    for (int i = 0; i < texts.length; i++) {
      final row = <String>[];
      for (int j = 0; j < texts.length; j++) {
        final similarity = cosineSimilarity(embeddings[i], embeddings[j]);
        row.add(similarity.toStringAsFixed(3).padLeft(15));
      }
      print('      ${row.join(' | ')}');
    }

    // Find most similar pair
    double maxSimilarity = 0;
    int bestI = 0, bestJ = 0;
    for (int i = 0; i < texts.length; i++) {
      for (int j = i + 1; j < texts.length; j++) {
        final similarity = cosineSimilarity(embeddings[i], embeddings[j]);
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
  } catch (e) {
    print('   ❌ Similarity calculation failed: $e');
  }
}

/// Calculate cosine similarity between two vectors
double cosineSimilarity(List<double> a, List<double> b) {
  if (a.length != b.length) {
    throw ArgumentError('Vectors must have the same length');
  }

  double dotProduct = 0;
  double normA = 0;
  double normB = 0;

  for (int i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }

  if (normA == 0 || normB == 0) {
    return 0;
  }

  return dotProduct / (normA.sqrt() * normB.sqrt());
}

extension on double {
  double sqrt() => math.sqrt(this);
}
