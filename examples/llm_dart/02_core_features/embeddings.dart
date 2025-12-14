import 'dart:math';
import 'package:llm_dart/llm_dart.dart';

/// Comprehensive embeddings examples using the unified EmbeddingCapability interface
///
/// This example demonstrates:
/// - Basic text embedding generation
/// - Batch embedding processing
/// - Similarity calculations
/// - Semantic search implementation
/// - Provider capability detection
/// - Error handling for embedding operations
Future<void> main() async {
  print('🔢 Vector Embeddings Examples\n');

  // Example with multiple providers that support embeddings
  final providers = [
    (
      'OpenAI',
      () => ai()
          .openai()
          .apiKey('your-openai-key')
          .model('text-embedding-3-small')
    ),
    (
      'Google',
      () => ai().google().apiKey('your-google-key').model('text-embedding-004')
    ),
    ('Ollama', () => ai().ollama().model('nomic-embed-text')),
  ];

  for (final (name, builderFactory) in providers) {
    print('📊 Testing $name Embeddings:');

    try {
      final provider = await builderFactory().buildEmbedding();
      await demonstrateEmbeddingFeatures(provider, name);
    } catch (e) {
      print('   ❌ Failed to initialize $name: $e\n');
    }
  }

  print('✅ Embeddings examples completed!');
  print('💡 For provider-specific optimizations, see:');
  print('   • example/04_providers/openai/embeddings.dart');
  print('   • example/04_providers/google/embeddings.dart');
}

/// Demonstrate various embedding features with a provider
Future<void> demonstrateEmbeddingFeatures(
    EmbeddingCapability provider, String providerName) async {
  // Basic embedding generation
  await demonstrateBasicEmbeddings(provider, providerName);

  // Batch processing
  await demonstrateBatchEmbeddings(provider, providerName);

  // Similarity calculations
  await demonstrateSimilarityCalculations(provider, providerName);

  // Semantic search
  await demonstrateSemanticSearch(provider, providerName);

  // Document clustering
  await demonstrateDocumentClustering(provider, providerName);

  print('');
}

/// Demonstrate basic embedding generation
Future<void> demonstrateBasicEmbeddings(
    EmbeddingCapability provider, String providerName) async {
  print('   🔤 Basic Embeddings:');

  try {
    // Single text embedding
    final singleText = ['Hello, world! This is a test sentence for embedding.'];
    final singleEmbedding = await provider.embed(singleText);

    print('      ✅ Single embedding: ${singleEmbedding[0].length} dimensions');
    print(
        '      📊 Sample values: ${singleEmbedding[0].take(5).map((v) => v.toStringAsFixed(4)).join(', ')}...');

    // Multiple texts
    final multipleTexts = [
      'The quick brown fox jumps over the lazy dog.',
      'Machine learning is a subset of artificial intelligence.',
      'The weather is beautiful today.',
    ];

    final multipleEmbeddings = await provider.embed(multipleTexts);

    print(
        '      ✅ Multiple embeddings: ${multipleEmbeddings.length} texts processed');
    for (int i = 0; i < multipleEmbeddings.length; i++) {
      print(
          '         Text ${i + 1}: ${multipleEmbeddings[i].length} dimensions');
    }
  } catch (e) {
    print('      ❌ Basic embeddings failed: $e');
  }
}

/// Demonstrate batch embedding processing
Future<void> demonstrateBatchEmbeddings(
    EmbeddingCapability provider, String providerName) async {
  print('   📦 Batch Processing:');

  try {
    // Large batch of texts
    final batchTexts = [
      'Artificial intelligence is transforming industries.',
      'Machine learning algorithms learn from data.',
      'Deep learning uses neural networks.',
      'Natural language processing handles text.',
      'Computer vision analyzes images.',
      'Robotics combines AI with physical systems.',
      'Data science extracts insights from data.',
      'Cloud computing provides scalable resources.',
      'Cybersecurity protects digital assets.',
      'Blockchain ensures data integrity.',
    ];

    print('      🔄 Processing ${batchTexts.length} texts in batch...');
    final startTime = DateTime.now();

    final batchEmbeddings = await provider.embed(batchTexts);

    final duration = DateTime.now().difference(startTime);
    print('      ✅ Batch completed in ${duration.inMilliseconds}ms');
    print(
        '      📊 Average: ${(duration.inMilliseconds / batchTexts.length).toStringAsFixed(1)}ms per text');
    print('      🔢 Dimensions: ${batchEmbeddings.first.length}');

    // Calculate batch statistics
    final allValues = batchEmbeddings.expand((e) => e).toList();
    final mean = allValues.reduce((a, b) => a + b) / allValues.length;
    final variance =
        allValues.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
            allValues.length;

    print(
        '      📈 Statistics: mean=${mean.toStringAsFixed(4)}, std=${sqrt(variance).toStringAsFixed(4)}');
  } catch (e) {
    print('      ❌ Batch processing failed: $e');
  }
}

