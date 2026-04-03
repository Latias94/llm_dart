// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';
import 'package:llm_dart/legacy.dart';

/// 🔧 Enhanced Tool Calling - Advanced Tool Features
///
/// This example demonstrates the enhanced tool calling capabilities:
/// - Tool validation and error handling
/// - Tool choice strategies
/// - Structured outputs with tools
/// - Parallel tool execution
/// - Provider-specific tool features
/// - Complex nested object structures in tool parameters
///
/// Before running, set your API key:
/// export OPENAI_API_KEY="your-key"
void main() async {
  print('🔧 Enhanced Tool Calling - Advanced Tool Features\n');

  // Get API key
  final apiKey = Platform.environment['OPENAI_API_KEY'] ?? 'sk-TESTKEY';

  // Create AI provider with enhanced capabilities
  final provider = await ai()
      .openai()
      .apiKey(apiKey)
      .model('gpt-4o')
      .temperature(0.1)
      .maxTokens(1000)
      .build();

  // Demonstrate enhanced tool calling features
  await demonstrateToolValidation(provider);
  await demonstrateToolChoiceStrategies(provider);
  await demonstrateNestedObjectStructures(provider);
  await demonstrateStructuredOutputWithTools(provider);
  await demonstrateProviderSpecificFeatures();

  print('\n✅ Enhanced tool calling completed!');
}

/// Demonstrate tool validation and error handling
Future<void> demonstrateToolValidation(ChatCapability provider) async {
  print('🔍 Tool Validation and Error Handling:\n');

  try {
    // Define a calculator tool with strict validation
    final calculatorTool = Tool.function(
      name: 'calculate',
      description: 'Perform mathematical calculations with validation',
      parameters: ParametersSchema(
        schemaType: 'object',
        properties: {
          'expression': ParameterProperty(
            propertyType: 'string',
            description: 'Mathematical expression (e.g., "2 + 3 * 4")',
          ),
          'precision': ParameterProperty(
            propertyType: 'integer',
            description: 'Number of decimal places for result',
          ),
          'operation_type': ParameterProperty(
            propertyType: 'string',
            description: 'Type of mathematical operation',
            enumList: ['arithmetic', 'algebraic', 'trigonometric'],
          ),
        },
        required: ['expression'],
      ),
    );

    final messages = [
      ChatMessage.user('Calculate 15.7 * 8.3 with 2 decimal places precision')
    ];

    print('   User: Calculate 15.7 * 8.3 with 2 decimal places precision');
    print('   Available tools: calculate (with validation)');

    final response = await provider.chatWithTools(messages, [calculatorTool]);

    if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
      print('   🔧 Tool calls made:');

      for (final toolCall in response.toolCalls!) {
        print('      • Function: ${toolCall.function.name}');
        print('      • Arguments: ${toolCall.function.arguments}');

        // Validate tool call
        try {
          final isValid =
              ToolValidator.validateToolCall(toolCall, calculatorTool);
          print('      • Validation: ${isValid ? '✅ Valid' : '❌ Invalid'}');

          // Simulate tool execution
          final args =
              jsonDecode(toolCall.function.arguments) as Map<String, dynamic>;
          final expression = args['expression'] as String;
          final precision = args['precision'] as int? ?? 2;

          // Simple calculation simulation
          final result = _simulateCalculation(expression, precision);
          print('      • Result: $result');
        } catch (e) {
          if (e is ToolValidationError) {
            print('      • Validation Error: ${e.message}');
          } else {
            print('      • Execution Error: $e');
          }
        }
      }
    }

    print('   ✅ Tool validation completed\n');
  } catch (e) {
    print('   ❌ Tool validation failed: $e\n');
  }
}

