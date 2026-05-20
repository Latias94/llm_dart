import 'dart:io';
import 'dart:math' as math;

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart_google/llm_dart_google.dart' as google;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

/// Stable semantic search implementation using shared embedding models.
///
/// This example demonstrates:
/// - app-owned indexing, filtering, ranking, and analytics structures
/// - shared `embed(...)` / `embedMany(...)` helpers for query and document vectors
/// - hybrid ranking and query expansion without legacy capability coupling
Future<void> main() async {
  print('Stable semantic search engine examples\n');

  final entry = _resolveEmbeddingModel();
  if (entry == null) {
    print('No embedding model is configured.');
    print('Set OPENAI_API_KEY or GOOGLE_API_KEY.');
    return;
  }

  print('Using ${entry.label}');
  print('Model id: ${entry.model.providerId}/${entry.model.modelId}\n');

  final searchEngine = SemanticSearchEngine(entry.model);
  await loadSampleDocuments(searchEngine);
  await demonstrateBasicSearch(searchEngine);
  await demonstrateAdvancedSearch(searchEngine);
  await demonstrateHybridSearch(searchEngine);
  await demonstrateQueryExpansion(searchEngine);
  await demonstrateSearchAnalytics(searchEngine);

  print('Completed stable semantic search examples.');
  print('Keep retrieval indexes, analytics, and filtering in app-owned code.');
}

_EmbeddingModelEntry? _resolveEmbeddingModel() {
  final openAIKey = Platform.environment['OPENAI_API_KEY'];
  if (openAIKey != null && openAIKey.isNotEmpty) {
    return _EmbeddingModelEntry(
      label: 'OpenAI text-embedding-3-small',
      model: openai
          .openai(
            apiKey: openAIKey,
          )
          .embeddingModel('text-embedding-3-small'),
    );
  }

  final googleKey = Platform.environment['GOOGLE_API_KEY'];
  if (googleKey != null && googleKey.isNotEmpty) {
    return _EmbeddingModelEntry(
      label: 'Google text-embedding-004',
      model: google
          .google(
            apiKey: googleKey,
          )
          .embeddingModel('text-embedding-004'),
    );
  }

  return null;
}

Future<void> loadSampleDocuments(SemanticSearchEngine searchEngine) async {
  print('Loading sample documents...');

  final documents = [
    Document(
      id: '1',
      title: 'Introduction to Machine Learning',
      content:
          'Machine learning is a subset of artificial intelligence that enables computers to learn and improve from experience without being explicitly programmed.',
      metadata: const {
        'category': 'AI',
        'difficulty': 'beginner',
        'author': 'Dr. Smith',
      },
    ),
    Document(
      id: '2',
      title: 'Deep Learning Neural Networks',
      content:
          'Deep learning is a machine learning technique that teaches computers to do what comes naturally to humans: learn by example.',
      metadata: const {
        'category': 'AI',
        'difficulty': 'advanced',
        'author': 'Prof. Johnson',
      },
    ),
    Document(
      id: '3',
      title: 'Natural Language Processing Fundamentals',
      content:
          'Natural language processing helps computers understand, interpret, and manipulate human language.',
      metadata: const {
        'category': 'NLP',
        'difficulty': 'intermediate',
        'author': 'Dr. Chen',
      },
    ),
    Document(
      id: '4',
      title: 'Computer Vision Applications',
      content:
          'Computer vision trains machines to interpret and understand the visual world using images and videos.',
      metadata: const {
        'category': 'CV',
        'difficulty': 'intermediate',
        'author': 'Dr. Williams',
      },
    ),
    Document(
      id: '5',
      title: 'Quantum Computing Basics',
      content:
          'Quantum computing harnesses superposition, interference, and entanglement to perform calculations.',
      metadata: const {
        'category': 'Quantum',
        'difficulty': 'advanced',
        'author': 'Prof. Anderson',
      },
    ),
    Document(
      id: '6',
      title: 'Data Science Methodology',
      content:
          'Data science combines statistics, programming, and domain knowledge to extract insights from data.',
      metadata: const {
        'category': 'Data Science',
        'difficulty': 'beginner',
        'author': 'Dr. Brown',
      },
    ),
    Document(
      id: '7',
      title: 'Blockchain Technology Overview',
      content:
          'Blockchain is a distributed ledger technology that enables secure, transparent, and decentralized transactions.',
      metadata: const {
        'category': 'Blockchain',
        'difficulty': 'intermediate',
        'author': 'Mr. Davis',
      },
    ),
    Document(
      id: '8',
      title: 'Cloud Computing Architecture',
      content:
          'Cloud computing delivers computing services over the internet to offer faster innovation and flexible resources.',
      metadata: const {
        'category': 'Cloud',
        'difficulty': 'intermediate',
        'author': 'Ms. Wilson',
      },
    ),
  ];

  await searchEngine.indexDocuments(documents);
  print('  Indexed ${documents.length} documents\n');
}

