/// Example demonstrating OpenAI's new Responses API
///
/// This example shows how to use the Responses API with built-in tools
/// like web search, file search, and computer use.
///
/// ## Two Ways to Build OpenAI Responses API Providers:
///
/// ### Method 1: Traditional approach with capability detection
/// ```dart
/// final provider = await ai()
///     .openai((openai) => openai.useResponsesAPI())
///     .apiKey(apiKey)
///     .model('gpt-4o')
///     .build();
///
/// // Requires type checking and casting
/// if (provider is ProviderCapabilities &&
///     (provider as ProviderCapabilities).supports(LLMCapability.openaiResponses) &&
///     provider is OpenAIProvider) {
///   final responses = (provider as OpenAIProvider).responses!;
///   // Use responses...
/// }
/// ```
///
/// ### Method 2: Direct approach with buildOpenAIResponses() (Recommended)
/// ```dart
/// final provider = await ai()
///     .openai((openai) => openai.webSearchTool())
///     .apiKey(apiKey)
///     .model('gpt-4o')
///     .buildOpenAIResponses();
///
/// // Direct access - no type checking needed!
/// final responses = provider.responses!;
/// // Use responses...
/// ```
///
/// The `buildOpenAIResponses()` method automatically enables the Responses API
/// and returns a properly typed OpenAIProvider, eliminating the need for
/// capability detection and type casting.
library;

import 'dart:io';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

void main() async {
  print('=== OpenAI Responses API Examples ===\n');

  // Get API key from environment
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null) {
    print('Please set OPENAI_API_KEY environment variable');
    print('Skipping API examples...\n');
    return;
  }

  // Example 0: Capability detection for type-safe usage
  await capabilityDetectionExample(apiKey);

  // Example 1: Basic Responses API usage
  await basicResponsesAPIExample(apiKey);

  // Example 2: Web search with Responses API
  await webSearchExample(apiKey);

  // Example 3: File search with Responses API
  await fileSearchExample(apiKey);

  // Example 4: Function calling
  await functionCallingExample(apiKey);

  // Example 5: Reasoning with o-series models
  await reasoningExample(apiKey);

  // Example 6: Multiple built-in tools
  await multipleToolsExample(apiKey);

  // Example 7: Streaming with Responses API
  await streamingExample(apiKey);

  // Example 8: Response chaining
  await responseChainingExample(apiKey);

  // Example 9: Stateful conversation management
  await statefulConversationExample(apiKey);

  // Example 10: Background processing
  await backgroundProcessingExample(apiKey);

  // Example 11: Response lifecycle management
  await responseLifecycleExample(apiKey);
}

/// Build a single user ModelMessage and bridge it to ChatMessage.
List<ChatMessage> _userMessages(String text) {
  final prompt = ChatPromptBuilder.user().text(text).build();
  return [ChatMessage.fromPromptMessage(prompt)];
}

