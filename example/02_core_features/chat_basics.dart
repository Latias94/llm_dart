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

  // Create AI provider
  final provider = await ai()
      .openai()
      .apiKey(apiKey)
      .model('gpt-4o-mini')
      .temperature(0.7)
      .maxTokens(500)
      .build();

  // Demonstrate different aspects of chat
  await demonstrateBasicChat(provider);
  await demonstrateMessageTypes(provider);
  await demonstrateConversationHistory(provider);
  await demonstrateResponseMetadata(provider);
  await demonstrateContextManagement(provider);

  print('\n✅ Chat basics completed!');
}

/// Demonstrate basic chat functionality
Future<void> demonstrateBasicChat(ChatCapability provider) async {
  print('🔤 Basic Chat:\n');

  try {
    // Simple question and answer
    final messages = [ChatMessage.user('What is the capital of Japan?')];

    final response = await provider.chat(messages);

    print('   User: What is the capital of Japan?');
    print('   AI: ${response.text}');
    print('   ✅ Basic chat successful\n');
  } catch (e) {
    print('   ❌ Basic chat failed: $e\n');
  }
}

/// Demonstrate different message types
Future<void> demonstrateMessageTypes(ChatCapability provider) async {
  print('📝 Message Types:\n');

  try {
    // Different message types in conversation
    final messages = [
      // System message - sets AI behavior
      ChatMessage.system(
          'You are a helpful math tutor. Explain concepts clearly and encourage learning.'),

      // User message - user input
      ChatMessage.user(
          'I\'m struggling with algebra. Can you help me understand variables?'),

      // Assistant message - previous AI response (for context)
      ChatMessage.assistant(
          'Of course! Variables in algebra are like containers that hold unknown values. Think of them as boxes with labels like "x" or "y" that can contain different numbers.'),

      // Follow-up user message
      ChatMessage.user('Can you give me a simple example?'),
    ];

    final response = await provider.chat(messages);

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
Future<void> demonstrateConversationHistory(ChatCapability provider) async {
  print('📚 Conversation History:\n');

  try {
    // Build conversation step by step
    final conversation = <ChatMessage>[];

    // First exchange
    conversation.add(ChatMessage.user('Hi! What\'s your name?'));
    var response = await provider.chat(conversation);
    conversation.add(ChatMessage.assistant(response.text ?? ''));
    print('   User: Hi! What\'s your name?');
    print('   AI: ${response.text}');

    // Second exchange - AI remembers context
    conversation.add(ChatMessage.user('What did I just ask you?'));
    response = await provider.chat(conversation);
    conversation.add(ChatMessage.assistant(response.text ?? ''));
    print('   User: What did I just ask you?');
    print('   AI: ${response.text}');

    // Third exchange - testing memory
    conversation
        .add(ChatMessage.user('Can you summarize our conversation so far?'));
    response = await provider.chat(conversation);
    print('   User: Can you summarize our conversation so far?');
    print('   AI: ${response.text}');

    print('   ✅ Conversation history maintained successfully\n');
  } catch (e) {
    print('   ❌ Conversation history failed: $e\n');
  }
}

/// Demonstrate response metadata and usage statistics
Future<void> demonstrateResponseMetadata(ChatCapability provider) async {
  print('📊 Response Metadata:\n');

  try {
    final messages = [
      ChatMessage.user('Explain quantum computing in exactly 100 words.')
    ];

    final response = await provider.chat(messages);

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
Future<void> demonstrateContextManagement(ChatCapability provider) async {
  print('🧠 Context Management:\n');

  try {
    // Strategy 1: Short context for focused responses
    print('   Strategy 1: Short Context');
    final shortContext = [ChatMessage.user('What is AI?')];
    var response = await provider.chat(shortContext);
    print('      Response length: ${response.text?.length ?? 0} characters');

    // Strategy 2: Rich context for detailed responses
    print('\n   Strategy 2: Rich Context');
    final richContext = [
      ChatMessage.system(
          'You are an AI expert with deep knowledge of machine learning, neural networks, and AI history.'),
      ChatMessage.user(
          'I\'m a computer science student preparing for an exam.'),
      ChatMessage.assistant(
          'I\'d be happy to help you prepare! What specific topics would you like to review?'),
      ChatMessage.user(
          'What is AI? Please provide a comprehensive explanation suitable for an exam.'),
    ];
    response = await provider.chat(richContext);
    print('      Response length: ${response.text?.length ?? 0} characters');

    // Strategy 3: Context window management
    print('\n   Strategy 3: Context Window Management');
    final longConversation = <ChatMessage>[];

    // Simulate a long conversation
    for (int i = 1; i <= 5; i++) {
      longConversation
          .add(ChatMessage.user('Question $i: Tell me about topic $i'));
      longConversation.add(ChatMessage.assistant(
          'Response $i: Here is information about topic $i...'));
    }

    // Add current question
    longConversation
        .add(ChatMessage.user('Summarize all the topics we\'ve discussed.'));

    print('      Total messages in context: ${longConversation.length}');
    response = await provider.chat(longConversation);
    print(
        '      AI can reference: ${response.text?.contains('topic') == true ? 'Previous topics' : 'Limited context'}');

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
