import 'dart:io';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart/providers/anthropic/anthropic.dart';

/// Helper utilities for Anthropic integration tests
class AnthropicTestHelpers {
  /// Check if integration tests can run (API key available)
  static bool get canRunIntegrationTests {
    final apiKey = Platform.environment['ANTHROPIC_API_KEY'] ?? '';
    return apiKey.isNotEmpty;
  }

  /// Get API key from environment
  static String get apiKey {
    final key = Platform.environment['ANTHROPIC_API_KEY'] ?? '';
    if (key.isEmpty) {
      throw StateError('ANTHROPIC_API_KEY environment variable not set');
    }
    return key;
  }

  /// Create a standard test provider
  static AnthropicProvider createTestProvider() {
    return createAnthropicProvider(
      apiKey: apiKey,
      model: 'claude-3-5-sonnet-20241022',
      maxTokens: 1000,
      temperature: 0.1,
    );
  }

  /// Create a provider optimized for tool testing
  static AnthropicProvider createToolTestProvider() {
    return createAnthropicProvider(
      apiKey: apiKey,
      model: 'claude-3-5-sonnet-20241022',
      maxTokens: 1500,
      temperature: 0.0, // More deterministic for tool calls
    );
  }

  /// Print test skip message when API key is not available
  static void printSkipMessage() {
    print('⚠️  ANTHROPIC_API_KEY not found. Skipping integration tests.');
    print('   Set ANTHROPIC_API_KEY environment variable to run these tests.');
  }

  /// Create a cached system message for testing
  static ChatMessage createCachedSystemMessage({
    required String content,
    AnthropicCacheTtl ttl = AnthropicCacheTtl.fiveMinutes,
    String? name,
  }) {
    var builder = MessageBuilder.system()
        .anthropic((anthropic) => anthropic.cachedText(content, ttl: ttl));
    
    if (name != null) {
      builder = builder.name(name);
    }
    
    return builder.build();
  }

  /// Create a tool result message
  static ChatMessage createToolResultMessage({
    required String toolUseId,
    required String content,
    bool isError = false,
  }) {
    return MessageBuilder.user()
        .anthropic((anthropic) => anthropic.toolResult(
              toolUseId: toolUseId,
              content: content,
              isError: isError,
            ))
        .build();
  }

  /// Print detailed response information
  static void printResponseDetails(ChatResponse response, {String? prefix}) {
    final prefixStr = prefix != null ? '$prefix: ' : '';
    print('${prefixStr}Response received');
    print('📝 Text length: ${response.text?.length ?? 0} characters');
    print('📊 Input tokens: ${response.usage?.promptTokens ?? 0}');
    print('📊 Output tokens: ${response.usage?.completionTokens ?? 0}');
    print('🔧 Tool calls: ${response.toolCalls?.length ?? 0}');
    
    if (response.text != null && response.text!.length > 100) {
      print('📄 Preview: ${response.text!.substring(0, 100)}...');
    } else if (response.text != null) {
      print('📄 Full text: ${response.text}');
    }
  }

  /// Assert response quality metrics
  static void assertResponseQuality(ChatResponse response) {
    // Basic assertions for response quality
    assert(response.text != null, 'Response should have text content');
    assert(response.text!.isNotEmpty, 'Response text should not be empty');
    assert(response.text!.length >= 10, 'Response should be meaningful (>= 10 chars)');
    
    if (response.usage != null) {
      assert(response.usage!.promptTokens != null && response.usage!.promptTokens! > 0, 'Should have prompt tokens');
      assert(response.usage!.completionTokens != null && response.usage!.completionTokens! > 0, 'Should have completion tokens');
    }
  }

  /// Measure execution time for performance testing
  static Future<T> measureExecutionTime<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      final name = operationName ?? 'Operation';
      print('⏱️  $name completed in ${stopwatch.elapsedMilliseconds}ms');
      
