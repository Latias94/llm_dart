import 'dart:io';
import 'dart:math' as math;

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/google.dart';

/// Google Embeddings Examples
///
/// This example demonstrates how to use Google's text embedding models
/// through the unified EmbeddingCapability interface.
///
/// Google provides high-quality text embeddings through the Gemini API
/// with models like text-embedding-004.
Future<void> main() async {
  print('🔢 Google Embeddings Examples\n');

  final apiKey = Platform.environment['GOOGLE_GENERATIVE_AI_API_KEY'] ??
      Platform.environment['GOOGLE_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print(
      '⚠️  Skipped: Please set GOOGLE_GENERATIVE_AI_API_KEY (recommended) or GOOGLE_API_KEY',
    );
    return;
  }

  final google = createGoogleGenerativeAI(apiKey: apiKey);

  await demonstrateBasicEmbeddings(google);
  await demonstrateBatchEmbeddings(google);
  await demonstrateEmbeddingParameters(google);
  await demonstrateSemanticSimilarity(google);

  print('\n✅ Google embeddings examples completed!');
}

/// Demonstrate basic embedding generation
Future<void> demonstrateBasicEmbeddings(GoogleProviderV3 google) async {
  print('📊 Basic Embeddings:');

  try {
    // Single text embedding
    final singleResponse = await embedMany(
      model: google.embeddingModel('text-embedding-004'),
      values: ['Hello, world!'],
    );
    print(
        '   ✅ Single embedding: ${singleResponse.embeddings.first.length} dimensions');

    // Multiple texts
    final multipleResponse = await embedMany(
      model: google.embeddingModel('text-embedding-004'),
      values: [
        'The quick brown fox jumps over the lazy dog',
        'Machine learning is transforming technology',
        'Google provides powerful embedding models',
      ],
    );
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
Future<void> demonstrateBatchEmbeddings(GoogleProviderV3 google) async {
  print('📦 Batch Processing:');

  try {
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

    final response = await embedMany(
      model: google.embeddingModel('text-embedding-004'),
      values: texts,
    );
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
Future<void> demonstrateEmbeddingParameters(GoogleProviderV3 google) async {
  print('⚙️  Google-Specific Parameters:');

  try {
    final response = await embedMany(
      model: google.embeddingModel('text-embedding-004'),
      values: [
        'Document for semantic similarity',
        'Another document for comparison',
      ],
      callOptions: const LLMCallOptions(
        body: {
          'taskType': 'SEMANTIC_SIMILARITY',
          'outputDimensionality': 512,
        },
      ),
    );

    print('   ✅ Task-specific embeddings generated');
    print('   📏 Reduced dimensions: ${response.embeddings.first.length}');

    final docResponse = await embedMany(
      model: google.embeddingModel('text-embedding-004'),
      values: [
        'This is a technical document about machine learning algorithms.',
      ],
      callOptions: const LLMCallOptions(
        body: {
          'taskType': 'RETRIEVAL_DOCUMENT',
          'title': 'Technical Documentation',
        },
      ),
    );

    print(
        '   ✅ Retrieval embeddings with title: ${docResponse.embeddings.first.length} dimensions');
  } catch (e) {
    print('   ❌ Parameter demonstration failed: $e');
  }

  print('');
}

/// Demonstrate semantic similarity calculations
Future<void> demonstrateSemanticSimilarity(GoogleProviderV3 google) async {
  print('🎯 Semantic Similarity:');

  try {
    final texts = [
      'The cat sat on the mat',
      'A feline rested on the rug',
      'Dogs are loyal pets',
      'Machine learning algorithms',
    ];

    final response = await embedMany(
      model: google.embeddingModel('text-embedding-004'),
      values: texts,
      callOptions: const LLMCallOptions(
        body: {'taskType': 'SEMANTIC_SIMILARITY'},
      ),
    );
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
