import 'dart:math';
import 'package:llm_dart/llm_dart.dart';

/// Advanced semantic search implementation using embeddings
///
/// This example demonstrates:
/// - Building a semantic search engine
/// - Document indexing and retrieval
/// - Similarity-based ranking
/// - Query expansion and refinement
/// - Hybrid search (semantic + keyword)
/// - Performance optimization techniques
Future<void> main() async {
  print('🔍 Semantic Search Engine Examples\n');

  // Initialize embedding provider
  final embeddingProvider = await initializeEmbeddingProvider();
  if (embeddingProvider == null) {
    print('❌ No embedding provider available. Please set API keys.');
    return;
  }

  print('🚀 Building Semantic Search Engine...\n');

  // Create and demonstrate search engine
  final searchEngine = SemanticSearchEngine(embeddingProvider);

  // Load sample documents
  await loadSampleDocuments(searchEngine);

  // Demonstrate different search scenarios
  await demonstrateBasicSearch(searchEngine);
  await demonstrateAdvancedSearch(searchEngine);
  await demonstrateHybridSearch(searchEngine);
  await demonstrateQueryExpansion(searchEngine);
  await demonstrateSearchAnalytics(searchEngine);

  print('✅ Semantic search examples completed!');
  print(
      '💡 This demonstrates how to build production-ready search with embeddings');
}

/// Initialize embedding provider
Future<EmbeddingCapability?> initializeEmbeddingProvider() async {
  // Try different providers in order of preference
  final providers = [
    (
      'OpenAI',
      () async {
        final apiKey = 'your-openai-key'; // Replace with actual key
        return await ai()
            .openai()
            .apiKey(apiKey)
            .model('text-embedding-3-small')
            .buildEmbedding();
      }
    ),
    (
      'Google',
      () async {
        final apiKey = 'your-google-key'; // Replace with actual key
        return await ai()
            .google()
            .apiKey(apiKey)
            .model('text-embedding-004')
            .buildEmbedding();
      }
    ),
  ];

  for (final (name, factory) in providers) {
    try {
      final provider = await factory();
      print('✅ Using $name for embeddings');
      return provider;
    } catch (e) {
      print('⚠️  $name not available: $e');
    }
  }

  return null;
}

/// Load sample documents into the search engine
Future<void> loadSampleDocuments(SemanticSearchEngine searchEngine) async {
  print('📚 Loading Sample Documents...');

  final documents = [
    Document(
      id: '1',
      title: 'Introduction to Machine Learning',
      content:
          'Machine learning is a subset of artificial intelligence that enables computers to learn and improve from experience without being explicitly programmed. It focuses on developing algorithms that can access data and use it to learn for themselves.',
      metadata: {
        'category': 'AI',
        'difficulty': 'beginner',
        'author': 'Dr. Smith'
      },
    ),
    Document(
      id: '2',
      title: 'Deep Learning Neural Networks',
      content:
          'Deep learning is a machine learning technique that teaches computers to do what comes naturally to humans: learn by example. Deep learning is a key technology behind driverless cars, voice control, and image recognition.',
      metadata: {
        'category': 'AI',
        'difficulty': 'advanced',
        'author': 'Prof. Johnson'
      },
    ),
    Document(
      id: '3',
      title: 'Natural Language Processing Fundamentals',
      content:
          'Natural Language Processing (NLP) is a branch of artificial intelligence that helps computers understand, interpret and manipulate human language. NLP draws from many disciplines, including computer science and computational linguistics.',
      metadata: {
        'category': 'NLP',
        'difficulty': 'intermediate',
        'author': 'Dr. Chen'
      },
    ),
    Document(
      id: '4',
      title: 'Computer Vision Applications',
      content:
          'Computer vision is a field of artificial intelligence that trains computers to interpret and understand the visual world. Using digital images from cameras and videos and deep learning models, machines can accurately identify and classify objects.',
      metadata: {
        'category': 'CV',
        'difficulty': 'intermediate',
        'author': 'Dr. Williams'
      },
    ),
    Document(
      id: '5',
      title: 'Quantum Computing Basics',
      content:
          'Quantum computing is a type of computation that harnesses the collective properties of quantum states, such as superposition, interference, and entanglement, to perform calculations. It represents a fundamental shift from classical computing.',
      metadata: {
        'category': 'Quantum',
        'difficulty': 'advanced',
        'author': 'Prof. Anderson'
      },
    ),
    Document(
      id: '6',
      title: 'Data Science Methodology',
      content:
          'Data science is an interdisciplinary field that uses scientific methods, processes, algorithms and systems to extract knowledge and insights from structured and unstructured data. It combines statistics, data analysis, and machine learning.',
      metadata: {
        'category': 'Data Science',
        'difficulty': 'beginner',
        'author': 'Dr. Brown'
      },
    ),
    Document(
      id: '7',
      title: 'Blockchain Technology Overview',
      content:
          'Blockchain is a distributed ledger technology that maintains a continuously growing list of records, called blocks, which are linked and secured using cryptography. It enables secure, transparent, and decentralized transactions.',
      metadata: {
        'category': 'Blockchain',
        'difficulty': 'intermediate',
        'author': 'Mr. Davis'
      },
    ),
    Document(
      id: '8',
      title: 'Cloud Computing Architecture',
      content:
          'Cloud computing is the delivery of computing services including servers, storage, databases, networking, software, analytics, and intelligence over the Internet to offer faster innovation, flexible resources, and economies of scale.',
      metadata: {
        'category': 'Cloud',
        'difficulty': 'intermediate',
        'author': 'Ms. Wilson'
      },
    ),
  ];

  await searchEngine.indexDocuments(documents);
  print('   ✅ Indexed ${documents.length} documents');
  print('');
}

