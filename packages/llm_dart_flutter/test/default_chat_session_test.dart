import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_flutter/llm_dart_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('DirectChatTransport', () {
    test('maps chat transport requests to language model requests', () async {
      GenerateTextRequest? capturedRequest;

      final transport = DirectChatTransport(
        model: _FakeLanguageModel(
          onStream: (request) {
            capturedRequest = request;
            return const Stream<TextStreamEvent>.empty();
          },
        ),
      );

      await transport
          .sendMessages(
            ChatTransportRequest(
              chatId: 'chat-1',
              prompt: [
                UserPromptMessage.text('Hello'),
              ],
              options: const ChatRequestOptions(
                generateOptions: GenerateTextOptions(
                  temperature: 0.2,
                ),
              ),
            ),
          )
          .drain<void>();

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.prompt.single, isA<UserPromptMessage>());
      expect(capturedRequest!.options.temperature, 0.2);
    });
  });

  group('ChatSessionSnapshotJsonCodec', () {
    test(
        'round-trips prompt and UI messages and falls back for unserializable errors',
        () {
      const codec = ChatSessionSnapshotJsonCodec();
      final snapshot = ChatSessionSnapshot(
        chatId: 'chat-1',
        prompt: [
          UserPromptMessage.text('Click the button.'),
          AssistantPromptMessage(
            parts: [
              const ToolCallPromptPart(
                toolCallId: 'tool-1',
                toolName: 'computer',
                input: {
                  'action': 'click',
                },
                providerExecuted: true,
                isDynamic: true,
                title: 'Browser',
              ),
              const ToolApprovalRequestPromptPart(
                approvalId: 'approval-1',
                toolCallId: 'tool-1',
              ),
            ],
          ),
          ToolPromptMessage(
            toolName: 'computer',
            parts: [
              const ToolApprovalResponsePromptPart(
                approvalId: 'approval-1',
                toolCallId: 'tool-1',
                approved: false,
              ),
            ],
          ),
        ],
        messages: [
          ChatUiMessage(
            id: 'msg-0',
            role: ChatUiRole.user,
            parts: const [
              TextUiPart(text: 'Click the button.'),
            ],
          ),
          ChatUiMessage(
            id: 'msg-1',
            role: ChatUiRole.assistant,
            parts: const [
              ToolUiPart(
                toolCallId: 'tool-1',
                toolName: 'computer',
                state: ToolUiPartState.outputDenied,
                input: {
                  'action': 'click',
                },
                providerExecuted: true,
                isDynamic: true,
                title: 'Browser',
                approval: ToolApprovalUiState(
                  approvalId: 'approval-1',
                  approved: false,
                ),
              ),
            ],
            metadata: {
              ChatUiMetadataKeys.finishReason: FinishReason.toolCalls,
            },
          ),
        ],
        status: ChatStatus.error,
        error: StateError('snapshot failed'),
      );

      final encoded = codec.encodeSnapshot(snapshot);
      final decoded = codec.decodeSnapshot(encoded);

      expect(encoded['kind'], ChatSessionSnapshotJsonCodec.envelopeKind);
      expect(decoded.chatId, 'chat-1');
      expect(decoded.prompt, hasLength(3));
      expect(decoded.messages, hasLength(2));
      expect(decoded.status, ChatStatus.error);

      final assistantPrompt = decoded.prompt[1] as AssistantPromptMessage;
      expect(assistantPrompt.parts, hasLength(2));
      final toolCall = assistantPrompt.parts.first as ToolCallPromptPart;
      expect(toolCall.providerExecuted, isTrue);
      expect(toolCall.isDynamic, isTrue);
      expect(toolCall.title, 'Browser');

      final toolPart = decoded.messages[1].parts.whereType<ToolUiPart>().single;
      expect(toolPart.state, ToolUiPartState.outputDenied);
      expect(toolPart.approval?.approved, isFalse);

      final decodedError = decoded.error as Map<String, Object?>;
      expect(decodedError['type'], 'unserializable-error');
      expect(decodedError['runtimeType'], 'StateError');
      expect(decodedError['message'], contains('snapshot failed'));
    });
  });

  group('DefaultChatSession', () {
    test('appends user and assistant messages and returns to ready state',
        () async {
      final session = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) => Stream<TextStreamEvent>.fromIterable([
            StartEvent(),
            const TextStartEvent(id: 'text-1'),
            const TextDeltaEvent(id: 'text-1', delta: 'Hello'),
            const TextEndEvent(id: 'text-1'),
            const FinishEvent(finishReason: FinishReason.stop),
          ]),
        ),
      );

      final emittedStates = <ChatState>[];
      final subscription = session.states.listen(emittedStates.add);

      await session.sendMessage(ChatInput.text('Hi'));

      expect(session.state.status, ChatStatus.ready);
      expect(session.state.error, isNull);
      expect(session.state.messages, hasLength(2));
      expect(session.state.messages.first.role, ChatUiRole.user);
      expect(
        session.state.messages.first.parts.whereType<TextUiPart>().single.text,
        'Hi',
      );
      expect(session.state.messages.last.role, ChatUiRole.assistant);
      expect(
        session.state.messages.last.parts.whereType<TextUiPart>().single.text,
        'Hello',
      );
      expect(
        emittedStates.map((state) => state.status),
        containsAllInOrder([
          ChatStatus.submitting,
          ChatStatus.streaming,
          ChatStatus.ready,
        ]),
      );

      await subscription.cancel();
      await session.dispose();
    });

    test('stop marks the active assistant turn as aborted', () async {
      final controller = StreamController<TextStreamEvent>();
      final session = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) => controller.stream,
        ),
      );

      final sendFuture = session.sendMessage(ChatInput.text('Hi'));
      await Future<void>.delayed(Duration.zero);

      controller.add(StartEvent());
      controller.add(const TextStartEvent(id: 'text-1'));
      controller.add(const TextDeltaEvent(id: 'text-1', delta: 'Partial'));
      await Future<void>.delayed(Duration.zero);

      await session.stop();
      await sendFuture;
      await controller.close();

      expect(session.state.status, ChatStatus.ready);
      expect(session.state.messages, hasLength(2));
      final assistantMessage = session.state.messages.last;
      expect(
        assistantMessage.metadata[ChatUiMetadataKeys.finishReason],
        FinishReason.aborted,
      );
      expect(
        assistantMessage.parts.whereType<TextUiPart>().single.text,
        'Partial',
      );

      await session.dispose();
    });

    test('regenerate replaces the latest assistant message', () async {
      var invocation = 0;
      final session = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) {
            invocation += 1;
            return Stream<TextStreamEvent>.fromIterable([
              StartEvent(),
              const TextStartEvent(id: 'text-1'),
              TextDeltaEvent(
                id: 'text-1',
                delta: invocation == 1 ? 'First' : 'Second',
              ),
              const TextEndEvent(id: 'text-1'),
              const FinishEvent(finishReason: FinishReason.stop),
            ]);
          },
        ),
      );

      await session.sendMessage(ChatInput.text('Hi'));
      await session.regenerate();

      expect(session.state.messages, hasLength(2));
      expect(
        session.state.messages.last.parts.whereType<TextUiPart>().single.text,
        'Second',
      );

      await session.dispose();
    });

    test(
        'waits for tool output and continues the same assistant message without duplicating prompt history',
        () async {
      final capturedRequests = <ChatTransportRequest>[];

      final session = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) {
            capturedRequests.add(request);

            switch (capturedRequests.length) {
              case 1:
                return Stream<TextStreamEvent>.fromIterable([
                  StartEvent(),
                  const ToolCallEvent(
                    toolCall: ToolCallContent(
                      toolCallId: 'tool-1',
                      toolName: 'weather',
                      input: {
                        'city': 'London',
                      },
                    ),
                  ),
                  const FinishEvent(finishReason: FinishReason.toolCalls),
                ]);
              case 2:
                return Stream<TextStreamEvent>.fromIterable([
                  StartEvent(),
                  const TextStartEvent(id: 'text-2'),
                  const TextDeltaEvent(
                    id: 'text-2',
                    delta: 'The forecast is sunny.',
                  ),
                  const TextEndEvent(id: 'text-2'),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
              default:
                return Stream<TextStreamEvent>.fromIterable([
                  StartEvent(),
                  const TextStartEvent(id: 'text-3'),
                  const TextDeltaEvent(
                    id: 'text-3',
                    delta: 'You are welcome.',
                  ),
                  const TextEndEvent(id: 'text-3'),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
            }
          },
        ),
      );

      await session
          .sendMessage(ChatInput.text('What is the weather in London?'));

      expect(session.state.status, ChatStatus.awaitingTool);
      expect(capturedRequests, hasLength(1));
      final firstAssistant = session.state.messages.last;
      expect(firstAssistant.parts.whereType<ToolUiPart>().single.state,
          ToolUiPartState.inputAvailable);

      await session.addToolOutput(
        const ToolOutputUpdate(
          toolCallId: 'tool-1',
          toolName: 'weather',
          output: {
            'forecast': 'sunny',
          },
        ),
      );

      expect(session.state.status, ChatStatus.ready);
      expect(capturedRequests, hasLength(2));
      final toolRoundtripPrompt = capturedRequests[1].prompt;
      expect(toolRoundtripPrompt, hasLength(3));
      expect(toolRoundtripPrompt[0], isA<UserPromptMessage>());
      expect(toolRoundtripPrompt[1], isA<AssistantPromptMessage>());
      expect(toolRoundtripPrompt[2], isA<ToolPromptMessage>());
      expect(
        (toolRoundtripPrompt[2] as ToolPromptMessage).parts.single,
        isA<ToolResultPromptPart>(),
      );

      final mergedAssistant = session.state.messages.last;
      expect(
        mergedAssistant.parts.whereType<StepBoundaryUiPart>(),
        hasLength(1),
      );
      final mergedToolPart =
          mergedAssistant.parts.whereType<ToolUiPart>().single;
      expect(mergedToolPart.state, ToolUiPartState.outputAvailable);
      expect(
        (mergedToolPart.output as Map<String, Object?>)['forecast'],
        'sunny',
      );
      expect(
        mergedAssistant.parts.whereType<TextUiPart>().single.text,
        'The forecast is sunny.',
      );

      await session.sendMessage(ChatInput.text('Thanks'));

      expect(capturedRequests, hasLength(3));
      final followUpPrompt = capturedRequests[2].prompt;
      expect(followUpPrompt, hasLength(5));
      expect(followUpPrompt[3], isA<AssistantPromptMessage>());
      final finalAssistantPrompt = followUpPrompt[3] as AssistantPromptMessage;
      expect(finalAssistantPrompt.parts, hasLength(1));
      expect(finalAssistantPrompt.parts.single, isA<TextPromptPart>());
      expect(
        (finalAssistantPrompt.parts.single as TextPromptPart).text,
        'The forecast is sunny.',
      );

      await session.dispose();
    });

    test('persists denied approval responses in prompt history', () async {
      final capturedRequests = <ChatTransportRequest>[];

      final session = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) {
            capturedRequests.add(request);

            switch (capturedRequests.length) {
              case 1:
                return Stream<TextStreamEvent>.fromIterable([
                  StartEvent(),
                  const ToolCallEvent(
                    toolCall: ToolCallContent(
                      toolCallId: 'tool-1',
                      toolName: 'computer',
                      input: {
                        'action': 'click',
                      },
                      providerExecuted: true,
                    ),
                  ),
                  const ToolApprovalRequestEvent(
                    approvalId: 'approval-1',
                    toolCallId: 'tool-1',
                  ),
                  const FinishEvent(finishReason: FinishReason.toolCalls),
                ]);
              default:
                return Stream<TextStreamEvent>.fromIterable([
                  StartEvent(),
                  const TextStartEvent(id: 'text-2'),
                  const TextDeltaEvent(
                    id: 'text-2',
                    delta: 'Denied approval history is preserved.',
                  ),
                  const TextEndEvent(id: 'text-2'),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
            }
          },
        ),
      );

      await session.sendMessage(ChatInput.text('Click the submit button.'));

      expect(session.state.status, ChatStatus.awaitingApproval);
      final pendingTool =
          session.state.messages.last.parts.whereType<ToolUiPart>().single;
      expect(pendingTool.state, ToolUiPartState.approvalRequested);
      expect(pendingTool.approval?.approvalId, 'approval-1');

      await session.respondToolApproval(
        const ToolApprovalResponse(
          approvalId: 'approval-1',
          approved: false,
        ),
      );

      expect(session.state.status, ChatStatus.ready);
      final deniedTool =
          session.state.messages.last.parts.whereType<ToolUiPart>().single;
      expect(deniedTool.state, ToolUiPartState.outputDenied);
      expect(deniedTool.approval?.approved, isFalse);

      await session.sendMessage(ChatInput.text('What happened?'));

      expect(capturedRequests, hasLength(2));
      final followUpPrompt = capturedRequests[1].prompt;
      expect(followUpPrompt, hasLength(4));
      expect(followUpPrompt[2], isA<ToolPromptMessage>());
      final approvalResponseMessage = followUpPrompt[2] as ToolPromptMessage;
      expect(
        approvalResponseMessage.parts.single,
        isA<ToolApprovalResponsePromptPart>(),
      );
      expect(
        (approvalResponseMessage.parts.single as ToolApprovalResponsePromptPart)
            .approved,
        isFalse,
      );

      await session.dispose();
    });

    test(
        'continues provider-executed approval flows through transport-backed requests',
        () async {
      final capturedRequests = <ChatTransportRequest>[];

      final session = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) {
            capturedRequests.add(request);

            switch (capturedRequests.length) {
              case 1:
                return Stream<TextStreamEvent>.fromIterable([
                  StartEvent(),
                  const ToolCallEvent(
                    toolCall: ToolCallContent(
                      toolCallId: 'tool-1',
                      toolName: 'computer',
                      input: {
                        'action': 'click',
                      },
                      providerExecuted: true,
                      isDynamic: true,
                      title: 'Browser',
                    ),
                  ),
                  const ToolApprovalRequestEvent(
                    approvalId: 'approval-1',
                    toolCallId: 'tool-1',
                  ),
                  const FinishEvent(finishReason: FinishReason.toolCalls),
                ]);
              default:
                return Stream<TextStreamEvent>.fromIterable([
                  StartEvent(),
                  const TextStartEvent(id: 'text-2'),
                  const TextDeltaEvent(
                    id: 'text-2',
                    delta: 'The click was approved and executed.',
                  ),
                  const TextEndEvent(id: 'text-2'),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
            }
          },
        ),
      );

      await session.sendMessage(ChatInput.text('Click the submit button.'));
      await session.respondToolApproval(
        const ToolApprovalResponse(
          approvalId: 'approval-1',
          approved: true,
        ),
      );

      expect(capturedRequests, hasLength(2));
      final continuationPrompt = capturedRequests[1].prompt;
      expect(continuationPrompt, hasLength(3));
      expect(continuationPrompt[1], isA<AssistantPromptMessage>());
      expect(continuationPrompt[2], isA<ToolPromptMessage>());

      final assistantPrompt = continuationPrompt[1] as AssistantPromptMessage;
      expect(assistantPrompt.parts, hasLength(2));
      expect(assistantPrompt.parts[0], isA<ToolCallPromptPart>());
      expect(assistantPrompt.parts[1], isA<ToolApprovalRequestPromptPart>());
      final toolCallPart = assistantPrompt.parts[0] as ToolCallPromptPart;
      expect(toolCallPart.providerExecuted, isTrue);
      expect(toolCallPart.isDynamic, isTrue);
      expect(toolCallPart.title, 'Browser');

      final approvalResponseMessage =
          continuationPrompt[2] as ToolPromptMessage;
      expect(
        approvalResponseMessage.parts.single,
        isA<ToolApprovalResponsePromptPart>(),
      );
      expect(
        (approvalResponseMessage.parts.single as ToolApprovalResponsePromptPart)
            .approved,
        isTrue,
      );

      expect(session.state.status, ChatStatus.ready);
      final assistantMessage = session.state.messages.last;
      final approvedTool =
          assistantMessage.parts.whereType<ToolUiPart>().single;
      expect(approvedTool.state, ToolUiPartState.approvalResponded);
      expect(approvedTool.approval?.approved, isTrue);
      expect(
        assistantMessage.parts.whereType<TextUiPart>().single.text,
        'The click was approved and executed.',
      );

      await session.dispose();
    });

    test(
        'approved client-side tool calls return to awaitingTool and accept tool output',
        () async {
      final capturedRequests = <ChatTransportRequest>[];

      final session = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) {
            capturedRequests.add(request);

            switch (capturedRequests.length) {
              case 1:
                return Stream<TextStreamEvent>.fromIterable([
                  StartEvent(),
                  const ToolCallEvent(
                    toolCall: ToolCallContent(
                      toolCallId: 'tool-1',
                      toolName: 'computer',
                      input: {
                        'action': 'click',
                      },
                    ),
                  ),
                  const ToolApprovalRequestEvent(
                    approvalId: 'approval-1',
                    toolCallId: 'tool-1',
                  ),
                  const FinishEvent(finishReason: FinishReason.toolCalls),
                ]);
              default:
                return Stream<TextStreamEvent>.fromIterable([
                  StartEvent(),
                  const TextStartEvent(id: 'text-2'),
                  const TextDeltaEvent(
                    id: 'text-2',
                    delta: 'The local tool finished successfully.',
                  ),
                  const TextEndEvent(id: 'text-2'),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
            }
          },
        ),
      );

      await session.sendMessage(ChatInput.text('Click the submit button.'));
      await session.respondToolApproval(
        const ToolApprovalResponse(
          approvalId: 'approval-1',
          approved: true,
        ),
      );

      expect(capturedRequests, hasLength(1));
      expect(session.state.status, ChatStatus.awaitingTool);
      final approvedTool =
          session.state.messages.last.parts.whereType<ToolUiPart>().single;
      expect(approvedTool.state, ToolUiPartState.approvalResponded);
      expect(approvedTool.approval?.approved, isTrue);

      await session.addToolOutput(
        const ToolOutputUpdate(
          toolCallId: 'tool-1',
          toolName: 'computer',
          output: {
            'clicked': true,
          },
        ),
      );

      expect(capturedRequests, hasLength(2));
      final continuationPrompt = capturedRequests[1].prompt;
      expect(continuationPrompt, hasLength(4));
      expect(
        (continuationPrompt[2] as ToolPromptMessage).parts.single,
        isA<ToolApprovalResponsePromptPart>(),
      );
      expect(
        (continuationPrompt[3] as ToolPromptMessage).parts.single,
        isA<ToolResultPromptPart>(),
      );

      expect(session.state.status, ChatStatus.ready);
      expect(
        session.state.messages.last.parts.whereType<TextUiPart>().single.text,
        'The local tool finished successfully.',
      );

      await session.dispose();
    });

    test(
        'restores ready snapshots and preserves prompt history with unique message ids',
        () async {
      final capturedRequests = <ChatTransportRequest>[];

      final session = DefaultChatSession.fromSnapshot(
        transport: _FakeChatTransport(
          onSendMessages: (request) {
            capturedRequests.add(request);
            return Stream<TextStreamEvent>.fromIterable([
              StartEvent(),
              const TextStartEvent(id: 'text-1'),
              const TextDeltaEvent(
                id: 'text-1',
                delta: 'Restored continuation works.',
              ),
              const TextEndEvent(id: 'text-1'),
              const FinishEvent(finishReason: FinishReason.stop),
            ]);
          },
        ),
        snapshot: ChatSessionSnapshot(
          chatId: 'chat-restored',
          prompt: [
            UserPromptMessage.text('Hi'),
            AssistantPromptMessage.text('Hello'),
          ],
          messages: [
            ChatUiMessage(
              id: 'msg-0',
              role: ChatUiRole.user,
              parts: const [
                TextUiPart(text: 'Hi'),
              ],
            ),
            ChatUiMessage(
              id: 'msg-1',
              role: ChatUiRole.assistant,
              parts: const [
                TextUiPart(text: 'Hello'),
              ],
            ),
          ],
          status: ChatStatus.ready,
        ),
      );

      await session.sendMessage(ChatInput.text('Can you continue?'));

      expect(capturedRequests, hasLength(1));
      expect(capturedRequests.single.chatId, 'chat-restored');
      expect(capturedRequests.single.prompt, hasLength(3));
      expect(capturedRequests.single.prompt[0], isA<UserPromptMessage>());
      expect(capturedRequests.single.prompt[1], isA<AssistantPromptMessage>());
      expect(capturedRequests.single.prompt[2], isA<UserPromptMessage>());
      expect(session.state.messages.map((message) => message.id), [
        'msg-0',
        'msg-1',
        'msg-2',
        'msg-3',
      ]);
      expect(session.state.status, ChatStatus.ready);
      expect(
        session.state.messages.last.parts.whereType<TextUiPart>().single.text,
        'Restored continuation works.',
      );

      final exported = session.exportSnapshot();
      expect(exported.prompt, hasLength(4));
      expect(exported.messages, hasLength(4));

      await session.dispose();
    });

    test(
        'exports awaitingTool snapshots and restored sessions accept tool output continuation',
        () async {
      final exportingSession = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) => Stream<TextStreamEvent>.fromIterable([
            StartEvent(),
            const ToolCallEvent(
              toolCall: ToolCallContent(
                toolCallId: 'tool-1',
                toolName: 'weather',
                input: {
                  'city': 'London',
                },
              ),
            ),
            const FinishEvent(finishReason: FinishReason.toolCalls),
          ]),
        ),
      );

      await exportingSession.sendMessage(ChatInput.text('Weather in London?'));

      final snapshot = exportingSession.exportSnapshot();
      expect(snapshot.status, ChatStatus.awaitingTool);
      expect(snapshot.prompt, hasLength(2));
      expect(snapshot.messages, hasLength(2));

      final capturedRequests = <ChatTransportRequest>[];
      final restoredSession = DefaultChatSession.fromSnapshot(
        transport: _FakeChatTransport(
          onSendMessages: (request) {
            capturedRequests.add(request);
            return Stream<TextStreamEvent>.fromIterable([
              StartEvent(),
              const TextStartEvent(id: 'text-2'),
              const TextDeltaEvent(
                id: 'text-2',
                delta: 'The restored tool result was applied.',
              ),
              const TextEndEvent(id: 'text-2'),
              const FinishEvent(finishReason: FinishReason.stop),
            ]);
          },
        ),
        snapshot: snapshot,
      );

      await restoredSession.addToolOutput(
        const ToolOutputUpdate(
          toolCallId: 'tool-1',
          toolName: 'weather',
          output: {
            'forecast': 'sunny',
          },
        ),
      );

      expect(capturedRequests, hasLength(1));
      expect(capturedRequests.single.prompt, hasLength(3));
      expect(capturedRequests.single.prompt[2], isA<ToolPromptMessage>());
      expect(
        (capturedRequests.single.prompt[2] as ToolPromptMessage).parts.single,
        isA<ToolResultPromptPart>(),
      );
      expect(restoredSession.state.status, ChatStatus.ready);

      final mergedAssistant = restoredSession.state.messages.last;
      final mergedTool = mergedAssistant.parts.whereType<ToolUiPart>().single;
      expect(mergedTool.state, ToolUiPartState.outputAvailable);
      expect(
        (mergedTool.output as Map<String, Object?>)['forecast'],
        'sunny',
      );
      expect(
        mergedAssistant.parts.whereType<TextUiPart>().single.text,
        'The restored tool result was applied.',
      );

      await exportingSession.dispose();
      await restoredSession.dispose();
    });

    test(
        'exports awaitingApproval snapshots and restored sessions continue provider approvals',
        () async {
      final exportingSession = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) => Stream<TextStreamEvent>.fromIterable([
            StartEvent(),
            const ToolCallEvent(
              toolCall: ToolCallContent(
                toolCallId: 'tool-1',
                toolName: 'computer',
                input: {
                  'action': 'click',
                },
                providerExecuted: true,
                isDynamic: true,
                title: 'Browser',
              ),
            ),
            const ToolApprovalRequestEvent(
              approvalId: 'approval-1',
              toolCallId: 'tool-1',
            ),
            const FinishEvent(finishReason: FinishReason.toolCalls),
          ]),
        ),
      );

      await exportingSession.sendMessage(ChatInput.text('Click the button.'));

      final snapshot = exportingSession.exportSnapshot();
      expect(snapshot.status, ChatStatus.awaitingApproval);
      expect(snapshot.prompt, hasLength(2));

      final capturedRequests = <ChatTransportRequest>[];
      final restoredSession = DefaultChatSession.fromSnapshot(
        transport: _FakeChatTransport(
          onSendMessages: (request) {
            capturedRequests.add(request);
            return Stream<TextStreamEvent>.fromIterable([
              StartEvent(),
              const TextStartEvent(id: 'text-2'),
              const TextDeltaEvent(
                id: 'text-2',
                delta: 'The restored approval was executed.',
              ),
              const TextEndEvent(id: 'text-2'),
              const FinishEvent(finishReason: FinishReason.stop),
            ]);
          },
        ),
        snapshot: snapshot,
      );

      await restoredSession.respondToolApproval(
        const ToolApprovalResponse(
          approvalId: 'approval-1',
          approved: true,
        ),
      );

      expect(capturedRequests, hasLength(1));
      expect(capturedRequests.single.prompt, hasLength(3));
      expect(capturedRequests.single.prompt[1], isA<AssistantPromptMessage>());
      expect(capturedRequests.single.prompt[2], isA<ToolPromptMessage>());
      expect(
        (capturedRequests.single.prompt[2] as ToolPromptMessage).parts.single,
        isA<ToolApprovalResponsePromptPart>(),
      );

      final assistantMessage = restoredSession.state.messages.last;
      final approvedTool =
          assistantMessage.parts.whereType<ToolUiPart>().single;
      expect(approvedTool.state, ToolUiPartState.approvalResponded);
      expect(approvedTool.approval?.approved, isTrue);
      expect(restoredSession.state.status, ChatStatus.ready);
      expect(
        assistantMessage.parts.whereType<TextUiPart>().single.text,
        'The restored approval was executed.',
      );

      await exportingSession.dispose();
      await restoredSession.dispose();
    });

    test('transitions to error state when the stream emits ErrorEvent',
        () async {
      final session = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) => Stream<TextStreamEvent>.fromIterable([
            StartEvent(),
            const ErrorEvent('provider failed'),
          ]),
        ),
      );

      await session.sendMessage(ChatInput.text('Hi'));

      expect(session.state.status, ChatStatus.error);
      expect(session.state.error, 'provider failed');
      expect(session.state.messages, hasLength(2));

      await session.clearError();
      expect(session.state.status, ChatStatus.ready);
      expect(session.state.error, isNull);

      await session.dispose();
    });
  });
}

final class _FakeChatTransport implements ChatTransport {
  final Stream<TextStreamEvent> Function(ChatTransportRequest request)
      onSendMessages;

  const _FakeChatTransport({
    required this.onSendMessages,
  });

  @override
  Stream<TextStreamEvent>? reconnect(String chatId) => null;

  @override
  Stream<TextStreamEvent> sendMessages(ChatTransportRequest request) {
    return onSendMessages(request);
  }
}

final class _FakeLanguageModel implements LanguageModel {
  final Stream<TextStreamEvent> Function(GenerateTextRequest request) onStream;

  const _FakeLanguageModel({
    required this.onStream,
  });

  @override
  String get modelId => 'fake-model';

  @override
  String get providerId => 'fake';

  @override
  Future<GenerateTextResult> generate(GenerateTextRequest request) {
    throw UnimplementedError();
  }

  @override
  Stream<TextStreamEvent> stream(GenerateTextRequest request) {
    return onStream(request);
  }
}