/// Demonstrate different tool choice strategies
Future<void> demonstrateToolChoiceStrategies(ChatCapability provider) async {
  print('🎯 Tool Choice Strategies:\n');

  final tools = [
    Tool.function(
      name: 'get_weather',
      description: 'Get current weather information',
      parameters: ParametersSchema(
        schemaType: 'object',
        properties: {
          'location': ParameterProperty(
            propertyType: 'string',
            description: 'City and country',
          ),
        },
        required: ['location'],
      ),
    ),
    Tool.function(
      name: 'get_time',
      description: 'Get current time in timezone',
      parameters: ParametersSchema(
        schemaType: 'object',
        properties: {
          'timezone': ParameterProperty(
            propertyType: 'string',
            description: 'Timezone identifier',
          ),
        },
        required: ['timezone'],
      ),
    ),
  ];

  // Test different tool choice strategies
  final strategies = [
    ('Auto', const AutoToolChoice()),
    ('Required', const AnyToolChoice()),
    ('Specific', const SpecificToolChoice('get_weather')),
    ('None', const NoneToolChoice()),
  ];

  for (final (strategyName, toolChoice) in strategies) {
    print('   Testing $strategyName tool choice:');

    try {
      // Validate tool choice
      ToolValidator.validateToolChoice(toolChoice, tools);
      print('      • Tool choice validation: ✅ Valid');

      // Note: This would require EnhancedChatCapability implementation
      print('      • Strategy: $strategyName');
      print('      • Behavior: ${_describeToolChoiceBehavior(toolChoice)}');
    } catch (e) {
      print('      • Tool choice validation: ❌ $e');
    }

    print('');
  }

  print('   ✅ Tool choice strategies completed\n');
}

/// Demonstrate structured outputs with tools
Future<void> demonstrateStructuredOutputWithTools(
    ChatCapability provider) async {
  print('📊 Structured Output with Tools:\n');

  try {
    // Define structured output format
    final structuredFormat = StructuredOutputFormat(
      name: 'analysis_result',
      description: 'Structured analysis result with tool usage',
      schema: {
        'type': 'object',
        'properties': {
          'summary': {'type': 'string', 'description': 'Brief summary'},
          'tools_used': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'List of tools used'
          },
          'confidence': {
            'type': 'number',
            'description': 'Confidence score 0-1'
          },
          'recommendations': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'List of recommendations'
          },
        },
        'required': ['summary', 'tools_used', 'confidence'],
      },
      strict: true,
    );

    // Validate structured output format
    try {
      ToolValidator.validateStructuredOutput(structuredFormat);
      print('   📋 Structured output validation: ✅ Valid');
      print('   📋 Schema: ${structuredFormat.name}');
      print(
          '   📋 OpenAI format: ${structuredFormat.toOpenAIResponseFormat()}');
    } catch (e) {
      print('   📋 Structured output validation: ❌ $e');
    }

    print('   ✅ Structured output with tools completed\n');
  } catch (e) {
    print('   ❌ Structured output failed: $e\n');
  }
}

/// Demonstrate provider-specific tool features
Future<void> demonstrateProviderSpecificFeatures() async {
  print('🌐 Provider-Specific Tool Features:\n');

  // Test tool choice format conversion
  final toolChoice = const SpecificToolChoice('my_function');

  print('   Tool Choice Format Conversion:');
  print('      • OpenAI format: ${toolChoice.toOpenAIJson()}');
  print('      • Anthropic format: ${toolChoice.toAnthropicJson()}');
  print('      • xAI format: ${toolChoice.toXAIJson()}');

  // Test parallel tool configuration
  final parallelConfig = const ParallelToolConfig(
    maxParallel: 3,
    toolTimeout: Duration(seconds: 30),
    continueOnError: true,
  );

  print('\n   Parallel Tool Configuration:');
  print('      • Max parallel: ${parallelConfig.maxParallel}');
  print('      • Timeout: ${parallelConfig.toolTimeout?.inSeconds}s');
  print('      • Continue on error: ${parallelConfig.continueOnError}');
  print('      • JSON: ${parallelConfig.toJson()}');

  print('\n   ✅ Provider-specific features completed\n');
}

/// Simulate calculation for demonstration
String _simulateCalculation(String expression, int precision) {
  // This is a simple simulation - in real use, you'd implement proper calculation
  try {
    // For demo purposes, just return a formatted result
    final result = 130.31; // Simulated result of 15.7 * 8.3
    return result.toStringAsFixed(precision);
  } catch (e) {
    return 'Error: Invalid expression';
  }
}