/// Example 0: Capability detection for type-safe Responses API usage
Future<void> capabilityDetectionExample(String apiKey) async {
  print('--- Example 0: Capability Detection ---');

  try {
    // Create standard OpenAI provider (without Responses API)
    // Standard provider (Chat Completions) – shown for capability contrast.
    final standardProvider =
        await ai().openai().apiKey(apiKey).model('gpt-4o-mini').build();

    print('Standard Provider Capabilities:');
    if (standardProvider is ProviderCapabilities) {
      _printCapabilities(standardProvider as ProviderCapabilities);
    }

    // Create OpenAI provider with Responses API enabled
    final responsesProvider = await ai()
        .openai((openai) => openai.useResponsesAPI().webSearchTool())
        .apiKey(apiKey)
        .model('gpt-4o')
        .build();

    print('\nResponses API Provider Capabilities:');
    if (responsesProvider is ProviderCapabilities) {
      _printCapabilities(responsesProvider as ProviderCapabilities);
    }

    // Type-safe capability detection and usage
    print('\nType-Safe Capability Usage:');

    if (responsesProvider is ProviderCapabilities &&
        (responsesProvider as ProviderCapabilities)
            .supports(LLMCapability.openaiResponses)) {
      print('✅ OpenAI Responses API capability detected');

      // Safe casting to OpenAI provider
      if (responsesProvider is openai.OpenAIProvider) {
        final openai.OpenAIProvider responsesProviderTyped = responsesProvider;
        final responsesAPI = responsesProviderTyped.responses;
        if (responsesAPI != null) {
          print('✅ Responses API module available');
          print('   • Stateful conversations: Available');
          print('   • Background processing: Available');
          print('   • Response lifecycle: Available');
          print('   • Built-in tools: Available');

          // Demonstrate type-safe access
          final testResponse = await responsesAPI.chat(
            _userMessages('Hello! This is a capability test.'),
          );

          if (testResponse is OpenAIResponsesResponse) {
            final responseId = testResponse.responseId;
            print(
                '   • Response ID: ${responseId?.substring(0, 20) ?? 'None'}...');
          }
        } else {
          print('❌ Responses API module not initialized');
        }
      } else {
        print('❌ Provider is not OpenAIProvider type');
      }

      // Demonstrate buildOpenAIResponses() convenience method
      print('\n🚀 Using buildOpenAIResponses() convenience method:');
      try {
        final autoProvider = await ai()
            .openai((openai) => openai.webSearchTool())
            .apiKey(apiKey)
            .model('gpt-4o')
            .buildOpenAIResponses();

        print('✅ Auto-configured OpenAI Responses provider created');
        print('   • Type: ${autoProvider.runtimeType}');
        print(
            '   • Responses API: ${autoProvider.responses != null ? 'Available' : 'Not Available'}');
        print(
            '   • Supports openaiResponses capability: ${autoProvider.supports(LLMCapability.openaiResponses)}');

        // Direct access without casting
        final directAPI = autoProvider.responses!;
        final quickTest = await directAPI.chat(
          _userMessages('Quick test of buildOpenAIResponses()'),
        );
        print(
            '   • Quick test response: ${quickTest.text?.substring(0, 50) ?? 'No text'}...');
      } catch (e) {
        print('❌ Error with buildOpenAIResponses(): $e');
      }
    } else {
      print('❌ OpenAI Responses API capability not available');
      print('💡 Enable with: .openai((openai) => openai.useResponsesAPI())');
    }

    print('');
  } catch (e) {
    print('Error in capability detection: $e\n');
  }
}

/// Helper function to print provider capabilities
void _printCapabilities(ProviderCapabilities provider) {
  final capabilities = provider.supportedCapabilities.toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  for (final capability in capabilities) {
    final icon = capability == LLMCapability.openaiResponses ? '🚀' : '✅';
    print('   $icon ${capability.name}');
  }

  print('   📊 Total: ${capabilities.length} capabilities');
}

/// Example 1: Basic Responses API usage
Future<void> basicResponsesAPIExample(String apiKey) async {
  print('--- Example 1: Basic Responses API ---');

  try {
    final provider = await ai()
        .openai((openai) => openai.useResponsesAPI())
        .apiKey(apiKey)
        .model('gpt-4.1')
        .temperature(0.7)
        .build();

    final response = await provider.chat(
      _userMessages(
        'Explain the difference between Responses API and Chat Completions API',
      ),
    );
    print('Response: ${response.text}\n');

    if (response.thinking != null) {
      print('Thinking: ${response.thinking}\n');
    }
  } catch (e) {
    print('Error in basic example: $e\n');
    print('Stack trace: ${StackTrace.current}');
  }
}

/// Example 2: Web search with Responses API
Future<void> webSearchExample(String apiKey) async {
  print('--- Example 2: Web Search ---');

  try {
    final provider = await ai()
        .openai((openai) => openai.useResponsesAPI().webSearchTool())
        .apiKey(apiKey)
        .model('gpt-4.1')
        .build();

    final response = await provider.chat(
      _userMessages('What are the latest developments in AI from this week?'),
    );
    print('Response with web search: ${response.text}\n');
  } catch (e) {
    print('Error in web search example: $e\n');
  }
}

