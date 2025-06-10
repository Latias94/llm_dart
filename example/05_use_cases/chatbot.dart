// ignore_for_file: avoid_print
import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

/// 🤖 Complete Chatbot Implementation
///
/// This example demonstrates how to build a production-ready chatbot with:
/// - Multi-turn conversation management
/// - Personality and context customization
/// - Memory and conversation persistence
/// - Error handling and recovery
/// - Performance optimization
///
/// Before running, set your API key:
/// export OPENAI_API_KEY="your-key"
/// export GROQ_API_KEY="your-key"
void main() async {
  print('🤖 Complete Chatbot Implementation\n');

  // Get API key
  final apiKey = Platform.environment['GROQ_API_KEY'] ?? 'gsk-TESTKEY';

  // Create chatbot instance
  final chatbot = Chatbot(
    apiKey: apiKey,
    personality: ChatbotPersonality.helpful,
    maxContextLength: 10, // Keep last 10 messages
  );

  await chatbot.initialize();

  print('🎉 Chatbot initialized! Type "quit" to exit.\n');

  // Interactive chat loop
  await runInteractiveChat(chatbot);

  print('\n👋 Goodbye! Thanks for chatting!');
}

/// Run interactive chat session
Future<void> runInteractiveChat(Chatbot chatbot) async {
  while (true) {
    // Get user input
    stdout.write('You: ');
    final userInput = stdin.readLineSync();

    if (userInput == null || userInput.toLowerCase() == 'quit') {
      break;
    }

    if (userInput.trim().isEmpty) {
      continue;
    }

    // Process user message and get response
    try {
      stdout.write('Bot: ');
      await chatbot.respondToUser(userInput);
      print(''); // New line after response
    } catch (e) {
      print('❌ Sorry, I encountered an error: $e');
    }
  }
}

/// Chatbot personality types
enum ChatbotPersonality {
  helpful,
  friendly,
  professional,
  creative,
  technical,
}

/// Complete chatbot implementation
class Chatbot {
  final String apiKey;
  final ChatbotPersonality personality;
  final int maxContextLength;

  late ChatCapability _ai;
  final List<ChatMessage> _conversationHistory = [];
  int _messageCount = 0;

  Chatbot({
    required this.apiKey,
    required this.personality,
    this.maxContextLength = 20,
  });

  /// Initialize the chatbot
  Future<void> initialize() async {
    try {
      _ai = await ai()
          .groq()
          .apiKey(apiKey)
          .model('llama-3.1-8b-instant')
          .temperature(_getTemperatureForPersonality())
          .maxTokens(500)
          .systemPrompt(_getSystemPromptForPersonality())
          .build();

      print('✅ Chatbot initialized with ${personality.name} personality');
    } catch (e) {
      throw Exception('Failed to initialize chatbot: $e');
    }
  }

  /// Respond to user input with streaming
  Future<void> respondToUser(String userInput) async {
    try {
      // Add user message to history
      _addToHistory(ChatMessage.user(userInput));

      // Get AI response with streaming
      final responseBuffer = StringBuffer();

      await for (final event in _ai.chatStream(_getContextMessages())) {
        switch (event) {
          case TextDeltaEvent(delta: final delta):
            stdout.write(delta);
            responseBuffer.write(delta);
            break;

          case CompletionEvent(response: final response):
            // Add complete response to history
            _addToHistory(ChatMessage.assistant(responseBuffer.toString()));

            // Log usage statistics
            if (response.usage != null) {
              _logUsage(response.usage!);
            }
            break;

          case ErrorEvent(error: final error):
            throw Exception('Stream error: $error');

          case ThinkingDeltaEvent():
          case ToolCallDeltaEvent():
            // Handle other event types
            break;
        }
      }

      _messageCount++;
    } catch (e) {
      // Error recovery - try with simpler context
      await _handleError(userInput, e);
    }
  }

  /// Handle errors with fallback strategies
  Future<void> _handleError(String userInput, dynamic error) async {
    print('\n⚠️  Error occurred, trying fallback...');

    try {
      // Fallback 1: Try with reduced context
      final simpleMessages = [
        ChatMessage.system(_getSystemPromptForPersonality()),
        ChatMessage.user(userInput),
      ];

      final response = await _ai.chat(simpleMessages);
      print(response.text ?? 'Sorry, I couldn\'t generate a response.');

      // Add to history if successful
      _addToHistory(ChatMessage.user(userInput));
      _addToHistory(ChatMessage.assistant(response.text ?? ''));
    } catch (fallbackError) {
      // Fallback 2: Generic error response
      print(
          'I apologize, but I\'m having technical difficulties right now. Please try again in a moment.');
    }
  }

