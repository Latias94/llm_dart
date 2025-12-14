// ignore_for_file: avoid_print
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

/// 🚀 Ollama Advanced Features - Performance & Optimization
///
/// This example demonstrates advanced Ollama features:
/// - Performance optimization with GPU acceleration
/// - Context length management
/// - Multimodal capabilities (vision models)
/// - Tool calling with local models
/// - Structured output generation
/// - Model memory management
///
/// Prerequisites:
/// 1. Install Ollama: curl -fsSL https://ollama.ai/install.sh | sh
/// 2. Download models: ollama pull llama3.2 && ollama pull llava
/// 3. Start Ollama server: ollama serve
///
/// Optional environment variable:
/// export OLLAMA_BASE_URL="http://localhost:11434"
void main() async {
  print('🚀 Ollama Advanced Features - Performance & Optimization\n');

  // Get Ollama base URL (defaults to localhost)
  final baseUrl =
      Platform.environment['OLLAMA_BASE_URL'] ?? 'http://localhost:11434';

  // Demonstrate different advanced features
  await demonstratePerformanceOptimization(baseUrl);
  await demonstrateContextManagement(baseUrl);
  await demonstrateStructuredOutput(baseUrl);
  await demonstrateModelMemoryManagement(baseUrl);
  await demonstrateToolCalling(baseUrl);

  print('\n✅ Ollama advanced features completed!');
}

/// Demonstrate performance optimization with GPU acceleration
Future<void> demonstratePerformanceOptimization(String baseUrl) async {
  print('⚡ Performance Optimization:\n');

  try {
    // High-performance configuration with GPU acceleration
    print('   High-Performance Configuration:');
    final highPerfModel = await ai()
        .ollama((ollama) => ollama
            .numCtx(4096) // Large context window
            .numGpu(1) // Use GPU acceleration
            .numThread(8) // Use 8 CPU threads
            .numa(false) // Disable NUMA for better performance
            .numBatch(512)) // Larger batch size
        .baseUrl(baseUrl)
        .model('llama3.2')
        .temperature(0.7)
        .buildLanguageModel();

    final stopwatch = Stopwatch()..start();
    final response = await generateTextPromptWithModel(
      highPerfModel,
      messages: [
        ModelMessage.userText('Explain quantum computing in 3 sentences.'),
      ],
    );
    stopwatch.stop();

    print('      Response: ${response.text}');
    print('      Time: ${stopwatch.elapsedMilliseconds}ms\n');

    // Memory-efficient configuration
    print('   Memory-Efficient Configuration:');
    final memoryEfficientModel = await ai()
        .ollama((ollama) => ollama
            .numCtx(2048) // Smaller context window
            .numGpu(0) // CPU only
            .numThread(4) // Fewer threads
            .numBatch(128)) // Smaller batch size
        .baseUrl(baseUrl)
        .model('llama3.2')
        .temperature(0.7)
        .buildLanguageModel();

    final stopwatch2 = Stopwatch()..start();
    final response2 = await generateTextPromptWithModel(
      memoryEfficientModel,
      messages: [
        ModelMessage.userText('What is machine learning?'),
      ],
    );
    stopwatch2.stop();

    print('      Response: ${response2.text}');
    print('      Time: ${stopwatch2.elapsedMilliseconds}ms');

    print('   ✅ Performance optimization demonstration completed\n');
  } catch (e) {
    print('   ❌ Performance optimization failed: $e\n');
  }
}

/// Demonstrate context length management
Future<void> demonstrateContextManagement(String baseUrl) async {
  print('📝 Context Management:\n');

  try {
    // Long context configuration
    final longContextModel = await ai()
        .ollama((ollama) => ollama
            .numCtx(8192) // Large context window
            .keepAlive('10m')) // Keep model in memory longer
        .baseUrl(baseUrl)
        .model('llama3.2')
        .buildLanguageModel();

    // Build a long conversation
    final conversation = [
      ModelMessage.systemText(
        'You are a helpful assistant with excellent memory.',
      ),
      ModelMessage.userText(
        'I\'m planning a trip to Japan. What should I know?',
      ),
    ];

    var response = await generateTextPromptWithModel(
      longContextModel,
      messages: conversation,
    );

    final firstReply = response.text;
    if (firstReply != null && firstReply.isNotEmpty) {
      conversation.add(ModelMessage.assistantText(firstReply));
      final truncated = firstReply.length > 100
          ? '${firstReply.substring(0, 100)}...'
          : firstReply;
      print('   Assistant: $truncated\n');
    }

    // Continue conversation with context
    conversation.add(
      ModelMessage.userText('What about the best time to visit?'),
    );
    response = await generateTextPromptWithModel(
      longContextModel,
      messages: conversation,
    );

    final secondReply = response.text;
    if (secondReply != null && secondReply.isNotEmpty) {
      conversation.add(ModelMessage.assistantText(secondReply));
      final truncated = secondReply.length > 100
          ? '${secondReply.substring(0, 100)}...'
          : secondReply;
      print('   Assistant: $truncated\n');
    }

    // Add more context
    conversation.add(
      ModelMessage.userText('And what about food recommendations?'),
    );
    response = await generateTextPromptWithModel(
      longContextModel,
      messages: conversation,
    );

    final thirdReply = response.text;
    if (thirdReply != null && thirdReply.isNotEmpty) {
      final truncated = thirdReply.length > 100
          ? '${thirdReply.substring(0, 100)}...'
          : thirdReply;
      print('   Assistant: $truncated\n');
    }

    print('   💡 Context Tips:');
    print('      • Larger numCtx = more memory usage but better context');
    print('      • Use keepAlive to avoid reloading models');
    print('      • Monitor memory usage with long contexts');
    print('   ✅ Context management demonstration completed\n');
  } catch (e) {
    print('   ❌ Context management failed: $e\n');
  }
}

