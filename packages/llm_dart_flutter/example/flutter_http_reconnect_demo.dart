import 'dart:async';

import 'package:flutter/material.dart';
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_flutter/llm_dart_flutter.dart';

import 'http_reconnect_demo_support.dart';

void main() {
  runApp(const HttpReconnectMaterialChatApp());
}

class HttpReconnectMaterialChatApp extends StatelessWidget {
  const HttpReconnectMaterialChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const HttpReconnectMaterialChatPage(),
    );
  }
}

class HttpReconnectMaterialChatPage extends StatefulWidget {
  const HttpReconnectMaterialChatPage({super.key});

  @override
  State<HttpReconnectMaterialChatPage> createState() =>
      _HttpReconnectMaterialChatPageState();
}

class _HttpReconnectMaterialChatPageState
    extends State<HttpReconnectMaterialChatPage> {
  static const _messageFieldKey = Key('http-reconnect-message-field');
  static const _sendButtonKey = Key('http-reconnect-send-button');
  static const _resumeButtonKey = Key('http-reconnect-resume-button');
  static const _statusKey = Key('http-reconnect-status');

  late final ChatController _controller;
  final TextEditingController _textController = TextEditingController(
    text: 'Summarize the reconnect recovery flow.',
  );

  @override
  void initState() {
    super.initState();
    _controller = createHttpReconnectDemoController();
  }

  @override
  void dispose() {
    _textController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _controller.status != ChatStatus.ready) {
      return;
    }

    await _controller.sendMessage(
      ChatInput.text(text),
      options: const ChatRequestOptions(
        generateOptions: GenerateTextOptions(
          maxOutputTokens: 180,
          temperature: 0.1,
        ),
        metadata: {
          'clientRequestId': 'flutter-http-reconnect-demo',
        },
      ),
    );
  }

  Future<void> _resume() {
    if (_controller.status != ChatStatus.error) {
      return Future.value();
    }

    return _controller.resume();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HTTP Reconnect Chat Demo'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ValueListenableBuilder<ChatState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              final canSend = state.status == ChatStatus.ready;
              final canResume = state.status == ChatStatus.error;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This demo simulates an HTTP streaming failure, then uses '
                    '`resume()` to rebuild the current assistant turn from '
                    'transport replay plus the resumed tail.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        key: _statusKey,
                        label: Text('status: ${state.status.name}'),
                      ),
                      OutlinedButton(
                        key: _resumeButtonKey,
                        onPressed:
                            canResume ? () => unawaited(_resume()) : null,
                        child: const Text('Resume'),
                      ),
                    ],
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      state.error!.message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Expanded(
                    child: state.messages.isEmpty
                        ? const Center(
                            child: Text(
                              'Send the default message to simulate a network drop and reconnect recovery.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 12),
                            itemCount: state.messages.length,
                            itemBuilder: (context, index) {
                              final message = state.messages[index];
                              final mapped =
                                  const ChatMessageMapper().map(message);
                              final progress =
                                  reconnectProgressSummary(message);
                              final reconnectInfo =
                                  reconnectInfoSummary(message);

                              return Align(
                                alignment: message.role == ChatUiRole.user
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 620),
                                  child: Card(
                                    color: message.role == ChatUiRole.user
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                        : null,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            message.role.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium,
                                          ),
                                          if (mapped.text.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(mapped.text),
                                          ],
                                          if (progress.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              'Progress: $progress',
                                              key: Key(
                                                'http-reconnect-progress-${message.id}',
                                              ),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                          if (reconnectInfo.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              'Reconnect: $reconnectInfo',
                                              key: Key(
                                                'http-reconnect-info-${message.id}',
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
                          ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: _messageFieldKey,
                          controller: _textController,
                          enabled: canSend,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText:
                                'Ask the backend to simulate reconnect recovery.',
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
                        child: Text(canSend ? 'Send' : state.status.name),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