/// Demonstrate basic semantic search
Future<void> demonstrateBasicSearch(SemanticSearchEngine searchEngine) async {
  print('🔍 Basic Semantic Search:');

  final queries = [
    'artificial intelligence and machine learning',
    'neural networks and deep learning',
    'understanding human language',
    'visual recognition and image processing',
    'distributed ledger and cryptocurrency',
  ];

  for (final query in queries) {
    print('   🔎 Query: "$query"');

    final results = await searchEngine.search(query, limit: 3);

    print('      📋 Results:');
    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      final score = (result.score * 100).toStringAsFixed(1);
      print('         ${i + 1}. [$score%] ${result.document.title}');
      print('            ${result.document.content.substring(0, 80)}...');
    }
    print('');
  }
}

/// Demonstrate advanced search with filters
Future<void> demonstrateAdvancedSearch(
    SemanticSearchEngine searchEngine) async {
  print('🎯 Advanced Search with Filters:');

  // Search with category filter
  print('   📂 Filtering by category "AI":');
  final aiResults = await searchEngine.search(
    'learning algorithms',
    filters: {'category': 'AI'},
    limit: 3,
  );

  for (final result in aiResults) {
    final score = (result.score * 100).toStringAsFixed(1);
    print(
        '      [$score%] ${result.document.title} (${result.document.metadata['category']})');
  }

  // Search with difficulty filter
  print('\n   📊 Filtering by difficulty "beginner":');
  final beginnerResults = await searchEngine.search(
    'introduction to technology',
    filters: {'difficulty': 'beginner'},
    limit: 3,
  );

  for (final result in beginnerResults) {
    final score = (result.score * 100).toStringAsFixed(1);
    print(
        '      [$score%] ${result.document.title} (${result.document.metadata['difficulty']})');
  }

  // Search with multiple filters
  print('\n   🎛️  Multiple filters (AI + intermediate):');
  final multiFilterResults = await searchEngine.search(
    'computer algorithms',
    filters: {'category': 'AI', 'difficulty': 'intermediate'},
    limit: 3,
  );

  for (final result in multiFilterResults) {
    final score = (result.score * 100).toStringAsFixed(1);
    final category = result.document.metadata['category'];
    final difficulty = result.document.metadata['difficulty'];
    print('      [$score%] ${result.document.title} ($category, $difficulty)');
  }

  print('');
}

