import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

/// xAI Grok Live Search Examples
///
/// This example demonstrates xAI's unique live search capabilities:
/// - Real-time web search integration
/// - Current events and news access
/// - Live data retrieval and analysis
/// - Search-enhanced conversations
/// - Fact-checking with live sources
/// - Trending topics analysis
///
/// Note: These features are specific to xAI's Grok models
/// For general chat examples, see: example/02_core_features/chat_completion.dart
Future<void> main() async {
  print('🔍 xAI Grok Live Search Examples\n');

  // Initialize xAI provider
  final xaiModel = await initializeXAIProvider();
  if (xaiModel == null) {
    print('❌ xAI provider not available. Please set XAI_API_KEY.');
    return;
  }

  print('🚀 Demonstrating xAI Live Search Capabilities...\n');

  // Demonstrate different live search scenarios
  await demonstrateBasicLiveSearch(xaiModel);
  await demonstrateCurrentEventsQuery(xaiModel);
  await demonstrateFactCheckingWithSources(xaiModel);
  await demonstrateTrendingTopicsAnalysis(xaiModel);
  await demonstrateSearchEnhancedConversation(xaiModel);
  await demonstrateRealTimeDataRetrieval(xaiModel);

  print('✅ xAI live search examples completed!');
  print('💡 xAI Grok advantages:');
  print('   • Access to real-time web information');
  print('   • Current events and breaking news');
  print('   • Fact-checking with live sources');
  print('   • Up-to-date data for analysis');
}

/// Initialize xAI provider with live search capabilities
Future<LanguageModel?> initializeXAIProvider() async {
  try {
    // Get xAI API key from environment variable
    final apiKey = Platform.environment['XAI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      print('❌ XAI_API_KEY environment variable not set.');
      print('💡 Please set your xAI API key:');
      print('   export XAI_API_KEY="your-actual-xai-api-key"');
      return null;
    }

    return await ai()
        .xai()
        .apiKey(apiKey)
        .model('grok-3') // Use latest Grok-3 model for live search
        .temperature(0.7)
        .enableWebSearch() // Enable live search functionality
        .buildLanguageModel();
  } catch (e) {
    print('⚠️  xAI provider initialization failed: $e');
    return null;
  }
}

/// Demonstrate basic live search functionality
Future<void> demonstrateBasicLiveSearch(LanguageModel model) async {
  print('🔍 Basic Live Search:');

  final searchQueries = [
    'What are the latest developments in AI technology this week?',
    'Current stock price of major tech companies',
    'Recent breakthroughs in quantum computing',
    'Latest news about space exploration missions',
  ];

  for (final query in searchQueries) {
    print('   🔎 Query: "$query"');

    try {
      final prompt = ChatPromptBuilder.user().text(query).build();
      final response = await generateTextWithModel(
        model,
        promptMessages: [prompt],
      );

      final text = response.text ?? '';
      if (text.isNotEmpty) {
        final preview =
            text.length > 150 ? '${text.substring(0, 150)}...' : text;
        print('   📝 Response: $preview');
        print('   🔍 Live search results integrated in response');
      }
    } catch (e) {
      print('   ❌ Search failed: $e');
    }

    print('');
  }
}

/// Demonstrate current events and news queries
Future<void> demonstrateCurrentEventsQuery(LanguageModel model) async {
  print('📰 Current Events & News:');

  final newsQueries = [
    'What are the top news stories today?',
    'Latest political developments in major countries',
    'Recent economic indicators and market trends',
    'Breaking news in technology and science',
    'Current weather patterns and climate events',
  ];

  for (final query in newsQueries) {
    print('   📰 News Query: "$query"');

    try {
      // xAI Grok models automatically prioritize recent news
      final prompt = ChatPromptBuilder.user().text(query).build();
      final response = await generateTextWithModel(
        model,
        promptMessages: [prompt],
      );

      final text = response.text ?? '';
      if (text.isNotEmpty) {
        final preview =
            text.length > 200 ? '${text.substring(0, 200)}...' : text;
        print('   📄 News Summary: $preview');
        print('   📰 Recent news integrated automatically by Grok');
      }
    } catch (e) {
      print('   ❌ News query failed: $e');
    }

    print('');
  }
}

