// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math' as math;

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart_ollama/llm_dart_ollama.dart' as ollama_pkg;

/// Stable shared embeddings example across multiple provider families.
///
/// This example demonstrates:
/// - shared `embed(...)` and `embedMany(...)` helpers
/// - model creation through stable provider/model factories
/// - semantic similarity and search without the legacy builder surface
Future<void> main() async {
  print('Stable embeddings examples\n');

  final models = _collectEmbeddingModels();
  if (models.isEmpty) {
    print('No embedding models are configured.');
    print('Set OPENAI_API_KEY, GOOGLE_API_KEY, or run a local Ollama server.');
    return;
  }

  for (final entry in models) {
    print('Testing ${entry.label}:');
    await demonstrateEmbeddingFeatures(entry.model);
  }

  print('Completed stable embeddings examples.');
  print('For provider-specific tuning, see:');
  print('  - example/04_providers/openai/embeddings.dart');
  print('  - example/04_providers/google/embeddings.dart');
}

List<_EmbeddingDemoEntry> _collectEmbeddingModels() {
  final entries = <_EmbeddingDemoEntry>[];

  final openAIKey = Platform.environment['OPENAI_API_KEY'];
  if (openAIKey != null && openAIKey.isNotEmpty) {
    entries.add(
      _EmbeddingDemoEntry(
        label: 'OpenAI text-embedding-3-small',
        model: llm
            .openai(
              apiKey: openAIKey,
            )
            .embeddingModel('text-embedding-3-small'),
      ),
    );
  }

  final googleKey = Platform.environment['GOOGLE_API_KEY'];
  if (googleKey != null && googleKey.isNotEmpty) {
    entries.add(
      _EmbeddingDemoEntry(
        label: 'Google text-embedding-004',
        model: llm
            .google(
              apiKey: googleKey,
            )
            .embeddingModel('text-embedding-004'),
      ),
    );
  }

  final ollamaBaseUrl = Platform.environment['OLLAMA_BASE_URL'] ??
      ollama_pkg.Ollama.defaultBaseUrl;
  entries.add(
    _EmbeddingDemoEntry(
      label: 'Ollama nomic-embed-text',
      model: ollama_pkg.Ollama(
        baseUrl: ollamaBaseUrl,
      ).embeddingModel(
        Platform.environment['OLLAMA_EMBEDDING_MODEL'] ?? 'nomic-embed-text',
      ),
    ),
  );

  return entries;
}

Future<void> demonstrateEmbeddingFeatures(core.EmbeddingModel model) async {
  print('  Model: ${model.providerId}/${model.modelId}');

  await demonstrateBasicEmbeddings(model);
  await demonstrateBatchEmbeddings(model);
  await demonstrateSimilarityCalculations(model);
  await demonstrateSemanticSearch(model);
  await demonstrateDocumentClustering(model);

  print('');
}

Future<void> demonstrateBasicEmbeddings(core.EmbeddingModel model) async {
  print('  Basic embeddings:');

  try {
    final single = await core.embed(
      model: model,
      value: 'Hello, world! This is a test sentence for embedding.',
    );

    print('    Single embedding: ${single.embedding.length} dimensions');
    print(
      '    Sample values: ${single.embedding.take(5).map((value) => value.toStringAsFixed(4)).join(', ')}...',
    );

    final multiple = await core.embedMany(
      model: model,
      values: const [
        'The quick brown fox jumps over the lazy dog.',
        'Machine learning is a subset of artificial intelligence.',
        'The weather is beautiful today.',
      ],
    );

    print(
      '    Multiple embeddings: ${multiple.embeddings.length} texts processed',
    );
    for (var index = 0; index < multiple.embeddings.length; index++) {
      print(
        '      Text ${index + 1}: ${multiple.embeddings[index].length} dimensions',
      );
    }
  } catch (error) {
    print('    Failed: $error');
  }
}