/// Demonstrate hybrid search (semantic + keyword)
Future<void> demonstrateHybridSearch(SemanticSearchEngine searchEngine) async {
  print('🔀 Hybrid Search (Semantic + Keyword):');

  final query = 'machine learning algorithms';

  // Pure semantic search
  print('   🧠 Semantic search only:');
  final semanticResults = await searchEngine.search(query, limit: 3);
  for (final result in semanticResults) {
    final score = (result.score * 100).toStringAsFixed(1);
    print('      [$score%] ${result.document.title}');
  }

  // Hybrid search
  print('\n   🔀 Hybrid search (semantic + keyword):');
  final hybridResults = await searchEngine.hybridSearch(query, limit: 3);
  for (final result in hybridResults) {
    final score = (result.score * 100).toStringAsFixed(1);
    print('      [$score%] ${result.document.title}');
  }

  print('');
}

/// Demonstrate query expansion
Future<void> demonstrateQueryExpansion(
    SemanticSearchEngine searchEngine) async {
  print('📈 Query Expansion:');

  final originalQuery = 'AI';
  print('   🔤 Original query: "$originalQuery"');

  // Expand query with related terms
  final expandedQuery = await searchEngine.expandQuery(originalQuery);
  print('   📝 Expanded query: "$expandedQuery"');

  // Search with expanded query
  final results = await searchEngine.search(expandedQuery, limit: 3);
  print('   📋 Results with expanded query:');
  for (final result in results) {
    final score = (result.score * 100).toStringAsFixed(1);
    print('      [$score%] ${result.document.title}');
  }

  print('');
}

/// Demonstrate search analytics
Future<void> demonstrateSearchAnalytics(
    SemanticSearchEngine searchEngine) async {
  print('📊 Search Analytics:');

  final analytics = searchEngine.getAnalytics();

  print('   📈 Search Statistics:');
  print('      • Total searches: ${analytics.totalSearches}');
  print(
      '      • Average results per search: ${analytics.averageResultsPerSearch.toStringAsFixed(1)}');
  print(
      '      • Most common categories: ${analytics.topCategories.join(', ')}');
  print(
      '      • Average search time: ${analytics.averageSearchTime.inMilliseconds}ms');

  print('\n   🔥 Popular Queries:');
  for (int i = 0; i < analytics.popularQueries.length && i < 5; i++) {
    final query = analytics.popularQueries[i];
    print('      ${i + 1}. "${query.query}" (${query.count} searches)');
  }

  print('');
}

/// Document class for search engine
class Document {
  final String id;
  final String title;
  final String content;
  final Map<String, String> metadata;

  Document({
    required this.id,
    required this.title,
    required this.content,
    required this.metadata,
  });

  String get fullText => '$title $content';
}

/// Search result class
class SearchResult {
  final Document document;
  final double score;
  final Map<String, dynamic> highlights;

  SearchResult({
    required this.document,
    required this.score,
    this.highlights = const {},
  });
}

/// Query analytics
class QueryAnalytics {
  final String query;
  final int count;

  QueryAnalytics(this.query, this.count);
}

/// Search analytics
class SearchAnalytics {
  final int totalSearches;
  final double averageResultsPerSearch;
  final List<String> topCategories;
  final Duration averageSearchTime;
  final List<QueryAnalytics> popularQueries;

  SearchAnalytics({
    required this.totalSearches,
    required this.averageResultsPerSearch,
    required this.topCategories,
    required this.averageSearchTime,
    required this.popularQueries,
  });
}

/// Semantic search engine implementation
class SemanticSearchEngine {
  final EmbeddingCapability _embeddingProvider;
  final List<Document> _documents = [];
  final List<List<double>> _embeddings = [];
  final Map<String, int> _queryCount = {};
  final List<Duration> _searchTimes = [];

  SemanticSearchEngine(this._embeddingProvider);

  /// Index documents for search
  Future<void> indexDocuments(List<Document> documents) async {
    _documents.clear();
    _embeddings.clear();

    final texts = documents.map((doc) => doc.fullText).toList();
    final embeddings = await _embeddingProvider.embed(texts);

    _documents.addAll(documents);
    _embeddings.addAll(embeddings);
  }

