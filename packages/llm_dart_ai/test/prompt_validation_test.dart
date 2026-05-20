import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_ai/src/prompt/prompt_validation.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;
import 'package:test/test.dart';

void main() {
  group('validateProviderPrompt', () {
    test('rejects client tool calls without tool results', () {
      expect(
        () => validateProviderPrompt([
          UserPromptMessage.text('What is the weather?'),
          AssistantPromptMessage(
            parts: const [
              ToolCallPromptPart(
                toolCallId: 'call-1',
                toolName: 'weather',
                input: {
                  'city': 'Tokyo',
                },
              ),
            ],
          ),
        ]),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('missing a tool result'),
          ),
        ),
      );
    });

    test('accepts completed client tool calls', () {
      validateProviderPrompt([
        UserPromptMessage.text('What is the weather?'),
        AssistantPromptMessage(
          parts: const [
            ToolCallPromptPart(
              toolCallId: 'call-1',
              toolName: 'weather',
              input: {
                'city': 'Tokyo',
              },
            ),
          ],
        ),
        ToolPromptMessage(
          toolName: 'weather',
          parts: [
            ToolResultPromptPart(
              toolCallId: 'call-1',
              toolName: 'weather',
              output: {
                'forecast': 'sunny',
              },
            ),
          ],
        ),
        UserPromptMessage.text('Summarize it.'),
      ]);
    });

    test('does not require client results for provider-executed tool calls',
        () {
      validateProviderPrompt([
        UserPromptMessage.text('Search internally.'),
        AssistantPromptMessage(
          parts: const [
            ToolCallPromptPart(
              toolCallId: 'server-call-1',
              toolName: 'web_search',
              input: {
                'query': 'Dart AI SDK',
              },
              providerExecuted: true,
              isDynamic: true,
            ),
          ],
        ),
        UserPromptMessage.text('Continue.'),
      ]);
    });

    test('allows provider-executed tool results as replay data', () {
      validateProviderPrompt([
        AssistantPromptMessage(
          parts: const [
            ToolCallPromptPart(
              toolCallId: 'server-call-1',
              toolName: 'web_search',
              providerExecuted: true,
            ),
          ],
        ),
        ToolPromptMessage(
          toolName: 'web_search',
          parts: [
            ToolResultPromptPart(
              toolCallId: 'server-call-1',
              toolName: 'web_search',
              output: {
                'source': 'provider',
              },
            ),
          ],
        ),
      ]);
    });

    test('rejects tool results without matching assistant tool calls', () {
      expect(
        () => validateProviderPrompt([
          ToolPromptMessage(
            toolName: 'weather',
            parts: [
              ToolResultPromptPart(
                toolCallId: 'call-1',
                toolName: 'weather',
                output: {
                  'forecast': 'sunny',
                },
              ),
            ],
          ),
        ]),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('no matching assistant tool call'),
          ),
        ),
      );
    });

    test('rejects duplicate client tool calls while the first is pending', () {
      expect(
        () => validateProviderPrompt([
          AssistantPromptMessage(
            parts: const [
              ToolCallPromptPart(
                toolCallId: 'call-1',
                toolName: 'weather',
              ),
              ToolCallPromptPart(
                toolCallId: 'call-1',
                toolName: 'weather',
              ),
            ],
          ),
        ]),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('already waiting for a tool result'),
          ),
        ),
      );
    });

    test('rejects mismatched tool result names', () {
      expect(
        () => validateProviderPrompt([
          AssistantPromptMessage(
            parts: const [
              ToolCallPromptPart(
                toolCallId: 'call-1',
                toolName: 'weather',
              ),
            ],
          ),
          ToolPromptMessage(
            toolName: 'weather',
            parts: [
              ToolResultPromptPart(
                toolCallId: 'call-1',
                toolName: 'search',
                output: {
                  'forecast': 'sunny',
                },
              ),
            ],
          ),
        ]),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('tool name "search" does not match expected tool'),
          ),
        ),
      );
    });

    test('requires provider approval requests to receive a response', () {
      expect(
        () => validateProviderPrompt([
          AssistantPromptMessage(
            parts: const [
              ToolCallPromptPart(
                toolCallId: 'approval-1',
                toolName: 'mcp.search',
                providerExecuted: true,
                isDynamic: true,
              ),
              ToolApprovalRequestPromptPart(
                approvalId: 'approval-1',
                toolCallId: 'approval-1',
              ),
            ],
          ),
        ]),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('missing an approval response'),
          ),
        ),
      );
    });

    test('rejects provider approval responses with mismatched tool calls', () {
      expect(
        () => validateProviderPrompt([
          AssistantPromptMessage(
            parts: const [
              ToolCallPromptPart(
                toolCallId: 'call-1',
                toolName: 'mcp.search',
                providerExecuted: true,
              ),
              ToolApprovalRequestPromptPart(
                approvalId: 'approval-1',
                toolCallId: 'call-1',
              ),
            ],
          ),
          ToolPromptMessage(
            toolName: 'mcp.search',
            parts: const [
              ToolApprovalResponsePromptPart(
                approvalId: 'approval-1',
                toolCallId: 'call-2',
                approved: true,
              ),
            ],
          ),
        ]),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('but the request referenced "call-1"'),
          ),
        ),
      );
    });

    test('accepts matching provider approval responses', () {
      validateProviderPrompt([
        AssistantPromptMessage(
          parts: const [
            ToolCallPromptPart(
              toolCallId: 'approval-1',
              toolName: 'mcp.search',
              providerExecuted: true,
              isDynamic: true,
            ),
            ToolApprovalRequestPromptPart(
              approvalId: 'approval-1',
              toolCallId: 'approval-1',
            ),
          ],
        ),
        ToolPromptMessage(
          toolName: 'mcp.search',
          parts: const [
            ToolApprovalResponsePromptPart(
              approvalId: 'approval-1',
              toolCallId: 'approval-1',
              approved: false,
              reason: 'not allowed',
            ),
          ],
        ),
      ]);
    });

    test('rejects system messages after conversation messages', () {
      expect(
        () => validateProviderPrompt([
          UserPromptMessage.text('Hello'),
          SystemPromptMessage.text('You are concise.'),
        ]),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('system messages must appear before'),
          ),
        ),
      );
    });
  });

  group('runtime validation', () {
    test('generateText validates prompt before calling the model', () {
      final model = _RecordingLanguageModel();

      expect(
        () => generateText(
          model: model,
          prompt: [
            AssistantPromptMessage(
              parts: const [
                ToolCallPromptPart(
                  toolCallId: 'call-1',
                  toolName: 'weather',
                ),
              ],
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(model.requests, isEmpty);
    });

    test('streamText validates prompt before calling the model', () {
      final model = _RecordingLanguageModel();

      expect(
        () => streamText(
          model: model,
          prompt: [
            ToolPromptMessage(
              toolName: 'weather',
              parts: [
                ToolResultPromptPart(
                  toolCallId: 'call-1',
                  toolName: 'weather',
                  output: {
                    'forecast': 'sunny',
                  },
                ),
              ],
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(model.requests, isEmpty);
    });
  });
}

final class _RecordingLanguageModel implements LanguageModel {
  final List<GenerateTextRequest> requests = [];

  @override
  String get modelId => 'test-model';

  @override
  String get providerId => 'test';

  @override
  Future<GenerateTextResult> doGenerate(GenerateTextRequest request) async {
    requests.add(request);
    return GenerateTextResult(
      content: const [
        TextContentPart('ok'),
      ],
      finishReason: FinishReason.stop,
    );
  }

  @override
  Stream<provider.LanguageModelStreamEvent> doStream(
    GenerateTextRequest request,
  ) async* {
    requests.add(request);
    yield const provider.FinishEvent(finishReason: FinishReason.stop);
  }
}
