import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

/// Unified Web Search Example
///
/// This example demonstrates the unified web search functionality that works
/// across different LLM providers with a consistent, ergonomic API.
///
/// **Supported Providers:**
/// - **xAI Grok**: Live Search with real-time web/news access
/// - **Anthropic Claude**: Web Search Tool with domain filtering
/// - **OpenAI**: Web Search with context size control
/// - **OpenRouter**: Plugin-based search with custom prompts
/// - **Perplexity**: Native search capabilities
///
/// **Key Features:**
/// - Provider-agnostic API
/// - Automatic adaptation to each provider's implementation
/// - Rich configuration options
/// - Type-safe parameters
void main() async {
  print('🔍 Unified Web Search API Demo\n');

  // Get API keys from environment
  final xaiApiKey = Platform.environment['XAI_API_KEY'];
  final anthropicApiKey = Platform.environment['ANTHROPIC_API_KEY'];
  final openaiApiKey = Platform.environment['OPENAI_API_KEY'];
  final openrouterApiKey = Platform.environment['OPENROUTER_API_KEY'];

  if (xaiApiKey == null &&
      anthropicApiKey == null &&
      openaiApiKey == null &&
      openrouterApiKey == null) {
    print('❌ Please set at least one API key:');
    print('   - XAI_API_KEY for xAI Grok');
    print('   - ANTHROPIC_API_KEY for Claude');
    print('   - OPENAI_API_KEY for OpenAI');
    print('   - OPENROUTER_API_KEY for OpenRouter');
    return;
  }

  // Demo 1: Basic unified web search
  await demoBasicWebSearch(
      xaiApiKey, anthropicApiKey, openaiApiKey, openrouterApiKey);

  // Demo 2: Provider-specific configurations
  await demoProviderSpecificConfigs(
      xaiApiKey, anthropicApiKey, openaiApiKey, openrouterApiKey);

  // Demo 3: Advanced search scenarios
  await demoAdvancedSearchScenarios(xaiApiKey, anthropicApiKey);

  // Demo 4: Configuration examples
  await demoConfigurationExamples();
}

/// Demo basic web search across all available providers
Future<void> demoBasicWebSearch(String? xaiKey, String? anthropicKey,
    String? openaiKey, String? openrouterKey) async {
  print('🚀 Basic Web Search Demo');
  print('=' * 50);

  final query = 'What are the latest developments in AI this week?';
  print('Query: "$query"\n');
  final prompt = ChatPromptBuilder.user().text(query).build();

  // xAI Grok
  if (xaiKey != null) {
    try {
      print('🤖 xAI Grok:');
      final model = await ai()
          .xai()
          .apiKey(xaiKey)
          .model('grok-3')
          .enableWebSearch()
          .buildLanguageModel();

      final response = await generateTextWithModel(
        model,
        promptMessages: [prompt],
      );
      final text = response.text ?? '';
      print(
          '   ${text.length > 200 ? '${text.substring(0, 200)}...' : text}\n');
    } catch (e) {
      print('   ❌ Error: $e\n');
    }
  }

  // Anthropic Claude
  if (anthropicKey != null) {
    try {
      print('🧠 Anthropic Claude:');
      final model = await ai()
          .anthropic()
          .apiKey(anthropicKey)
          .model('claude-sonnet-4-20250514')
          .enableWebSearch()
          .buildLanguageModel();

      final response = await generateTextWithModel(
        model,
        promptMessages: [prompt],
      );
      final text = response.text ?? '';
      print(
          '   ${text.length > 200 ? '${text.substring(0, 200)}...' : text}\n');
    } catch (e) {
      print('   ❌ Error: $e\n');
    }
  }

  // OpenAI
  if (openaiKey != null) {
    try {
      print('🔍 OpenAI:');
      final model = await ai()
          .openai()
          .apiKey(openaiKey)
          .model('gpt-4o-search-preview')
          .enableWebSearch()
          .buildLanguageModel();

      final response = await generateTextWithModel(
        model,
        promptMessages: [prompt],
      );
      final text = response.text ?? '';
      print(
          '   ${text.length > 200 ? '${text.substring(0, 200)}...' : text}\n');
    } catch (e) {
      print('   ❌ Error: $e\n');
    }
  }

  // OpenRouter
  if (openrouterKey != null) {
    try {
      print('🌐 OpenRouter:');
      final model = await ai()
          .openRouter()
          .apiKey(openrouterKey)
          .model('anthropic/claude-3.5-sonnet:online')
          .enableWebSearch()
          .buildLanguageModel();

      final response = await generateTextWithModel(
        model,
        promptMessages: [prompt],
      );
      final text = response.text ?? '';
      print(
          '   ${text.length > 200 ? '${text.substring(0, 200)}...' : text}\n');
    } catch (e) {
      print('   ❌ Error: $e\n');
    }
  }

  print('✅ Same API, different providers!\n');
}