Future<void> demonstrateBasicSearch(SemanticSearchEngine searchEngine) async {
  print('Basic semantic search:');

  final queries = [
    'artificial intelligence and machine learning',
    'neural networks and deep learning',
    'understanding human language',
    'visual recognition and image processing',
    'distributed ledger and cryptocurrency',
  ];

  for (final query in queries) {
    print('  Query: "$query"');
    final results = await searchEngine.search(query, limit: 3);

    for (var index = 0; index < results.length; index++) {
      final result = results[index];
      final score = (result.score * 100).toStringAsFixed(1);
      print('    ${index + 1}. [$score%] ${result.document.title}');
      print('       ${_preview(result.document.content, 80)}');
    }
  }

  print('');
}

Future<void> demonstrateAdvancedSearch(
  SemanticSearchEngine searchEngine,
) async {
  print('Advanced search with filters:');

  print('  Filter by category "AI":');
  final aiResults = await searchEngine.search(
    'learning algorithms',
    filters: const {'category': 'AI'},
    limit: 3,
  );
  for (final result in aiResults) {
    final score = (result.score * 100).toStringAsFixed(1);
    print(
      '    [$score%] ${result.document.title} '
      '(${result.document.metadata['category']})',
    );
  }

  print('\n  Filter by difficulty "beginner":');
  final beginnerResults = await searchEngine.search(
    'introduction to technology',
    filters: const {'difficulty': 'beginner'},
    limit: 3,
  );
  for (final result in beginnerResults) {
    final score = (result.score * 100).toStringAsFixed(1);
    print(
      '    [$score%] ${result.document.title} '
      '(${result.document.metadata['difficulty']})',
    );
  }

  print('\n  Multiple filters (AI + intermediate):');
  final multiFilterResults = await searchEngine.search(
    'computer algorithms',
    filters: const {
      'category': 'AI',
      'difficulty': 'intermediate',
    },
    limit: 3,
  );
  for (final result in multiFilterResults) {
    final score = (result.score * 100).toStringAsFixed(1);
    final category = result.document.metadata['category'];
    final difficulty = result.document.metadata['difficulty'];
    print('    [$score%] ${result.document.title} ($category, $difficulty)');
  }

  print('');
}

Future<void> demonstrateHybridSearch(SemanticSearchEngine searchEngine) async {
  print('Hybrid search (semantic + keyword):');

  const query = 'machine learning algorithms';

  print('  Semantic search only:');
  final semanticResults = await searchEngine.search(query, limit: 3);
  for (final result in semanticResults) {
    final score = (result.score * 100).toStringAsFixed(1);
    print('    [$score%] ${result.document.title}');
  }

  print('\n  Hybrid search:');
  final hybridResults = await searchEngine.hybridSearch(query, limit: 3);
  for (final result in hybridResults) {
    final score = (result.score * 100).toStringAsFixed(1);
    print('    [$score%] ${result.document.title}');
  }

  print('');
}

Future<void> demonstrateQueryExpansion(
  SemanticSearchEngine searchEngine,
) async {
  print('Query expansion:');

  const originalQuery = 'AI';
  print('  Original query: "$originalQuery"');

  final expandedQuery = await searchEngine.expandQuery(originalQuery);
  print('  Expanded query: "$expandedQuery"');

  final results = await searchEngine.search(expandedQuery, limit: 3);
  for (final result in results) {
    final score = (result.score * 100).toStringAsFixed(1);
    print('    [$score%] ${result.document.title}');
  }

  print('');
}

