import 'dart:async';

import 'package:llm_dart_ai/internal.dart';
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_chat/llm_dart_chat.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:test/test.dart';

void main() {
  group('DirectChatTransport', () {
    test('maps chat transport requests to language model requests', () async {
      GenerateTextRequest? capturedRequest;

      final transport = DirectChatTransport(
        model: FakeLanguageModel(
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
        model: FakeLanguageModel(
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
        model: FakeLanguageModel(
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
}