/// Demo provider-specific configurations
Future<void> demoProviderSpecificConfigs(String? xaiKey, String? anthropicKey,
    String? openaiKey, String? openrouterKey) async {
  print('⚙️  Provider-Specific Configurations');
  print('=' * 50);

  // xAI with news search
  if (xaiKey != null) {
    try {
      print('\n1. xAI News Search:');
      final model = await ai()
          .xai()
          .apiKey(xaiKey)
          .newsSearch(
            maxResults: 5,
            fromDate: '2024-12-01',
          )
          .buildLanguageModel();

      final prompt = ChatPromptBuilder.user()
          .text('What are the top tech news stories this month?')
          .build();
      final response = await generateTextWithModel(
        model,
        promptMessages: [prompt],
      );
      final text = response.text ?? '';
      print(
          '   ${text.length > 200 ? '${text.substring(0, 200)}...' : text}\n');
    } catch (e) {
      print('   ❌ Error: $e\n');
    }
  }

  // Anthropic with domain filtering
  if (anthropicKey != null) {
    try {
      print('2. Anthropic with Domain Filtering:');
      final model = await ai()
          .anthropic()
          .apiKey(anthropicKey)
          .webSearch(
            maxUses: 3,
            allowedDomains: ['wikipedia.org', 'github.com', 'arxiv.org'],
            location: WebSearchLocation.sanFrancisco(),
          )
          .buildLanguageModel();

      final prompt = ChatPromptBuilder.user()
          .text('Find information about machine learning research')
          .build();
      final response = await generateTextWithModel(
        model,
        promptMessages: [prompt],
      );
      final text = response.text ?? '';
      print(
          '   ${text.length > 200 ? '${text.substring(0, 200)}...' : text}\n');
    } catch (e) {
      print('   ❌ Error: $e\n');
    }
  }

  // OpenAI with context size
  if (openaiKey != null) {
    try {
      print('3. OpenAI with High Context:');
      final model = await ai()
          .openai((openai) =>
              openai.webSearch(contextSize: WebSearchContextSize.high))
          .apiKey(openaiKey)
          .model('gpt-4o-search-preview')
          .buildLanguageModel();

      final prompt = ChatPromptBuilder.user()
          .text('Explain quantum computing breakthroughs')
          .build();
      final response = await generateTextWithModel(
        model,
        promptMessages: [prompt],
      );
      final text = response.text ?? '';
      print(
          '   ${text.length > 200 ? '${text.substring(0, 200)}...' : text}\n');
    } catch (e) {
      print('   ❌ Error: $e\n');
    }
  }

  // OpenRouter with custom search prompt
  if (openrouterKey != null) {
    try {
      print('4. OpenRouter with Custom Search Prompt:');
      final model = await ai()
          .openRouter((openrouter) => openrouter.webSearch(
                maxResults: 5,
                searchPrompt: 'Focus on recent academic papers and research',
              ))
          .apiKey(openrouterKey)
          .model('anthropic/claude-3.5-sonnet')
          .buildLanguageModel();

      final prompt = ChatPromptBuilder.user()
          .text('Find recent AI research papers')
          .build();
      final response = await generateTextWithModel(
        model,
        promptMessages: [prompt],
      );
      final text = response.text ?? '';
      print(
          '   ${text.length > 200 ? '${text.substring(0, 200)}...' : text}\n');
    } catch (e) {
      print('   ❌ Error: $e\n');
    }
  }
}