/// Demonstrate similarity calculations
Future<void> demonstrateSimilarityCalculations(
    EmbeddingCapability provider, String providerName) async {
  print('   🎯 Similarity Calculations:');

  try {
    // Test texts with varying similarity
    final testTexts = [
      'I love programming in Dart.', // Reference
      'Dart programming is enjoyable.', // Similar
      'Python is a great language.', // Somewhat similar
      'The weather is sunny today.', // Different
    ];

    final embeddings = await provider.embed(testTexts);
    final referenceEmbedding = embeddings[0];

    print('      📝 Reference: "${testTexts[0]}"');
    print('      🔍 Similarities:');

    for (int i = 1; i < testTexts.length; i++) {
      final similarity =
          EmbeddingUtils.cosineSimilarity(referenceEmbedding, embeddings[i]);
      final similarityPercent = (similarity * 100).toStringAsFixed(1);

      print(
          '         ${_getSimilarityIcon(similarity)} "${testTexts[i]}" - $similarityPercent%');
    }

    // Find most similar pair
    double maxSimilarity = -1;
    int bestI = 0, bestJ = 0;

    for (int i = 0; i < embeddings.length; i++) {
      for (int j = i + 1; j < embeddings.length; j++) {
        final similarity =
            EmbeddingUtils.cosineSimilarity(embeddings[i], embeddings[j]);
        if (similarity > maxSimilarity) {
          maxSimilarity = similarity;
          bestI = i;
          bestJ = j;
        }
      }
    }

    print(
        '      🏆 Most similar pair (${(maxSimilarity * 100).toStringAsFixed(1)}%):');
    print('         "${testTexts[bestI]}"');
    print('         "${testTexts[bestJ]}"');
  } catch (e) {
    print('      ❌ Similarity calculations failed: $e');
  }
}

/// Demonstrate semantic search
Future<void> demonstrateSemanticSearch(
    EmbeddingCapability provider, String providerName) async {
  print('   🔍 Semantic Search:');

  try {
    // Document corpus
    final documents = [
      'Machine learning algorithms can learn patterns from data without explicit programming.',
      'Deep learning is a subset of machine learning that uses neural networks with multiple layers.',
      'Natural language processing enables computers to understand and generate human language.',
      'Computer vision allows machines to interpret and analyze visual information from images.',
      'Artificial intelligence aims to create systems that can perform tasks requiring human intelligence.',
      'Data science combines statistics, programming, and domain expertise to extract insights.',
      'Cloud computing provides on-demand access to computing resources over the internet.',
      'Cybersecurity focuses on protecting digital systems from threats and attacks.',
      'The weather forecast predicts rain for tomorrow afternoon.',
      'Cooking pasta requires boiling water and adding salt for flavor.',
    ];

    // Create document embeddings
    print('      🔄 Creating document index...');
    final documentEmbeddings = await provider.embed(documents);

    // Search queries
    final queries = [
      'neural networks and deep learning',
      'understanding human language',
      'cooking food',
    ];

    for (final query in queries) {
      print('      🔎 Query: "$query"');

      final queryEmbedding = await provider.embed([query]);
      final results = SemanticSearchEngine.search(
        queryEmbedding[0],
        documentEmbeddings,
        documents,
        topK: 3,
      );

      print('         📋 Top results:');
      for (int i = 0; i < results.length; i++) {
        final result = results[i];
        final score = (result.score * 100).toStringAsFixed(1);
        print(
            '         ${i + 1}. [$score%] ${result.text.substring(0, 60)}...');
      }
      print('');
    }
  } catch (e) {
    print('      ❌ Semantic search failed: $e');
  }
}

