// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart_flutter/llm_dart_flutter.dart';

Future<void> main() async {
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Set OPENAI_API_KEY to run this example.');
    return;
  }

  final model = llm.AI.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');
  final session = DefaultChatSession(
    transport: DirectChatTransport(model: model),
  );

  final subscription = session.states.listen(printState);

  try {
    await session.sendMessage(
      ChatInput.text('Write a short haiku about Flutter widgets.'),
    );

    final snapshot = session.exportSnapshot();
    print('\nSnapshot exported for chatId=${snapshot.chatId}');
    print('Persisted messages=${snapshot.messages.length}');
  } finally {
    await subscription.cancel();
    await session.dispose();
  }
}

void printState(ChatState state) {
  print('status=${state.status}');

  if (state.messages.isEmpty) {
    return;
  }

  final latest = state.messages.last;
  print('latest role=${latest.role} parts=${latest.parts.length}');
}
