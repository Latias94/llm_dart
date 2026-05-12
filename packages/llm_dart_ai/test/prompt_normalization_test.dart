import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeModelMessages', () {
    test('maps user-facing message roles to provider-facing prompt roles', () {
      const systemOptions = _TestPromptPartOptions('system');
      const userOptions = _TestPromptPartOptions('user');
      const assistantPartOptions = _TestPromptPartOptions('assistant-part');
      const toolOptions = _TestPromptPartOptions('tool');
      final fileData = FileTextData('file text');
      final imageData = FileBytesData.constBytes([1, 2, 3]);

      final prompt = normalizeModelMessages([
        const SystemModelMessage.text(
          'system text',
          providerOptions: systemOptions,
        ),
        UserModelMessage(
          parts: [
            const TextModelPart('user text'),
            FileModelPart(
              mediaType: 'text/plain',
              filename: 'notes.txt',
              data: fileData,
            ),
            ImageModelPart(
              mediaType: 'image/png',
              data: imageData,
            ),
          ],
          providerOptions: userOptions,
        ),
        AssistantModelMessage(
          parts: const [
            TextModelPart('assistant text'),
            ReasoningModelPart(
              'reasoning text',
              providerOptions: assistantPartOptions,
            ),
            CustomModelPart(
              kind: 'provider-event',
              data: {
                'value': 'custom',
              },
            ),
            ToolCallModelPart(
              toolCallId: 'call-1',
              toolName: 'weather',
              input: {
                'city': 'Tokyo',
              },
              title: 'Weather',
            ),
            ToolApprovalRequestModelPart(
              approvalId: 'approval-1',
              toolCallId: 'call-2',
            ),
          ],
        ),
        ToolModelMessage(
          parts: [
            ToolResultModelPart(
              toolCallId: 'call-1',
              toolName: 'weather',
              output: {
                'forecast': 'sunny',
              },
            ),
            const ToolApprovalResponseModelPart(
              approvalId: 'approval-1',
              toolCallId: 'call-2',
              toolName: 'shell',
              approved: false,
              reason: 'not allowed',
            ),
          ],
          providerOptions: toolOptions,
        ),
      ]);

      expect(prompt.map((message) => message.role), [
        PromptRole.system,
        PromptRole.user,
        PromptRole.assistant,
        PromptRole.tool,
        PromptRole.tool,
      ]);

      final systemMessage = prompt[0] as SystemPromptMessage;
      final systemText = systemMessage.parts.single as TextPromptPart;
      expect(systemText.text, 'system text');
      expect(systemText.providerOptions, same(systemOptions));

      final userMessage = prompt[1] as UserPromptMessage;
      expect(userMessage.parts, hasLength(3));
      expect(userMessage.parts[0], isA<TextPromptPart>());
      expect(
        (userMessage.parts[0] as TextPromptPart).providerOptions,
        same(userOptions),
      );
      final filePart = userMessage.parts[1] as FilePromptPart;
      expect(filePart.mediaType, 'text/plain');
      expect(filePart.filename, 'notes.txt');
      expect(filePart.data, same(fileData));
      expect(filePart.providerOptions, same(userOptions));
      final imagePart = userMessage.parts[2] as ImagePromptPart;
      expect(imagePart.mediaType, 'image/png');
      expect(imagePart.data, same(imageData));
      expect(imagePart.providerOptions, same(userOptions));

      final assistantMessage = prompt[2] as AssistantPromptMessage;
      expect(assistantMessage.parts, hasLength(5));
      expect(assistantMessage.parts[0], isA<TextPromptPart>());
      final reasoningPart = assistantMessage.parts[1] as ReasoningPromptPart;
      expect(reasoningPart.text, 'reasoning text');
      expect(reasoningPart.providerOptions, same(assistantPartOptions));
      final customPart = assistantMessage.parts[2] as CustomPromptPart;
      expect(customPart.kind, 'provider-event');
      expect(customPart.data, {
        'value': 'custom',
      });
      final toolCallPart = assistantMessage.parts[3] as ToolCallPromptPart;
      expect(toolCallPart.toolCallId, 'call-1');
      expect(toolCallPart.toolName, 'weather');
      expect(toolCallPart.input, {
        'city': 'Tokyo',
      });
      expect(toolCallPart.title, 'Weather');
      final approvalRequest =
          assistantMessage.parts[4] as ToolApprovalRequestPromptPart;
      expect(approvalRequest.approvalId, 'approval-1');
      expect(approvalRequest.toolCallId, 'call-2');

      final toolResultMessage = prompt[3] as ToolPromptMessage;
      expect(toolResultMessage.toolName, 'weather');
      final toolResultPart =
          toolResultMessage.parts.single as ToolResultPromptPart;
      expect(toolResultPart.toolCallId, 'call-1');
      expect(toolResultPart.toolName, 'weather');
      expect(toolResultPart.output, {
        'forecast': 'sunny',
      });
      expect(toolResultPart.providerOptions, same(toolOptions));

      final approvalMessage = prompt[4] as ToolPromptMessage;
      expect(approvalMessage.toolName, 'shell');
      final approvalPart =
          approvalMessage.parts.single as ToolApprovalResponsePromptPart;
      expect(approvalPart.approvalId, 'approval-1');
      expect(approvalPart.toolCallId, 'call-2');
      expect(approvalPart.approved, isFalse);
      expect(approvalPart.reason, 'not allowed');
      expect(approvalPart.providerOptions, same(toolOptions));
    });

    test('maps assistant file and tool-result parts', () {
      final fileData = FileTextData('analysis');

      final prompt = normalizeModelMessages([
        AssistantModelMessage(
          parts: [
            FileModelPart(
              mediaType: 'text/plain',
              filename: 'analysis.txt',
              data: fileData,
            ),
            ReasoningFileModelPart(
              mediaType: 'text/plain',
              filename: 'reasoning.txt',
              data: fileData,
            ),
            ToolResultModelPart(
              toolCallId: 'call-1',
              toolName: 'search',
              output: 'done',
            ),
          ],
        ),
      ]);

      final message = prompt.single as AssistantPromptMessage;
      expect(message.parts[0], isA<FilePromptPart>());
      expect((message.parts[0] as FilePromptPart).data, same(fileData));
      expect(message.parts[1], isA<ReasoningFilePromptPart>());
      expect(
        (message.parts[1] as ReasoningFilePromptPart).data,
        same(fileData),
      );
      final toolResult = message.parts[2] as ToolResultPromptPart;
      expect(toolResult.toolCallId, 'call-1');
      expect(toolResult.toolName, 'search');
      expect(toolResult.output, 'done');
    });

    test('rejects unsupported part types for each message role', () {
      expect(
        () => normalizeModelMessages([
          UserModelMessage(
            parts: const [
              ToolCallModelPart(
                toolCallId: 'call-1',
                toolName: 'weather',
              ),
            ],
          ),
        ]),
        throwsA(isA<UnsupportedError>()),
      );

      expect(
        () => normalizeModelMessages([
          AssistantModelMessage(
            parts: [
              ImageModelPart(data: FileTextData('image')),
            ],
          ),
        ]),
        throwsA(isA<UnsupportedError>()),
      );

      expect(
        () => normalizeModelMessages([
          ToolModelMessage(
            parts: const [
              TextModelPart('not a tool result'),
            ],
          ),
        ]),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('resolveProviderPrompt', () {
    test('uses provider-facing prompt when provided', () {
      final providerPrompt = [
        UserPromptMessage.text('provider prompt'),
      ];

      final resolved = resolveProviderPrompt(prompt: providerPrompt);

      expect(resolved.single, same(providerPrompt.single));
      expect(
        () => resolved.add(UserPromptMessage.text('extra')),
        throwsUnsupportedError,
      );
    });

    test('normalizes user-facing messages when provided', () {
      final resolved = resolveProviderPrompt(
        messages: [
          UserModelMessage.text('model message'),
        ],
      );

      expect(resolved.single, isA<UserPromptMessage>());
      final text = resolved.single.parts.single as TextPromptPart;
      expect(text.text, 'model message');
    });

    test('rejects ambiguous or missing prompt inputs', () {
      expect(
        () => resolveProviderPrompt(
          prompt: [
            UserPromptMessage.text('provider prompt'),
          ],
          messages: [
            UserModelMessage.text('model message'),
          ],
        ),
        throwsArgumentError,
      );

      expect(
        () => resolveProviderPrompt(),
        throwsArgumentError,
      );
    });
  });

  group('runtime helpers', () {
    test('generateText sends normalized messages to the model', () async {
      final model = _RecordingLanguageModel(
        generateResult: GenerateTextResult(
          content: const [
            TextContentPart('ok'),
          ],
          finishReason: FinishReason.stop,
        ),
      );

      final result = await generateText(
        model: model,
        messages: [
          const SystemModelMessage.text('system'),
          UserModelMessage.text('hello'),
        ],
      );

      expect(result.text, 'ok');
      expect(model.lastRequest?.prompt, hasLength(2));
      expect(model.lastRequest?.prompt[0], isA<SystemPromptMessage>());
      expect(model.lastRequest?.prompt[1], isA<UserPromptMessage>());
    });

    test('streamText sends normalized messages to the model', () async {
      final model = _RecordingLanguageModel(
        generateResult: GenerateTextResult(
          content: const [],
          finishReason: FinishReason.stop,
        ),
        streamEvents: const [
          FinishEvent(finishReason: FinishReason.stop),
        ],
      );

      await streamText(
        model: model,
        messages: [
          UserModelMessage.text('stream this'),
        ],
      ).drain<void>();

      expect(model.lastRequest?.prompt, hasLength(1));
      expect(model.lastRequest?.prompt.single, isA<UserPromptMessage>());
      final message = model.lastRequest!.prompt.single as UserPromptMessage;
      final text = message.parts.single as TextPromptPart;
      expect(text.text, 'stream this');
    });
  });
}

final class _TestPromptPartOptions implements ProviderPromptPartOptions {
  final String value;

  const _TestPromptPartOptions(this.value);
}

final class _RecordingLanguageModel implements LanguageModel {
  final GenerateTextResult generateResult;
  final List<TextStreamEvent> streamEvents;
  GenerateTextRequest? lastRequest;

  _RecordingLanguageModel({
    required this.generateResult,
    this.streamEvents = const [],
  });

  @override
  String get modelId => 'test-model';

  @override
  String get providerId => 'test';

  @override
  Future<GenerateTextResult> doGenerate(GenerateTextRequest request) async {
    lastRequest = request;
    return generateResult;
  }

  @override
  Stream<TextStreamEvent> doStream(GenerateTextRequest request) async* {
    lastRequest = request;
    yield* Stream<TextStreamEvent>.fromIterable(streamEvents);
  }
}