/// Example 4: Function calling with Responses API
Future<void> functionCallingExample(String apiKey) async {
  print('--- Example 4: Function Calling ---');

  try {
    final provider = await ai()
        .openai((openai) => openai.useResponsesAPI())
        .apiKey(apiKey)
        .model('gpt-4.1')
        .build();

    // Define a simple weather function
    final tools = [
      Tool.function(
        name: 'get_current_weather',
        description: 'Get the current weather in a given location',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'location': ParameterProperty(
              propertyType: 'string',
              description: 'The city and state, e.g. San Francisco, CA',
            ),
            'unit': ParameterProperty(
              propertyType: 'string',
              description: 'Temperature unit',
              enumList: ['celsius', 'fahrenheit'],
            ),
          },
          required: ['location', 'unit'],
        ),
      ),
    ];

    final response = await provider.chatWithTools(
      _userMessages('What is the weather like in Boston today?'),
      tools,
    );

    if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
      print('Function call requested:');
      for (final toolCall in response.toolCalls!) {
        print('  Function: ${toolCall.function.name}');
        print('  Arguments: ${toolCall.function.arguments}');
      }
    } else {
      print('Response: ${response.text}');
    }
    print('');
  } catch (e) {
    print('Error in function calling example: $e\n');
  }
}

/// Example 5: Reasoning with o-series models
Future<void> reasoningExample(String apiKey) async {
  print('--- Example 5: Reasoning with o-series models ---');

  try {
    final provider = await ai()
        .openai((openai) => openai.useResponsesAPI())
        .apiKey(apiKey)
        .model('o3-mini') // Use o-series model for reasoning
        .reasoningEffort(ReasoningEffort.high)
        .maxTokens(2000)
        .build();

    final response = await provider.chat(
      _userMessages(
        'How much wood would a woodchuck chuck if a woodchuck could chuck wood? Please think through this step by step.',
      ),
    );
    print('Response: ${response.text}\n');

    if (response.thinking != null) {
      print('Reasoning process: ${response.thinking}\n');
    }

    // Check usage for reasoning tokens
    if (response.usage != null) {
      print('Usage:');
      print('  Input tokens: ${response.usage!.promptTokens}');
      print('  Output tokens: ${response.usage!.completionTokens}');
      if (response.usage!.reasoningTokens != null) {
        print('  Reasoning tokens: ${response.usage!.reasoningTokens}');
      }
      print('  Total tokens: ${response.usage!.totalTokens}');
    }
    print('');
  } catch (e) {
    print('Error in reasoning example: $e\n');
  }
}

/// Example 6: File search with Responses API
Future<void> fileSearchExample(String apiKey) async {
  print('--- Example 3: File Search ---');

  try {
    // Note: You would need to create vector stores first
    // This is just an example of the API usage
    final provider = await ai()
        .openai((openai) => openai.useResponsesAPI().fileSearchTool(
              vectorStoreIds: [
                'vs_example123'
              ], // Replace with actual vector store IDs
              parameters: {'max_num_results': 20},
            ))
        .apiKey(apiKey)
        .model('gpt-4.1')
        .build();

    final response = await provider.chat(
      _userMessages(
        'Search for information about machine learning in the uploaded documents',
      ),
    );
    print('Response with file search: ${response.text}\n');
  } catch (e) {
    print('Error in file search example (expected if no vector stores): $e\n');
  }
}

/// Example 6: Multiple built-in tools
Future<void> multipleToolsExample(String apiKey) async {
  print('--- Example 6: Multiple Built-in Tools ---');

  try {
    final provider = await ai()
        .openai((openai) => openai
            .useResponsesAPI()
            .webSearchTool()
            .fileSearchTool(vectorStoreIds: ['vs_example123']))
        .apiKey(apiKey)
        .model('gpt-4.1')
        .build();

    final response = await provider.chat(
      _userMessages(
        'Compare recent AI news with information from my documents about AI trends',
      ),
    );
    print('Response with multiple tools: ${response.text}\n');
  } catch (e) {
    print('Error in multiple tools example: $e\n');
  }
}

