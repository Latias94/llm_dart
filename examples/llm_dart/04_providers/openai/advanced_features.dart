// ignore_for_file: avoid_print
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_core/llm_dart_core.dart'
    show
        ChatContentPart,
        TextContentPart,
        ToolCallContentPart,
        ToolResultContentPart,
        ToolResultTextPayload;

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
  final apiKey = Platform.environment['OPENAI_API_KEY'] ?? 'sk-TESTKEY';

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

      final reasoningModel = await ai()
          .openai()
          .apiKey(apiKey)
          .model(model['name']!)
          .reasoning(true) // Enable reasoning
          .reasoningEffort(ReasoningEffort.medium)
          .maxTokens(2000)
          .timeout(Duration(seconds: 120)) // Longer timeout for reasoning
          .buildLanguageModel();

      final stopwatch = Stopwatch()..start();
      final prompt = ChatPromptBuilder.user().text(complexProblem).build();
      final response = await generateTextWithModel(
        reasoningModel,
        promptMessages: [prompt],
      );
      stopwatch.stop();

      print('      Problem: Chickens and rabbits puzzle');
      print('      Time: ${stopwatch.elapsedMilliseconds}ms');

      if (response.thinking != null) {
        print(
            '      Thinking process: ${response.thinking!.length} characters');
        print('      Reasoning: ${response.thinking!.substring(0, 200)}...');
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

    final model = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-5.1')
        .temperature(0.3)
        .buildLanguageModel();

    // Test function calling
    print('   Testing function calling with multiple tools...');
    const question = 'What\'s the weather like in Tokyo and calculate 15 * 23?';

    final prompt = ChatPromptBuilder.user().text(question).build();

    final response = await generateTextWithModel(
      model,
      promptMessages: [prompt],
      options: LanguageModelCallOptions(tools: tools),
    );

    print('      User: $question');

    if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
      print('      🔧 Tool calls made:');
      for (final toolCall in response.toolCalls!) {
        print(
            '         ${toolCall.function.name}: ${toolCall.function.arguments}');
      }

      print(
          '      (tool execution and follow-up conversation omitted for brevity)');
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
    // For now we demonstrate assistant-like behavior using a prompt-first
    // LanguageModel. A dedicated Assistants API integration can build on the
    // same pattern.
    final model = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-5.1')
        .buildLanguageModel();

    print('   Note: Assistants API requires OpenAI-specific implementation');
    print(
        '   For now, demonstrating basic conversation with assistant-like behavior...');

    final messages = <ModelMessage>[
      ModelMessage.systemText('''
You are a patient and helpful math tutor. When solving problems:
1. Break down the problem into steps
2. Explain each step clearly
3. Show all calculations
4. Verify the answer
'''),
      ModelMessage.userText('Solve this quadratic equation: 2x² + 5x - 3 = 0'),
    ];

    final response = await generateTextPromptWithModel(
      model,
      messages: messages,
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
    final model = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-5.1')
        .temperature(0.1)
        .buildLanguageModel();

    final messages = <ModelMessage>[
      ModelMessage.userText('''
Extract information from this text and return it in JSON format:
"John Smith, age 30, works as a software engineer at TechCorp. 
He lives in San Francisco and has 5 years of experience."

Return JSON with fields: name, age, job, company, location, experience_years
'''),
    ];

    final response = await generateTextPromptWithModel(
      model,
      messages: messages,
    );

    print('      Structured response: ${response.text}');
  } catch (e) {
    print('      ❌ Structured output error: $e');
  }

  // Advanced parameters
  print('\n   Advanced Parameters:');
  try {
    final advancedModel = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-5.1')
        .temperature(0.7)
        .topP(0.9)
        .extension('frequencyPenalty', 0.1)
        .extension('presencePenalty', 0.1)
        .maxTokens(500)
        .extension('seed', 42) // For reproducible outputs
        .extension('logitBias', {
      '50256': -100.0,
    }) // Bias against specific tokens
        .buildLanguageModel();

    final prompt = ChatPromptBuilder.user()
        .text('Write a creative short story about AI.')
        .build();

    final response = await generateTextWithModel(
      advancedModel,
      promptMessages: [prompt],
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
    final weatherTool = Tool.function(
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
    );

    const question =
        'Tell me about the weather in Paris and write a short poem about it.';

    final tools = [weatherTool];
    final prompt = ChatPromptBuilder.user().text(question).build();

    print('   Streaming with function calls (two-pass flow)...\n');
    print('   User: $question');
    print('   Available tools: get_weather\n');

    // Build a high-level LanguageModel with tools configured.
    final model = await ai()
        .openai()
        .apiKey(apiKey)
        .model('gpt-5.1')
        .temperature(0.7)
        .tools(tools)
        .buildLanguageModel();

    // First pass: stream planning + tool calls using StreamTextPart.
    final planningText = StringBuffer();
    final streamedToolCalls = <ToolCall>[];
    var toolCallsDetected = false;

    await for (final part in model.streamTextPartsWithOptions(
      [prompt],
      options: null,
    )) {
      switch (part) {
        case StreamTextStart():
          break;
        case StreamTextDelta(delta: final delta):
          stdout.write(delta);
          planningText.write(delta);
          break;
        case StreamThinkingDelta():
          // Ignore thinking content for this example
          break;
        case StreamToolInputStart(
            toolCallId: final toolCallId,
            toolName: final toolName
          ):
          if (!toolCallsDetected) {
            print('\n');
            print('   🔧 Tool call detected in stream');
            toolCallsDetected = true;
          }
          print('      • Tool input started: $toolName (id: $toolCallId)');
          break;
        case StreamToolInputDelta():
          // Arguments deltas are aggregated internally; we keep logs compact.
          break;
        case StreamToolInputEnd(toolCallId: final toolCallId):
          print('      • Tool input completed for id: $toolCallId');
          break;
        case StreamToolCall(toolCall: final toolCall):
          streamedToolCalls.add(toolCall);
          print(
              '      • Final tool call: ${toolCall.function.name}(${toolCall.function.arguments})');
          break;
        case StreamTextEnd():
          break;
        case StreamFinish(result: final result):
          print('\n   🏁 First streaming pass completed');
          if (result.usage != null) {
            print('   Tokens used: ${result.usage!.totalTokens}');
          }
          break;
      }
    }

    print('\n   First pass text length: ${planningText.length} characters');
    print('   Tool calls detected: ${streamedToolCalls.length}');

    if (streamedToolCalls.isEmpty) {
      print('   ℹ️  Model did not call tools during streaming');
      print('   ✅ Advanced streaming demonstration completed\n');
      return;
    }

    // Simulate tool execution based on streamed tool calls and build a
    // prompt-first conversation for the second pass.
    final conversation = <ModelMessage>[
      prompt,
    ];

    // Assistant message containing the planning text + tool call parts.
    final toolUseParts = <ChatContentPart>[
      if (planningText.isNotEmpty) TextContentPart(planningText.toString()),
      for (final toolCall in streamedToolCalls)
        ToolCallContentPart(
          toolName: toolCall.function.name,
          argumentsJson: toolCall.function.arguments,
          toolCallId: toolCall.id,
        ),
    ];

    if (toolUseParts.isNotEmpty) {
      conversation.add(
        ModelMessage(
          role: ChatRole.assistant,
          parts: toolUseParts,
        ),
      );
    }

    for (final toolCall in streamedToolCalls) {
      final name = toolCall.function.name;
      String result;

      if (name == 'get_weather') {
        result = '{"temperature": 22, "condition": "sunny", "humidity": 65}';
      } else {
        result = '{"error": "Unknown function: $name"}';
      }

      print('   📄 $name result: $result');

      conversation.add(
        ModelMessage(
          role: ChatRole.user,
          parts: [
            ToolResultContentPart(
              toolCallId: toolCall.id,
              toolName: toolCall.function.name,
              payload: ToolResultTextPayload(result),
            ),
          ],
        ),
      );
    }

    // Second pass: stream final answer with tool results.
    print('\n   Streaming final answer with tool results...\n');

    final finalText = StringBuffer();

    await for (final part in model.streamTextPartsWithOptions(
      conversation,
      options: null,
    )) {
      switch (part) {
        case StreamTextStart():
          break;
        case StreamTextDelta(delta: final delta):
          stdout.write(delta);
          finalText.write(delta);
          break;
        case StreamThinkingDelta():
          // Ignore thinking content in the second pass as well
          break;
        case StreamToolInputStart():
          // In the second pass we expect the model to use tool results directly.
          // If it still tries to call tools, we ignore them in this example.
          break;
        case StreamToolInputDelta():
          break;
        case StreamToolInputEnd():
          break;
        case StreamToolCall():
          break;
        case StreamTextEnd():
          break;
        case StreamFinish(result: final result):
          print('\n\n   🏁 Second streaming pass completed');
          if (result.usage != null) {
            print('   Tokens used: ${result.usage!.totalTokens}');
          }
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