Future<void> demonstrateSearchAnalytics(
  SemanticSearchEngine searchEngine,
) async {
  print('Search analytics:');

  final analytics = searchEngine.getAnalytics();
  print('  Total searches: ${analytics.totalSearches}');
  print(
    '  Average results per search: '
    '${analytics.averageResultsPerSearch.toStringAsFixed(1)}',
  );
  print('  Top categories: ${analytics.topCategories.join(', ')}');
  print(
    '  Average search time: ${analytics.averageSearchTime.inMilliseconds}ms',
  );
  print('  Query embedding cache size: ${analytics.cachedQueryEmbeddings}');

  if (analytics.popularQueries.isNotEmpty) {
    print('\n  Popular queries:');
    for (var index = 0;
        index < analytics.popularQueries.length && index < 5;
        index++) {
      final query = analytics.popularQueries[index];
      print('    ${index + 1}. "${query.query}" (${query.count} searches)');
    }
  }

  print('');
}

class Document {
  final String id;
  final String title;
  final String content;
  final Map<String, String> metadata;

  const Document({
    required this.id,
    required this.title,
    required this.content,
    required this.metadata,
  });

  String get fullText => '$title $content';
}

class SearchResult {
  final Document document;
  final double score;
  final Map<String, Object?> highlights;

  const SearchResult({
    required this.document,
    required this.score,
    this.highlights = const {},
  });
}

class QueryAnalytics {
  final String query;
  final int count;

  const QueryAnalytics(this.query, this.count);
}

class SearchAnalytics {
  final int totalSearches;
  final double averageResultsPerSearch;
  final List<String> topCategories;
  final Duration averageSearchTime;
  final List<QueryAnalytics> popularQueries;
  final int cachedQueryEmbeddings;

  const SearchAnalytics({
    required this.totalSearches,
    required this.averageResultsPerSearch,
    required this.topCategories,
    required this.averageSearchTime,
    required this.popularQueries,
    required this.cachedQueryEmbeddings,
  });
}

class SemanticSearchEngine {
  final core.EmbeddingModel _embeddingModel;
  final List<Document> _documents = [];
  final List<List<double>> _documentEmbeddings = [];
  final Map<String, int> _queryCount = {};
  final List<Duration> _searchTimes = [];
  final List<int> _resultCounts = [];
  final Map<String, List<double>> _queryEmbeddingCache = {};

  SemanticSearchEngine(this._embeddingModel);

  Future<void> indexDocuments(List<Document> documents) async {
    _documents
      ..clear()
      ..addAll(documents);
    _documentEmbeddings.clear();

    final values = documents.map((document) => document.fullText).toList();
    final batch = await core.embedMany(
      model: _embeddingModel,
      values: values,
    );

    _documentEmbeddings.addAll(batch.embeddings);
  }

  Future<List<SearchResult>> search(
    String query, {
    int limit = 10,
    Map<String, String>? filters,
  }) {
    return _searchInternal(
      query,
      limit: limit,
      filters: filters,
      includeKeywordScore: false,
      trackAnalytics: true,
    );
  }

  Future<List<SearchResult>> hybridSearch(
    String query, {
    int limit = 10,
    Map<String, String>? filters,
  }) {
    return _searchInternal(
      query,
      limit: limit,
      filters: filters,
      includeKeywordScore: true,
      trackAnalytics: true,
    );
  }

  Future<String> expandQuery(String query) async {
    const expansions = {
      'AI': 'artificial intelligence machine learning',
      'ML': 'machine learning algorithms',
      'DL': 'deep learning neural networks',
      'NLP': 'natural language processing text',
      'CV': 'computer vision image recognition',
    };

    var expandedQuery = query;
    for (final entry in expansions.entries) {
      if (query.toLowerCase().contains(entry.key.toLowerCase())) {
        expandedQuery = '$expandedQuery ${entry.value}';
      }
    }

    return expandedQuery;
  }

