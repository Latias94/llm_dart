import 'dart:async';

import 'package:flutter/material.dart';
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_flutter/llm_dart_flutter.dart';

import 'backend_hint_demo_support.dart';

void main() {
  runApp(const BackendHintMaterialChatApp());
}

class BackendHintMaterialChatApp extends StatelessWidget {
  const BackendHintMaterialChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const BackendHintMaterialChatPage(),
    );
  }
}

class BackendHintMaterialChatPage extends StatefulWidget {
  const BackendHintMaterialChatPage({super.key});

  @override
  State<BackendHintMaterialChatPage> createState() =>
      _BackendHintMaterialChatPageState();
}

class _BackendHintMaterialChatPageState
    extends State<BackendHintMaterialChatPage> {
  static const _messageFieldKey = Key('backend-hint-message-field');
  static const _sendButtonKey = Key('backend-hint-send-button');

  late final ValueNotifier<String> _providerProfile;
  late final ChatController _controller;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _providerProfile = ValueNotifier<String>(defaultBackendHintDemoProfile);
    _controller = ChatController(
      session: DefaultChatSession(
        transport: createBackendHintDemoTransport(
          providerProfileListenable: _providerProfile,
          fixedMetadata: const {
            'tenantId': 'acme-mobile',
            'screen': 'material-chat-demo',
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _providerProfile.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _controller.status != ChatStatus.ready) {
      return;
    }

    _textController.clear();
    await _controller.sendMessage(
      ChatInput.text(text),
      options: const ChatRequestOptions(
        generateOptions: GenerateTextOptions(
          maxOutputTokens: 180,
          temperature: 0.1,
        ),
        metadata: {
          'clientRequestId': 'flutter-material-demo',
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Hint Chat Demo'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ValueListenableBuilder<String>(
                valueListenable: _providerProfile,
                builder: (context, selectedProfile, _) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final profile in backendHintDemoProfiles)
                          ChoiceChip(
                            key: Key('backend-profile-$profile'),
                            label: Text(backendHintProfileLabel(profile)),
                            selected: selectedProfile == profile,
                            onSelected: (selected) {
                              if (!selected) {
                                return;
                              }

                              _providerProfile.value = profile;
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ValueListenableBuilder<ChatState>(
                  valueListenable: _controller,
                  builder: (context, state, _) {
                    if (state.messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'Send a message to see backend-owned provider routing.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final message = state.messages[index];
                        final mapped = const ChatMessageMapper().map(message);
                        final planSummary = message.role == ChatUiRole.assistant
                            ? backendPlanSummary(message)
                            : '';

                        return Align(
                          alignment: message.role == ChatUiRole.user
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: Card(
                              color: message.role == ChatUiRole.user
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.role.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(mapped.text),
                                    if (planSummary.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Backend plan: $planSummary',
                                        key: Key(
                                          'backend-plan-${message.id}',
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<ChatState>(
                valueListenable: _controller,
                builder: (context, state, _) {
                  final canSend = state.status == ChatStatus.ready;

                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: _messageFieldKey,
                          controller: _textController,
                          enabled: canSend,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            hintText:
                                'Ask the backend to summarize the latest update.',
                            errorText: state.status == ChatStatus.error &&
                                    state.error != null
                                ? state.error!.message
                                : null,
                          ),
                          minLines: 1,
                          maxLines: 4,
                          onSubmitted: (_) {
                            unawaited(_send());
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        key: _sendButtonKey,
                        onPressed: canSend ? () => unawaited(_send()) : null,
                        child: Text(
                          canSend ? 'Send' : state.status.name,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
