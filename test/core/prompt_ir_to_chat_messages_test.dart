import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('Prompt IR toChatMessages', () {
    test('system messages cannot contain images/files', () {
      expect(
        () => Prompt(
          messages: [
            PromptMessage(
              role: ChatRole.system,
              parts: const [
                ImagePart(
                  mime: ImageMime.png,
                  data: [1, 2, 3],
                ),
              ],
            ),
          ],
        ).toChatMessages(),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => Prompt(
          messages: [
            PromptMessage(
              role: ChatRole.system,
              parts: const [
                ImageUrlPart(url: 'https://example.com/a.png'),
              ],
            ),
          ],
        ).toChatMessages(),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => Prompt(
          messages: [
            PromptMessage(
              role: ChatRole.system,
              parts: const [
                FilePart(
                  mime: FileMime.pdf,
                  data: [1, 2, 3],
                ),
              ],
            ),
          ],
        ).toChatMessages(),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('ToolCallPart must be emitted from assistant message', () {
      expect(
        () => Prompt(
          messages: [
            PromptMessage(
              role: ChatRole.user,
              parts: [
                ToolCallPart(
                  ToolCall(
                    id: 'call_1',
                    callType: 'function',
                    function: const FunctionCall(
                      name: 'get_weather',
                      arguments: '{}',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ).toChatMessages(),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('ToolResultPart must be emitted from user message', () {
      expect(
        () => Prompt(
          messages: [
            PromptMessage(
              role: ChatRole.assistant,
              parts: [
                ToolResultPart(
                  ToolCall(
                    id: 'call_1',
                    callType: 'function',
                    function: const FunctionCall(
                      name: 'get_weather',
                      arguments: '{"ok":true}',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ).toChatMessages(),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('merges providerOptions (message + part) and prefers part overrides',
        () {
      final messages = Prompt(
        messages: [
          PromptMessage(
            role: ChatRole.user,
            providerOptions: const {
              'openai': {'foo': 1, 'bar': 1},
              'anthropic': {
                'cacheControl': {'type': 'ephemeral'}
              },
            },
            parts: const [
              TextPart(
                'hi',
                providerOptions: {
                  'openai': {'bar': 2},
                },
              ),
            ],
          ),
        ],
      ).toChatMessages();

      expect(messages, hasLength(1));
      final msg = messages.single;

      expect(
        msg.providerOptions['openai'],
        equals({'foo': 1, 'bar': 2}),
      );
      expect(
        msg.providerOptions['anthropic'],
        equals({
          'cacheControl': {'type': 'ephemeral'}
        }),
      );
    });

    test('ToolCallPart merges providerOptions into ToolCall.providerOptions',
        () {
      final messages = Prompt(
        messages: [
          PromptMessage(
            role: ChatRole.assistant,
            providerOptions: const {
              'openai': {'foo': 1},
            },
            parts: [
              ToolCallPart(
                ToolCall(
                  id: 'call_1',
                  callType: 'function',
                  function: const FunctionCall(
                    name: 'get_weather',
                    arguments: '{}',
                  ),
                  providerOptions: const {
                    'openai': {'existing': 1},
                  },
                ),
                providerOptions: const {
                  'openai': {'foo': 2},
                },
              ),
            ],
          ),
        ],
      ).toChatMessages();

      expect(messages, hasLength(1));
      final msg = messages.single;
      expect(msg.messageType, isA<ToolUseMessage>());
      final toolCalls = (msg.messageType as ToolUseMessage).toolCalls;
      expect(toolCalls, hasLength(1));
      final toolCall = toolCalls.single;

      expect(
        toolCall.providerOptions['openai'],
        equals({'existing': 1, 'foo': 2}),
      );
      expect(
        msg.providerOptions['openai'],
        equals({'foo': 2}),
      );
    });

    test('propagates protocolPayloads to emitted ChatMessages', () {
      final messages = Prompt(
        messages: const [
          PromptMessage(
            role: ChatRole.user,
            protocolPayloads: {
              'google': {
                'fileUri': 'gs://bucket/file.pdf',
              },
            },
            parts: [
              TextPart('hi'),
              ImageUrlPart(url: 'https://example.com/a.png'),
            ],
          ),
        ],
      ).toChatMessages();

      expect(messages, hasLength(2));
      expect(
        messages[0].protocolPayloads,
        containsPair('google', {'fileUri': 'gs://bucket/file.pdf'}),
      );
      expect(
        messages[1].protocolPayloads,
        containsPair('google', {'fileUri': 'gs://bucket/file.pdf'}),
      );
    });

    test('FileUrlPart cannot be converted to legacy ChatMessages', () {
      expect(
        () => const Prompt(
          messages: [
            PromptMessage(
              role: ChatRole.user,
              parts: [
                FileUrlPart(
                  mime: FileMime.pdf,
                  url: 'https://example.com/a.pdf',
                ),
              ],
            ),
          ],
        ).toChatMessages(),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('FileIdPart cannot be converted to legacy ChatMessages', () {
      expect(
        () => const Prompt(
          messages: [
            PromptMessage(
              role: ChatRole.user,
              parts: [
                FileIdPart(
                  mime: FileMime.pdf,
                  id: 'files/123',
                ),
              ],
            ),
          ],
        ).toChatMessages(),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