  /// Add message to conversation history with context management
  void _addToHistory(ChatMessage message) {
    _conversationHistory.add(message);

    // Manage context length (keep system message + recent messages)
    while (_conversationHistory.length > maxContextLength) {
      // Remove oldest non-system message
      for (int i = 0; i < _conversationHistory.length; i++) {
        if (_conversationHistory[i].role != ChatRole.system) {
          _conversationHistory.removeAt(i);
          break;
        }
      }
    }
  }

  /// Get messages for current context
  List<ChatMessage> _getContextMessages() {
    // Always include system message if not in history
    final messages = <ChatMessage>[];

    if (_conversationHistory.isEmpty ||
        _conversationHistory.first.role != ChatRole.system) {
      messages.add(ChatMessage.system(_getSystemPromptForPersonality()));
    }

    messages.addAll(_conversationHistory);
    return messages;
  }

  /// Get system prompt based on personality
  String _getSystemPromptForPersonality() {
    switch (personality) {
      case ChatbotPersonality.helpful:
        return 'You are a helpful and friendly AI assistant. Provide clear, accurate, and useful responses. Be concise but thorough.';

      case ChatbotPersonality.friendly:
        return 'You are a warm, friendly, and enthusiastic AI assistant. Use a conversational tone and show genuine interest in helping users.';

      case ChatbotPersonality.professional:
        return 'You are a professional AI assistant. Provide formal, precise, and well-structured responses. Maintain a business-appropriate tone.';

      case ChatbotPersonality.creative:
        return 'You are a creative and imaginative AI assistant. Think outside the box and provide innovative solutions and ideas.';

      case ChatbotPersonality.technical:
        return 'You are a technical AI assistant with expertise in programming, engineering, and technology. Provide detailed technical explanations.';
    }
  }

  /// Get temperature setting based on personality
  double _getTemperatureForPersonality() {
    switch (personality) {
      case ChatbotPersonality.helpful:
      case ChatbotPersonality.professional:
      case ChatbotPersonality.technical:
        return 0.3; // More focused and consistent

      case ChatbotPersonality.friendly:
        return 0.7; // Balanced

      case ChatbotPersonality.creative:
        return 0.9; // More creative and varied
    }
  }

  /// Log usage statistics
  void _logUsage(dynamic usage) {
    // In a real application, you might want to:
    // - Store usage data in a database
    // - Monitor costs and usage patterns
    // - Implement usage limits
    // - Generate analytics reports

    print('\n📊 Message #$_messageCount - Tokens: ${usage.totalTokens}');
  }

  /// Get conversation summary (useful for long conversations)
  Future<String> getConversationSummary() async {
    if (_conversationHistory.length < 4) {
      return 'Short conversation, no summary needed.';
    }

    try {
      final summaryMessages = [
        ChatMessage.system(
            'Summarize the following conversation in 2-3 sentences:'),
        ..._conversationHistory.where((m) => m.role != ChatRole.system),
      ];

      final response = await _ai.chat(summaryMessages);
      return response.text ?? 'Unable to generate summary.';
    } catch (e) {
      return 'Error generating summary: $e';
    }
  }

  /// Reset conversation
  void resetConversation() {
    _conversationHistory.clear();
    _messageCount = 0;
    print('🔄 Conversation reset');
  }

  /// Get conversation statistics
  Map<String, dynamic> getStats() {
    final userMessages =
        _conversationHistory.where((m) => m.role == ChatRole.user).length;
    final assistantMessages =
        _conversationHistory.where((m) => m.role == ChatRole.assistant).length;

    return {
      'totalMessages': _conversationHistory.length,
      'userMessages': userMessages,
      'assistantMessages': assistantMessages,
      'personality': personality.name,
      'maxContextLength': maxContextLength,
    };
  }
}

/// 🎯 Key Chatbot Features Summary:
///
/// Core Features:
/// - Multi-turn conversation management
/// - Personality customization
/// - Context window management
/// - Streaming responses
/// - Error handling and recovery
///
/// Production Features:
/// - Usage tracking and analytics
/// - Conversation summarization
/// - Memory management
/// - Performance optimization
/// - Graceful error handling
///
/// Customization Options:
/// - Different personalities
/// - Adjustable context length
/// - Temperature settings
/// - System prompt customization
///
/// Next Steps:
/// - Add conversation persistence (database storage)
/// - Implement user authentication
/// - Add conversation export/import
/// - Create web or mobile interface
/// - Add multi-language support
