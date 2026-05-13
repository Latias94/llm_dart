// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;

Future<void> main() async {
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Set OPENAI_API_KEY to run this example.');
    return;
  }

  final model = llm.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');

  print('Chat basics with the stable shared text-call surface.\n');

  await demonstrateBasicChat(model);
  await demonstrateMessageTypes(model);
  await demonstrateConversationHistory(model);
  await demonstrateResponseMetadata(model);
  await demonstrateContextManagement(model);
}

Future<void> demonstrateBasicChat(core.LanguageModel model) async {
  print('1. Basic chat');

  try {
    final result = await core.generateTextCall(
      model: model,
      messages: [
        core.UserModelMessage.text('What is the capital of Japan?'),
      ],
    );

    print('User: What is the capital of Japan?');
    print('Assistant: ${result.text}\n');
  } catch (error) {
    print('Basic chat failed: $error\n');
  }
}

Future<void> demonstrateMessageTypes(core.LanguageModel model) async {
  print('2. Prompt message roles');

  try {
    final result = await core.generateTextCall(
      model: model,
      messages: [
        core.SystemModelMessage.text(
          'You are a patient algebra tutor. Explain ideas simply and clearly.',
        ),
        core.UserModelMessage.text(
          'I keep hearing about variables in algebra. What are they?',
        ),
        core.AssistantModelMessage.text(
          'Variables are placeholders for values that may change or still need '
          'to be discovered.',
        ),
        core.UserModelMessage.text(
          'Give me a short example with x.',
        ),
      ],
    );

    print('System -> sets behavior');
    print('User -> provides the current question');
    print('Assistant -> replays prior context');
    print('Assistant reply: ${result.text}\n');
  } catch (error) {
    print('Prompt message role demo failed: $error\n');
  }
}

Future<void> demonstrateConversationHistory(core.LanguageModel model) async {
  print('3. Conversation history');

  try {
    final conversation = <core.ModelMessage>[];

    conversation.add(
      core.UserModelMessage.text('Hi. What did I just ask you to remember?'),
    );
    var result = await core.generateTextCall(
      model: model,
      messages: conversation,
    );
    conversation.add(core.AssistantModelMessage.text(result.text));
    print('Turn 1: ${result.text}');

    conversation.add(
      core.UserModelMessage.text(
        'Remember that my favorite language is Dart. Repeat it back.',
      ),
    );
    result = await core.generateTextCall(
      model: model,
      messages: conversation,
    );
    conversation.add(core.AssistantModelMessage.text(result.text));
    print('Turn 2: ${result.text}');

    conversation.add(
      core.UserModelMessage.text(
        'Now summarize this conversation in one sentence.',
      ),
    );
    result = await core.generateTextCall(
      model: model,
      messages: conversation,
    );
    print('Turn 3: ${result.text}\n');
  } catch (error) {
    print('Conversation history demo failed: $error\n');
  }
}

Future<void> demonstrateResponseMetadata(core.LanguageModel model) async {
  print('4. Response metadata');

  try {
    final result = await core.generateTextCall(
      model: model,
      messages: [
        core.UserModelMessage.text(
          'Explain quantum computing in about 80 words.',
        ),
      ],
    );

    print('Text: ${result.text}');
    print('Response ID: ${result.responseId ?? "n/a"}');
    print('Response model: ${result.responseModelId ?? "n/a"}');

    final usage = result.usage;
    if (usage != null) {
      print('Input tokens: ${usage.inputTokens ?? "n/a"}');
      print('Output tokens: ${usage.outputTokens ?? "n/a"}');
      print('Total tokens: ${usage.totalTokens ?? "n/a"}');
    } else {
      print('Usage: n/a');
    }

    final reasoningText = result.reasoningText;
    if (reasoningText != null && reasoningText.isNotEmpty) {
      print('Reasoning text length: ${reasoningText.length}');
    } else {
      print('Reasoning text: not returned by this response');
    }

    print('');
  } catch (error) {
    print('Response metadata demo failed: $error\n');
  }
}

Future<void> demonstrateContextManagement(core.LanguageModel model) async {
  print('5. Context management');

  try {
    final shortContext = await core.generateTextCall(
      model: model,
      messages: [
        core.UserModelMessage.text('What is AI?'),
      ],
    );

    final richContext = await core.generateTextCall(
      model: model,
      messages: [
        core.SystemModelMessage.text(
          'You are helping a computer-science student prepare for an exam.',
        ),
        core.UserModelMessage.text(
          'I need a concise but exam-ready definition of AI.',
        ),
        core.AssistantModelMessage.text(
          'Sure. I can answer briefly or expand with examples.',
        ),
        core.UserModelMessage.text(
          'Give me the exam-ready version with one example.',
        ),
      ],
    );

    final longConversation = <core.ModelMessage>[
      core.SystemModelMessage.text(
        'You summarize prior discussion accurately before answering.',
      ),
    ];

    for (var index = 1; index <= 4; index += 1) {
      longConversation.add(
        core.UserModelMessage.text(
            'We discussed topic $index. Keep track of it.'),
      );
      longConversation.add(
        core.AssistantModelMessage.text(
            'Recorded topic $index for later recall.'),
      );
    }

    longConversation.add(
      core.UserModelMessage.text('List every topic we discussed so far.'),
    );

    final summary = await core.generateTextCall(
      model: model,
      messages: longConversation,
    );

    print('Short context response length: ${shortContext.text.length}');
    print('Rich context response length: ${richContext.text.length}');
    print('Long conversation message count: ${longConversation.length}');
    print('Summary of prior topics: ${summary.text}\n');
  } catch (error) {
    print('Context management demo failed: $error\n');
  }
}