/// Example 5: Streaming with Responses API
Future<void> streamingExample(String apiKey) async {
  print('--- Example 5: Streaming ---');

  try {
    final provider = await ai()
        .openai((openai) => openai.useResponsesAPI().webSearchTool())
        .apiKey(apiKey)
        .model('gpt-4.1')
        .build();

    print('Streaming response:');
    await for (final event in provider.chatStream(
        _userMessages('Tell me about the latest AI research papers'))) {
      switch (event) {
        case TextDeltaEvent(delta: final delta):
          stdout.write(delta);
          break;
        case ThinkingDeltaEvent():
          // Thinking content (if any)
          break;
        case ToolCallDeltaEvent():
          print('\n[Tool call in progress...]');
          break;
        case CompletionEvent():
          print('\n[Stream completed]');
          break;
        case ErrorEvent():
          print('\n[Error occurred]');
          break;
      }
    }
    print('\n');
  } catch (e) {
    print('Error in streaming example: $e\n');
  }
}

/// Example 6: Computer use (commented out as it requires special access)
/*
Future<void> computerUseExample(String apiKey) async {
  print('--- Example 6: Computer Use ---');

  try {
    final provider = await ai()
        .openai((openai) => openai
            .useResponsesAPI()
            .computerUseTool(
              displayWidth: 1024,
              displayHeight: 768,
              environment: 'browser',
            ))
        .apiKey(apiKey)
        .model('computer-use-preview')
        .build();

    final messages = [
      ChatMessage.user('Help me search for information about Dart programming'),
    ];

    final response = await provider.chat(messages);
    print('Response with computer use: ${response.text}\n');
  } catch (e) {
    print('Error in computer use example: $e\n');
  }
}
*/

/// Example 7: Response chaining
Future<void> responseChainingExample(String apiKey) async {
  print('--- Example 7: Response Chaining ---');

  try {
    // First request
    final provider1 = await ai()
        .openai((openai) => openai.useResponsesAPI())
        .apiKey(apiKey)
        .model('gpt-4.1')
        .build();

    final response1 = await provider1.chat(
      _userMessages('Start a story about a robot learning to paint'),
    );
    print('First response: ${response1.text}\n');

    // Extract response ID for chaining
    if (response1 is OpenAIResponsesResponse && response1.responseId != null) {
      print('Response ID: ${response1.responseId}');

      // Second request using previous response ID for chaining
      final provider2 = await ai()
          .openai((openai) => openai
              .useResponsesAPI()
              .previousResponseId(response1.responseId!))
          .apiKey(apiKey)
          .model('gpt-4.1')
          .build();

      final response2 = await provider2.chat(
        _userMessages('Continue the story with the robot discovering colors'),
      );
      print('Chained response: ${response2.text}\n');
    } else {
      print('Response chaining not available (no response ID found)\n');
    }
  } catch (e) {
    print('Error in response chaining example: $e\n');
  }
}

/// Example 9: Stateful conversation management
Future<void> statefulConversationExample(String apiKey) async {
  print('--- Example 9: Stateful Conversation Management ---');

  try {
    // Using buildOpenAIResponses() for direct access - no casting needed!
    final provider = await ai()
        .openai((openai) => openai.webSearchTool())
        .apiKey(apiKey)
        .model('gpt-4o')
        .buildOpenAIResponses();

    // Direct access to Responses API without type checking
    final responses = provider.responses!;

    // Start a conversation
    final response1 = await responses.chat(
      _userMessages('My name is Alice. Tell me about quantum computing.'),
    );
    print('Response 1: ${response1.text?.substring(0, 100)}...\n');

    // Get response ID for stateful continuation
    String? responseId;
    if (response1 is OpenAIResponsesResponse) {
      responseId = response1.responseId;
      print('Response ID: $responseId\n');
    }

    if (responseId != null) {
      // Continue the conversation with state preservation
      final response2 = await responses.continueConversation(
        responseId,
        _userMessages('Remember my name and explain it in simple terms.'),
      );
      print('Response 2: ${response2.text?.substring(0, 100)}...\n');

      // Fork the conversation to explore different paths
      final forkResponse = await responses.forkConversation(
        responseId,
        _userMessages('Instead, tell me about classical computing.'),
      );
      print('Fork response: ${forkResponse.text?.substring(0, 100)}...\n');
    }
  } catch (e) {
    if (e is OpenAIResponsesError) {
      print('OpenAI Responses API error: ${e.message}');
      if (e.responseId != null) print('Response ID: ${e.responseId}');
      if (e.errorType != null) print('Error type: ${e.errorType}');
    } else {
      print('Error in stateful conversation example: $e');
    }
    print('');
  }
}

