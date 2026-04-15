// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_flutter/llm_dart_flutter.dart';

import 'backend_hint_demo_support.dart';

Future<void> main() async {
  final providerProfile = ValueNotifier<String>(defaultBackendHintDemoProfile);
  final controller = ChatController(
    session: DefaultChatSession(
      transport: createBackendHintDemoTransport(
        providerProfileListenable: providerProfile,
        fixedMetadata: const {
          'tenantId': 'acme-mobile',
          'screen': 'chat-home',
        },
      ),
    ),
  );

  controller.addListener(() {
    _printState(controller.state);
  });

  try {
    await controller.sendMessage(
      ChatInput.text('Plan a short release-summary message for the user.'),
      options: const ChatRequestOptions(
        generateOptions: GenerateTextOptions(
          maxOutputTokens: 180,
          temperature: 0.1,
        ),
        metadata: {
          'clientRequestId': 'flutter-client-1',
        },
      ),
    );

    await _waitUntilReady(controller);

    final latest = controller.state.messages.last;
    final mapped = const ChatMessageMapper().map(latest);

    print('\nFinal assistant text:');
    print(mapped.text);

    print('\nMessage metadata:');
    print(latest.metadata);

    final planSummary = backendPlanSummary(latest);
    if (planSummary.isNotEmpty) {
      print('\nBackend plan:');
      print(planSummary);
    }
  } finally {
    await controller.close();
    providerProfile.dispose();
  }
}

Future<void> _waitUntilReady(ChatController controller) async {
  if (controller.status == ChatStatus.ready) {
    return;
  }

  await controller.session.states.firstWhere(
    (state) => state.status == ChatStatus.ready,
  );
}

void _printState(ChatState state) {
  print('status=${state.status}');

  if (state.messages.isEmpty) {
    return;
  }

  final latest = state.messages.last;
  if (latest.role != ChatUiRole.assistant) {
    return;
  }

  final mapped = const ChatMessageMapper().map(latest);
  if (mapped.text.isNotEmpty) {
    print('assistantText=${mapped.text}');
  }
}