/// Demonstrate structured output generation
Future<void> demonstrateStructuredOutput(String baseUrl) async {
  print('🏗️ Structured Output:\n');

  try {
    // Configure for JSON output
    final structuredModel = await ai()
        .ollama()
        .baseUrl(baseUrl)
        .model('llama3.2')
        .temperature(0.1) // Lower temperature for consistent structure
        .jsonSchema(StructuredOutputFormat(
          name: 'product_review',
          schema: {
            'type': 'object',
            'properties': {
              'rating': {'type': 'integer', 'minimum': 1, 'maximum': 5},
              'summary': {'type': 'string'},
              'pros': {
                'type': 'array',
                'items': {'type': 'string'}
              },
              'cons': {
                'type': 'array',
                'items': {'type': 'string'}
              },
              'recommended': {'type': 'boolean'}
            },
            'required': ['rating', 'summary', 'pros', 'cons', 'recommended']
          },
        ))
        .buildLanguageModel();

    final response = await generateTextPromptWithModel(
      structuredModel,
      messages: [
        ModelMessage.userText(
          'Review this product: '
          '"Wireless headphones with 30-hour battery life, noise '
          'cancellation, and comfortable fit. Price: \$150."',
        ),
      ],
    );

    print('   Structured Review:');
    print('   ${response.text}');

    print('   ✅ Structured output demonstration completed\n');
  } catch (e) {
    print('   ❌ Structured output failed: $e\n');
  }
}

/// Demonstrate model memory management
Future<void> demonstrateModelMemoryManagement(String baseUrl) async {
  print('🧠 Model Memory Management:\n');

  try {
    // Short-lived model (unloads quickly)
    print('   Short-lived model configuration:');
    final shortLivedModel = await ai()
        .ollama((ollama) => ollama.keepAlive('30s')) // Unload after 30 seconds
        .baseUrl(baseUrl)
        .model('llama3.2')
        .buildLanguageModel();

    await generateTextPromptWithModel(
      shortLivedModel,
      messages: [ModelMessage.userText('Hello!')],
    );
    print('      ✅ Model will unload in 30 seconds');

    // Long-lived model (stays in memory)
    print('   Long-lived model configuration:');
    final longLivedModel = await ai()
        .ollama((ollama) =>
            ollama.keepAlive('30m')) // Keep in memory for 30 minutes
        .baseUrl(baseUrl)
        .model('llama3.2')
        .buildLanguageModel();

    await generateTextPromptWithModel(
      longLivedModel,
      messages: [ModelMessage.userText('Hello!')],
    );
    print('      ✅ Model will stay loaded for 30 minutes');

    print('   💡 Memory Management Tips:');
    print('      • Use short keepAlive for infrequent usage');
    print('      • Use long keepAlive for frequent usage');
    print('      • Monitor system memory usage');
    print('      • Consider model size vs available RAM');
    print('   ✅ Memory management demonstration completed\n');
  } catch (e) {
    print('   ❌ Memory management failed: $e\n');
  }
}

/// Demonstrate tool calling with local models
Future<void> demonstrateToolCalling(String baseUrl) async {
  print('🔧 Tool Calling:\n');

  try {
    // Define a simple tool
    final weatherTool = Tool.function(
      name: 'get_weather',
      description: 'Get current weather for a location',
      parameters: ParametersSchema(
        schemaType: 'object',
        properties: {
          'location': ParameterProperty(
            propertyType: 'string',
            description: 'The city and country, e.g. "London, UK"',
          ),
          'unit': ParameterProperty(
            propertyType: 'string',
            description: 'Temperature unit',
            enumList: ['celsius', 'fahrenheit'],
          ),
        },
        required: ['location'],
      ),
    );

    final toolModel = await ai()
        .ollama()
        .baseUrl(baseUrl)
        .model('llama3.2') // Ensure model supports tool calling
        .temperature(0.1)
        .tools([weatherTool]).buildLanguageModel();

    final response = await generateTextPromptWithModel(
      toolModel,
      messages: [
        ModelMessage.userText('What\'s the weather like in Tokyo?'),
      ],
    );

    print('   Tool Response:');
    if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
      for (final toolCall in response.toolCalls!) {
        print('      Tool: ${toolCall.function.name}');
        print('      Arguments: ${toolCall.function.arguments}');
      }
    } else {
      print('      Text: ${response.text}');
    }

    print('   ✅ Tool calling demonstration completed\n');
  } catch (e) {
    print('   ❌ Tool calling failed: $e\n');
  }
}

/// 🎯 Key Advanced Features Summary:
///
/// Performance Optimization:
/// - numGpu: Enable GPU acceleration for faster inference
/// - numThread: Control CPU thread usage
/// - numBatch: Optimize batch processing
/// - numa: NUMA support for multi-socket systems
///
/// Context Management:
/// - numCtx: Control context window size
/// - keepAlive: Manage model memory persistence
/// - Balance memory usage vs context length
///
/// Structured Output:
/// - JSON schema validation
/// - Consistent data format
/// - Perfect for API integrations
///
/// Memory Management:
/// - keepAlive duration control
/// - Model loading/unloading optimization
/// - Resource usage monitoring
///
/// Tool Integration:
/// - Local tool calling capabilities
/// - Function definition and execution
/// - Enhanced AI capabilities
///
/// Best Practices:
/// - Start with default settings and optimize based on needs
/// - Monitor system resources during usage
/// - Use appropriate context lengths for your use case
/// - Consider model size vs available hardware
/// - Test different configurations for your specific workload