  SearchAnalytics getAnalytics() {
    final totalSearches =
        _queryCount.values.fold<int>(0, (sum, count) => sum + count);
    final averageResults = _resultCounts.isEmpty
        ? 0.0
        : _resultCounts.reduce((left, right) => left + right) /
            _resultCounts.length;
    final averageTime = _searchTimes.isEmpty
        ? Duration.zero
        : Duration(
            microseconds: _searchTimes
                    .map((duration) => duration.inMicroseconds)
                    .reduce((left, right) => left + right) ~/
                _searchTimes.length,
          );

    final categoryCounts = <String, int>{};
    for (final document in _documents) {
      final category = document.metadata['category'] ?? 'Unknown';
      categoryCounts.update(category, (count) => count + 1, ifAbsent: () => 1);
    }

    final topCategories = categoryCounts.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));

    final popularQueries = _queryCount.entries
        .map((entry) => QueryAnalytics(entry.key, entry.value))
        .toList()
      ..sort((left, right) => right.count.compareTo(left.count));

    return SearchAnalytics(
      totalSearches: totalSearches,
      averageResultsPerSearch: averageResults,
      topCategories: topCategories.map((entry) => entry.key).toList(),
      averageSearchTime: averageTime,
      popularQueries: popularQueries,
      cachedQueryEmbeddings: _queryEmbeddingCache.length,
    );
  }

  Future<List<SearchResult>> _searchInternal(
    String query, {
    required int limit,
    required bool includeKeywordScore,
    required bool trackAnalytics,
    Map<String, String>? filters,
  }) async {
    final startedAt = DateTime.now();

    if (trackAnalytics) {
      _queryCount.update(query, (count) => count + 1, ifAbsent: () => 1);
    }

    final queryEmbedding = await _embeddingForQuery(query);
    final results = <SearchResult>[];

    for (var index = 0; index < _documents.length; index++) {
      final document = _documents[index];
      if (filters != null && !_matchesFilters(document, filters)) {
        continue;
      }

      final semanticScore = _cosineSimilarity(
        queryEmbedding,
        _documentEmbeddings[index],
      );
      final keywordScore =
          includeKeywordScore ? _keywordScore(query, document.fullText) : 0.0;
      final score = includeKeywordScore
          ? semanticScore * 0.7 + keywordScore * 0.3
          : semanticScore;

      results.add(
        SearchResult(
          document: document,
          score: score,
          highlights: {
            'semanticScore': semanticScore,
            if (includeKeywordScore) 'keywordScore': keywordScore,
          },
        ),
      );
    }

    results.sort((left, right) => right.score.compareTo(left.score));
    final limited = results.take(limit).toList();

    if (trackAnalytics) {
      _searchTimes.add(DateTime.now().difference(startedAt));
      _resultCounts.add(limited.length);
    }

    return limited;
  }

  Future<List<double>> _embeddingForQuery(String query) async {
    final cached = _queryEmbeddingCache[query];
    if (cached != null) {
      return cached;
    }

    final result = await core.embed(
      model: _embeddingModel,
      value: query,
    );
    _queryEmbeddingCache[query] = result.embedding;
    return result.embedding;
  }

  bool _matchesFilters(Document document, Map<String, String> filters) {
    for (final entry in filters.entries) {
      if (document.metadata[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  double _keywordScore(String query, String content) {
    final terms = query.toLowerCase().split(RegExp(r'\s+'));
    final normalizedContent = content.toLowerCase();
    final totalWords = normalizedContent.split(RegExp(r'\s+')).length;
    if (totalWords == 0) {
      return 0.0;
    }

    var score = 0.0;
    for (final term in terms) {
      if (term.isEmpty) {
        continue;
      }

      final matches = RegExp(r'\b' + RegExp.escape(term) + r'\b')
          .allMatches(normalizedContent)
          .length;
      score += matches / totalWords;
    }

    return score;
  }

  double _cosineSimilarity(List<double> left, List<double> right) {
    var dotProduct = 0.0;
    var normLeft = 0.0;
    var normRight = 0.0;

    for (var index = 0; index < left.length; index++) {
      dotProduct += left[index] * right[index];
      normLeft += left[index] * left[index];
      normRight += right[index] * right[index];
    }

    if (normLeft == 0.0 || normRight == 0.0) {
      return 0.0;
    }

    return dotProduct / (math.sqrt(normLeft) * math.sqrt(normRight));
  }
}

String _preview(String value, int maxLength) {
  if (value.length <= maxLength) {
    return value;
  }

  return '${value.substring(0, maxLength)}...';
}

final class _EmbeddingModelEntry {
  final String label;
  final core.EmbeddingModel model;

  const _EmbeddingModelEntry({
    required this.label,
    required this.model,
  });
}
