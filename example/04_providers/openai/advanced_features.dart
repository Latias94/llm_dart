// ignore_for_file: avoid_print
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

/// 🔵 OpenAI Advanced Features - Reasoning, Function Calling, and Assistants
///
/// This example demonstrates advanced OpenAI capabilities:
/// - Reasoning models (GPT-5.1) with thinking process
/// - Function calling and tool usage
/// - Assistants API integration
/// - Advanced configuration options
///
/// Before running, set your API key:
/// export OPENAI_API_KEY="your-openai-api-key"
void main() async {
  print('🔵 OpenAI Advanced Features - Reasoning and Tools\n');

  // Get API key
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set OPENAI_API_KEY environment variable');
    exit(1);
  }

  registerOpenAI();

  // Demonstrate advanced OpenAI features
  await demonstrateReasoningModels(apiKey);
  await demonstrateFunctionCalling(apiKey);
  await demonstrateAssistantsAPI(apiKey);
  await demonstrateAdvancedConfiguration(apiKey);
  await demonstrateStreamingFeatures(apiKey);

  print('\n✅ OpenAI advanced features completed!');
}

/// Demonstrate reasoning models (GPT-5.1)
Future<void> demonstrateReasoningModels(String apiKey) async {
  print('🧠 Reasoning Models (GPT-5.1):\n');

  final reasoningModels = [
    {
      'name': 'gpt-5.1',
      'description': 'Advanced reasoning for complex, multi-step problems',
    },
  ];

  const complexProblem = '''
A farmer has chickens and rabbits. In total, there are 35 heads and 94 legs.
How many chickens and how many rabbits does the farmer have?
Show your reasoning step by step.
''';

  for (final model in reasoningModels) {
    try {
      print('   Testing ${model['name']}: ${model['description']}');

      final provider = await LLMBuilder()
          .provider(openaiProviderId)
          .apiKey(apiKey)
          .model(model['name']!)
          .reasoningEffort(ReasoningEffort.medium)
          .maxTokens(2000)
          .timeout(const Duration(seconds: 120)) // Longer timeout for reasoning
          .build();

      final stopwatch = Stopwatch()..start();
      final response = await generateText(
        model: provider,
        promptIr: Prompt(messages: [PromptMessage.user(complexProblem)]),
      );
      stopwatch.stop();

      print('      Problem: Chickens and rabbits puzzle');
      print('      Time: ${stopwatch.elapsedMilliseconds}ms');

      if (response.thinking != null && response.thinking!.isNotEmpty) {
        print(
            '      Thinking process: ${response.thinking!.length} characters');
        final thinking = response.thinking!;
        final preview = thinking.substring(
            0, thinking.length < 200 ? thinking.length : 200);
        print('      Reasoning: $preview...');
      }

      print('      Final answer: ${response.text}');

      if (response.usage != null) {
        print('      Tokens: ${response.usage!.totalTokens}');
      }

      print('');
    } catch (e) {
      print('      ❌ Error with ${model['name']}: $e\n');
    }
  }

  print('   💡 Reasoning Model Tips:');
  print('      • Use gpt-5.1 for complex mathematical/logical problems');
  print('      • Allow longer timeouts for complex reasoning');
  print('      • Access thinking process for transparency');
  print('   ✅ Reasoning models demonstration completed\n');
}

