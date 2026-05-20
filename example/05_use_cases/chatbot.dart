// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

/// Complete chatbot example built on the stable model API.
Future<void> main() async {
  print('🤖 Complete Chatbot Implementation\n');

  final model = _resolveChatModel();
  if (model == null) {
    print('Set GROQ_API_KEY or OPENAI_API_KEY to run this example.');
    return;
  }

  final chatbot = Chatbot(
    model: model,
    personality: ChatbotPersonality.helpful,
    maxContextLength: 10,
  );

  await chatbot.initialize();

  print('🎉 Chatbot initialized! Type "quit" to exit.\n');
  await runInteractiveChat(chatbot);
  print('\n👋 Goodbye!');
}

core.LanguageModel? _resolveChatModel() {
  final groqKey = Platform.environment['GROQ_API_KEY'];
  if (groqKey != null && groqKey.isNotEmpty) {
    return openai
        .groq(
          apiKey: groqKey,
        )
        .chatModel('llama-3.3-70b-versatile');
  }

  final openaiKey = Platform.environment['OPENAI_API_KEY'];
  if (openaiKey != null && openaiKey.isNotEmpty) {
    return openai
        .openai(
          apiKey: openaiKey,
        )
        .chatModel('gpt-4.1-mini');
  }

  return null;
}

Future<void> runInteractiveChat(Chatbot chatbot) async {
  while (true) {
    stdout.write('You: ');
    final userInput = stdin.readLineSync();

    if (userInput == null || userInput.toLowerCase() == 'quit') {
      break;
    }

    if (userInput.trim().isEmpty) {
      continue;
    }

    try {
      stdout.write('Bot: ');
      await chatbot.respondToUser(userInput);
      print('');
    } catch (error) {
      print('❌ Sorry, I encountered an error: $error');
    }
  }
}

enum ChatbotPersonality {
  helpful,
  friendly,
  professional,
  creative,
  technical,
}

class Chatbot {
  final core.LanguageModel model;
  final ChatbotPersonality personality;
  final int maxContextLength;

  final List<core.ModelMessage> _conversationHistory = [];
  int _messageCount = 0;

  Chatbot({
    required this.model,
    required this.personality,
    this.maxContextLength = 20,
  });

  Future<void> initialize() async {
    print(
      '✅ Chatbot initialized with ${personality.name} personality '
      'on ${model.providerId}/${model.modelId}',
    );
  }

  Future<void> respondToUser(String userInput) async {
    try {
      _addToHistory(core.UserModelMessage.text(userInput));

      final stream = core.streamTextCall(
        model: model,
        messages: _getContextMessages(),
        options: _requestOptions(maxOutputTokens: 500),
      );

      final responseBuffer = StringBuffer();

      await for (final event in stream) {
        switch (event) {
          case core.TextDeltaEvent(:final delta):
            stdout.write(delta);
            responseBuffer.write(delta);
          case core.FinishEvent(:final usage):
            if (usage != null) {
              _logUsage(usage);
            }
          case core.ErrorEvent(:final error):
            throw Exception('Stream error: $error');
          case core.ReasoningDeltaEvent():
          case core.RunStartEvent():
          case core.RunFinishEvent():
          case core.StepStartEvent():
          case core.StepFinishEvent():
          case core.StartEvent():
          case core.ResponseMetadataEvent():
          case core.TextStartEvent():
          case core.TextEndEvent():
          case core.ReasoningStartEvent():
          case core.ReasoningEndEvent():
          case core.ReasoningFileEvent():
          case core.ToolInputStartEvent():
          case core.ToolInputDeltaEvent():
          case core.ToolInputEndEvent():
          case core.ToolInputErrorEvent():
          case core.ToolCallEvent():
          case core.ToolResultEvent():
          case core.ToolApprovalRequestEvent():
          case core.ToolOutputDeniedEvent():
          case core.SourceEvent():
          case core.FileEvent():
          case core.CustomEvent():
          case core.AbortEvent():
          case core.RawChunkEvent():
            break;
        }
      }

      final finalText = (await stream.text).trim();
      final assistantText =
          finalText.isEmpty ? responseBuffer.toString().trim() : finalText;
      if (assistantText.isNotEmpty) {
        _addToHistory(core.AssistantModelMessage.text(assistantText));
      }

      _messageCount++;
    } catch (error) {
      await _handleError(userInput, error);
    }
  }

