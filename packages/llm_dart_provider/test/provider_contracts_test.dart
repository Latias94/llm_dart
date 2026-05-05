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

  group('ResponseFormat and TextStreamEvent', () {
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
      );

      expect(request.values, ['a', 'b']);
      expect(request.dimensions, 256);
      expect(
        request.callOptions.providerOptions,
        isA<_TestProviderOptions>(),
      );
      expect(result.embeddings.first, [0.1, 0.2]);
      expect(result.usage!.totalTokens, 2);
      expect(() => request.values.add('c'), throwsUnsupportedError);
      expect(() => result.embeddings.add(const []), throwsUnsupportedError);
      expect(() => result.embeddings.first.add(0.5), throwsUnsupportedError);
    });

    test('carries image generation outputs and provider metadata', () {
      final result = ImageGenerationResult(
        images: [
          GeneratedImage(
            uri: Uri.parse('https://example.test/image.png'),
            mediaType: 'image/png',
          ),
        ],
        providerMetadata: ProviderMetadata.forNamespace('openai', {
          'imageId': 'img_1',
        }),
      );

      expect(result.images.single.uri.toString(),
          'https://example.test/image.png');
      expect(result.images.single.mediaType, 'image/png');
      expect(result.providerMetadata!.containsNamespace('openai'), isTrue);
      expect(
        () => result.images.add(const GeneratedImage()),
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
        profile.sharedFeature(
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