  /// Perform semantic search
  Future<List<SearchResult>> search(
    String query, {
    int limit = 10,
    Map<String, String>? filters,
  }) async {
    final startTime = DateTime.now();

    // Track query
    _queryCount[query] = (_queryCount[query] ?? 0) + 1;

    // Get query embedding
    final queryEmbedding = await _embeddingProvider.embed([query]);

    // Calculate similarities
    final results = <SearchResult>[];
    for (int i = 0; i < _documents.length; i++) {
      final document = _documents[i];

      // Apply filters
      if (filters != null && !_matchesFilters(document, filters)) {
        continue;
      }

      final similarity = _cosineSimilarity(queryEmbedding[0], _embeddings[i]);
      results.add(SearchResult(
        document: document,
        score: similarity,
      ));
    }

    // Sort by similarity and limit results
    results.sort((a, b) => b.score.compareTo(a.score));
    final limitedResults = results.take(limit).toList();

    // Track search time
    final searchTime = DateTime.now().difference(startTime);
    _searchTimes.add(searchTime);

    return limitedResults;
  }

  /// Perform hybrid search (semantic + keyword)
  Future<List<SearchResult>> hybridSearch(String query,
      {int limit = 10}) async {
    // Get semantic results
    final semanticResults = await search(query, limit: limit * 2);

    // Get keyword scores
    final keywordScores = _calculateKeywordScores(query);

    // Combine scores (70% semantic, 30% keyword)
    for (final result in semanticResults) {
      final keywordScore = keywordScores[result.document.id] ?? 0.0;
      final combinedScore = (result.score * 0.7) + (keywordScore * 0.3);

      // Update result with combined score
      final index = semanticResults.indexOf(result);
      semanticResults[index] = SearchResult(
        document: result.document,
        score: combinedScore,
        highlights: result.highlights,
      );
    }

    // Re-sort and limit
    semanticResults.sort((a, b) => b.score.compareTo(a.score));
    return semanticResults.take(limit).toList();
  }

  /// Expand query with related terms
  Future<String> expandQuery(String query) async {
    // Simple query expansion - in production, you might use a thesaurus or LLM
    final expansions = {
      'AI': 'artificial intelligence machine learning',
      'ML': 'machine learning algorithms',
      'DL': 'deep learning neural networks',
      'NLP': 'natural language processing text',
      'CV': 'computer vision image recognition',
    };

    var expandedQuery = query;
    for (final entry in expansions.entries) {
      if (query.toLowerCase().contains(entry.key.toLowerCase())) {
        expandedQuery += ' ${entry.value}';
      }
    }

    return expandedQuery;
  }

  /// Get search analytics
  SearchAnalytics getAnalytics() {
    final totalSearches =
        _queryCount.values.fold(0, (sum, count) => sum + count);
    final averageResults = _documents.length.toDouble();
    final averageTime = _searchTimes.isNotEmpty
        ? Duration(
            microseconds: _searchTimes
                    .map((d) => d.inMicroseconds)
                    .reduce((a, b) => a + b) ~/
                _searchTimes.length)
        : Duration.zero;

    final topCategories = _documents
        .map((doc) => doc.metadata['category'] ?? 'Unknown')
        .toSet()
        .toList();

    final popularQueries = _queryCount.entries
        .map((e) => QueryAnalytics(e.key, e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return SearchAnalytics(
      totalSearches: totalSearches,
      averageResultsPerSearch: averageResults,
      topCategories: topCategories,
      averageSearchTime: averageTime,
      popularQueries: popularQueries,
    );
  }

  /// Check if document matches filters
  bool _matchesFilters(Document document, Map<String, String> filters) {
    for (final entry in filters.entries) {
      final key = entry.key;
      final value = entry.value;
      if (document.metadata[key] != value) {
        return false;
      }
    }
    return true;
  }

  /// Calculate cosine similarity
  double _cosineSimilarity(List<double> a, List<double> b) {
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

  /// Calculate keyword-based scores
  Map<String, double> _calculateKeywordScores(String query) {
    final queryTerms = query.toLowerCase().split(' ');
    final scores = <String, double>{};

    for (final document in _documents) {
      final content = document.fullText.toLowerCase();
      double score = 0.0;

      for (final term in queryTerms) {
        final matches = RegExp(r'\b' + RegExp.escape(term) + r'\b')
            .allMatches(content)
            .length;
        score += matches / content.split(' ').length;
      }

      scores[document.id] = score;
    }

    return scores;
  }
}