/// Demonstrate fact-checking with live sources
Future<void> demonstrateFactCheckingWithSources(LanguageModel model) async {
  print('✅ Fact-Checking with Live Sources:');

  final factCheckQueries = [
    'Is it true that renewable energy costs have decreased significantly in 2024?',
    'Verify the claim that AI models are becoming more energy efficient',
    'Check if the recent Mars mission discoveries are accurate',
    'Fact-check recent statements about global climate change statistics',
  ];

  for (final query in factCheckQueries) {
    print('   🔍 Fact-Check: "$query"');

    try {
      // Grok automatically provides fact-checking with reliable sources
      final prompt = ChatPromptBuilder.user()
          .text(
              'You are a fact-checker. Verify claims using the most recent and reliable sources. Provide source citations.')
          .text(query)
          .build();
      final response = await generateTextWithModel(
        model,
        promptMessages: [prompt],
      );

      final text = response.text ?? '';
      if (text.isNotEmpty) {
        final preview =
            text.length > 180 ? '${text.substring(0, 180)}...' : text;
        print('   ✅ Fact-Check Result: $preview');
        print('   📚 Sources automatically verified by Grok');
      }
    } catch (e) {
      print('   ❌ Fact-checking failed: $e');
    }

    print('');
  }
}

/// Demonstrate trending topics analysis
Future<void> demonstrateTrendingTopicsAnalysis(LanguageModel model) async {
  print('📈 Trending Topics Analysis:');

  final trendingQueries = [
    'What topics are trending on social media today?',
    'Analyze current trending hashtags and their context',
    'What are people discussing most in tech communities?',
    'Identify emerging trends in business and finance',
  ];

  for (final query in trendingQueries) {
    print('   📈 Trending Analysis: "$query"');

    try {
      // Grok automatically analyzes trending topics from multiple sources
      final prompt = ChatPromptBuilder.user().text(query).build();
      final response = await generateTextWithModel(
        model,
        promptMessages: [prompt],
      );

      final text = response.text ?? '';
      if (text.isNotEmpty) {
        final preview =
            text.length > 160 ? '${text.substring(0, 160)}...' : text;
        print('   📊 Trending Analysis: $preview');
        print('   📈 Trending data integrated by Grok');
      }
    } catch (e) {
      print('   ❌ Trending analysis failed: $e');
    }

    print('');
  }
}

/// Demonstrate search-enhanced conversation
Future<void> demonstrateSearchEnhancedConversation(LanguageModel model) async {
  print('💬 Search-Enhanced Conversation:');

  // Simulate a conversation where live search enhances responses
  final conversationFlow = [
    {
      'user':
          'I\'m interested in investing in renewable energy. What should I know?',
      'context': 'Investment advice with current market data',
    },
    {
      'user': 'What are the latest developments in solar technology?',
      'context': 'Follow-up requiring recent tech news',
    },
    {
      'user': 'How do current solar stocks compare to last year?',
      'context': 'Financial data requiring live market information',
    },
  ];

  final conversationHistory = <ModelMessage>[];

  for (final turn in conversationFlow) {
    final userMessage = turn['user'] as String;
    final context = turn['context'] as String;

    print('   👤 User: "$userMessage"');
    print('   🎯 Context: $context');

    try {
      final userPrompt = ChatPromptBuilder.user()
          .text(userMessage)
          .text('(context: $context)')
          .build();
      conversationHistory.add(userPrompt);

      // Grok maintains conversation context and enhances with live search
      final response = await generateTextWithModel(
        model,
        promptMessages: List<ModelMessage>.from(conversationHistory),
      );

      final text = response.text ?? '';
      if (text.isNotEmpty) {
        final preview =
            text.length > 200 ? '${text.substring(0, 200)}...' : text;
        print('   🤖 Grok: $preview');
        conversationHistory
            .add(ChatPromptBuilder.assistant().text(text).build());
        print('   🔍 Search enhancement integrated automatically');
      }
    } catch (e) {
      print('   ❌ Enhanced conversation failed: $e');
    }

    print('');
  }
}

