import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderMetadata', () {
    test('builds namespaced metadata and deep merges payloads', () {
      final left = ProviderMetadata.forNamespace('openai', {
        'itemId': 'msg_1',
        'debug': null,
      });
      const right = ProviderMetadata({
        'openai': {
          'callPhase': 'completed',
        },
      });

      final merged = left!.mergedWith(right);

      expect(
        merged,
        const ProviderMetadata({
          'openai': {
            'itemId': 'msg_1',
            'callPhase': 'completed',
          },
        }),
      );
    });

    test('rejects invalid top-level namespace keys', () {
      const metadata = ProviderMetadata({
        'OpenAI': {
          'itemId': 'msg_1',
        },
      });

      expect(metadata.toJsonMap, throwsFormatException);
    });
  });

  group('ProviderReference and FileData', () {
    test('builds provider-native references and validates JSON keys', () {
      final reference = ProviderReference.forProvider('openai', 'file_123');

      expect(reference['openai'], 'file_123');
      expect(reference.requireProvider('openai'), 'file_123');
      expect(reference.toJsonMap(), {
        'openai': 'file_123',
      });

      expect(
        const ProviderReference({'OpenAI': 'file_123'}).toJsonMap,
        throwsFormatException,
      );
    });

    test('throws clear errors for missing provider entries', () {
      const reference = ProviderReference({'anthropic': 'file_123'});

      expect(
        () => reference.requireProvider(
          'openai',
          context: 'OpenAI file prompt part',
        ),
        throwsA(
          isA<UnsupportedError>()
              .having(
                (error) => error.toString(),
                'message',
                contains('OpenAI file prompt part'),
              )
              .having(
                (error) => error.toString(),
                'message',
                contains('"openai"'),
              )
              .having(
                (error) => error.toString(),
                'message',
                contains('anthropic'),
              ),
        ),
      );
    });

    test('stores file prompts as structured data variants', () {
      final urlPart = FilePromptPart(
        mediaType: 'application/pdf',
        data: FileUrlData(Uri.parse('https://example.test/file.pdf')),
      );
      const bytesPart = FilePromptPart(
        mediaType: 'application/pdf',
        data: FileBytesData.constBytes([1, 2, 3]),
      );
      const referencePart = FilePromptPart(
        mediaType: 'application/pdf',
        data: FileProviderReferenceData(
          ProviderReference({'openai': 'file_123'}),
        ),
      );

      expect(urlPart.data, isA<FileUrlData>());
      expect(urlPart.uri.toString(), 'https://example.test/file.pdf');
      expect(bytesPart.data, isA<FileBytesData>());
      expect(bytesPart.bytes, [1, 2, 3]);
      expect(referencePart.data, isA<FileProviderReferenceData>());
      expect(referencePart.providerReference!.requireProvider('openai'),
          'file_123');
    });
  });

  group('ToolOutput', () {
    test('projects legacy tool result output into structured variants', () {
      final ok = ToolResultPromptPart(
        toolCallId: 'call_1',
        toolName: 'weather',
        output: 'sunny',
      );
      final failed = ToolResultPromptPart(
        toolCallId: 'call_2',
        toolName: 'weather',
        output: 'timeout',
        isError: true,
      );
      final denied = ToolResultPromptPart(
        toolCallId: 'call_3',
        toolName: 'weather',
        toolOutput: ExecutionDeniedToolOutput('requires approval'),
      );

      expect(ok.toolOutput, isA<TextToolOutput>());
      expect(ok.output, 'sunny');
      expect(ok.isError, isFalse);
      expect(failed.toolOutput, isA<ErrorTextToolOutput>());
      expect(failed.output, 'timeout');
      expect(failed.isError, isTrue);
      expect(denied.toolOutput.denied, isTrue);
      expect(denied.output, 'requires approval');

      final json = ToolOutput.fromValue({'ok': true});
      final jsonError =
          ToolOutput.fromValue({'error': 'timeout'}, isError: true);

      expect(json, isA<JsonToolOutput>());
      expect(json.value, {'ok': true});
      expect(jsonError, isA<ErrorJsonToolOutput>());
      expect(jsonError.isError, isTrue);
    });

    test('supports provider metadata and multimodal content output parts', () {
      final output = ContentToolOutput(
        providerMetadata: const ProviderMetadata({
          'openai': {
            'itemId': 'tool_result_1',
          },
        }),
        parts: [
          const TextToolOutputContentPart(
            'forecast',
            providerOptions: _TestPromptPartOptions(),
          ),
          const FileToolOutputContentPart(
            mediaType: 'image/png',
            filename: 'preview.png',
            data: FileBytesData.constBytes([1, 2, 3]),
            providerOptions: _TestPromptPartOptions(),
          ),
          const CustomToolOutputContentPart(
            kind: 'openai.computer_screenshot',
            data: {
              'width': 1024,
              'height': 768,
            },
          ),
        ],
      );

      expect(
        output.providerMetadata!['openai'],
        containsPair('itemId', 'tool_result_1'),
      );

      final text = output.parts[0] as TextToolOutputContentPart;
      expect(text.providerOptions, isA<_TestPromptPartOptions>());

      final file = output.parts[1] as FileToolOutputContentPart;
      expect(file.bytes, [1, 2, 3]);
      expect(file.providerOptions, isA<_TestPromptPartOptions>());

      final custom = output.parts[2] as CustomToolOutputContentPart;
      expect(custom.kind, 'openai.computer_screenshot');
    });
  });

  group('ModelError', () {
    test('normalizes provider payload maps into structured errors', () {
      final error = ModelError.fromUnknown(
        {
          'type': 'server_error',
          'message': 'upstream failed',
          'statusCode': 503,
          'retryable': true,
        },
        kind: ModelErrorKind.provider,
      );

      expect(error.kind, ModelErrorKind.provider);
      expect(error.code, 'server_error');
      expect(error.message, 'upstream failed');
      expect(error.statusCode, 503);
      expect(error.isRetryable, isTrue);
    });

    test('round-trips the current serialized error shape', () {
      const error = ModelError(
        kind: ModelErrorKind.transport,
        message: 'backend failed',
        code: 'transport_error',
        statusCode: 503,
        isRetryable: true,
        details: {
          'retryAfter': 3,
        },
        originalType: 'TransportHttpException',
      );

      expect(ModelError.fromJson(error.toJsonMap()), error);
    });
  });

  group('PromptMessage and ContentPart', () {
    test('keeps prompt and content contracts immutable', () {
      final message = UserPromptMessage(
        parts: [
          const TextPromptPart('Hello'),
        ],
      );
      final content = [
        const TextContentPart('Hi'),
        ToolCallContentPart(
          const ToolCallContent(
            toolCallId: 'call_1',
            toolName: 'weather',
          ),
          providerMetadata: ProviderMetadata.forNamespace('openai', {
            'itemId': 'item_1',
          }),
        ),
      ];

      expect(message.role, PromptRole.user);
      expect(message.parts.single, isA<TextPromptPart>());
      expect(() => message.parts.add(const TextPromptPart('Nope')),
          throwsUnsupportedError);
      expect(content.whereType<ToolCallContentPart>().single.toolCall.toolName,
          'weather');
    });
  });

  group('ToolJsonSchema', () {
    test('builds object-rooted tool input schemas', () {
      final schema = ToolJsonSchema.object(
        properties: const {
          'city': {
            'type': 'string',
          },
        },
        required: const ['city'],
      );

      expect(schema.toJson()['type'], 'object');
      expect(schema.toJson()['required'], ['city']);
    });

    test('rejects non-object root schemas', () {
      expect(
        () => ToolJsonSchema.raw(
          const {
            'type': 'array',
          },
        ),
        throwsArgumentError,
      );
    });
  });

  group('ResponseFormat and LanguageModelStreamEvent', () {
    test('keeps response and stream contracts provider-facing', () {
      final responseFormat = JsonResponseFormat(
        schema: JsonSchema.object(),
        name: 'answer',
      );
      final event = FinishEvent(
        finishReason: FinishReason.stop,
        usage: const UsageStats(
          inputTokens: 3,
          outputTokens: 4,
          totalTokens: 7,
        ),
        providerMetadata: ProviderMetadata.forNamespace('openai', {
          'responseId': 'resp_1',
        }),
      );

      expect(responseFormat.schema.toJson()['type'], 'object');
      expect(event.finishReason, FinishReason.stop);
      expect(event.usage!.totalTokens, 7);
      expect(event.providerMetadata!.containsNamespace('openai'), isTrue);
    });

    test('carries structured stream errors', () {
      const event = ErrorEvent(
        ModelError(
          kind: ModelErrorKind.provider,
          message: 'failed',
        ),
      );

      expect(event.error.kind, ModelErrorKind.provider);
    });
  });

  group('LanguageModel contracts', () {
    test('builds immutable requests with provider invocation options', () {
      final providerOptions = _TestProviderOptions();
      final request = GenerateTextRequest(
        prompt: [
          UserPromptMessage.text('Search weather.'),
        ],
        tools: [
          FunctionToolDefinition(
            name: 'weather',
            inputSchema: ToolJsonSchema.object(),
          ),
        ],
        toolChoice: const SpecificToolChoice('weather'),
        options: GenerateTextOptions(
          maxOutputTokens: 128,
          responseFormat: JsonResponseFormat(
            schema: JsonSchema.object(),
          ),
        ),
        callOptions: CallOptions(providerOptions: providerOptions),
      );

      final promptPart =
          (request.prompt.single as UserPromptMessage).parts.single;
      expect(promptPart, isA<TextPromptPart>());
      expect((promptPart as TextPromptPart).text, 'Search weather.');
      expect(request.tools.single.name, 'weather');
      expect(request.toolChoice, isA<SpecificToolChoice>());
      expect(request.options.maxOutputTokens, 128);
      expect(request.callOptions.providerOptions, same(providerOptions));
      expect(() => request.prompt.add(UserPromptMessage.text('Nope')),
          throwsUnsupportedError);
      expect(
        () => request.tools.add(
          FunctionToolDefinition(
            name: 'other',
            inputSchema: ToolJsonSchema.object(),
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('rejects invalid tool choices before provider execution', () {
      expect(
        () => GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Hello'),
          ],
          toolChoice: const RequiredToolChoice(),
        ),
        throwsArgumentError,
      );

      expect(
        () => GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Hello'),
          ],
          tools: [
            FunctionToolDefinition(
              name: 'weather',
              inputSchema: ToolJsonSchema.object(),
            ),
          ],
          toolChoice: const SpecificToolChoice('calendar'),
        ),
        throwsArgumentError,
      );
    });

    test('direct provider calls stay single-step and orchestration-free',
        () async {
      final model = _SingleStepLanguageModel(
        result: GenerateTextResult(
          content: const [
            ToolCallContentPart(
              ToolCallContent(
                toolCallId: 'call_1',
                toolName: 'weather',
                input: {
                  'city': 'Tokyo',
                },
              ),
            ),
          ],
          finishReason: FinishReason.toolCalls,
        ),
        streamEvents: const [
          ToolCallEvent(
            toolCall: ToolCallContent(
              toolCallId: 'call_2',
              toolName: 'weather',
              input: {
                'city': 'Osaka',
              },
            ),
          ),
          FinishEvent(finishReason: FinishReason.toolCalls),
        ],
      );
      final request = GenerateTextRequest(
        prompt: [
          UserPromptMessage.text('Weather?'),
        ],
        tools: [
          FunctionToolDefinition(
            name: 'weather',
            inputSchema: ToolJsonSchema.object(),
          ),
        ],
      );

      final result = await model.doGenerate(request);
      final events = await model.doStream(request).toList();

      expect(model.generateRequests, hasLength(1));
      expect(model.generateRequests.single, same(request));
      expect(model.streamRequests, hasLength(1));
      expect(model.streamRequests.single, same(request));
      expect(result.finishReason, FinishReason.toolCalls);
      expect(result.content.single, isA<ToolCallContentPart>());
      expect(events, hasLength(2));
      expect(events.first, isA<ToolCallEvent>());
      expect((events.last as FinishEvent).finishReason, FinishReason.toolCalls);
    });

    test('aggregates text and reasoning content from results', () {
      final result = GenerateTextResult(
        content: [
          const ReasoningContentPart('Think. '),
          const TextContentPart('Hello'),
          const TextContentPart(' world'),
          const ReasoningContentPart('Answer.'),
        ],
        finishReason: FinishReason.stop,
        usage: const UsageStats(totalTokens: 12),
      );

      expect(result.text, 'Hello world');
      expect(result.reasoningText, 'Think. Answer.');
      expect(result.usage!.totalTokens, 12);
      expect(() => result.content.add(const TextContentPart('Nope')),
          throwsUnsupportedError);
    });
  });

  group('Non-text model contracts', () {
    test('keeps embedding requests and results immutable', () {
      final request = EmbedRequest(
        values: ['a', 'b'],
        dimensions: 256,
        callOptions: CallOptions(
          providerOptions: _TestProviderOptions(),
        ),
      );
      final result = EmbedResult(
        embeddings: const [
          [0.1, 0.2],
          [0.3, 0.4],
        ],
        usage: const UsageStats(inputTokens: 2, totalTokens: 2),
        warnings: const [
          ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'encodingFormat',
            message: 'encodingFormat is ignored.',
          ),
        ],
        responseMetadata: ModelResponseMetadata(
          timestamp: DateTime.utc(2026, 5, 15),
          modelId: 'text-embedding-3-small',
          headers: const {
            'x-request-id': 'req_embed_1',
          },
        ),
      );

      expect(request.values, ['a', 'b']);
      expect(request.dimensions, 256);
      expect(
        request.callOptions.providerOptions,
        isA<_TestProviderOptions>(),
      );
      expect(result.embeddings.first, [0.1, 0.2]);
      expect(result.usage!.totalTokens, 2);
      expect(result.responseMetadata!.modelId, 'text-embedding-3-small');
      expect(result.warnings.single.field, 'encodingFormat');
      expect(() => request.values.add('c'), throwsUnsupportedError);
      expect(() => result.embeddings.add(const []), throwsUnsupportedError);
      expect(() => result.embeddings.first.add(0.5), throwsUnsupportedError);
      expect(
        () => result.warnings.add(
          const ModelWarning(
            type: ModelWarningType.other,
            message: 'Nope',
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('carries image generation outputs and provider metadata', () {
      final result = ImageGenerationResult(
        images: [
          GeneratedImage(
            uri: Uri.parse('https://example.test/image.png'),
            mediaType: 'image/png',
          ),
        ],
        usage: const UsageStats(inputTokens: 3, totalTokens: 5),
        warnings: const [
          ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'seed',
            message: 'seed is not supported.',
          ),
        ],
        responseMetadata: ModelResponseMetadata(
          timestamp: DateTime.utc(2026, 5, 15),
          modelId: 'gpt-image-2',
          headers: const {
            'x-request-id': 'req_img_1',
          },
        ),
        providerMetadata: ProviderMetadata.forNamespace('openai', {
          'imageId': 'img_1',
        }),
      );

      expect(result.images.single.uri.toString(),
          'https://example.test/image.png');
      expect(result.images.single.mediaType, 'image/png');
      expect(result.usage!.inputTokens, 3);
      expect(result.responseMetadata!.modelId, 'gpt-image-2');
      expect(result.warnings.single.field, 'seed');
      expect(result.providerMetadata!.containsNamespace('openai'), isTrue);
      expect(
        () => result.images.add(const GeneratedImage()),
        throwsUnsupportedError,
      );
      expect(
        () => result.warnings.add(
          const ModelWarning(
            type: ModelWarningType.other,
            message: 'Nope',
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('carries speech response metadata and warnings', () {
      final metadata = ModelResponseMetadata(
        timestamp: DateTime.utc(2026, 5, 5),
        modelId: 'tts-1',
        headers: const {
          'x-request-id': 'req_1',
        },
      );
      final result = SpeechGenerationResult(
        audioBytes: const [1, 2, 3],
        mediaType: 'audio/mpeg',
        warnings: const [
          ModelWarning(
            type: ModelWarningType.unsupported,
            message: 'voice was ignored',
          ),
        ],
        responseMetadata: metadata,
      );

      expect(result.audioBytes, [1, 2, 3]);
      expect(result.mediaType, 'audio/mpeg');
      expect(result.warnings.single.type, ModelWarningType.unsupported);
      expect(result.responseMetadata!.headers['x-request-id'], 'req_1');
    });

    test('carries transcription segments and response metadata', () {
      final result = TranscriptionResult(
        text: 'hello world',
        segments: const [
          TranscriptionSegment(
            text: 'hello',
            startSeconds: 0,
            endSeconds: 0.5,
          ),
        ],
        language: 'en',
        durationSeconds: 1.2,
        responseMetadata: ModelResponseMetadata(
          timestamp: DateTime.utc(2026, 5, 5),
          modelId: 'transcribe-1',
        ),
      );

      expect(result.text, 'hello world');
      expect(result.segments.single.text, 'hello');
      expect(result.language, 'en');
      expect(result.durationSeconds, 1.2);
      expect(result.responseMetadata!.modelId, 'transcribe-1');
    });
  });

  group('Capability profiles', () {
    test('describes shared and provider-owned capabilities', () {
      final profile = ModelCapabilityProfile(
        providerId: 'openai',
        modelId: 'gpt-4.1-mini',
        kind: ModelCapabilityKind.language,
        sharedFeatures: const [
          CapabilityDescriptor(
            id: ModelCapabilityFeatureIds.languageStreaming,
          ),
          CapabilityDescriptor(
            id: ModelCapabilityFeatureIds.languageReasoningOutput,
            confidence: CapabilityConfidence.inferred,
          ),
        ],
        providerFeatures: const [
          ProviderFeatureDescriptor(
            providerId: 'openai',
            featureId: 'responses.builtInTools',
            detail: ['web_search'],
          ),
        ],
      );

      expect(
        profile.supports(ModelCapabilityFeatureIds.languageStreaming),
        isTrue,
      );
      expect(
        profile
            .sharedFeature(
              ModelCapabilityFeatureIds.languageReasoningOutput,
            )!
            .confidence,
        CapabilityConfidence.inferred,
      );
      expect(
        profile.providerFeature('openai', 'responses.builtInTools')!.detail,
        ['web_search'],
      );
      expect(profile.providerFeaturesFor('anthropic'), isEmpty);
    });
  });

  group('CallOptions and ProviderCancellation', () {
    test('resolves typed provider invocation options', () {
      final options = _TestProviderOptions();

      expect(
        resolveProviderInvocationOptions<_TestProviderOptions>(
          options,
          parameterName: 'providerOptions',
          expectedTypeName: '_TestProviderOptions',
          usageContext: 'test models',
        ),
        same(options),
      );
      expect(
        resolveProviderInvocationOptions<_TestProviderOptions>(
          null,
          parameterName: 'providerOptions',
          expectedTypeName: '_TestProviderOptions',
          usageContext: 'test models',
        ),
        isNull,
      );
      expect(
        () => resolveProviderInvocationOptions<_TestProviderOptions>(
          _OtherProviderOptions(),
          parameterName: 'providerOptions',
          expectedTypeName: '_TestProviderOptions',
          usageContext: 'test models',
        ),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'providerOptions')
              .having(
                (error) => error.message,
                'message',
                'Expected _TestProviderOptions for test models.',
              ),
        ),
      );
    });

    test('resolves typed provider model options', () {
      final options = _TestModelOptions();

      expect(
        resolveProviderModelOptions<_TestModelOptions>(
          options,
          parameterName: 'settings',
          expectedTypeName: '_TestModelOptions',
          usageContext: 'test models',
        ),
        same(options),
      );
      expect(
        () => resolveProviderModelOptions<_TestModelOptions>(
          _OtherModelOptions(),
          parameterName: 'settings',
          expectedTypeName: '_TestModelOptions',
          usageContext: 'test models',
        ),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'settings')
              .having(
                (error) => error.message,
                'message',
                'Expected _TestModelOptions for test models.',
              ),
        ),
      );
    });

    test('resolves typed provider prompt part options', () {
      final options = _TestPromptPartOptions();

      expect(
        resolveProviderPromptPartOptions<_TestPromptPartOptions>(
          options,
          parameterName: 'part.providerOptions',
          expectedTypeName: '_TestPromptPartOptions',
          usageContext: 'test prompt parts',
        ),
        same(options),
      );
      expect(
        resolveProviderPromptPartOptions<_TestPromptPartOptions>(
          null,
          parameterName: 'part.providerOptions',
          expectedTypeName: '_TestPromptPartOptions',
          usageContext: 'test prompt parts',
        ),
        isNull,
      );
      const replayOptions = ProviderReplayPromptPartOptions(
        ProviderMetadata({
          'test': {
            'itemId': 'item_1',
          },
        }),
      );
      expect(
        resolveProviderPromptPartOptions<_TestPromptPartOptions>(
          replayOptions,
          parameterName: 'part.providerOptions',
          expectedTypeName: '_TestPromptPartOptions',
          usageContext: 'test prompt parts',
        ),
        isNull,
      );
      expect(
        resolveProviderPromptPartOptions<ProviderReplayPromptPartOptions>(
          replayOptions,
          parameterName: 'part.providerOptions',
          expectedTypeName: 'ProviderReplayPromptPartOptions',
        ),
        same(replayOptions),
      );
      expect(
        () => resolveProviderPromptPartOptions<_TestPromptPartOptions>(
          _OtherPromptPartOptions(),
          parameterName: 'part.providerOptions',
          expectedTypeName: '_TestPromptPartOptions',
          usageContext: 'test prompt parts',
        ),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'part.providerOptions')
              .having(
                (error) => error.message,
                'message',
                'Expected _TestPromptPartOptions for test prompt parts.',
              ),
        ),
      );
    });

    test('carries provider invocation options and cancellation', () {
      final cancellation = ProviderCancellation();
      final options = CallOptions(
        timeout: const Duration(seconds: 3),
        headers: const {
          'x-test': 'true',
        },
        cancellation: cancellation,
      );

      expect(options.timeout, const Duration(seconds: 3));
      expect(options.headers!['x-test'], 'true');
      expect(options.cancellation, same(cancellation));
    });

    test('cancels once and throws provider cancellation exceptions', () {
      final cancellation = ProviderCancellation();

      cancellation.cancel('stop');
      cancellation.cancel('ignored');

      expect(cancellation.isCancelled, isTrue);
      expect(cancellation.reason, 'stop');
      expect(
        cancellation.throwIfCancelled,
        throwsA(isA<ProviderCancelledException>()),
      );
      expect(
        ProviderCancellation.isCancel(
          const ProviderCancelledException('stop'),
        ),
        isTrue,
      );
    });
  });
}

final class _TestProviderOptions implements ProviderInvocationOptions {}

final class _OtherProviderOptions implements ProviderInvocationOptions {}

final class _TestModelOptions implements ProviderModelOptions {}

final class _OtherModelOptions implements ProviderModelOptions {}

final class _TestPromptPartOptions implements ProviderPromptPartOptions {
  const _TestPromptPartOptions();
}

final class _OtherPromptPartOptions implements ProviderPromptPartOptions {}

final class _SingleStepLanguageModel implements LanguageModel {
  final GenerateTextResult result;
  final List<LanguageModelStreamEvent> streamEvents;
  final List<GenerateTextRequest> generateRequests = [];
  final List<GenerateTextRequest> streamRequests = [];

  _SingleStepLanguageModel({
    required this.result,
    required this.streamEvents,
  });

  @override
  String get modelId => 'single-step';

  @override
  String get providerId => 'test';

  @override
  Future<GenerateTextResult> doGenerate(GenerateTextRequest request) async {
    generateRequests.add(request);
    return result;
  }

  @override
  Stream<LanguageModelStreamEvent> doStream(
    GenerateTextRequest request,
  ) async* {
    streamRequests.add(request);
    for (final event in streamEvents) {
      yield event;
    }
  }
}