/// Demonstrate function calling
Future<void> demonstrateFunctionCalling(String apiKey) async {
  print('🔧 Function Calling:\n');

  try {
    final provider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(apiKey)
        .model('gpt-5.1')
        .temperature(0.3)
        .build();

    // Define tools/functions
    final weatherTool = Tool.function(
      name: 'get_weather',
      description: 'Get current weather information for a location',
      parameters: ParametersSchema(
        schemaType: 'object',
        properties: {
          'location': ParameterProperty(
            propertyType: 'string',
            description: 'City name or location',
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

    final calculatorTool = Tool.function(
      name: 'calculate',
      description: 'Perform mathematical calculations',
      parameters: ParametersSchema(
        schemaType: 'object',
        properties: {
          'expression': ParameterProperty(
            propertyType: 'string',
            description: 'Mathematical expression to evaluate',
          ),
        },
        required: ['expression'],
      ),
    );

    final tools = [weatherTool, calculatorTool];

    // Test function calling
    print('   Testing function calling with multiple tools...');
    const question = 'What\'s the weather like in Tokyo and calculate 15 * 23?';

    final messages = [ChatMessage.user(question)];

    final response = await provider.chatWithTools(messages, tools);

    print('      User: $question');

    if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
      print('      🔧 Tool calls made:');
      for (final toolCall in response.toolCalls!) {
        print(
            '         ${toolCall.function.name}: ${toolCall.function.arguments}');
      }

      // Build conversation with tool call message
      final conversation = List<ChatMessage>.from(messages)
        ..add(ChatMessage.toolUse(
          toolCalls: response.toolCalls!,
          content: response.text ?? '',
        ));

      // Simulate tool execution and add tool results
      for (final toolCall in response.toolCalls!) {
        String result;
        if (toolCall.function.name == 'get_weather') {
          result = '{"temperature": 22, "condition": "sunny", "humidity": 65}';
        } else if (toolCall.function.name == 'calculate') {
          result = '{"result": 345}';
        } else {
          result = '{"error": "Unknown function"}';
        }

        conversation.add(ChatMessage.toolResult(
          results: [toolCall],
          content: result,
        ));
      }

      // Continue conversation with tool results
      final finalResponse =
          await generateText(model: provider, messages: conversation);

      print('      Final response: ${finalResponse.text}');
    } else {
      print('      Response: ${response.text}');
    }

    print('   ✅ Function calling demonstration completed\n');
  } catch (e) {
    print('   ❌ Function calling failed: $e\n');
  }
}

/// Demonstrate Assistants API
Future<void> demonstrateAssistantsAPI(String apiKey) async {
  print('🤖 Assistants API:\n');

  try {
    final provider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(apiKey)
        .model('gpt-5.1')
        .build();

    print('   Note: Assistants API requires OpenAI-specific implementation');
    print(
        '   For now, demonstrating basic conversation with assistant-like behavior...');

    final response = await generateText(
      model: provider,
      promptIr: Prompt(
        messages: [
          PromptMessage.system('''
You are a patient and helpful math tutor. When solving problems:
1. Break down the problem into steps
2. Explain each step clearly
3. Show all calculations
4. Verify the answer
'''),
          PromptMessage.user('Solve this quadratic equation: 2x² + 5x - 3 = 0'),
        ],
      ),
    );

    print('      Math Tutor Response:');
    print('      ${response.text}');

    print('   ✅ Assistant-like behavior demonstration completed\n');
  } catch (e) {
    print('   ❌ Assistants API failed: $e\n');
  }
}

/// Demonstrate advanced configuration
Future<void> demonstrateAdvancedConfiguration(String apiKey) async {
  print('⚙️  Advanced Configuration:\n');

  // Structured output
  print('   Structured Output:');
  try {
    final provider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(apiKey)
        .model('gpt-5.1')
        .temperature(0.1)
        .build();

    final response = await generateText(
      model: provider,
      promptIr: Prompt(
        messages: [
          PromptMessage.user('''
Extract information from this text and return it in JSON format:
"John Smith, age 30, works as a software engineer at TechCorp. 
He lives in San Francisco and has 5 years of experience."

Return JSON with fields: name, age, job, company, location, experience_years
'''),
        ],
      ),
    );

    print('      Structured response: ${response.text}');
  } catch (e) {
    print('      ❌ Structured output error: $e');
  }

  // Advanced parameters
  print('\n   Advanced Parameters:');
  try {
    final advancedProvider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(apiKey)
        .model('gpt-5.1')
        .temperature(0.7)
        .topP(0.9)
        .providerConfig((p) => p
            .frequencyPenalty(0.1)
            .presencePenalty(0.1)
            .seed(42)
            .logitBias({'50256': -100.0}))
        .maxTokens(500)
        .build();

    final response = await generateText(
      model: advancedProvider,
      promptIr: Prompt(
        messages: [
          PromptMessage.user('Write a creative short story about AI.'),
        ],
      ),
    );

    final fullText = response.text ?? '';
    final previewLength = fullText.length < 200 ? fullText.length : 200;
    final preview = fullText.substring(0, previewLength);

    print('      Advanced config response: $preview...');
  } catch (e) {
    print('      ❌ Advanced config error: $e');
  }

  print('\n   💡 Advanced Configuration Tips:');
  print('      • Use structured output for data extraction');
  print(
      '      • For non-reasoning models (e.g. gpt-4.1, gpt-4o), adjust frequency/presence penalties to reduce repetition');
  print(
      '      • For reasoning models (GPT-5 family), focus on settings like seed or service tier instead');
  print('      • Use seed for reproducible outputs in testing');
  print('   ✅ Advanced configuration demonstration completed\n');
}

/// Demonstrate streaming features
Future<void> demonstrateStreamingFeatures(String apiKey) async {
  print('🌊 Advanced Streaming:\n');

  try {
    final provider = await LLMBuilder()
        .provider(openaiProviderId)
        .apiKey(apiKey)
        .model('gpt-5.1')
        .temperature(0.7)
        .build();

    print('   Streaming with locally executed tools (tool loop)...');

    final toolSet = ToolSet([
      functionTool(
        name: 'get_weather',
        description: 'Get weather information',
        parameters: ParametersSchema(
          schemaType: 'object',
          properties: {
            'location': ParameterProperty(
              propertyType: 'string',
              description: 'City name',
            ),
          },
          required: ['location'],
        ),
        handler: (toolCall, {cancelToken}) async {
          return {
            'temperature': 22,
            'condition': 'sunny',
            'humidity': 65,
            'toolCallId': toolCall.id,
          };
        },
      ),
    ]);

    const question =
        'Tell me about the weather in Paris and write a short poem about it.';

    final prompt = Prompt(messages: [PromptMessage.user(question)]);

    final finalText = StringBuffer();

    await for (final part in streamToolLoopPartsWithToolSet(
      model: provider,
      promptIr: prompt,
      toolSet: toolSet,
      maxSteps: 5,
    )) {
      switch (part) {
        case LLMTextDeltaPart(delta: final delta):
          finalText.write(delta);
          stdout.write(delta);
          break;
        case LLMToolCallStartPart(toolCall: final toolCall):
          print('\n\n🔧 Tool call started: ${toolCall.function.name}');
          break;
        case LLMToolResultPart(result: final result):
          print('\n\n🧰 Tool result: ${result.content}');
          break;
        case LLMFinishPart(response: final response):
          print('\n\n✅ Streaming completed');
          if (response.usage != null) {
            print('   Tokens used: ${response.usage!.totalTokens}');
          }
          break;
        case LLMErrorPart(error: final error):
          print('\n❌ Stream error: $error');
          break;
        default:
          break;
      }
    }

    print('\n   Final streamed answer length: ${finalText.length} characters');
    print('   ✅ Advanced streaming demonstration completed\n');
  } catch (e) {
    print('   ❌ Advanced streaming failed: $e\n');
  }
}

/// 🎯 Key OpenAI Advanced Concepts Summary:
///
/// Reasoning Models (GPT-5 Series):
/// - gpt-5.1: Advanced reasoning and problem solving
/// - gpt-5-mini: Faster, cost-efficient reasoning for simpler tasks
/// - Thinking process access for transparency
/// - Extended timeouts for complex problems
///
/// Function Calling:
/// - Define tools with JSON schema
/// - Multi-tool conversations
/// - Tool result integration
/// - Streaming with function calls
///
/// Assistants API:
/// - Persistent conversations
/// - Code interpreter integration
/// - File handling capabilities
/// - Stateful interactions
///
/// Advanced Configuration:
/// - Structured output generation
/// - Reproducible outputs with seed
/// - Token bias for behavior control
/// - Fine-tuned parameter control
///
/// Best Practices:
/// 1. Choose appropriate model for task complexity
/// 2. Use reasoning models for complex problems
/// 3. Implement proper tool execution
/// 4. Handle streaming events appropriately
/// 5. Clean up assistants and threads
///
/// Next Steps:
/// - image_generation.dart: DALL-E image creation
/// - audio_processing.dart: Whisper and TTS
/// - ../../03_advanced_features/: Cross-provider comparisons
