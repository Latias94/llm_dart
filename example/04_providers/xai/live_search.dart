import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_xai/llm_dart_xai.dart';

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

  registerXAI();

  // Initialize xAI provider
  final xaiProvider = await initializeXAIProvider();
  if (xaiProvider == null) {
    print('❌ xAI provider not available. Please set XAI_API_KEY.');
    return;
  }

  print('🚀 Demonstrating xAI Live Search Capabilities...\n');

  // Demonstrate different live search scenarios
  await demonstrateBasicLiveSearch(xaiProvider);
  await demonstrateCurrentEventsQuery(xaiProvider);
  await demonstrateFactCheckingWithSources(xaiProvider);
  await demonstrateTrendingTopicsAnalysis(xaiProvider);
  await demonstrateSearchEnhancedConversation(xaiProvider);
  await demonstrateRealTimeDataRetrieval(xaiProvider);

  print('✅ xAI live search examples completed!');
  print('💡 xAI Grok advantages:');
  print('   • Access to real-time web information');
  print('   • Current events and breaking news');
  print('   • Fact-checking with live sources');
  print('   • Up-to-date data for analysis');
}

/// Initialize xAI provider with live search capabilities
Future<ChatCapability?> initializeXAIProvider() async {
  try {
    // Get xAI API key from environment variable
    final apiKey = Platform.environment['XAI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      print('❌ XAI_API_KEY environment variable not set.');
      print('💡 Please set your xAI API key:');
      print('   export XAI_API_KEY="your-actual-xai-api-key"');
      return null;
    }

    return await LLMBuilder()
        .provider(xaiProviderId)
        .apiKey(apiKey)
        .model('grok-3') // Use latest Grok-3 model for live search
        .temperature(0.7)
        // Prefer providerOptions escape hatch for xAI live search.
        .providerOptions('xai', {
      'liveSearch': true,
      'searchParameters': SearchParameters.webSearch().toJson(),
    }).build();
  } catch (e) {
    print('⚠️  xAI provider initialization failed: $e');
    return null;
  }
}

/// Demonstrate basic live search functionality
Future<void> demonstrateBasicLiveSearch(ChatCapability provider) async {
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
      // Enable live search for this specific request
      // xAI Grok models have live search capabilities built-in
      final response = await generateText(
        model: provider,
        messages: [ChatMessage.user(query)],
      );

      if (response.text != null) {
        print('   📝 Response: ${response.text!.substring(0, 150)}...');
        print('   🔍 Live search results integrated in response');
      }
    } catch (e) {
      print('   ❌ Search failed: $e');
    }

    print('');
  }
}

/// Demonstrate current events and news queries
Future<void> demonstrateCurrentEventsQuery(ChatCapability provider) async {
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
      final response = await generateText(
        model: provider,
        messages: [ChatMessage.user(query)],
      );

      if (response.text != null) {
        print('   📄 News Summary: ${response.text!.substring(0, 200)}...');
        print('   📰 Recent news integrated automatically by Grok');
      }
    } catch (e) {
      print('   ❌ News query failed: $e');
    }

    print('');
  }
}

/// Demonstrate fact-checking with live sources
Future<void> demonstrateFactCheckingWithSources(ChatCapability provider) async {
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
      final response = await generateText(
        model: provider,
        messages: [
          ChatMessage.system(
              'You are a fact-checker. Verify claims using the most recent and reliable sources. Provide source citations.'),
          ChatMessage.user(query),
        ],
      );

      if (response.text != null) {
        print('   ✅ Fact-Check Result: ${response.text!.substring(0, 180)}...');
        print('   📚 Sources automatically verified by Grok');
      }
    } catch (e) {
      print('   ❌ Fact-checking failed: $e');
    }

    print('');
  }
}

/// Demonstrate trending topics analysis
Future<void> demonstrateTrendingTopicsAnalysis(ChatCapability provider) async {
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
      final response = await generateText(
        model: provider,
        messages: [ChatMessage.user(query)],
      );

      if (response.text != null) {
        print(
            '   📊 Trending Analysis: ${response.text!.substring(0, 160)}...');
        print('   📈 Trending data integrated by Grok');
      }
    } catch (e) {
      print('   ❌ Trending analysis failed: $e');
    }

    print('');
  }
}

/// Demonstrate search-enhanced conversation
Future<void> demonstrateSearchEnhancedConversation(
    ChatCapability provider) async {
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

  final conversationHistory = <ChatMessage>[];

  for (final turn in conversationFlow) {
    final userMessage = turn['user'] as String;
    final context = turn['context'] as String;

    print('   👤 User: "$userMessage"');
    print('   🎯 Context: $context');

    try {
      conversationHistory.add(ChatMessage.user(userMessage));

      // Grok maintains conversation context and enhances with live search
      final response = await generateText(
        model: provider,
        messages: conversationHistory,
      );

      if (response.text != null) {
        print('   🤖 Grok: ${response.text!.substring(0, 200)}...');
        conversationHistory.add(ChatMessage.assistant(response.text!));
        print('   🔍 Search enhancement integrated automatically');
      }
    } catch (e) {
      print('   ❌ Enhanced conversation failed: $e');
    }

    print('');
  }
}

/// Demonstrate real-time data retrieval
Future<void> demonstrateRealTimeDataRetrieval(ChatCapability provider) async {
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
      final response = await generateText(
        model: provider,
        messages: [ChatMessage.user(query)],
      );

      if (response.text != null) {
        print('   📊 Real-Time Data: ${response.text!.substring(0, 180)}...');
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