/// Demo advanced search scenarios
Future<void> demoAdvancedSearchScenarios(
    String? xaiKey, String? anthropicKey) async {
  print('🎯 Advanced Search Scenarios');
  print('=' * 50);

  if (xaiKey != null) {
    try {
      print('\n1. Real-time Information Query:');
      final model = await ai()
          .xai()
          .apiKey(xaiKey)
          .quickWebSearch(maxResults: 3)
          .buildLanguageModel();

      final prompt = ChatPromptBuilder.user()
          .text(
              'What is the current stock price of NVIDIA and recent news about the company?')
          .build();
      final response = await generateTextWithModel(
        model,
        promptMessages: [prompt],
      );
      final text = response.text ?? '';
      print(
          '   ${text.length > 300 ? '${text.substring(0, 300)}...' : text}\n');
    } catch (e) {
      print('   ❌ Error: $e\n');
    }
  }

  if (anthropicKey != null) {
    try {
      print('2. Academic Research Query:');
      final model = await ai()
          .anthropic()
          .apiKey(anthropicKey)
          .advancedWebSearch(
            strategy: WebSearchStrategy.tool,
            maxUses: 3,
            allowedDomains: ['arxiv.org', 'scholar.google.com', 'nature.com'],
            searchType: WebSearchType.academic,
          )
          .buildLanguageModel();

      final prompt = ChatPromptBuilder.user()
          .text(
              'Find recent papers on large language model efficiency improvements')
          .build();
      final response = await generateTextWithModel(
        model,
        promptMessages: [prompt],
      );
      final text = response.text ?? '';
      print(
          '   ${text.length > 300 ? '${text.substring(0, 300)}...' : text}\n');
    } catch (e) {
      print('   ❌ Error: $e\n');
    }
  }
}

/// Demo configuration examples (documentation purposes)
Future<void> demoConfigurationExamples() async {
  print('📚 Configuration Examples');
  print('=' * 50);

  print('\n1. Simple Web Search:');
  print('''
  final model = await ai()
      .xai()
      .apiKey(apiKey)
      .enableWebSearch()  // Just enable it!
      .buildLanguageModel();
  ''');

  print('2. Quick Configuration:');
  print('''
  final provider = await ai()
      .anthropic()
      .apiKey(apiKey)
      .quickWebSearch(maxResults: 5)
      .build();
  ''');

  print('3. Provider-Specific:');
  print('''
  // xAI with news search
  final xaiProvider = await ai()
      .xai()
      .apiKey(apiKey)
      .newsSearch(fromDate: '2024-01-01')
      .build();

  // Anthropic with domain filtering
  final anthropicProvider = await ai()
      .anthropic()
      .apiKey(apiKey)
      .webSearch(
        allowedDomains: ['wikipedia.org'],
        location: WebSearchLocation.london(),
      )
      .build();

  // OpenAI with context control
  final openaiProvider = await ai()
      .openai((openai) => openai
          .webSearch(contextSize: WebSearchContextSize.high))
      .apiKey(apiKey)
      .model('gpt-4o-search-preview')
      .build();
  ''');

  print('4. Advanced Configuration:');
  print('''
  final provider = await ai()
      .anthropic()
      .apiKey(apiKey)
      .advancedWebSearch(
        strategy: WebSearchStrategy.tool,
        contextSize: WebSearchContextSize.high,
        maxUses: 3,
        allowedDomains: ['arxiv.org', 'github.com'],
        blockedDomains: ['spam-site.com'],
        location: WebSearchLocation.sanFrancisco(),
        searchType: WebSearchType.academic,
      )
      .build();
  ''');

  print('\n✨ The unified API automatically adapts to each provider!');
}