  Future<void> _handleError(String userInput, Object error) async {
    print('\n⚠️  Error occurred, trying fallback...');

    try {
      final result = await core.generateTextCall(
        model: model,
        messages: [
          core.SystemModelMessage.text(_getSystemPromptForPersonality()),
          core.UserModelMessage.text(userInput),
        ],
        options: _requestOptions(maxOutputTokens: 260),
      );

      print(result.text);
      _addToHistory(core.AssistantModelMessage.text(result.text));
    } catch (_) {
      print(
        'I apologize, but I\'m having technical difficulties right now. '
        'Please try again in a moment.',
      );
    }
  }

  void _addToHistory(core.ModelMessage message) {
    _conversationHistory.add(message);

    while (_conversationHistory.length > maxContextLength) {
      for (var i = 0; i < _conversationHistory.length; i++) {
        if (_conversationHistory[i].role != core.ModelMessageRole.system) {
          _conversationHistory.removeAt(i);
          break;
        }
      }
    }
  }

  List<core.ModelMessage> _getContextMessages() {
    final messages = <core.ModelMessage>[];

    if (_conversationHistory.isEmpty ||
        _conversationHistory.first.role != core.ModelMessageRole.system) {
      messages.add(
        core.SystemModelMessage.text(_getSystemPromptForPersonality()),
      );
    }

    messages.addAll(_conversationHistory);
    return messages;
  }

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

  double _getTemperatureForPersonality() {
    switch (personality) {
      case ChatbotPersonality.helpful:
      case ChatbotPersonality.professional:
      case ChatbotPersonality.technical:
        return 0.3;
      case ChatbotPersonality.friendly:
        return 0.7;
      case ChatbotPersonality.creative:
        return 0.9;
    }
  }

  core.GenerateTextOptions _requestOptions({int maxOutputTokens = 500}) {
    return core.GenerateTextOptions(
      temperature: _getTemperatureForPersonality(),
      maxOutputTokens: maxOutputTokens,
    );
  }

  void _logUsage(core.UsageStats usage) {
    print('\n📊 Message #$_messageCount - Tokens: ${usage.totalTokens}');
  }

  Future<String> getConversationSummary() async {
    if (_conversationHistory.length < 4) {
      return 'Short conversation, no summary needed.';
    }

    try {
      final result = await core.generateTextCall(
        model: model,
        messages: [
          core.SystemModelMessage.text(
            'Summarize the following conversation in 2-3 sentences:',
          ),
          ..._conversationHistory.where(
            (message) => message.role != core.ModelMessageRole.system,
          ),
        ],
        options: const core.GenerateTextOptions(
          temperature: 0.3,
          maxOutputTokens: 160,
        ),
      );
      return result.text;
    } catch (error) {
      return 'Error generating summary: $error';
    }
  }

  void resetConversation() {
    _conversationHistory.clear();
    _messageCount = 0;
    print('🔄 Conversation reset');
  }

  Map<String, dynamic> getStats() {
    final userMessages = _conversationHistory
        .where((message) => message.role == core.ModelMessageRole.user)
        .length;
    final assistantMessages = _conversationHistory
        .where((message) => message.role == core.ModelMessageRole.assistant)
        .length;

    return {
      'totalMessages': _conversationHistory.length,
      'userMessages': userMessages,
      'assistantMessages': assistantMessages,
      'personality': personality.name,
      'maxContextLength': maxContextLength,
      'provider': model.providerId,
      'model': model.modelId,
    };
  }
}
