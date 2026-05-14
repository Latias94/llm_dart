import 'dart:async';

import 'package:llm_dart_chat/llm_dart_chat.dart';
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_ai/internal.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:test/test.dart';

void main() {
  group('DirectChatTransport', () {
    test('maps chat transport requests to language model requests', () async {
      GenerateTextRequest? capturedRequest;

      final transport = DirectChatTransport(
        model: _FakeLanguageModel(
          onStream: (request) {
            capturedRequest = request;
            return Stream<LanguageModelStreamEvent>.fromIterable([
              textStreamEventToProvider(
                const FinishEvent(finishReason: FinishReason.stop),
              ),
            ]);
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
                callOptions: CallOptions(
                  headers: {
                    'x-chat': '1',
                  },
                ),
              ),
            ),
          )
          .drain<void>();

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.prompt.single, isA<UserPromptMessage>());
      expect(capturedRequest!.options.temperature, 0.2);
      expect(capturedRequest!.callOptions.headers, {
        'x-chat': '1',
      });
    });

    test('streams through AI runtime projection with message metadata',
        () async {
      final transport = DirectChatTransport(
        model: _FakeLanguageModel(
          onStream: (_) => Stream<LanguageModelStreamEvent>.fromIterable(
            [
              textStreamEventToProvider(const TextStartEvent(id: 'text-1')),
              textStreamEventToProvider(
                const TextDeltaEvent(id: 'text-1', delta: 'Hello'),
              ),
              textStreamEventToProvider(const TextEndEvent(id: 'text-1')),
              textStreamEventToProvider(
                const FinishEvent(finishReason: FinishReason.stop),
              ),
            ],
          ),
        ),
      );

      final chunks = await transport
          .sendMessages(
            ChatTransportRequest(
              chatId: 'chat-1',
              prompt: [
                UserPromptMessage.text('Hello'),
              ],
              options: const ChatRequestOptions(
                metadata: {
                  'source': 'direct',
                },
              ),
            ),
          )
          .toList();

      final start = chunks.first as ChatUiMessageStartChunk;
      expect(start.metadata['source'], 'direct');
      final eventChunks = chunks.whereType<ChatUiEventChunk>().toList();
      expect(eventChunks, hasLength(8));
      expect(eventChunks.first.event, isA<RunStartEvent>());
      expect(eventChunks[1].event, isA<StepStartEvent>());
      expect(eventChunks[eventChunks.length - 2].event, isA<StepFinishEvent>());
      expect(eventChunks.last.event, isA<RunFinishEvent>());
    });

    test('forwards runtime tool loop options to streamText', () async {
      final streamedEvents = <TextStreamEvent>[];
      final toolStarts = <GenerateTextToolExecutionStartEvent>[];
      final toolFinishes = <GenerateTextToolExecutionFinishEvent>[];
      final stepFinishes = <GenerateTextStepResult>[];
      GenerateTextRunResult? runResult;

      final transport = DirectChatTransport(
        model: _FakeLanguageModel(
          onStream: (request) {
            switch (request.prompt.length) {
              case 1:
                expect(request.tools.single.name, 'weather');
                expect(request.toolChoice, isA<RequiredToolChoice>());
                expect(request.options.temperature, 0.2);
                expect(
                  request.callOptions.timeout,
                  const Duration(seconds: 3),
                );
                return Stream<LanguageModelStreamEvent>.fromIterable([
                  textStreamEventToProvider(
                    const ToolCallEvent(
                      toolCall: ToolCallContent(
                        toolCallId: 'tool-1',
                        toolName: 'weather',
                        input: {
                          'location': 'Tokyo',
                        },
                      ),
                    ),
                  ),
                  textStreamEventToProvider(
                    const FinishEvent(finishReason: FinishReason.toolCalls),
                  ),
                ]);
              case 3:
                final toolMessage = request.prompt[2] as ToolPromptMessage;
                final toolResult =
                    toolMessage.parts.single as ToolResultPromptPart;
                expect(toolResult.toolCallId, 'tool-1');
                expect(toolResult.output, {
                  'temperature': 24,
                });
                return Stream<LanguageModelStreamEvent>.fromIterable([
                  textStreamEventToProvider(
                    const TextStartEvent(id: 'text-2'),
                  ),
                  textStreamEventToProvider(
                    const TextDeltaEvent(
                      id: 'text-2',
                      delta: 'It is 24C in Tokyo.',
                    ),
                  ),
                  textStreamEventToProvider(
                    const TextEndEvent(id: 'text-2'),
                  ),
                  textStreamEventToProvider(
                    const FinishEvent(finishReason: FinishReason.stop),
                  ),
                ]);
              default:
                throw StateError(
                  'Unexpected prompt length ${request.prompt.length}.',
                );
            }
          },
        ),
      );

      final chunks = await transport
          .sendMessages(
            ChatTransportRequest(
              chatId: 'chat-1',
              prompt: [
                UserPromptMessage.text('Weather in Tokyo?'),
              ],
              options: ChatRequestOptions(
                tools: [
                  FunctionToolDefinition(
                    name: 'weather',
                    inputSchema: ToolJsonSchema.object(),
                  ),
                ],
                toolChoice: const RequiredToolChoice(),
                generateOptions: const GenerateTextOptions(
                  temperature: 0.2,
                ),
                callOptions: const CallOptions(
                  timeout: Duration(seconds: 3),
                ),
                functionToolExecutor: (request) {
                  expect(request.stepNumber, 0);
                  expect(request.toolCall.toolName, 'weather');
                  return const GenerateTextToolExecutionResult.output({
                    'temperature': 24,
                  });
                },
                maxSteps: 4,
                stopWhen: [isLoopFinished()],
                onToolStart: toolStarts.add,
                onToolFinish: toolFinishes.add,
                onStepFinish: stepFinishes.add,
                onFinish: (result) {
                  runResult = result;
                },
                onChunk: streamedEvents.add,
              ),
            ),
          )
          .toList();

      final events = chunks.whereType<ChatUiEventChunk>().map(
            (chunk) => chunk.event,
          );
      expect(events.whereType<ToolResultEvent>(), hasLength(1));
      expect(
        events.whereType<TextDeltaEvent>().single.delta,
        'It is 24C in Tokyo.',
      );
      expect(streamedEvents.whereType<RunStartEvent>(), hasLength(1));
      expect(streamedEvents.whereType<RunFinishEvent>(), hasLength(1));
      expect(toolStarts, hasLength(1));
      expect(toolFinishes, hasLength(1));
      expect(stepFinishes, hasLength(2));
      expect(runResult?.text, 'It is 24C in Tokyo.');
    });
  });

  group('ChatSessionSnapshotJsonCodec', () {
    test('round-trips prompt and UI messages with typed errors', () {
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
                reason: 'User denied browser automation.',
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
                  reason: 'User denied browser automation.',
                ),
              ),
              DataUiPart<Object?>(
                id: 'approval-ui',
                key: 'client',
                data: {
                  'screen': 'browser-approval',
                },
              ),
            ],
            metadata: {
              ChatUiMetadataKeys.finishReason: FinishReason.toolCalls,
            },
          ),
        ],
        status: ChatStatus.error,
        error: ModelError.fromUnknown(StateError('snapshot failed')),
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
      expect(toolPart.approval?.reason, 'User denied browser automation.');

      final dataPart =
          decoded.messages[1].parts.whereType<DataUiPart<Object?>>().single;
      expect(dataPart.id, 'approval-ui');
      expect(dataPart.key, 'client');
      expect((dataPart.data as Map<String, Object?>)['screen'],
          'browser-approval');

      final decodedError = decoded.error!;
      expect(decodedError.kind, ModelErrorKind.stream);
      expect(decodedError.originalType, 'StateError');
      expect(decodedError.message, contains('snapshot failed'));
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

    test('normalizes user-facing chat input before transport replay', () async {
      final fileData = FileTextData('notes');
      ChatTransportRequest? capturedRequest;
      final session = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) {
            capturedRequest = request;
            return Stream<TextStreamEvent>.fromIterable([
              const FinishEvent(finishReason: FinishReason.stop),
            ]);
          },
        ),
      );

      await session.sendMessage(
        ChatInput.parts(
          [
            const TextModelPart('Read this'),
            FileModelPart(
              mediaType: 'text/plain',
              filename: 'notes.txt',
              data: fileData,
            ),
          ],
        ),
      );

      final prompt = capturedRequest!.prompt;
      expect(prompt, hasLength(1));
      final userPrompt = prompt.single as UserPromptMessage;
      expect(userPrompt.parts, hasLength(2));
      expect((userPrompt.parts[0] as TextPromptPart).text, 'Read this');
      final filePart = userPrompt.parts[1] as FilePromptPart;
      expect(filePart.mediaType, 'text/plain');
      expect(filePart.filename, 'notes.txt');
      expect(filePart.data, same(fileData));

      final userMessage = session.state.messages.first;
      expect(userMessage.role, ChatUiRole.user);
      expect(
        userMessage.parts.whereType<TextUiPart>().single.text,
        'Read this',
      );
      expect(
        userMessage.parts.whereType<FileUiPart>().single.file.data,
        same(fileData),
      );

      await session.dispose();
    });

    test('normalizes app-facing initial messages before transport replay',
        () async {
      ChatTransportRequest? capturedRequest;
      final session = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) {
            capturedRequest = request;
            return Stream<TextStreamEvent>.fromIterable([
              const FinishEvent(finishReason: FinishReason.stop),
            ]);
          },
        ),
        initialMessages: [
          SystemModelMessage.text('You are concise.'),
          UserModelMessage.text('Seed question'),
          AssistantModelMessage.text('Seed answer'),
        ],
      );

      expect(session.state.messages, hasLength(3));
      expect(session.state.messages[0].role, ChatUiRole.system);
      expect(session.state.messages[1].role, ChatUiRole.user);
      expect(session.state.messages[2].role, ChatUiRole.assistant);

      await session.sendMessage(ChatInput.text('Follow up'));

      final prompt = capturedRequest!.prompt;
      expect(prompt, hasLength(4));
      expect(prompt[0], isA<SystemPromptMessage>());
      expect(prompt[1], isA<UserPromptMessage>());
      expect(prompt[2], isA<AssistantPromptMessage>());
      expect(prompt[3], isA<UserPromptMessage>());
      expect((prompt[3].parts.single as TextPromptPart).text, 'Follow up');

      await session.dispose();
    });

    test('keeps provider prompt history behind explicit advanced constructor',
        () async {
      ChatTransportRequest? capturedRequest;
      final session = DefaultChatSession.withPromptHistory(
        transport: _FakeChatTransport(
          onSendMessages: (request) {
            capturedRequest = request;
            return Stream<TextStreamEvent>.fromIterable([
              const FinishEvent(finishReason: FinishReason.stop),
            ]);
          },
        ),
        initialPrompt: [
          UserPromptMessage.text('Seed prompt'),
          AssistantPromptMessage.text('Seed answer'),
        ],
      );

      expect(session.state.messages, hasLength(2));

      await session.sendMessage(ChatInput.text('Follow up'));

      final prompt = capturedRequest!.prompt;
      expect(prompt, hasLength(3));
      expect((prompt[0].parts.single as TextPromptPart).text, 'Seed prompt');
      expect((prompt[1].parts.single as TextPromptPart).text, 'Seed answer');
      expect((prompt[2].parts.single as TextPromptPart).text, 'Follow up');

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
        assistantMessage.metadata[ChatUiMetadataKeys.isAborted],
        isTrue,
      );
      expect(
        assistantMessage.parts.whereType<TextUiPart>().single.text,
        'Partial',
      );

      await session.dispose();
    });

    test('regenerate replaces the latest assistant message', () async {
      var invocation = 0;
      final capturedRequests = <ChatTransportRequest>[];
      final session = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) {
            capturedRequests.add(request);
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
      expect(capturedRequests, hasLength(2));
      expect(capturedRequests[0].trigger, ChatTransportTrigger.sendMessage);
      expect(capturedRequests[1].trigger, ChatTransportTrigger.regenerate);

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
      expect(capturedRequests[0].trigger, ChatTransportTrigger.sendMessage);
      expect(capturedRequests[1].trigger, ChatTransportTrigger.toolOutput);
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
      expect(capturedRequests[2].trigger, ChatTransportTrigger.sendMessage);
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

    test(
        'preserves reasoning, reasoning-file, custom parts, and part metadata in assistant replay',
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
                  const ReasoningStartEvent(
                    id: 'reasoning-1',
                    providerMetadata: ProviderMetadata({
                      'google': {
                        'thoughtSignature': 'sig_reasoning',
                      },
                    }),
                  ),
                  const ReasoningDeltaEvent(
                    id: 'reasoning-1',
                    delta: 'Plan first.',
                    providerMetadata: ProviderMetadata({
                      'google': {
                        'thoughtSignature': 'sig_reasoning',
                      },
                    }),
                  ),
                  const ReasoningEndEvent(id: 'reasoning-1'),
                  const ReasoningFileEvent(
                    GeneratedFile(
                      mediaType: 'image/png',
                      filename: 'thought.png',
                      data: FileBytesData.constBytes([1, 2, 3]),
                    ),
                    providerMetadata: ProviderMetadata({
                      'google': {
                        'thoughtSignature': 'sig_reasoning_file',
                      },
                    }),
                  ),
                  const TextStartEvent(
                    id: 'text-1',
                    providerMetadata: ProviderMetadata({
                      'openai': {
                        'itemId': 'msg_1',
                      },
                    }),
                  ),
                  const TextDeltaEvent(
                    id: 'text-1',
                    delta: 'Here is the answer.',
                    providerMetadata: ProviderMetadata({
                      'openai': {
                        'itemId': 'msg_1',
                      },
                    }),
                  ),
                  const TextEndEvent(id: 'text-1'),
                  const CustomEvent(
                    kind: 'openai.compaction',
                    data: {
                      'type': 'compaction',
                      'id': 'cmp_1',
                      'encrypted_content': 'enc_1',
                    },
                    providerMetadata: ProviderMetadata({
                      'openai': {
                        'itemId': 'cmp_1',
                      },
                    }),
                  ),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
              default:
                return Stream<TextStreamEvent>.fromIterable([
                  StartEvent(),
                  const TextStartEvent(id: 'text-2'),
                  const TextDeltaEvent(id: 'text-2', delta: 'Follow-up reply.'),
                  const TextEndEvent(id: 'text-2'),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
            }
          },
        ),
      );

      await session.sendMessage(ChatInput.text('Hi'));

      final assistantMessage = session.state.messages.last;
      expect(
        assistantMessage.parts.whereType<ReasoningUiPart>().single.text,
        'Plan first.',
      );
      expect(
        assistantMessage.parts
            .whereType<ReasoningFileUiPart>()
            .single
            .file
            .filename,
        'thought.png',
      );
      expect(
        assistantMessage.parts.whereType<CustomUiPart>().single.kind,
        'openai.compaction',
      );

      await session.sendMessage(ChatInput.text('What next?'));

      expect(capturedRequests, hasLength(2));
      final replayPrompt = capturedRequests[1].prompt;
      expect(replayPrompt, hasLength(3));
      final assistantPrompt = replayPrompt[1] as AssistantPromptMessage;
      expect(assistantPrompt.parts, hasLength(4));
      expect(assistantPrompt.parts[0], isA<ReasoningPromptPart>());
      expect(assistantPrompt.parts[1], isA<ReasoningFilePromptPart>());
      expect(assistantPrompt.parts[2], isA<TextPromptPart>());
      expect(assistantPrompt.parts[3], isA<CustomPromptPart>());

      final reasoningPart = assistantPrompt.parts[0] as ReasoningPromptPart;
      expect(reasoningPart.text, 'Plan first.');
      expect(
        _promptReplayMetadata(reasoningPart)!['google'],
        containsPair('thoughtSignature', 'sig_reasoning'),
      );

      final reasoningFilePart =
          assistantPrompt.parts[1] as ReasoningFilePromptPart;
      expect(reasoningFilePart.filename, 'thought.png');
      expect(reasoningFilePart.bytes, [1, 2, 3]);
      expect(
        _promptReplayMetadata(reasoningFilePart)!['google'],
        containsPair('thoughtSignature', 'sig_reasoning_file'),
      );

      final textPart = assistantPrompt.parts[2] as TextPromptPart;
      expect(textPart.text, 'Here is the answer.');
      expect(
        _promptReplayMetadata(textPart)!['openai'],
        containsPair('itemId', 'msg_1'),
      );

      final customPart = assistantPrompt.parts[3] as CustomPromptPart;
      expect(customPart.kind, 'openai.compaction');
      expect(customPart.data, {
        'type': 'compaction',
        'id': 'cmp_1',
        'encrypted_content': 'enc_1',
      });
      expect(
        _promptReplayMetadata(customPart)!['openai'],
        containsPair('itemId', 'cmp_1'),
      );

      await session.dispose();
    });

    test('preserves file parts and metadata in assistant replay', () async {
      final capturedRequests = <ChatTransportRequest>[];

      final session = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) {
            capturedRequests.add(request);

            switch (capturedRequests.length) {
              case 1:
                return Stream<TextStreamEvent>.fromIterable([
                  StartEvent(),
                  FileEvent(
                    GeneratedFile(
                      mediaType: 'application/pdf',
                      filename: 'report.pdf',
                      data: FileBytesData([4, 5, 6]),
                    ),
                    providerMetadata: ProviderMetadata({
                      'google': {
                        'fileId': 'file_pdf_1',
                      },
                    }),
                  ),
                  const TextStartEvent(id: 'text-1'),
                  const TextDeltaEvent(
                    id: 'text-1',
                    delta: 'Attached the report.',
                  ),
                  const TextEndEvent(id: 'text-1'),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
              default:
                return Stream<TextStreamEvent>.fromIterable([
                  StartEvent(),
                  const TextStartEvent(id: 'text-2'),
                  const TextDeltaEvent(id: 'text-2', delta: 'Follow-up reply.'),
                  const TextEndEvent(id: 'text-2'),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
            }
          },
        ),
      );

      await session.sendMessage(ChatInput.text('Send the report.'));

      final assistantMessage = session.state.messages.last;
      final filePart = assistantMessage.parts.whereType<FileUiPart>().single;
      expect(filePart.file.mediaType, 'application/pdf');
      expect(filePart.file.filename, 'report.pdf');
      expect(filePart.file.uri, isNull);
      expect(filePart.file.bytes, [4, 5, 6]);
      expect(
        filePart.providerMetadata!['google'],
        containsPair('fileId', 'file_pdf_1'),
      );

      await session.sendMessage(ChatInput.text('What should I read first?'));

      expect(capturedRequests, hasLength(2));
      expect(capturedRequests[1].prompt, hasLength(3));
      final assistantPrompt =
          capturedRequests[1].prompt[1] as AssistantPromptMessage;
      expect(assistantPrompt.parts, hasLength(2));
      expect(assistantPrompt.parts[0], isA<FilePromptPart>());
      expect(assistantPrompt.parts[1], isA<TextPromptPart>());

      final replayedFilePart = assistantPrompt.parts[0] as FilePromptPart;
      expect(replayedFilePart.mediaType, 'application/pdf');
      expect(replayedFilePart.filename, 'report.pdf');
      expect(replayedFilePart.uri, isNull);
      expect(replayedFilePart.bytes, [4, 5, 6]);
      expect(
        _promptReplayMetadata(replayedFilePart)!['google'],
        containsPair('fileId', 'file_pdf_1'),
      );

      final replayedTextPart = assistantPrompt.parts[1] as TextPromptPart;
      expect(replayedTextPart.text, 'Attached the report.');

      await session.dispose();
    });

    test(
        'replays provider-executed web-search tool results through custom prompt parts',
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
                      toolCallId: 'srvtoolu_1',
                      toolName: 'web_search',
                      input: {
                        'query': 'dart sdk',
                      },
                      providerExecuted: true,
                      isDynamic: true,
                    ),
                  ),
                  ToolResultEvent(
                    toolResult: ToolResultContent(
                      toolCallId: 'srvtoolu_1',
                      toolName: 'web_search',
                      output: [
                        {
                          'url': 'https://dart.dev',
                          'title': 'Dart',
                        },
                      ],
                      isDynamic: true,
                    ),
                    providerMetadata: ProviderMetadata({
                      'anthropic': {
                        'blockType': 'web_search_tool_result',
                      },
                    }),
                  ),
                  const CustomEvent(
                    kind: 'anthropic.result.web_search',
                    data: {
                      'replayRole': 'tool',
                      'toolCallId': 'srvtoolu_1',
                      'toolName': 'web_search',
                      'block': {
                        'type': 'web_search_tool_result',
                        'tool_use_id': 'srvtoolu_1',
                        'content': [
                          {
                            'url': 'https://dart.dev',
                            'title': 'Dart',
                            'type': 'web_search_result',
                          },
                        ],
                      },
                    },
                    providerMetadata: ProviderMetadata({
                      'anthropic': {
                        'blockType': 'web_search_tool_result',
                      },
                    }),
                  ),
                  SourceEvent(
                    SourceReference(
                      kind: SourceReferenceKind.url,
                      sourceId: 'https://dart.dev',
                      uri: Uri.parse('https://dart.dev'),
                      title: 'Dart',
                    ),
                  ),
                  const TextStartEvent(id: 'text-1'),
                  const TextDeltaEvent(
                    id: 'text-1',
                    delta: 'Dart has a modern SDK.',
                  ),
                  const TextEndEvent(id: 'text-1'),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
              default:
                return Stream<TextStreamEvent>.fromIterable([
                  StartEvent(),
                  const TextStartEvent(id: 'text-2'),
                  const TextDeltaEvent(
                    id: 'text-2',
                    delta: 'Follow-up reply.',
                  ),
                  const TextEndEvent(id: 'text-2'),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
            }
          },
        ),
      );

      await session.sendMessage(ChatInput.text('Search for Dart.'));

      final assistantMessage = session.state.messages.last;
      expect(
        assistantMessage.parts.whereType<CustomUiPart>().single.kind,
        'anthropic.result.web_search',
      );

      await session.sendMessage(ChatInput.text('What next?'));

      expect(capturedRequests, hasLength(2));
      final replayPrompt = capturedRequests[1].prompt;
      expect(replayPrompt, hasLength(5));

      final assistantToolReplay = replayPrompt[1] as AssistantPromptMessage;
      expect(assistantToolReplay.parts.single, isA<ToolCallPromptPart>());
      final toolCallPart =
          assistantToolReplay.parts.single as ToolCallPromptPart;
      expect(toolCallPart.toolCallId, 'srvtoolu_1');
      expect(toolCallPart.providerExecuted, isTrue);
      expect(toolCallPart.isDynamic, isTrue);

      final toolResultReplay = replayPrompt[2] as ToolPromptMessage;
      expect(toolResultReplay.toolName, 'web_search');
      expect(toolResultReplay.parts.single, isA<CustomPromptPart>());
      final customPart = toolResultReplay.parts.single as CustomPromptPart;
      expect(customPart.kind, 'anthropic.result.web_search');
      expect(customPart.data, {
        'replayRole': 'tool',
        'toolCallId': 'srvtoolu_1',
        'toolName': 'web_search',
        'block': {
          'type': 'web_search_tool_result',
          'tool_use_id': 'srvtoolu_1',
          'content': [
            {
              'url': 'https://dart.dev',
              'title': 'Dart',
              'type': 'web_search_result',
            },
          ],
        },
      });

      final assistantTextReplay = replayPrompt[3] as AssistantPromptMessage;
      expect(assistantTextReplay.parts.single, isA<TextPromptPart>());
      expect(
        (assistantTextReplay.parts.single as TextPromptPart).text,
        'Dart has a modern SDK.',
      );

      await session.dispose();
    });

    test(
        'replays Google server-side tool circulation through assistant custom prompt parts',
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
                  const CustomEvent(
                    kind: 'google.result.tool_call',
                    data: {
                      'schema': 'google.tool_call.v1',
                      'replayRole': 'assistant',
                      'toolCallId': 'srvtool_1',
                      'toolName': 'google_search',
                      'toolCall': {
                        'id': 'srvtool_1',
                        'toolType': 'google_search',
                        'query': 'Dart SDK',
                      },
                    },
                    providerMetadata: ProviderMetadata({
                      'google': {
                        'thoughtSignature': 'sig_srvtool_1',
                        'serverToolPart': 'toolCall',
                        'toolCallId': 'srvtool_1',
                        'toolType': 'google_search',
                      },
                    }),
                  ),
                  const CustomEvent(
                    kind: 'google.result.tool_response',
                    data: {
                      'schema': 'google.tool_response.v1',
                      'replayRole': 'assistant',
                      'toolCallId': 'srvtool_1',
                      'toolName': 'google_search',
                      'toolResponse': {
                        'id': 'srvtool_1',
                        'toolType': 'google_search',
                        'result': {
                          'items': [
                            {
                              'uri': 'https://dart.dev',
                              'title': 'Dart',
                            },
                          ],
                        },
                      },
                    },
                    providerMetadata: ProviderMetadata({
                      'google': {
                        'serverToolPart': 'toolResponse',
                        'toolCallId': 'srvtool_1',
                        'toolType': 'google_search',
                      },
                    }),
                  ),
                  const TextStartEvent(id: 'text-1'),
                  const TextDeltaEvent(
                    id: 'text-1',
                    delta: 'Dart search finished.',
                  ),
                  const TextEndEvent(id: 'text-1'),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
              default:
                return Stream<TextStreamEvent>.fromIterable([
                  StartEvent(),
                  const TextStartEvent(id: 'text-2'),
                  const TextDeltaEvent(
                    id: 'text-2',
                    delta: 'Follow-up reply.',
                  ),
                  const TextEndEvent(id: 'text-2'),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
            }
          },
        ),
      );

      await session.sendMessage(ChatInput.text('Search for Dart.'));

      final assistantMessage = session.state.messages.last;
      final customParts =
          assistantMessage.parts.whereType<CustomUiPart>().toList(
                growable: false,
              );
      expect(
        customParts.map((part) => part.kind),
        orderedEquals([
          'google.result.tool_call',
          'google.result.tool_response',
        ]),
      );

      await session.sendMessage(ChatInput.text('What next?'));

      expect(capturedRequests, hasLength(2));
      final replayPrompt = capturedRequests[1].prompt;
      expect(replayPrompt, hasLength(3));
      final assistantPrompt = replayPrompt[1] as AssistantPromptMessage;
      expect(assistantPrompt.parts, hasLength(3));

      final replayedToolCall = assistantPrompt.parts[0] as CustomPromptPart;
      expect(replayedToolCall.kind, 'google.result.tool_call');
      expect(replayedToolCall.data, {
        'schema': 'google.tool_call.v1',
        'replayRole': 'assistant',
        'toolCallId': 'srvtool_1',
        'toolName': 'google_search',
        'toolCall': {
          'id': 'srvtool_1',
          'toolType': 'google_search',
          'query': 'Dart SDK',
        },
      });
      expect(
        _promptReplayMetadata(replayedToolCall)!['google'],
        containsPair('thoughtSignature', 'sig_srvtool_1'),
      );

      final replayedToolResponse = assistantPrompt.parts[1] as CustomPromptPart;
      expect(replayedToolResponse.kind, 'google.result.tool_response');
      expect(replayedToolResponse.data, {
        'schema': 'google.tool_response.v1',
        'replayRole': 'assistant',
        'toolCallId': 'srvtool_1',
        'toolName': 'google_search',
        'toolResponse': {
          'id': 'srvtool_1',
          'toolType': 'google_search',
          'result': {
            'items': [
              {
                'uri': 'https://dart.dev',
                'title': 'Dart',
              },
            ],
          },
        },
      });

      final replayedText = assistantPrompt.parts[2] as TextPromptPart;
      expect(replayedText.text, 'Dart search finished.');

      await session.dispose();
    });

    test(
        'replays provider-executed code-execution tool results through custom prompt parts',
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
                      toolCallId: 'srvtoolu_3',
                      toolName: 'bash_code_execution',
                      input: {
                        'command': 'echo hi',
                      },
                      providerExecuted: true,
                      isDynamic: true,
                    ),
                  ),
                  ToolResultEvent(
                    toolResult: ToolResultContent(
                      toolCallId: 'srvtoolu_3',
                      toolName: 'bash_code_execution',
                      output: {
                        'type': 'bash_code_execution_result',
                        'stdout': 'hi\n',
                        'stderr': '',
                        'return_code': 0,
                        'content': [
                          {
                            'type': 'bash_code_execution_output',
                            'file_id': 'file_123',
                          },
                        ],
                      },
                      isDynamic: true,
                    ),
                    providerMetadata: ProviderMetadata({
                      'anthropic': {
                        'blockType': 'bash_code_execution_tool_result',
                      },
                    }),
                  ),
                  const CustomEvent(
                    kind: 'anthropic.result.code_execution',
                    data: {
                      'schema': 'anthropic.execution.result.v1',
                      'replayRole': 'tool',
                      'toolCallId': 'srvtoolu_3',
                      'toolName': 'code_execution',
                      'blockType': 'bash_code_execution_tool_result',
                      'block': {
                        'type': 'bash_code_execution_tool_result',
                        'tool_use_id': 'srvtoolu_3',
                        'content': {
                          'type': 'bash_code_execution_result',
                          'stdout': 'hi\n',
                          'stderr': '',
                          'return_code': 0,
                          'content': [
                            {
                              'type': 'bash_code_execution_output',
                              'file_id': 'file_123',
                            },
                          ],
                        },
                      },
                    },
                    providerMetadata: ProviderMetadata({
                      'anthropic': {
                        'blockType': 'bash_code_execution_tool_result',
                      },
                    }),
                  ),
                  const TextStartEvent(id: 'text-1'),
                  const TextDeltaEvent(
                    id: 'text-1',
                    delta: 'Command finished.',
                  ),
                  const TextEndEvent(id: 'text-1'),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
              default:
                return Stream<TextStreamEvent>.fromIterable([
                  StartEvent(),
                  const TextStartEvent(id: 'text-2'),
                  const TextDeltaEvent(
                    id: 'text-2',
                    delta: 'Follow-up reply.',
                  ),
                  const TextEndEvent(id: 'text-2'),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
            }
          },
        ),
      );

      await session.sendMessage(ChatInput.text('Run a command.'));

      final assistantMessage = session.state.messages.last;
      expect(
        assistantMessage.parts.whereType<CustomUiPart>().single.kind,
        'anthropic.result.code_execution',
      );

      await session.sendMessage(ChatInput.text('What next?'));

      expect(capturedRequests, hasLength(2));
      final replayPrompt = capturedRequests[1].prompt;
      expect(replayPrompt, hasLength(5));

      final assistantToolReplay = replayPrompt[1] as AssistantPromptMessage;
      expect(assistantToolReplay.parts.single, isA<ToolCallPromptPart>());
      final toolCallPart =
          assistantToolReplay.parts.single as ToolCallPromptPart;
      expect(toolCallPart.toolCallId, 'srvtoolu_3');
      expect(toolCallPart.toolName, 'bash_code_execution');
      expect(toolCallPart.providerExecuted, isTrue);
      expect(toolCallPart.isDynamic, isTrue);

      final toolResultReplay = replayPrompt[2] as ToolPromptMessage;
      expect(toolResultReplay.toolName, 'code_execution');
      expect(toolResultReplay.parts.single, isA<CustomPromptPart>());
      final customPart = toolResultReplay.parts.single as CustomPromptPart;
      expect(customPart.kind, 'anthropic.result.code_execution');
      expect(customPart.data, {
        'schema': 'anthropic.execution.result.v1',
        'replayRole': 'tool',
        'toolCallId': 'srvtoolu_3',
        'toolName': 'code_execution',
        'blockType': 'bash_code_execution_tool_result',
        'block': {
          'type': 'bash_code_execution_tool_result',
          'tool_use_id': 'srvtoolu_3',
          'content': {
            'type': 'bash_code_execution_result',
            'stdout': 'hi\n',
            'stderr': '',
            'return_code': 0,
            'content': [
              {
                'type': 'bash_code_execution_output',
                'file_id': 'file_123',
              },
            ],
          },
        },
      });

      final assistantTextReplay = replayPrompt[3] as AssistantPromptMessage;
      expect(assistantTextReplay.parts.single, isA<TextPromptPart>());
      expect(
        (assistantTextReplay.parts.single as TextPromptPart).text,
        'Command finished.',
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
          reason: 'The target page is not trusted.',
        ),
      );

      expect(session.state.status, ChatStatus.ready);
      final deniedTool =
          session.state.messages.last.parts.whereType<ToolUiPart>().single;
      expect(deniedTool.state, ToolUiPartState.outputDenied);
      expect(deniedTool.approval?.approved, isFalse);
      expect(deniedTool.approval?.reason, 'The target page is not trusted.');
      expect(deniedTool.toolOutput, isA<ExecutionDeniedToolOutput>());
      expect(
        (deniedTool.toolOutput as ExecutionDeniedToolOutput).reason,
        'The target page is not trusted.',
      );

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
      expect(
        (approvalResponseMessage.parts.single as ToolApprovalResponsePromptPart)
            .reason,
        'The target page is not trusted.',
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
          reason: 'The action is expected.',
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
      expect(
        (approvalResponseMessage.parts.single as ToolApprovalResponsePromptPart)
            .reason,
        'The action is expected.',
      );

      expect(session.state.status, ChatStatus.ready);
      final assistantMessage = session.state.messages.last;
      final approvedTool =
          assistantMessage.parts.whereType<ToolUiPart>().single;
      expect(approvedTool.state, ToolUiPartState.approvalResponded);
      expect(approvedTool.approval?.approved, isTrue);
      expect(approvedTool.approval?.reason, 'The action is expected.');
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

    test('automatically executes client-side tools through onToolCall',
        () async {
      final capturedRequests = <ChatTransportRequest>[];
      final toolCalls = <ToolExecutionRequest>[];

      final session = DefaultChatSession(
        onToolCall: (request) async {
          toolCalls.add(request);
          return const ToolExecutionResult.output({
            'temperature': 24,
            'unit': 'celsius',
          });
        },
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
                        'location': 'Tokyo',
                      },
                    ),
                  ),
                  const FinishEvent(finishReason: FinishReason.toolCalls),
                ]);
              default:
                return Stream<TextStreamEvent>.fromIterable([
                  StartEvent(),
                  const TextStartEvent(id: 'text-2'),
                  const TextDeltaEvent(
                    id: 'text-2',
                    delta: 'Automatic tool execution completed.',
                  ),
                  const TextEndEvent(id: 'text-2'),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
            }
          },
        ),
      );

      await session.sendMessage(ChatInput.text('Weather in Tokyo?'));
      await _flushAsyncWork();

      expect(toolCalls, hasLength(1));
      expect(toolCalls.single.toolCallId, 'tool-1');
      expect(toolCalls.single.toolName, 'weather');
      expect(toolCalls.single.input, {
        'location': 'Tokyo',
      });
      expect(capturedRequests, hasLength(2));
      expect(session.state.status, ChatStatus.ready);
      expect(
        session.state.messages.last.parts.whereType<TextUiPart>().single.text,
        'Automatic tool execution completed.',
      );

      await session.dispose();
    });

    test(
        'automatically executes client-side tools through toolExecutionRegistry',
        () async {
      final capturedRequests = <ChatTransportRequest>[];

      final session = DefaultChatSession(
        toolExecutionRegistry: ToolExecutionRegistry(
          handlers: {
            'weather': (request) {
              expect(request.toolName, 'weather');
              return const ToolExecutionResult.output({
                'temperature': 24,
              });
            },
          },
        ),
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
                        'location': 'Tokyo',
                      },
                    ),
                  ),
                  const FinishEvent(finishReason: FinishReason.toolCalls),
                ]);
              default:
                return Stream<TextStreamEvent>.fromIterable([
                  StartEvent(),
                  const TextStartEvent(id: 'text-2'),
                  const TextDeltaEvent(
                    id: 'text-2',
                    delta: 'Registry-based tool execution completed.',
                  ),
                  const TextEndEvent(id: 'text-2'),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
            }
          },
        ),
      );

      await session.sendMessage(ChatInput.text('Weather in Tokyo?'));
      await _flushAsyncWork();

      expect(capturedRequests, hasLength(2));
      expect(session.state.status, ChatStatus.ready);
      expect(
        session.state.messages.last.parts.whereType<TextUiPart>().single.text,
        'Registry-based tool execution completed.',
      );

      await session.dispose();
    });

    test(
        'toolExecutionRegistry.withJsonHandler reports decode failures as tool error output',
        () async {
      final capturedRequests = <ChatTransportRequest>[];

      final session = DefaultChatSession(
        toolExecutionRegistry: ToolExecutionRegistry().withJsonHandler<String>(
          'weather',
          decode: (json) => json['location'] as String,
          handle: (request, location) => ToolExecutionResult.output({
            'location': location,
          }),
        ),
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
                      input: ['Tokyo'],
                    ),
                  ),
                  const FinishEvent(finishReason: FinishReason.toolCalls),
                ]);
              default:
                return Stream<TextStreamEvent>.fromIterable([
                  StartEvent(),
                  const TextStartEvent(id: 'text-2'),
                  const TextDeltaEvent(
                    id: 'text-2',
                    delta: 'Decode failures are returned as tool errors.',
                  ),
                  const TextEndEvent(id: 'text-2'),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
            }
          },
        ),
      );

      await session.sendMessage(ChatInput.text('Weather in Tokyo?'));
      await _flushAsyncWork();

      expect(capturedRequests, hasLength(2));
      final continuationPrompt = capturedRequests[1].prompt;
      expect(continuationPrompt, hasLength(3));
      final toolResultMessage = continuationPrompt[2] as ToolPromptMessage;
      final toolResult = toolResultMessage.parts.single as ToolResultPromptPart;
      expect(toolResult.isError, isTrue);
      expect(toolResult.output, isA<String>());
      expect(
        toolResult.output as String,
        contains('expected a JSON object input'),
      );
      expect(session.state.status, ChatStatus.ready);
      expect(
        session.state.messages.last.parts.whereType<TextUiPart>().single.text,
        'Decode failures are returned as tool errors.',
      );

      await session.dispose();
    });

    test('waits for all automatic tool outputs before continuing', () async {
      final capturedRequests = <ChatTransportRequest>[];
      final weatherCompletion = Completer<ToolExecutionResult?>();
      final calendarCompletion = Completer<ToolExecutionResult?>();

      final session = DefaultChatSession(
        onToolCall: (request) {
          return switch (request.toolName) {
            'weather' => weatherCompletion.future,
            'calendar' => calendarCompletion.future,
            _ => throw StateError('Unexpected tool ${request.toolName}.'),
          };
        },
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
                        'location': 'Tokyo',
                      },
                    ),
                  ),
                  const ToolCallEvent(
                    toolCall: ToolCallContent(
                      toolCallId: 'tool-2',
                      toolName: 'calendar',
                      input: {
                        'day': 'Monday',
                      },
                    ),
                  ),
                  const FinishEvent(finishReason: FinishReason.toolCalls),
                ]);
              default:
                return Stream<TextStreamEvent>.fromIterable([
                  StartEvent(),
                  const TextStartEvent(id: 'text-2'),
                  const TextDeltaEvent(
                    id: 'text-2',
                    delta: 'All automatic tools completed.',
                  ),
                  const TextEndEvent(id: 'text-2'),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
            }
          },
        ),
      );

      await session.sendMessage(ChatInput.text('Plan my Monday in Tokyo.'));
      expect(session.state.status, ChatStatus.awaitingTool);

      weatherCompletion.complete(
        const ToolExecutionResult.output({
          'temperature': 24,
        }),
      );
      await _flushAsyncWork();

      expect(capturedRequests, hasLength(1));
      expect(session.state.status, ChatStatus.awaitingTool);

      calendarCompletion.complete(
        const ToolExecutionResult.output({
          'events': ['Standup'],
        }),
      );
      await _flushAsyncWork();

      expect(capturedRequests, hasLength(2));
      expect(session.state.status, ChatStatus.ready);
      expect(
        session.state.messages.last.parts.whereType<TextUiPart>().single.text,
        'All automatic tools completed.',
      );

      await session.dispose();
    });

    test(
        'approved client-side tools trigger automatic execution after approval',
        () async {
      final capturedRequests = <ChatTransportRequest>[];
      final toolCalls = <ToolExecutionRequest>[];

      final session = DefaultChatSession(
        onToolCall: (request) async {
          toolCalls.add(request);
          return const ToolExecutionResult.output({
            'clicked': true,
          });
        },
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
                    delta: 'Approved automatic tool execution completed.',
                  ),
                  const TextEndEvent(id: 'text-2'),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
            }
          },
        ),
      );

      await session.sendMessage(ChatInput.text('Click the submit button.'));
      expect(toolCalls, isEmpty);

      await session.respondToolApproval(
        const ToolApprovalResponse(
          approvalId: 'approval-1',
          approved: true,
        ),
      );
      await _flushAsyncWork();

      expect(toolCalls, hasLength(1));
      expect(toolCalls.single.toolName, 'computer');
      expect(capturedRequests, hasLength(2));
      expect(session.state.status, ChatStatus.ready);

      await session.dispose();
    });

    test('automatic tool execution failures become tool error output',
        () async {
      final capturedRequests = <ChatTransportRequest>[];

      final session = DefaultChatSession(
        onToolCall: (_) => throw StateError('Tool process crashed.'),
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
                        'location': 'Tokyo',
                      },
                    ),
                  ),
                  const FinishEvent(finishReason: FinishReason.toolCalls),
                ]);
              default:
                return Stream<TextStreamEvent>.fromIterable([
                  StartEvent(),
                  const TextStartEvent(id: 'text-2'),
                  const TextDeltaEvent(
                    id: 'text-2',
                    delta: 'The tool failure was reported back to the model.',
                  ),
                  const TextEndEvent(id: 'text-2'),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
            }
          },
        ),
      );

      await session.sendMessage(ChatInput.text('Weather in Tokyo?'));
      await _flushAsyncWork();

      expect(capturedRequests, hasLength(2));
      final continuationPrompt = capturedRequests[1].prompt;
      expect(continuationPrompt, hasLength(3));
      final toolResultMessage = continuationPrompt[2] as ToolPromptMessage;
      final toolResult = toolResultMessage.parts.single as ToolResultPromptPart;
      expect(toolResult.isError, isTrue);
      expect(
        toolResult.output,
        contains('Automatic tool execution failed for "weather"'),
      );
      expect(session.state.status, ChatStatus.ready);

      await session.dispose();
    });

    test('rejects configuring both onToolCall and toolExecutionRegistry', () {
      expect(
        () => DefaultChatSession(
          transport: _FakeChatTransport(
            onSendMessages: (request) => const Stream<TextStreamEvent>.empty(),
          ),
          onToolCall: (_) => null,
          toolExecutionRegistry: ToolExecutionRegistry(),
        ),
        throwsArgumentError,
      );
    });

    test(
        'waits until all client-side tool outputs are available before continuing',
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
                        'location': 'Tokyo',
                      },
                    ),
                  ),
                  const ToolCallEvent(
                    toolCall: ToolCallContent(
                      toolCallId: 'tool-2',
                      toolName: 'calendar',
                      input: {
                        'day': 'Monday',
                      },
                    ),
                  ),
                  const FinishEvent(finishReason: FinishReason.toolCalls),
                ]);
              default:
                return Stream<TextStreamEvent>.fromIterable([
                  StartEvent(),
                  const TextStartEvent(id: 'text-2'),
                  const TextDeltaEvent(
                    id: 'text-2',
                    delta: 'Both local tools finished.',
                  ),
                  const TextEndEvent(id: 'text-2'),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
            }
          },
        ),
      );

      await session
          .sendMessage(ChatInput.text('Check my Monday plan in Tokyo.'));

      expect(capturedRequests, hasLength(1));
      expect(session.state.status, ChatStatus.awaitingTool);

      await session.addToolOutput(
        const ToolOutputUpdate(
          toolCallId: 'tool-1',
          toolName: 'weather',
          output: {
            'temperature': 24,
          },
        ),
      );

      expect(capturedRequests, hasLength(1));
      expect(session.state.status, ChatStatus.awaitingTool);
      final partialTools =
          session.state.messages.last.parts.whereType<ToolUiPart>().toList();
      expect(
        partialTools.singleWhere((part) => part.toolCallId == 'tool-1').state,
        ToolUiPartState.outputAvailable,
      );
      expect(
        partialTools.singleWhere((part) => part.toolCallId == 'tool-2').state,
        ToolUiPartState.inputAvailable,
      );

      await session.addToolOutput(
        const ToolOutputUpdate(
          toolCallId: 'tool-2',
          toolName: 'calendar',
          output: {
            'events': ['Standup'],
          },
        ),
      );

      expect(capturedRequests, hasLength(2));
      final continuationPrompt = capturedRequests[1].prompt;
      expect(continuationPrompt, hasLength(4));
      expect(continuationPrompt[1], isA<AssistantPromptMessage>());
      final assistantPrompt = continuationPrompt[1] as AssistantPromptMessage;
      expect(
          assistantPrompt.parts.whereType<ToolCallPromptPart>(), hasLength(2));
      expect(
        ((continuationPrompt[2] as ToolPromptMessage).parts.single
                as ToolResultPromptPart)
            .toolCallId,
        'tool-1',
      );
      expect(
        ((continuationPrompt[3] as ToolPromptMessage).parts.single
                as ToolResultPromptPart)
            .toolCallId,
        'tool-2',
      );

      expect(session.state.status, ChatStatus.ready);
      expect(
        session.state.messages.last.parts.whereType<TextUiPart>().single.text,
        'Both local tools finished.',
      );

      await session.dispose();
    });

    test(
        'approved provider tools wait for remaining client outputs before continuing',
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
                      toolCallId: 'tool-provider',
                      toolName: 'computer',
                      input: {
                        'action': 'click',
                      },
                      providerExecuted: true,
                    ),
                  ),
                  const ToolApprovalRequestEvent(
                    approvalId: 'approval-1',
                    toolCallId: 'tool-provider',
                  ),
                  const ToolCallEvent(
                    toolCall: ToolCallContent(
                      toolCallId: 'tool-local',
                      toolName: 'weather',
                      input: {
                        'location': 'Tokyo',
                      },
                    ),
                  ),
                  const FinishEvent(finishReason: FinishReason.toolCalls),
                ]);
              default:
                return Stream<TextStreamEvent>.fromIterable([
                  StartEvent(),
                  const TextStartEvent(id: 'text-2'),
                  const TextDeltaEvent(
                    id: 'text-2',
                    delta: 'Approval and local output were both applied.',
                  ),
                  const TextEndEvent(id: 'text-2'),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
            }
          },
        ),
      );

      await session.sendMessage(ChatInput.text('Click and then check Tokyo.'));
      expect(session.state.status, ChatStatus.awaitingApproval);

      await session.respondToolApproval(
        const ToolApprovalResponse(
          approvalId: 'approval-1',
          approved: true,
          reason: 'The browser action is expected.',
        ),
      );

      expect(capturedRequests, hasLength(1));
      expect(session.state.status, ChatStatus.awaitingTool);
      final awaitingTools =
          session.state.messages.last.parts.whereType<ToolUiPart>().toList();
      expect(
        awaitingTools
            .singleWhere((part) => part.toolCallId == 'tool-provider')
            .state,
        ToolUiPartState.approvalResponded,
      );
      expect(
        awaitingTools
            .singleWhere((part) => part.toolCallId == 'tool-local')
            .state,
        ToolUiPartState.inputAvailable,
      );

      await session.addToolOutput(
        const ToolOutputUpdate(
          toolCallId: 'tool-local',
          toolName: 'weather',
          output: {
            'temperature': 24,
          },
        ),
      );

      expect(capturedRequests, hasLength(2));
      final continuationPrompt = capturedRequests[1].prompt;
      expect(continuationPrompt, hasLength(4));
      final assistantPrompt = continuationPrompt[1] as AssistantPromptMessage;
      expect(
          assistantPrompt.parts.whereType<ToolCallPromptPart>(), hasLength(2));
      expect(
        assistantPrompt.parts.whereType<ToolApprovalRequestPromptPart>(),
        hasLength(1),
      );
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
        'Approval and local output were both applied.',
      );

      await session.dispose();
    });

    test(
        'mixed provider approval responses continue once all approvals are collected',
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
                    ),
                  ),
                  const ToolApprovalRequestEvent(
                    approvalId: 'approval-1',
                    toolCallId: 'tool-1',
                  ),
                  const ToolCallEvent(
                    toolCall: ToolCallContent(
                      toolCallId: 'tool-2',
                      toolName: 'computer',
                      input: {
                        'action': 'type',
                      },
                      providerExecuted: true,
                    ),
                  ),
                  const ToolApprovalRequestEvent(
                    approvalId: 'approval-2',
                    toolCallId: 'tool-2',
                  ),
                  const FinishEvent(finishReason: FinishReason.toolCalls),
                ]);
              default:
                return Stream<TextStreamEvent>.fromIterable([
                  StartEvent(),
                  const TextStartEvent(id: 'text-2'),
                  const TextDeltaEvent(
                    id: 'text-2',
                    delta: 'Mixed approvals continued correctly.',
                  ),
                  const TextEndEvent(id: 'text-2'),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
            }
          },
        ),
      );

      await session
          .sendMessage(ChatInput.text('Complete both browser actions.'));
      expect(session.state.status, ChatStatus.awaitingApproval);

      await session.respondToolApproval(
        const ToolApprovalResponse(
          approvalId: 'approval-1',
          approved: true,
          reason: 'The first action is safe.',
        ),
      );

      expect(capturedRequests, hasLength(1));
      expect(session.state.status, ChatStatus.awaitingApproval);

      await session.respondToolApproval(
        const ToolApprovalResponse(
          approvalId: 'approval-2',
          approved: false,
          reason: 'The second action is not trusted.',
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
        isA<ToolApprovalResponsePromptPart>(),
      );

      expect(session.state.status, ChatStatus.ready);
      expect(
        session.state.messages.last.parts.whereType<TextUiPart>().single.text,
        'Mixed approvals continued correctly.',
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
        'restores snapshots with Google thought signatures and reasoning files for follow-up replay',
        () async {
      final exportingSession = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) => Stream<TextStreamEvent>.fromIterable([
            StartEvent(),
            const ReasoningStartEvent(
              id: 'reasoning-1',
              providerMetadata: ProviderMetadata({
                'google': {
                  'thoughtSignature': 'sig_reasoning',
                },
              }),
            ),
            const ReasoningDeltaEvent(
              id: 'reasoning-1',
              delta: 'Plan first.',
              providerMetadata: ProviderMetadata({
                'google': {
                  'thoughtSignature': 'sig_reasoning',
                },
              }),
            ),
            const ReasoningEndEvent(id: 'reasoning-1'),
            const ReasoningFileEvent(
              GeneratedFile(
                mediaType: 'image/png',
                filename: 'thought.png',
                data: FileBytesData.constBytes([1, 2, 3]),
              ),
              providerMetadata: ProviderMetadata({
                'google': {
                  'thoughtSignature': 'sig_reasoning_file',
                },
              }),
            ),
            const TextStartEvent(
              id: 'text-1',
              providerMetadata: ProviderMetadata({
                'google': {
                  'thoughtSignature': 'sig_text',
                },
              }),
            ),
            const TextDeltaEvent(
              id: 'text-1',
              delta: 'Visible answer.',
              providerMetadata: ProviderMetadata({
                'google': {
                  'thoughtSignature': 'sig_text',
                },
              }),
            ),
            const TextEndEvent(id: 'text-1'),
            const FinishEvent(finishReason: FinishReason.stop),
          ]),
        ),
      );

      await exportingSession.sendMessage(ChatInput.text('Hi'));

      const codec = ChatSessionSnapshotJsonCodec();
      final encodedSnapshot =
          codec.encodeSnapshot(exportingSession.exportSnapshot());
      final decodedSnapshot = codec.decodeSnapshot(encodedSnapshot);

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
                delta: 'Restored Google continuation works.',
              ),
              const TextEndEvent(id: 'text-2'),
              const FinishEvent(finishReason: FinishReason.stop),
            ]);
          },
        ),
        snapshot: decodedSnapshot,
      );

      await restoredSession.sendMessage(ChatInput.text('What next?'));

      expect(capturedRequests, hasLength(1));
      expect(capturedRequests.single.prompt, hasLength(3));
      final assistantPrompt =
          capturedRequests.single.prompt[1] as AssistantPromptMessage;
      expect(assistantPrompt.parts, hasLength(3));
      expect(assistantPrompt.parts[0], isA<ReasoningPromptPart>());
      expect(assistantPrompt.parts[1], isA<ReasoningFilePromptPart>());
      expect(assistantPrompt.parts[2], isA<TextPromptPart>());

      final reasoningPart = assistantPrompt.parts[0] as ReasoningPromptPart;
      expect(reasoningPart.text, 'Plan first.');
      expect(
        _promptReplayMetadata(reasoningPart)!['google'],
        containsPair('thoughtSignature', 'sig_reasoning'),
      );

      final reasoningFilePart =
          assistantPrompt.parts[1] as ReasoningFilePromptPart;
      expect(reasoningFilePart.filename, 'thought.png');
      expect(reasoningFilePart.bytes, [1, 2, 3]);
      expect(
        _promptReplayMetadata(reasoningFilePart)!['google'],
        containsPair('thoughtSignature', 'sig_reasoning_file'),
      );

      final textPart = assistantPrompt.parts[2] as TextPromptPart;
      expect(textPart.text, 'Visible answer.');
      expect(
        _promptReplayMetadata(textPart)!['google'],
        containsPair('thoughtSignature', 'sig_text'),
      );

      await exportingSession.dispose();
      await restoredSession.dispose();
    });

    test('restores snapshots with assistant files for follow-up replay',
        () async {
      final exportingSession = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) => Stream<TextStreamEvent>.fromIterable([
            StartEvent(),
            FileEvent(
              GeneratedFile(
                mediaType: 'application/pdf',
                filename: 'report.pdf',
                data: FileBytesData([4, 5, 6]),
              ),
              providerMetadata: ProviderMetadata({
                'google': {
                  'fileId': 'file_pdf_1',
                },
              }),
            ),
            const TextStartEvent(
              id: 'text-1',
              providerMetadata: ProviderMetadata({
                'google': {
                  'responsePart': 'visible_text',
                },
              }),
            ),
            const TextDeltaEvent(
              id: 'text-1',
              delta: 'Attached the report.',
              providerMetadata: ProviderMetadata({
                'google': {
                  'responsePart': 'visible_text',
                },
              }),
            ),
            const TextEndEvent(id: 'text-1'),
            const FinishEvent(finishReason: FinishReason.stop),
          ]),
        ),
      );

      await exportingSession.sendMessage(ChatInput.text('Send the report.'));

      const codec = ChatSessionSnapshotJsonCodec();
      final encodedSnapshot =
          codec.encodeSnapshot(exportingSession.exportSnapshot());
      final decodedSnapshot = codec.decodeSnapshot(encodedSnapshot);

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
                delta: 'Restored file continuation works.',
              ),
              const TextEndEvent(id: 'text-2'),
              const FinishEvent(finishReason: FinishReason.stop),
            ]);
          },
        ),
        snapshot: decodedSnapshot,
      );

      await restoredSession
          .sendMessage(ChatInput.text('What should I read first?'));

      expect(capturedRequests, hasLength(1));
      expect(capturedRequests.single.prompt, hasLength(3));
      final assistantPrompt =
          capturedRequests.single.prompt[1] as AssistantPromptMessage;
      expect(assistantPrompt.parts, hasLength(2));
      expect(assistantPrompt.parts[0], isA<FilePromptPart>());
      expect(assistantPrompt.parts[1], isA<TextPromptPart>());

      final replayedFilePart = assistantPrompt.parts[0] as FilePromptPart;
      expect(replayedFilePart.mediaType, 'application/pdf');
      expect(replayedFilePart.filename, 'report.pdf');
      expect(replayedFilePart.uri, isNull);
      expect(replayedFilePart.bytes, [4, 5, 6]);
      expect(
        _promptReplayMetadata(replayedFilePart)!['google'],
        containsPair('fileId', 'file_pdf_1'),
      );

      final replayedTextPart = assistantPrompt.parts[1] as TextPromptPart;
      expect(replayedTextPart.text, 'Attached the report.');
      expect(
        _promptReplayMetadata(replayedTextPart)!['google'],
        containsPair('responsePart', 'visible_text'),
      );

      await exportingSession.dispose();
      await restoredSession.dispose();
    });

    test(
        'restores snapshots with Google server-side tool replay for follow-up requests',
        () async {
      final exportingSession = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) => Stream<TextStreamEvent>.fromIterable([
            StartEvent(),
            const CustomEvent(
              kind: 'google.result.tool_call',
              data: {
                'schema': 'google.tool_call.v1',
                'replayRole': 'assistant',
                'toolCallId': 'srvtool_1',
                'toolName': 'google_search',
                'toolCall': {
                  'id': 'srvtool_1',
                  'toolType': 'google_search',
                  'query': 'Dart SDK',
                },
              },
              providerMetadata: ProviderMetadata({
                'google': {
                  'thoughtSignature': 'sig_srvtool_1',
                  'serverToolPart': 'toolCall',
                  'toolCallId': 'srvtool_1',
                  'toolType': 'google_search',
                },
              }),
            ),
            const CustomEvent(
              kind: 'google.result.tool_response',
              data: {
                'schema': 'google.tool_response.v1',
                'replayRole': 'assistant',
                'toolCallId': 'srvtool_1',
                'toolName': 'google_search',
                'toolResponse': {
                  'id': 'srvtool_1',
                  'toolType': 'google_search',
                  'result': {
                    'items': [
                      {
                        'uri': 'https://dart.dev',
                        'title': 'Dart',
                      },
                    ],
                  },
                },
              },
              providerMetadata: ProviderMetadata({
                'google': {
                  'serverToolPart': 'toolResponse',
                  'toolCallId': 'srvtool_1',
                  'toolType': 'google_search',
                },
              }),
            ),
            const TextStartEvent(id: 'text-1'),
            const TextDeltaEvent(
              id: 'text-1',
              delta: 'Dart search finished.',
            ),
            const TextEndEvent(id: 'text-1'),
            const FinishEvent(finishReason: FinishReason.stop),
          ]),
        ),
      );

      await exportingSession.sendMessage(ChatInput.text('Search for Dart.'));

      const codec = ChatSessionSnapshotJsonCodec();
      final encodedSnapshot =
          codec.encodeSnapshot(exportingSession.exportSnapshot());
      final decodedSnapshot = codec.decodeSnapshot(encodedSnapshot);

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
                delta: 'Restored Google tool replay works.',
              ),
              const TextEndEvent(id: 'text-2'),
              const FinishEvent(finishReason: FinishReason.stop),
            ]);
          },
        ),
        snapshot: decodedSnapshot,
      );

      await restoredSession.sendMessage(ChatInput.text('What next?'));

      expect(capturedRequests, hasLength(1));
      expect(capturedRequests.single.prompt, hasLength(3));
      final assistantPrompt =
          capturedRequests.single.prompt[1] as AssistantPromptMessage;
      expect(assistantPrompt.parts, hasLength(3));

      final replayedToolCall = assistantPrompt.parts[0] as CustomPromptPart;
      expect(replayedToolCall.kind, 'google.result.tool_call');
      expect(replayedToolCall.data, {
        'schema': 'google.tool_call.v1',
        'replayRole': 'assistant',
        'toolCallId': 'srvtool_1',
        'toolName': 'google_search',
        'toolCall': {
          'id': 'srvtool_1',
          'toolType': 'google_search',
          'query': 'Dart SDK',
        },
      });
      expect(
        _promptReplayMetadata(replayedToolCall)!['google'],
        containsPair('thoughtSignature', 'sig_srvtool_1'),
      );

      final replayedToolResponse = assistantPrompt.parts[1] as CustomPromptPart;
      expect(replayedToolResponse.kind, 'google.result.tool_response');
      expect(replayedToolResponse.data, {
        'schema': 'google.tool_response.v1',
        'replayRole': 'assistant',
        'toolCallId': 'srvtool_1',
        'toolName': 'google_search',
        'toolResponse': {
          'id': 'srvtool_1',
          'toolType': 'google_search',
          'result': {
            'items': [
              {
                'uri': 'https://dart.dev',
                'title': 'Dart',
              },
            ],
          },
        },
      });

      final replayedText = assistantPrompt.parts[2] as TextPromptPart;
      expect(replayedText.text, 'Dart search finished.');

      await exportingSession.dispose();
      await restoredSession.dispose();
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
          reason: 'Restored approval context.',
        ),
      );

      expect(capturedRequests, hasLength(1));
      expect(
          capturedRequests.single.trigger, ChatTransportTrigger.toolApproval);
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
      expect(approvedTool.approval?.reason, 'Restored approval context.');
      expect(restoredSession.state.status, ChatStatus.ready);
      expect(
        assistantMessage.parts.whereType<TextUiPart>().single.text,
        'The restored approval was executed.',
      );

      await exportingSession.dispose();
      await restoredSession.dispose();
    });

    test(
        'adds UI-only data parts while awaitingTool without polluting prompt history',
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
              default:
                return Stream<TextStreamEvent>.fromIterable([
                  StartEvent(),
                  const TextStartEvent(id: 'text-2'),
                  const TextDeltaEvent(
                    id: 'text-2',
                    delta: 'The forecast card is ready.',
                  ),
                  const TextEndEvent(id: 'text-2'),
                  const FinishEvent(finishReason: FinishReason.stop),
                ]);
            }
          },
        ),
      );

      await session.sendMessage(ChatInput.text('Weather in London?'));
      await session.addDataPart(
        const DataUiPart<Object?>(
          id: 'progress',
          key: 'tool-status',
          data: {
            'value': 0.25,
          },
        ),
      );
      await session.addDataPart(
        const DataUiPart<Object?>(
          id: 'progress',
          key: 'tool-status',
          data: {
            'value': 0.75,
          },
        ),
      );

      expect(session.state.status, ChatStatus.awaitingTool);
      final pendingAssistant = session.state.messages.last;
      final pendingDataPart =
          pendingAssistant.parts.whereType<DataUiPart<Object?>>().single;
      expect(pendingDataPart.id, 'progress');
      expect((pendingDataPart.data as Map<String, Object?>)['value'], 0.75);

      final snapshot = session.exportSnapshot();
      final snapshotDataPart =
          snapshot.messages.last.parts.whereType<DataUiPart<Object?>>().single;
      expect(snapshotDataPart.id, 'progress');
      expect((snapshotDataPart.data as Map<String, Object?>)['value'], 0.75);

      await session.addToolOutput(
        const ToolOutputUpdate(
          toolCallId: 'tool-1',
          toolName: 'weather',
          output: {
            'forecast': 'sunny',
          },
        ),
      );

      expect(capturedRequests, hasLength(2));
      final continuationPrompt = capturedRequests[1].prompt;
      final assistantPrompt = continuationPrompt[1] as AssistantPromptMessage;
      expect(assistantPrompt.parts, hasLength(1));
      expect(assistantPrompt.parts.single, isA<ToolCallPromptPart>());

      final mergedAssistant = session.state.messages.last;
      final mergedDataPart =
          mergedAssistant.parts.whereType<DataUiPart<Object?>>().single;
      expect((mergedDataPart.data as Map<String, Object?>)['value'], 0.75);
      expect(
        mergedAssistant.parts.whereType<TextUiPart>().single.text,
        'The forecast card is ready.',
      );

      await session.dispose();
    });

    test('projects transport data chunks into the active assistant message',
        () async {
      final session = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) => const Stream<TextStreamEvent>.empty(),
          onSendMessageChunks: (request) =>
              Stream<ChatUiStreamChunk>.fromIterable([
            ChatUiMessageStartChunk(
              messageId: 'server-msg-1',
              metadata: const {
                'serverOwned': true,
              },
            ),
            ChatUiEventChunk(StartEvent()),
            const ChatUiDataPartChunk<Object?>(
              DataUiPart<Object?>(
                id: 'progress',
                key: 'status',
                data: {
                  'value': 0.25,
                },
              ),
            ),
            const ChatUiEventChunk(TextStartEvent(id: 'text-1')),
            const ChatUiEventChunk(
              TextDeltaEvent(
                id: 'text-1',
                delta: 'Hello',
              ),
            ),
            const ChatUiDataPartChunk<Object?>(
              DataUiPart<Object?>(
                id: 'progress',
                key: 'status',
                data: {
                  'value': 1.0,
                },
              ),
            ),
            const ChatUiEventChunk(TextEndEvent(id: 'text-1')),
            const ChatUiEventChunk(
              FinishEvent(finishReason: FinishReason.stop),
            ),
            ChatUiMessageFinishChunk(
              metadata: const {
                'persisted': true,
              },
            ),
          ]),
        ),
      );

      await session.sendMessage(ChatInput.text('Hi'));

      expect(session.state.status, ChatStatus.ready);
      final assistantMessage = session.state.messages.last;
      expect(
        assistantMessage.parts.whereType<TextUiPart>().single.text,
        'Hello',
      );
      expect(assistantMessage.id, 'server-msg-1');
      expect(assistantMessage.metadata['serverOwned'], isTrue);
      expect(assistantMessage.metadata['persisted'], isTrue);
      final dataPart =
          assistantMessage.parts.whereType<DataUiPart<Object?>>().single;
      expect(dataPart.id, 'progress');
      expect((dataPart.data as Map<String, Object?>)['value'], 1.0);

      await session.dispose();
    });

    test(
        'keeps locally added data parts while later transport chunks continue streaming',
        () async {
      final controller = StreamController<ChatUiStreamChunk>();
      final session = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) => const Stream<TextStreamEvent>.empty(),
          onSendMessageChunks: (request) => controller.stream,
        ),
      );

      final sendFuture = session.sendMessage(ChatInput.text('Hi'));
      await _flushAsyncWork();

      controller.add(const ChatUiEventChunk(TextStartEvent(id: 'text-1')));
      controller.add(
        const ChatUiEventChunk(
          TextDeltaEvent(
            id: 'text-1',
            delta: 'Hello',
          ),
        ),
      );
      await _flushAsyncWork();

      await session.addDataPart(
        const DataUiPart<Object?>(
          id: 'progress',
          key: 'status',
          data: {
            'value': 0.5,
          },
        ),
      );

      controller.add(
        const ChatUiEventChunk(
          TextDeltaEvent(
            id: 'text-1',
            delta: ' world',
          ),
        ),
      );
      controller.add(const ChatUiEventChunk(TextEndEvent(id: 'text-1')));
      controller.add(
        const ChatUiEventChunk(
          FinishEvent(finishReason: FinishReason.stop),
        ),
      );
      await controller.close();
      await sendFuture;

      expect(session.state.status, ChatStatus.ready);
      final assistantMessage = session.state.messages.last;
      expect(
        assistantMessage.parts.whereType<TextUiPart>().single.text,
        'Hello world',
      );
      final dataPart =
          assistantMessage.parts.whereType<DataUiPart<Object?>>().single;
      expect(dataPart.id, 'progress');
      expect((dataPart.data as Map<String, Object?>)['value'], 0.5);

      await session.dispose();
    });

    test(
        'emits transient transport data through the side channel without persisting it',
        () async {
      final session = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) => const Stream<TextStreamEvent>.empty(),
          onSendMessageChunks: (request) =>
              Stream<ChatUiStreamChunk>.fromIterable([
            const ChatUiTransientDataPartChunk<Object?>(
              DataUiPart<Object?>(
                id: 'heartbeat',
                key: 'tool-status',
                data: {
                  'phase': 'running',
                },
              ),
            ),
            const ChatUiEventChunk(TextStartEvent(id: 'text-1')),
            const ChatUiEventChunk(
              TextDeltaEvent(
                id: 'text-1',
                delta: 'Hello',
              ),
            ),
            const ChatUiEventChunk(TextEndEvent(id: 'text-1')),
            const ChatUiEventChunk(
              FinishEvent(finishReason: FinishReason.stop),
            ),
          ]),
        ),
      );

      final transientPartFuture = session.transientDataParts.first;

      await session.sendMessage(ChatInput.text('Hi'));

      final transientPart = await transientPartFuture;
      expect(transientPart.id, 'heartbeat');
      expect(
        (transientPart.data as Map<String, Object?>)['phase'],
        'running',
      );

      final assistantMessage = session.state.messages.last;
      expect(
        assistantMessage.parts.whereType<DataUiPart<Object?>>(),
        isEmpty,
      );
      expect(
        assistantMessage.parts.whereType<TextUiPart>().single.text,
        'Hello',
      );

      await session.dispose();
    });

    test('transitions to error state when the stream emits ErrorEvent',
        () async {
      final session = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) => Stream<TextStreamEvent>.fromIterable([
            StartEvent(),
            const ErrorEvent(
              ModelError(
                kind: ModelErrorKind.provider,
                message: 'provider failed',
                code: 'provider_failed',
              ),
            ),
          ]),
        ),
      );

      await session.sendMessage(ChatInput.text('Hi'));

      expect(session.state.status, ChatStatus.error);
      expect(session.state.error?.message, 'provider failed');
      expect(session.state.messages, hasLength(2));

      await session.clearError();
      expect(session.state.status, ChatStatus.ready);
      expect(session.state.error, isNull);

      await session.dispose();
    });

    test(
        'resume removes the partial assistant message and rebuilds it from replay',
        () async {
      var sendCount = 0;
      final session = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) {
            sendCount += 1;
            return Stream<TextStreamEvent>.fromIterable([
              StartEvent(),
              const TextStartEvent(id: 'text-1'),
              const TextDeltaEvent(id: 'text-1', delta: 'Hel'),
              const ErrorEvent(
                ModelError(
                  kind: ModelErrorKind.transport,
                  message: 'socket closed',
                  code: 'socket_closed',
                ),
              ),
            ]);
          },
          onReconnect: (chatId) => Stream<TextStreamEvent>.fromIterable([
            StartEvent(),
            const TextStartEvent(id: 'text-1'),
            const TextDeltaEvent(id: 'text-1', delta: 'Hel'),
            const TextDeltaEvent(id: 'text-1', delta: 'lo'),
            const TextEndEvent(id: 'text-1'),
            const FinishEvent(finishReason: FinishReason.stop),
          ]),
        ),
      );

      await session.sendMessage(ChatInput.text('Hi'));

      expect(session.state.status, ChatStatus.error);
      expect(session.state.messages, hasLength(2));
      final partialAssistant = session.state.messages.last;
      expect(partialAssistant.id, 'msg-1');
      expect(
        partialAssistant.parts.whereType<TextUiPart>().single.text,
        'Hel',
      );

      await session.resume();

      expect(sendCount, 1);
      expect(session.state.status, ChatStatus.ready);
      expect(session.state.error, isNull);
      expect(session.state.messages, hasLength(2));
      expect(session.state.messages.last.id, 'msg-1');
      expect(
        session.state.messages.last.parts.whereType<TextUiPart>().single.text,
        'Hello',
      );

      await session.dispose();
    });

    test('resume throws when the transport cannot reconnect', () async {
      final session = DefaultChatSession(
        transport: _FakeChatTransport(
          onSendMessages: (request) => Stream<TextStreamEvent>.fromIterable([
            StartEvent(),
            const TextStartEvent(id: 'text-1'),
            const TextDeltaEvent(id: 'text-1', delta: 'Hel'),
            const ErrorEvent(
              ModelError(
                kind: ModelErrorKind.transport,
                message: 'socket closed',
                code: 'socket_closed',
              ),
            ),
          ]),
        ),
      );

      await session.sendMessage(ChatInput.text('Hi'));

      await expectLater(
        session.resume(),
        throwsA(isA<StateError>()),
      );

      await session.dispose();
    });
  });
}

