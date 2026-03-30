// ignore_for_file: avoid_print, avoid_relative_lib_imports

import 'dart:async';
import 'dart:io';

import '../../../lib/llm_dart.dart' as llm;
import 'package:llm_dart_flutter/llm_dart_flutter.dart';

Future<void> main() async {
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Set OPENAI_API_KEY to run this example.');
    return;
  }

  final controller = ChatController(
    session: DefaultChatSession(
      transport: DirectChatTransport(
        model: llm.AI.openai(apiKey: apiKey).chatModel('gpt-4.1-mini'),
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
  final mapped = const ChatMessageMapper().map(latest);
  print('latest role=${latest.role} parts=${latest.parts.length}');
  print('latest text=${mapped.text}');
  print('latest tools=${mapped.toolParts.length}');
}
