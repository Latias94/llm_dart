import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;
import 'package:test/test.dart';

class _FakeIdentityChatModel
    implements ChatCapability, ModelIdentityCapability {
  @override
  final String modelId;

  @override
  final String providerId;

  _FakeIdentityChatModel(this.modelId) : providerId = 'fake';

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async =>
      'summary';
}

class _NoopMiddleware extends LanguageModelMiddleware {
  const _NoopMiddleware();
}

class _FakeIdentityVideoModel
    implements ExperimentalVideoGenerationCapability, ModelIdentityCapability {
  @override
  final String modelId;

  @override
  final String providerId;

  _FakeIdentityVideoModel(this.modelId) : providerId = 'fake';

  @override
  Future<ExperimentalVideoGenerationResponse> generateVideos(
    ExperimentalVideoGenerationRequest request, {
    CancelToken? cancelToken,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  group('provider registry', () {
    test('splits providerId:modelId and resolves language models', () {
      final registry = createProviderRegistry({
        'openai': ProviderRegistryEntry(
          languageModel: (modelId) => _FakeIdentityChatModel(modelId),
        ),
      });

      final model = registry.languageModel('openai:gpt-test');
      expect(model, isA<ChatCapability>());
      expect(model, isA<ModelIdentityCapability>());
      expect((model as ModelIdentityCapability).modelId, equals('gpt-test'));
    });

    test('splits providerId:modelId and resolves video models (experimental)',
        () {
      final registry = createProviderRegistry({
        'google': ProviderRegistryEntry(
          videoModel: (modelId) => _FakeIdentityVideoModel(modelId),
        ),
      });

      final model = registry.videoModel('google:veo-test');
      expect(model, isA<ExperimentalVideoGenerationCapability>());
      expect(model, isA<ModelIdentityCapability>());
      expect((model as ModelIdentityCapability).modelId, equals('veo-test'));
    });

    test('throws NoSuchModelError for invalid registry ids', () {
      final registry = createProviderRegistry({
        'openai': ProviderRegistryEntry(
          languageModel: (modelId) => _FakeIdentityChatModel(modelId),
        ),
      });

      expect(
        () => registry.languageModel('openai'),
        throwsA(allOf(
          isA<NoSuchModelError>(),
          isA<provider.NoSuchModelError>(),
        )),
      );

      expect(
        () => registry.videoModel('google'),
        throwsA(allOf(
          isA<NoSuchModelError>(),
          isA<provider.NoSuchModelError>(),
        )),
      );
    });

    test('throws NoSuchProviderError for missing providers', () {
      final registry = createProviderRegistry({
        'openai': ProviderRegistryEntry(
          languageModel: (modelId) => _FakeIdentityChatModel(modelId),
        ),
      });

      expect(
        () => registry.languageModel('missing:any'),
        throwsA(
          predicate(
            (e) =>
                e is NoSuchProviderError &&
                e.availableProviders.contains('openai'),
          ),
        ),
      );
    });

    test('throws when model type is not supported by provider entry', () {
      final registry = createProviderRegistry({
        'openai': ProviderRegistryEntry(
          languageModel: (modelId) => _FakeIdentityChatModel(modelId),
          // embeddingModel intentionally missing
        ),
      });

      expect(
        () => registry.embeddingModel('openai:text-embedding-3'),
        throwsA(isA<NoSuchModelError>()),
      );

      expect(
        () => registry.videoModel('openai:veo-test'),
        throwsA(isA<NoSuchModelError>()),
      );
    });

    test('wraps language models with middleware when configured', () {
      ChatCapability? created;

      final registry = createProviderRegistry(
        {
          'openai': ProviderRegistryEntry(
            languageModel: (modelId) {
              final m = _FakeIdentityChatModel(modelId);
              created = m;
              return m;
            },
          ),
        },
        languageModelMiddleware: const _NoopMiddleware(),
      );

      final resolved = registry.languageModel('openai:gpt-test');
      expect(created, isNotNull);
      expect(identical(created, resolved), isFalse);
      expect(resolved, isA<ModelIdentityCapability>());
      expect(
        (resolved as ModelIdentityCapability).modelId,
        equals('gpt-test'),
      );
    });
  });
}