Future<void> _flushAsyncWork([int turns = 8]) async {
  for (var index = 0; index < turns; index++) {
    await Future<void>.delayed(Duration.zero);
  }
}

ProviderMetadata? _promptReplayMetadata(PromptPart part) {
  return providerReplayMetadataFromOptions(part.providerOptions);
}

final class _FakeChatTransport implements ChatTransport {
  final Stream<TextStreamEvent> Function(ChatTransportRequest request)
      onSendMessages;
  final Stream<TextStreamEvent>? Function(String chatId)? onReconnect;
  final Stream<ChatUiStreamChunk> Function(ChatTransportRequest request)?
      onSendMessageChunks;

  const _FakeChatTransport({
    required this.onSendMessages,
    this.onReconnect,
    this.onSendMessageChunks,
  });

  @override
  Stream<ChatUiStreamChunk>? reconnect(String chatId) {
    return onReconnect
        ?.call(chatId)
        ?.map<ChatUiStreamChunk>((event) => ChatUiEventChunk(event));
  }

  @override
  Stream<ChatUiStreamChunk> sendMessages(ChatTransportRequest request) {
    final chunkStream = onSendMessageChunks?.call(request);
    if (chunkStream != null) {
      return chunkStream;
    }

    return onSendMessages(request)
        .map<ChatUiStreamChunk>((event) => ChatUiEventChunk(event));
  }
}

typedef _FakeLanguageModel = FakeLanguageModel;
