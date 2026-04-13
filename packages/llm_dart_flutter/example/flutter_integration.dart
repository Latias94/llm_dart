// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:llm_dart_flutter/llm_dart_flutter.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

Future<void> main() async {
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Set OPENAI_API_KEY to run this example.');
    return;
  }

  final controller = ChatController(
    session: DefaultChatSession(
      transport: DirectChatTransport(
        model: openai.OpenAI(apiKey: apiKey).chatModel('gpt-4.1-mini'),
      ),
    ),
  );

  controller.addListener(() {
    printState(controller.state);
  });

  try {
    await controller.sendMessage(
      ChatInput.text('Write a short haiku about Flutter widgets.'),
    );

    final snapshot = controller.exportSnapshot();
    print('\nSnapshot exported for chatId=${snapshot.chatId}');
    print('Persisted messages=${snapshot.messages.length}');
  } finally {
    await controller.close();
  }
}

void printState(ChatState state) {
  print('status=${state.status}');

  if (state.messages.isEmpty) {
    return;
  }

  final latest = state.messages.last;
  final shared = const ChatMessageMapper().map(latest);
  final provider = const openai.OpenAIMessageMapper().map(latest);
  print('latest role=${latest.role} parts=${latest.parts.length}');
  print('latest text=${shared.text}');
  print('latest tools=${shared.toolParts.length}');
  print('openai metadata=${provider.hasOpenAIMetadata}');
  print('openai logprobs=${provider.hasLogprobs}');
  print('openai part details=${provider.partDetails.length}');
}
