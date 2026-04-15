import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_flutter/llm_dart_flutter.dart';

import 'tool_approval_demo_support.dart';

void main() {
  runApp(const ToolApprovalMaterialChatApp());
}

class ToolApprovalMaterialChatApp extends StatelessWidget {
  const ToolApprovalMaterialChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const ToolApprovalMaterialChatPage(),
    );
  }
}

class ToolApprovalMaterialChatPage extends StatefulWidget {
  const ToolApprovalMaterialChatPage({super.key});

  @override
  State<ToolApprovalMaterialChatPage> createState() =>
      _ToolApprovalMaterialChatPageState();
}

class _ToolApprovalMaterialChatPageState
    extends State<ToolApprovalMaterialChatPage> {
  static const _messageFieldKey = Key('tool-approval-message-field');
  static const _sendButtonKey = Key('tool-approval-send-button');
  static const _statusKey = Key('tool-approval-status');

  late final ChatController _controller;
  final TextEditingController _textController = TextEditingController(
    text: 'Please publish the release update and confirm today\'s weather.',
  );

  @override
  void initState() {
    super.initState();
    _controller = ChatController(
      session: createToolApprovalDemoSession(),
    );
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
          maxOutputTokens: 200,
          temperature: 0.1,
        ),
      ),
    );
  }

  Future<void> _respondApproval({
    required String approvalId,
    required bool approved,
  }) {
    return _controller.respondToolApproval(
      ToolApprovalResponse(
        approvalId: approvalId,
        approved: approved,
        reason: approved
            ? 'This browser action is expected for the release flow.'
            : 'Do not click the publish button from this demo.',
      ),
    );
  }

  Future<void> _runLocalTool(ToolUiPart part) {
    return _controller.addToolOutput(
      ToolOutputUpdate(
        toolCallId: part.toolCallId,
        toolName: part.toolName,
        output: buildDemoLocalToolOutput(part),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tool Approval Chat Demo'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ValueListenableBuilder<ChatState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              final canSend = state.status == ChatStatus.ready;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This demo exercises the UI loop from '
                    '`awaitingApproval` to `awaitingTool` and back to `ready`.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Chip(
                    key: _statusKey,
                    label: Text('status: ${state.status.name}'),
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
                              'Send the default message to trigger one provider approval and one local tool call.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 12),
                            itemCount: state.messages.length,
                            itemBuilder: (context, index) {
                              return _MessageCard(
                                message: state.messages[index],
                                onApprove: _respondApproval,
                                onRunLocalTool: _runLocalTool,
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
                                'Ask the assistant to publish and check the weather.',
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

class _MessageCard extends StatelessWidget {
  final ChatUiMessage message;
  final Future<void> Function({
    required String approvalId,
    required bool approved,
  }) onApprove;
  final Future<void> Function(ToolUiPart part) onRunLocalTool;

  const _MessageCard({
    required this.message,
    required this.onApprove,
    required this.onRunLocalTool,
  });

  @override
  Widget build(BuildContext context) {
    final mapped = const ChatMessageMapper().map(message);
    final toolParts = message.parts.whereType<ToolUiPart>().toList();

    return Align(
      alignment: message.role == ChatUiRole.user
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Card(
          color: message.role == ChatUiRole.user
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.role.name,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                if (mapped.text.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(mapped.text),
                ],
                if (toolParts.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  for (final part in toolParts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ToolPartCard(
                        part: part,
                        onApprove: onApprove,
                        onRunLocalTool: onRunLocalTool,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolPartCard extends StatelessWidget {
  final ToolUiPart part;
  final Future<void> Function({
    required String approvalId,
    required bool approved,
  }) onApprove;
  final Future<void> Function(ToolUiPart part) onRunLocalTool;

  const _ToolPartCard({
    required this.part,
    required this.onApprove,
    required this.onRunLocalTool,
  });

  @override
  Widget build(BuildContext context) {
    final approval = part.approval;
    final canApprove =
        part.state == ToolUiPartState.approvalRequested && approval != null;
    final canRunLocalTool = !part.providerExecuted &&
        (part.state == ToolUiPartState.inputAvailable ||
            part.state == ToolUiPartState.inputStreaming ||
            part.state == ToolUiPartState.approvalResponded);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  part.toolName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Chip(
                  label: Text(part.providerExecuted ? 'provider' : 'local'),
                ),
                Chip(
                  label: Text(toolUiStateLabel(part.state)),
                ),
              ],
            ),
            if (part.title != null) ...[
              const SizedBox(height: 6),
              Text('title: ${part.title}'),
            ],
            if (part.input != null) ...[
              const SizedBox(height: 6),
              Text('input: ${_compactObject(part.input)}'),
            ],
            if (approval != null) ...[
              const SizedBox(height: 6),
              Text(
                'approvalId: ${approval.approvalId}'
                '${approval.approved == null ? '' : ', approved: ${approval.approved}'}'
                '${approval.reason == null ? '' : ', reason: ${approval.reason}'}',
              ),
            ],
            if (part.output != null) ...[
              const SizedBox(height: 6),
              Text('output: ${_compactObject(part.output)}'),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canApprove)
                  OutlinedButton(
                    key: Key('tool-approve-${approval.approvalId}'),
                    onPressed: () => unawaited(
                      onApprove(
                        approvalId: approval.approvalId,
                        approved: true,
                      ),
                    ),
                    child: const Text('Approve'),
                  ),
                if (canApprove)
                  OutlinedButton(
                    key: Key('tool-deny-${approval.approvalId}'),
                    onPressed: () => unawaited(
                      onApprove(
                        approvalId: approval.approvalId,
                        approved: false,
                      ),
                    ),
                    child: const Text('Deny'),
                  ),
                if (canRunLocalTool)
                  FilledButton.tonal(
                    key: Key('tool-run-${part.toolCallId}'),
                    onPressed: () => unawaited(onRunLocalTool(part)),
                    child: const Text('Run local tool'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _compactObject(Object? value) {
    if (value == null) {
      return 'null';
    }

    if (value is String) {
      return value;
    }

    try {
      return jsonEncode(value);
    } catch (_) {
      return '$value';
    }
  }
}
