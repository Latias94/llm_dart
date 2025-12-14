// ignore_for_file: avoid_print
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

/// 💬 Chat Basics - Foundation of AI Interactions
///
/// This example demonstrates the fundamental concepts of chat-based AI:
/// - Creating and managing conversations
/// - Different message types and their purposes
/// - Handling responses and metadata
/// - Managing conversation context and history
///
/// Before running, set your API key:
/// export OPENAI_API_KEY="your-key"
/// export GROQ_API_KEY="your-key"
void main() async {
  print('💬 Chat Basics - Foundation of AI Interactions\n');

  // Get API key
  final apiKey = Platform.environment['OPENAI_API_KEY'] ?? 'sk-TESTKEY';

  // Create AI model
  final model = await ai()
      .openai()
      .apiKey(apiKey)
      .model('gpt-4o-mini')
      .temperature(0.7)
      .maxTokens(500)
      .buildLanguageModel();

  // Demonstrate different aspects of chat
  await demonstrateBasicChat(model);
  await demonstrateMessageTypes(model);
  await demonstrateConversationHistory(model);
  await demonstrateResponseMetadata(model);
  await demonstrateContextManagement(model);

  print('\n✅ Chat basics completed!');
}

/// Demonstrate basic chat functionality
Future<void> demonstrateBasicChat(LanguageModel model) async {
  print('🔤 Basic Chat:\n');

  try {
    // Simple question and answer
    final prompt =
        ChatPromptBuilder.user().text('What is the capital of Japan?').build();

    final response = await generateTextWithModel(
      model,
      promptMessages: [prompt],
    );

    print('   User: What is the capital of Japan?');
    print('   AI: ${response.text}');
    print('   ✅ Basic chat successful\n');
  } catch (e) {
    print('   ❌ Basic chat failed: $e\n');
  }
}

/// Demonstrate different message types
Future<void> demonstrateMessageTypes(LanguageModel model) async {
  print('📝 Message Types:\n');

  try {
    // Different message types in conversation
    final prompts = <ModelMessage>[
      // System message - sets AI behavior
      ChatPromptBuilder.system()
          .text(
              'You are a helpful math tutor. Explain concepts clearly and encourage learning.')
          .build(),

      // User message - user input
      ChatPromptBuilder.user()
          .text(
              'I\'m struggling with algebra. Can you help me understand variables?')
          .build(),

      // Assistant message - previous AI response (for context)
      ChatPromptBuilder.assistant()
          .text(
              'Of course! Variables in algebra are like containers that hold unknown values. Think of them as boxes with labels like "x" or "y" that can contain different numbers.')
          .build(),

      // Follow-up user message
      ChatPromptBuilder.user()
          .text('Can you give me a simple example?')
          .build(),
    ];

    final response = await generateTextWithModel(
      model,
      promptMessages: prompts,
    );

    print('   System: Math tutor personality set');
    print('   User: Asking about algebra variables');
    print('   Assistant: Previous explanation about variables');
    print('   User: Requesting an example');
    print('   AI: ${response.text}');
    print('   ✅ Message types demonstration successful\n');
  } catch (e) {
    print('   ❌ Message types failed: $e\n');
  }
}

/// Demonstrate conversation history management
Future<void> demonstrateConversationHistory(LanguageModel model) async {
  print('📚 Conversation History:\n');

  try {
    // Build conversation step by step
    final conversation = <ModelMessage>[];

    // First exchange
    conversation
        .add(ChatPromptBuilder.user().text('Hi! What\'s your name?').build());
    var response = await generateTextWithModel(
      model,
      promptMessages: List<ModelMessage>.from(conversation),
    );
    conversation
        .add(ChatPromptBuilder.assistant().text(response.text ?? '').build());
    print('   User: Hi! What\'s your name?');
    print('   AI: ${response.text}');

    // Second exchange - AI remembers context
    conversation
        .add(ChatPromptBuilder.user().text('What did I just ask you?').build());
    response = await generateTextWithModel(
      model,
      promptMessages: List<ModelMessage>.from(conversation),
    );
    conversation
        .add(ChatPromptBuilder.assistant().text(response.text ?? '').build());
    print('   User: What did I just ask you?');
    print('   AI: ${response.text}');

    // Third exchange - testing memory
    conversation.add(ChatPromptBuilder.user()
        .text('Can you summarize our conversation so far?')
        .build());
    response = await generateTextWithModel(
      model,
      promptMessages: List<ModelMessage>.from(conversation),
    );
    print('   User: Can you summarize our conversation so far?');
    print('   AI: ${response.text}');

    print('   ✅ Conversation history maintained successfully\n');
  } catch (e) {
    print('   ❌ Conversation history failed: $e\n');
  }
}