/// Demonstrate complex nested object structures in tool parameters
Future<void> demonstrateNestedObjectStructures(ChatCapability provider) async {
  print('🏗️  Complex Nested Object Structures:\n');

  try {
    // Define a tool for processing orders with complex item structures
    final processOrdersTool = Tool.function(
      name: 'process_orders',
      description: 'Process customer orders with complex item structures',
      parameters: ParametersSchema(
        schemaType: 'object',
        properties: {
          'orders': ParameterProperty(
            propertyType: 'array',
            description: 'Array of customer orders',
            items: ParameterProperty(
              propertyType: 'object',
              description: 'Individual order object',
              properties: {
                'order_id': ParameterProperty(
                  propertyType: 'string',
                  description: 'Unique order identifier',
                ),
                'customer_name': ParameterProperty(
                  propertyType: 'string',
                  description: 'Customer full name',
                ),
                'items': ParameterProperty(
                  propertyType: 'array',
                  description: 'Array of items in the order',
                  items: ParameterProperty(
                    propertyType: 'object',
                    description: 'Individual item object',
                    properties: {
                      'product_name': ParameterProperty(
                        propertyType: 'string',
                        description: 'Name of the product',
                      ),
                      'quantity': ParameterProperty(
                        propertyType: 'integer',
                        description: 'Number of items ordered',
                      ),
                      'price': ParameterProperty(
                        propertyType: 'number',
                        description: 'Price per item in dollars',
                      ),
                      'category': ParameterProperty(
                        propertyType: 'string',
                        description: 'Product category',
                        enumList: ['electronics', 'clothing', 'books', 'home'],
                      ),
                    },
                    required: ['product_name', 'quantity', 'price'],
                  ),
                ),
                'total_amount': ParameterProperty(
                  propertyType: 'number',
                  description: 'Total order amount in dollars',
                ),
              },
              required: ['order_id', 'customer_name', 'items'],
            ),
          ),
        },
        required: ['orders'],
      ),
    );

    final messages = [
      ChatMessage.user(
        'Process order ORD001 for Alice Johnson: 2x Laptop at \$999 each (electronics), 1x T-shirt at \$25 (clothing). Total: \$2023. Use the process_orders tool.',
      )
    ];

    print('   User: Process order ORD001 for Alice Johnson...');
    print(
        '   Available tools: process_orders (with nested arrays and objects)');

    final response =
        await provider.chatWithTools(messages, [processOrdersTool]);

    if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
      print('   🔧 AI tool calls:');

      for (final toolCall in response.toolCalls!) {
        print('      • Function: ${toolCall.function.name}');
        print('      • Arguments: ${toolCall.function.arguments}');

        try {
          final isValid =
              ToolValidator.validateToolCall(toolCall, processOrdersTool);
          print('      • Validation: ${isValid ? '✅ Valid' : '❌ Invalid'}');

          final result = await _processOrders(toolCall);
          print('      • Result: $result');
        } catch (e) {
          print('      • Validation Error: $e');
        }
      }

      print('   ✅ Complex nested structures completed\n');
    } else {
      print('   ℹ️  AI chose not to use tools: ${response.text}\n');
    }
  } catch (e) {
    print('   ❌ Error: $e\n');
  }
}

/// Mock function to process orders
Future<String> _processOrders(ToolCall toolCall) async {
  try {
    final args =
        jsonDecode(toolCall.function.arguments) as Map<String, dynamic>;
    final orders = args['orders'] as List;

    double totalRevenue = 0;
    int totalItems = 0;

    for (final order in orders) {
      final o = order as Map<String, dynamic>;
      final items = o['items'] as List;

      for (final item in items) {
        final i = item as Map<String, dynamic>;
        totalItems += i['quantity'] as int;
        totalRevenue += (i['quantity'] as int) * (i['price'] as num);
      }
    }

    return 'Processed ${orders.length} orders, $totalItems items, \$${totalRevenue.toStringAsFixed(2)} revenue';
  } catch (e) {
    return 'Error processing orders: $e';
  }
}

/// Describe tool choice behavior
String _describeToolChoiceBehavior(ToolChoice toolChoice) {
  return switch (toolChoice) {
    AutoToolChoice() => 'Model decides whether to use tools',
    AnyToolChoice() => 'Model must use at least one tool',
    SpecificToolChoice(toolName: final name) => 'Model must use tool: $name',
    NoneToolChoice() => 'Model cannot use any tools',
  };
}