/// Example 10: Background processing
Future<void> backgroundProcessingExample(String apiKey) async {
  print('--- Example 10: Background Processing ---');

  try {
    // Using buildOpenAIResponses() for direct access - no casting needed!
    final provider = await ai()
        .openai((openai) => openai.webSearchTool())
        .apiKey(apiKey)
        .model('gpt-4o')
        .buildOpenAIResponses();

    // Direct access to Responses API
    final responses = provider.responses!;

    // Start a background task
    print('Starting background processing...');
    final backgroundResponse = await responses.chatWithToolsBackground(
      _userMessages(
        'Write a detailed analysis of renewable energy trends.',
      ),
      null,
    );

    String? responseId;
    if (backgroundResponse is OpenAIResponsesResponse) {
      responseId = backgroundResponse.responseId;
      print('Background task started with ID: $responseId\n');
    }

    if (responseId != null) {
      // Check status periodically
      for (int i = 0; i < 3; i++) {
        await Future.delayed(Duration(seconds: 2));

        try {
          final currentResponse = await responses.getResponse(responseId);
          print('Status check ${i + 1}: Response available');
          print('Content: ${currentResponse.text?.substring(0, 100)}...\n');
          break;
        } catch (e) {
          print('Status check ${i + 1}: Still processing or error occurred');
          if (i == 2) {
            // Try to cancel if still processing
            try {
              await responses.cancelResponse(responseId);
              print('Background task cancelled.\n');
            } catch (cancelError) {
              print('Could not cancel task: $cancelError\n');
            }
          }
        }
      }
    }
  } catch (e) {
    if (e is OpenAIResponsesError) {
      print('OpenAI Responses API error: ${e.message}');
    } else {
      print('Error in background processing example: $e');
    }
    print('');
  }
}

/// Example 11: Response lifecycle management
Future<void> responseLifecycleExample(String apiKey) async {
  print('--- Example 11: Response Lifecycle Management ---');

  try {
    // Using buildOpenAIResponses() for direct access - no casting needed!
    final provider = await ai()
        .openai((openai) => openai.webSearchTool())
        .apiKey(apiKey)
        .model('gpt-4o')
        .buildOpenAIResponses();

    // Direct access to Responses API
    final responses = provider.responses!;

    // Create a response
    final response = await responses.chat(
      _userMessages('Tell me about machine learning.'),
    );
    print('Created response: ${response.text?.substring(0, 100)}...\n');

    String? responseId;
    if (response is OpenAIResponsesResponse) {
      responseId = response.responseId;
    }

    if (responseId != null) {
      // Retrieve the response by ID
      try {
        final retrievedResponse = await responses.getResponse(responseId);
        print(
            'Retrieved response: ${retrievedResponse.text?.substring(0, 100)}...\n');
      } catch (e) {
        print('Could not retrieve response: $e\n');
      }

      // List input items for the response
      try {
        final inputItems = await responses.listInputItems(responseId);
        print('Input items count: ${inputItems.data.length}');
        if (inputItems.data.isNotEmpty) {
          print('First input item type: ${inputItems.data.first.type}');
        }
        print('');
      } catch (e) {
        print('Could not list input items: $e\n');
      }

      // Delete the response (cleanup)
      try {
        final deleted = await responses.deleteResponse(responseId);
        print('Response deleted: $deleted\n');
      } catch (e) {
        print('Could not delete response: $e\n');
      }
    }
  } catch (e) {
    if (e is OpenAIResponsesError) {
      print('OpenAI Responses API error: ${e.message}');
    } else {
      print('Error in response lifecycle example: $e');
    }
    print('');
  }
}