/// Demonstrate response metadata and usage statistics
Future<void> demonstrateResponseMetadata(LanguageModel model) async {
  print('📊 Response Metadata:\n');

  try {
    final prompt = ChatPromptBuilder.user()
        .text('Explain quantum computing in exactly 100 words.')
        .build();

    final response = await generateTextWithModel(
      model,
      promptMessages: [prompt],
    );

    print('   Question: Explain quantum computing in exactly 100 words.');
    print('   Response: ${response.text}');

    // Check usage statistics
    if (response.usage != null) {
      final usage = response.usage!;
      print('\n   📈 Usage Statistics:');
      print('      • Prompt tokens: ${usage.promptTokens}');
      print('      • Completion tokens: ${usage.completionTokens}');
      print('      • Total tokens: ${usage.totalTokens}');

      // Calculate approximate cost (example rates)
      final promptCost =
          (usage.promptTokens ?? 0) * 0.00001; // $0.01 per 1K tokens
      final completionCost =
          (usage.completionTokens ?? 0) * 0.00003; // $0.03 per 1K tokens
      final totalCost = promptCost + completionCost;
      print('      • Estimated cost: \$${totalCost.toStringAsFixed(6)}');
    }

    // Check for thinking process (if available)
    if (response.thinking != null && response.thinking!.isNotEmpty) {
      print(
          '\n   🧠 Thinking Process Available: ${response.thinking!.length} characters');
    }

    print('   ✅ Metadata extraction successful\n');
  } catch (e) {
    print('   ❌ Metadata extraction failed: $e\n');
  }
}

/// Demonstrate context management strategies
Future<void> demonstrateContextManagement(LanguageModel model) async {
  print('🧠 Context Management:\n');

  try {
    // Strategy 1: Short context for focused responses
    print('   Strategy 1: Short Context');
    final shortContext = [
      ChatPromptBuilder.user().text('What is AI?').build(),
    ];
    var response = await generateTextWithModel(
      model,
      promptMessages: shortContext,
    );
    print('      Response length: ${response.text?.length ?? 0} characters');

    // Strategy 2: Rich context for detailed responses
    print('\n   Strategy 2: Rich Context');
    final richContext = [
      ChatPromptBuilder.system()
          .text(
              'You are an AI expert with deep knowledge of machine learning, neural networks, and AI history.')
          .build(),
      ChatPromptBuilder.user()
          .text('I\'m a computer science student preparing for an exam.')
          .build(),
      ChatPromptBuilder.assistant()
          .text(
              'I\'d be happy to help you prepare! What specific topics would you like to review?')
          .build(),
      ChatPromptBuilder.user()
          .text(
              'What is AI? Please provide a comprehensive explanation suitable for an exam.')
          .build(),
    ];
    response = await generateTextWithModel(
      model,
      promptMessages: richContext,
    );
    print('      Response length: ${response.text?.length ?? 0} characters');

    // Strategy 3: Context window management
    print('\n   Strategy 3: Context Window Management');
    final longConversation = <ModelMessage>[];

    // Simulate a long conversation
    for (int i = 1; i <= 5; i++) {
      longConversation.add(ChatPromptBuilder.user()
          .text('Question $i: Tell me about topic $i')
          .build());
      longConversation.add(ChatPromptBuilder.assistant()
          .text('Response $i: Here is information about topic $i...')
          .build());
    }

    // Add current question
    longConversation.add(ChatPromptBuilder.user()
        .text('Summarize all the topics we\'ve discussed.')
        .build());

    print('      Total messages in context: ${longConversation.length}');
    response = await generateTextWithModel(
      model,
      promptMessages: longConversation,
    );
    final canReference = response.text?.contains('topic') == true
        ? 'Previous topics'
        : 'Limited context';
    print('      AI can reference: $canReference');

    print('\n   💡 Context Management Tips:');
    print('      • Short context = Faster, cheaper, focused responses');
    print(
        '      • Rich context = Better understanding, more relevant responses');
    print('      • Monitor token usage to avoid hitting limits');
    print('      • Consider summarizing old messages for long conversations');

    print('   ✅ Context management demonstration successful\n');
  } catch (e) {
    print('   ❌ Context management failed: $e\n');
  }
}

/// 🎯 Key Chat Concepts Summary:
///
/// Message Types:
/// - System: Sets AI behavior and personality
/// - User: Human input and questions
/// - Assistant: AI responses (for conversation history)
///
/// Best Practices:
/// 1. Use system messages to define AI behavior
/// 2. Maintain conversation history for context
/// 3. Monitor token usage and costs
/// 4. Handle errors gracefully
/// 5. Manage context window size appropriately
///
/// Response Data:
/// - text: The AI's response content
/// - usage: Token consumption statistics
/// - thinking: Internal reasoning (some models)
///
/// Next Steps:
/// - streaming_chat.dart: Real-time response streaming
/// - tool_calling.dart: Function calling and execution
/// - structured_output.dart: JSON and schema responses