/// Demonstrate document clustering
Future<void> demonstrateDocumentClustering(
    EmbeddingCapability provider, String providerName) async {
  print('   🗂️  Document Clustering:');

  try {
    // Documents from different topics
    final documents = [
      // Technology cluster
      'Artificial intelligence is revolutionizing technology.',
      'Machine learning algorithms improve with more data.',
      'Software development requires careful planning.',

      // Food cluster
      'Italian cuisine features pasta and pizza.',
      'French cooking emphasizes technique and flavor.',
      'Asian food includes rice and noodles.',

      // Sports cluster
      'Football is popular in many countries.',
      'Basketball requires teamwork and skill.',
      'Tennis is an individual sport.',
    ];

    final embeddings = await provider.embed(documents);

    // Simple clustering using similarity threshold
    final clusters = DocumentClusterer.clusterBySimilarity(
      embeddings,
      documents,
      threshold: 0.3,
    );

    print('      📊 Found ${clusters.length} clusters:');
    for (int i = 0; i < clusters.length; i++) {
      final cluster = clusters[i];
      print('         Cluster ${i + 1} (${cluster.length} documents):');
      for (final doc in cluster) {
        print('           • ${doc.substring(0, 40)}...');
      }
    }
  } catch (e) {
    print('      ❌ Document clustering failed: $e');
  }
}

/// Get similarity icon based on score
String _getSimilarityIcon(double similarity) {
  if (similarity > 0.8) return '🟢';
  if (similarity > 0.6) return '🟡';
  if (similarity > 0.4) return '🟠';
  return '🔴';
}

/// Utility class for embedding operations
class EmbeddingUtils {
  /// Calculate cosine similarity between two vectors
  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Vectors must have the same length');
    }

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// Calculate Euclidean distance between two vectors
  static double euclideanDistance(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Vectors must have the same length');
    }

    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      sum += diff * diff;
    }

    return sqrt(sum);
  }

  /// Normalize a vector to unit length
  static List<double> normalize(List<double> vector) {
    final norm = sqrt(vector.map((v) => v * v).reduce((a, b) => a + b));
    if (norm == 0.0) return vector;
    return vector.map((v) => v / norm).toList();
  }
}

/// Search result for semantic search
class SearchResult {
  final String text;
  final double score;
  final int index;

  SearchResult(this.text, this.score, this.index);
}

/// Simple semantic search engine
class SemanticSearchEngine {
  /// Search for similar documents
  static List<SearchResult> search(List<double> queryEmbedding,
      List<List<double>> documentEmbeddings, List<String> documents,
      {int topK = 5}) {
    final results = <SearchResult>[];

    for (int i = 0; i < documentEmbeddings.length; i++) {
      final similarity = EmbeddingUtils.cosineSimilarity(
        queryEmbedding,
        documentEmbeddings[i],
      );
      results.add(SearchResult(documents[i], similarity, i));
    }

    // Sort by similarity (descending)
    results.sort((a, b) => b.score.compareTo(a.score));

    return results.take(topK).toList();
  }
}

/// Simple document clustering
class DocumentClusterer {
  /// Cluster documents by similarity threshold
  static List<List<String>> clusterBySimilarity(
      List<List<double>> embeddings, List<String> documents,
      {double threshold = 0.5}) {
    final clusters = <List<String>>[];
    final assigned = List<bool>.filled(documents.length, false);

    for (int i = 0; i < documents.length; i++) {
      if (assigned[i]) continue;

      final cluster = [documents[i]];
      assigned[i] = true;

      for (int j = i + 1; j < documents.length; j++) {
        if (assigned[j]) continue;

        final similarity = EmbeddingUtils.cosineSimilarity(
          embeddings[i],
          embeddings[j],
        );

        if (similarity >= threshold) {
          cluster.add(documents[j]);
          assigned[j] = true;
        }
      }

      clusters.add(cluster);
    }

    return clusters;
  }
}