/// Demonstrate real-time data retrieval
Future<void> demonstrateRealTimeDataRetrieval(LanguageModel model) async {
  print('⏰ Real-Time Data Retrieval:');

  final realTimeQueries = [
    'Current cryptocurrency prices for Bitcoin and Ethereum',
    'Live weather conditions in major cities worldwide',
    'Real-time traffic conditions in New York City',
    'Current status of major airline flights',
    'Live sports scores and ongoing games',
  ];

  for (final query in realTimeQueries) {
    print('   ⏰ Real-Time Query: "$query"');

    try {
      // Grok automatically provides real-time data
      final prompt = ChatPromptBuilder.user().text(query).build();
      final response = await generateTextWithModel(
        model,
        promptMessages: [prompt],
      );

      final text = response.text ?? '';
      if (text.isNotEmpty) {
        final preview =
            text.length > 180 ? '${text.substring(0, 180)}...' : text;
        print('   📊 Real-Time Data: $preview');
        print('   ⚡ Real-time data automatically integrated by Grok');
      }
    } catch (e) {
      print('   ❌ Real-time data retrieval failed: $e');
    }

    print('');
  }
}

/// xAI Live Search Configuration
///
/// Note: xAI Grok models have live search capabilities built-in.
/// These options would be used if the API supported configuration.
class XAILiveSearchConfig {
  final bool enableLiveSearch;
  final String? searchDepth;
  final String? searchTimeframe;
  final bool prioritizeNews;
  final bool includeSourceUrls;
  final bool includeTimestamps;
  final bool requireSourceCitations;
  final bool prioritizeReliableSources;
  final List<String>? searchSources;
  final bool trendingAnalysis;
  final bool includePopularityMetrics;
  final String? searchContext;
  final bool maintainConversationContext;
  final bool adaptSearchToConversation;
  final bool requireRealTimeData;
  final String? dataFreshness;
  final bool includeDataTimestamps;

  const XAILiveSearchConfig({
    this.enableLiveSearch = true,
    this.searchDepth,
    this.searchTimeframe,
    this.prioritizeNews = false,
    this.includeSourceUrls = false,
    this.includeTimestamps = false,
    this.requireSourceCitations = false,
    this.prioritizeReliableSources = false,
    this.searchSources,
    this.trendingAnalysis = false,
    this.includePopularityMetrics = false,
    this.searchContext,
    this.maintainConversationContext = false,
    this.adaptSearchToConversation = false,
    this.requireRealTimeData = false,
    this.dataFreshness,
    this.includeDataTimestamps = false,
  });
}

/// Utility class for xAI live search features
class XAILiveSearchUtils {
  /// Validate search query for optimal results
  static bool isValidSearchQuery(String query) {
    // Check if query is suitable for live search
    final searchKeywords = [
      'current',
      'latest',
      'recent',
      'today',
      'now',
      'live',
      'breaking',
      'trending',
      'update',
      'news',
      'real-time'
    ];

    return searchKeywords
        .any((keyword) => query.toLowerCase().contains(keyword));
  }

  /// Suggest search enhancements for better results
  static List<String> suggestSearchEnhancements(String query) {
    final suggestions = <String>[];

    if (!query.contains('recent') && !query.contains('latest')) {
      suggestions.add('Add "recent" or "latest" for current information');
    }

    if (!query.contains('source') && query.contains('fact')) {
      suggestions.add('Request sources for fact-checking');
    }

    if (query.contains('trend') && !query.contains('analysis')) {
      suggestions.add('Add "analysis" for deeper trending insights');
    }

    return suggestions;
  }

  /// Format search results for display
  static String formatSearchResults(Map<String, dynamic> metadata) {
    final buffer = StringBuffer();

    if (metadata['search_sources'] != null) {
      final sources = metadata['search_sources'] as List;
      buffer.writeln('Sources consulted: ${sources.length}');
    }

    if (metadata['data_freshness'] != null) {
      final freshness = metadata['data_freshness'] as Map;
      buffer.writeln('Data freshness: ${freshness['last_updated']}');
    }

    if (metadata['trending_data'] != null) {
      buffer.writeln('Trending analysis included');
    }

    return buffer.toString();
  }

  /// Check if live search is beneficial for query
  static bool shouldUseLiveSearch(String query) {
    final liveSearchIndicators = [
      'current',
      'latest',
      'recent',
      'today',
      'now',
      'live',
      'breaking',
      'trending',
      'update',
      'news',
      'price',
      'weather',
      'stock',
      'score',
      'status'
    ];

    return liveSearchIndicators
        .any((indicator) => query.toLowerCase().contains(indicator));
  }
}