      return result;
    } catch (e) {
      stopwatch.stop();
      print('❌ Operation failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }
}

/// Predefined tools for testing scenarios
class TestTools {
  /// Web search tool for information retrieval tests
  static Tool get webSearchTool => Tool.function(
        name: 'web_search',
        description: 'Search the web for current information',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'query': ParameterProperty(
              propertyType: 'string',
              description: 'The search query to execute',
            ),
            'max_results': ParameterProperty(
              propertyType: 'integer',
              description: 'Maximum number of results to return',
            ),
          },
          required: ['query'],
        ),
      );

  /// Calculator tool for mathematical operations tests
  static Tool get calculatorTool => Tool.function(
        name: 'calculate',
        description: 'Perform mathematical calculations',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'expression': ParameterProperty(
              propertyType: 'string',
              description: 'Mathematical expression to evaluate',
            ),
            'precision': ParameterProperty(
              propertyType: 'integer',
              description: 'Number of decimal places for result',
            ),
          },
          required: ['expression'],
        ),
      );

  /// File operations tool for document handling tests
  static Tool get fileOperationsTool => Tool.function(
        name: 'file_operations',
        description: 'Perform file operations like read, write, or analyze',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'operation': ParameterProperty(
              propertyType: 'string',
              description: 'The file operation to perform',
              enumList: ['read', 'write', 'analyze', 'list'],
            ),
            'file_path': ParameterProperty(
              propertyType: 'string',
              description: 'Path to the file to operate on',
            ),
            'content': ParameterProperty(
              propertyType: 'string',
              description: 'Content for write operations',
            ),
          },
          required: ['operation', 'file_path'],
        ),
      );

  /// Data analysis tool for complex analysis scenarios
  static Tool get dataAnalysisTool => Tool.function(
        name: 'analyze_data',
        description: 'Analyze data and generate insights',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'data_type': ParameterProperty(
              propertyType: 'string',
              description: 'Type of data to analyze',
              enumList: ['sales', 'user_behavior', 'performance', 'financial'],
            ),
            'time_period': ParameterProperty(
              propertyType: 'string',
              description: 'Time period for analysis',
            ),
            'metrics': ParameterProperty(
              propertyType: 'array',
              description: 'Specific metrics to analyze',
              items: ParameterProperty(
                propertyType: 'string',
                description: 'Metric name',
              ),
            ),
          },
          required: ['data_type', 'time_period'],
        ),
      );

  /// All test tools for comprehensive scenarios
  static List<Tool> get allTools => [
        webSearchTool,
        calculatorTool,
        fileOperationsTool,
        dataAnalysisTool,
      ];
}

/// Test scenarios and prompts
class TestScenarios {
  /// System messages for different testing scenarios
  static const Map<String, String> systemMessages = {
    'general_assistant': 
        'You are a helpful AI assistant. Provide clear, accurate, and concise responses.',
    
    'code_reviewer': 
        'You are an expert code reviewer. Analyze code for best practices, '
        'performance issues, and potential bugs. Provide constructive feedback.',
    
    'data_analyst': 
        'You are a business data analyst. Analyze data patterns, generate insights, '
        'and provide actionable recommendations based on data.',
    
    'technical_writer': 
        'You are a technical documentation expert. Create clear, comprehensive '
        'documentation that helps users understand complex technical concepts.',
    
    'problem_solver': 
        'You are a systematic problem solver. Break down complex problems into '
        'manageable steps and provide logical, step-by-step solutions.',
  };

  /// User prompts for testing different capabilities
  static const Map<String, String> userPrompts = {
    'simple_question': 'What is the capital of France?',
    
    'complex_analysis': 
        'Analyze the trade-offs between microservices and monolithic architecture '
        'for a medium-sized e-commerce application.',
    
    'code_review_request': 
        'Please review this Dart code: class UserManager { final List<User> users = []; '
        'void addUser(User user) { users.add(user); } }',
    
    'tool_requiring_task': 
        'Calculate the compound interest for an investment of \$10,000 at 7% '
        'annual interest rate compounded monthly for 5 years.',
    
    'creative_task': 
        'Write a short story about a message that gets lost in a complex system '
        'and has to find its way through various components.',
    
    'research_task': 
        'What are the latest developments in quantum computing and their potential '
        'impact on current encryption methods?',
  };

  /// Get a test conversation for specific scenarios
  static List<ChatMessage> getTestConversation(String scenarioName) {
    final systemContent = systemMessages[scenarioName] ?? systemMessages['general_assistant']!;
    final userContent = userPrompts[scenarioName] ?? userPrompts['simple_question']!;

    return [
      AnthropicTestHelpers.createCachedSystemMessage(
        content: systemContent,
        ttl: AnthropicCacheTtl.fiveMinutes,
      ),
      MessageBuilder.user().text(userContent).build(),
    ];
  }
}