Future<void> demonstrateBatchEmbeddings(core.EmbeddingModel model) async {
  print('  Batch processing:');

  try {
    final batchTexts = const [
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

    final startTime = DateTime.now();
    final batch = await core.embedMany(
      model: model,
      values: batchTexts,
    );
    final duration = DateTime.now().difference(startTime);

    print('    Completed in ${duration.inMilliseconds}ms');
    print(
      '    Average: ${(duration.inMilliseconds / batch.embeddings.length).toStringAsFixed(1)}ms per text',
    );
    print('    Dimensions: ${batch.embeddings.first.length}');

    final allValues = batch.embeddings.expand((entry) => entry).toList();
    final mean = allValues.reduce((a, b) => a + b) / allValues.length;
    final variance = allValues
            .map((value) => math.pow(value - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        allValues.length;

    print(
      '    Statistics: mean=${mean.toStringAsFixed(4)}, std=${math.sqrt(variance).toStringAsFixed(4)}',
    );
  } catch (error) {
    print('    Failed: $error');
  }
}

Future<void> demonstrateSimilarityCalculations(
    core.EmbeddingModel model) async {
  print('  Similarity calculations:');

  try {
    final testTexts = const [
      'I love programming in Dart.',
      'Dart programming is enjoyable.',
      'Python is a great language.',
      'The weather is sunny today.',
    ];

    final batch = await core.embedMany(
      model: model,
      values: testTexts,
    );
    final referenceEmbedding = batch.embeddings.first;

    print('    Reference: "${testTexts.first}"');
    for (var index = 1; index < batch.embeddings.length; index++) {
      final similarity = EmbeddingUtils.cosineSimilarity(
        referenceEmbedding,
        batch.embeddings[index],
      );
      final similarityPercent = (similarity * 100).toStringAsFixed(1);

      print(
        '    ${_similarityLabel(similarity)} "${testTexts[index]}" - $similarityPercent%',
      );
    }
  } catch (error) {
    print('    Failed: $error');
  }
}

Future<void> demonstrateSemanticSearch(core.EmbeddingModel model) async {
  print('  Semantic search:');

  try {
    final documents = const [
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

    final documentEmbeddings = await core.embedMany(
      model: model,
      values: documents,
    );

    final queries = const [
      'neural networks and deep learning',
      'understanding human language',
      'cooking food',
    ];

    for (final query in queries) {
      final queryResult = await core.embed(
        model: model,
        value: query,
      );

      final results = SemanticSearchEngine.search(
        queryResult.embedding,
        documentEmbeddings.embeddings,
        documents,
        topK: 3,
      );

      print('    Query: "$query"');
      for (var index = 0; index < results.length; index++) {
        final result = results[index];
        final score = (result.score * 100).toStringAsFixed(1);
        print(
          '      ${index + 1}. [$score%] ${result.text.substring(0, 60)}...',
        );
      }
    }
  } catch (error) {
    print('    Failed: $error');
  }
}

Future<void> demonstrateDocumentClustering(core.EmbeddingModel model) async {
  print('  Document clustering:');

  try {
    final documents = const [
      'Artificial intelligence is revolutionizing technology.',
      'Machine learning algorithms improve with more data.',
      'Software development requires careful planning.',
      'Italian cuisine features pasta and pizza.',
      'French cooking emphasizes technique and flavor.',
      'Asian food includes rice and noodles.',
      'Football is popular in many countries.',
      'Basketball requires teamwork and skill.',
      'Tennis is an individual sport.',
    ];

    final embeddings = await core.embedMany(
      model: model,
      values: documents,
    );

    final clusters = DocumentClusterer.clusterBySimilarity(
      embeddings.embeddings,
      documents,
      threshold: 0.3,
    );

    print('    Found ${clusters.length} clusters:');
    for (var index = 0; index < clusters.length; index++) {
      final cluster = clusters[index];
      print('      Cluster ${index + 1} (${cluster.length} documents):');
      for (final document in cluster) {
        print('        - ${document.substring(0, 40)}...');
      }
    }
  } catch (error) {
    print('    Failed: $error');
  }
}

String _similarityLabel(double similarity) {
  if (similarity > 0.8) {
    return 'very similar';
  }
  if (similarity > 0.6) {
    return 'similar';
  }
  if (similarity > 0.4) {
    return 'partially related';
  }

  return 'different';
}

final class _EmbeddingDemoEntry {
  final String label;
  final core.EmbeddingModel model;

  const _EmbeddingDemoEntry({
    required this.label,
    required this.model,
  });
}

class EmbeddingUtils {
  static double cosineSimilarity(List<double> a, List<double> b) {
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

    if (normA == 0.0 || normB == 0.0) {
      return 0.0;
    }

    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }

  static double euclideanDistance(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Vectors must have the same length');
    }

    var sum = 0.0;
    for (var index = 0; index < a.length; index++) {
      final diff = a[index] - b[index];
      sum += diff * diff;
    }

    return math.sqrt(sum);
  }

  static List<double> normalize(List<double> vector) {
    final norm = math.sqrt(
      vector.map((value) => value * value).reduce((a, b) => a + b),
    );
    if (norm == 0.0) {
      return vector;
    }

    return vector.map((value) => value / norm).toList();
  }
}

class SearchResult {
  final String text;
  final double score;
  final int index;

  SearchResult(this.text, this.score, this.index);
}

class SemanticSearchEngine {
  static List<SearchResult> search(
    List<double> queryEmbedding,
    List<List<double>> documentEmbeddings,
    List<String> documents, {
    int topK = 5,
  }) {
    final results = <SearchResult>[];

    for (var index = 0; index < documentEmbeddings.length; index++) {
      final similarity = EmbeddingUtils.cosineSimilarity(
        queryEmbedding,
        documentEmbeddings[index],
      );
      results.add(SearchResult(documents[index], similarity, index));
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(topK).toList();
  }
}

class DocumentClusterer {
  static List<List<String>> clusterBySimilarity(
    List<List<double>> embeddings,
    List<String> documents, {
    double threshold = 0.5,
  }) {
    final clusters = <List<String>>[];
    final assigned = List<bool>.filled(documents.length, false);

    for (var i = 0; i < documents.length; i++) {
      if (assigned[i]) {
        continue;
      }

      final cluster = [documents[i]];
      assigned[i] = true;

      for (var j = i + 1; j < documents.length; j++) {
        if (assigned[j]) {
          continue;
        }

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
