import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider/src/provider/provider_model_facet_support.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderModelFacetSupportResolver', () {
    const resolver = ProviderModelFacetSupportResolver();

    test('rejects null and providers without model facets', () {
      expect(resolver.supportsLanguageModels(null), isFalse);
      expect(
        resolver.supportsLanguageModels(const _PlainProvider('plain')),
        isFalse,
      );
    });

    test('treats implemented model provider interfaces as implicit support',
        () {
      const provider = _ImplicitAllModelProvider('all');

      expect(resolver.supportsLanguageModels(provider), isTrue);
      expect(resolver.supportsEmbeddingModels(provider), isTrue);
      expect(resolver.supportsImageModels(provider), isTrue);
      expect(resolver.supportsSpeechModels(provider), isTrue);
      expect(resolver.supportsTranscriptionModels(provider), isTrue);
    });

    test('requires provider specification to declare matching facets', () {
      const provider = _SpecificationLimitedProvider('limited');

      expect(resolver.supportsLanguageModels(provider), isTrue);
      expect(resolver.supportsEmbeddingModels(provider), isFalse);
      expect(resolver.supportsImageModels(provider), isFalse);
      expect(resolver.supportsSpeechModels(provider), isFalse);
      expect(resolver.supportsTranscriptionModels(provider), isFalse);
    });

    test('respects explicit provider model facet support', () {
      const provider = _DeclaredFacetProvider(
        'declared',
        supportsLanguageModels: true,
        supportsEmbeddingModels: false,
        supportsImageModels: true,
        supportsSpeechModels: false,
        supportsTranscriptionModels: true,
      );

      expect(resolver.supportsLanguageModels(provider), isTrue);
      expect(resolver.supportsEmbeddingModels(provider), isFalse);
      expect(resolver.supportsImageModels(provider), isTrue);
      expect(resolver.supportsSpeechModels(provider), isFalse);
      expect(resolver.supportsTranscriptionModels(provider), isTrue);
    });

    test('still requires the matching model provider interface', () {
      const provider = _FacetOnlyProvider('facet-only');

      expect(resolver.supportsLanguageModels(provider), isFalse);
      expect(resolver.supportsEmbeddingModels(provider), isFalse);
      expect(resolver.supportsImageModels(provider), isFalse);
      expect(resolver.supportsSpeechModels(provider), isFalse);
      expect(resolver.supportsTranscriptionModels(provider), isFalse);
    });
  });
}

final class _PlainProvider implements Provider {
  @override
  final String providerId;

  const _PlainProvider(this.providerId);

  @override
  ProviderSpecification get specification => _providerSpecification(
        providerId,
        const {},
      );
}

ProviderSpecification _providerSpecification(
  String providerId,
  Iterable<ProviderModelFacet> facets,
) {
  return ProviderSpecification(
    providerId: providerId,
    modelFacets: facets,
  );
}

final class _ImplicitAllModelProvider
    implements
        LanguageModelProvider,
        EmbeddingModelProvider,
        ImageModelProvider,
        SpeechModelProvider,
        TranscriptionModelProvider {
  @override
  final String providerId;

  const _ImplicitAllModelProvider(this.providerId);

  @override
  ProviderSpecification get specification => _providerSpecification(
        providerId,
        const {
          ProviderModelFacet.language,
          ProviderModelFacet.embedding,
          ProviderModelFacet.image,
          ProviderModelFacet.speech,
          ProviderModelFacet.transcription,
        },
      );

  @override
  LanguageModel languageModel(String modelId) => throw UnimplementedError();

  @override
  EmbeddingModel embeddingModel(String modelId) => throw UnimplementedError();

  @override
  ImageModel imageModel(String modelId) => throw UnimplementedError();

  @override
  SpeechModel speechModel(String modelId) => throw UnimplementedError();

  @override
  TranscriptionModel transcriptionModel(String modelId) {
    throw UnimplementedError();
  }
}

final class _DeclaredFacetProvider
    implements
        ProviderModelFacetSupport,
        LanguageModelProvider,
        EmbeddingModelProvider,
        ImageModelProvider,
        SpeechModelProvider,
        TranscriptionModelProvider {
  @override
  final String providerId;

  @override
  final bool supportsLanguageModels;

  @override
  final bool supportsEmbeddingModels;

  @override
  final bool supportsImageModels;

  @override
  final bool supportsSpeechModels;

  @override
  final bool supportsTranscriptionModels;

  const _DeclaredFacetProvider(
    this.providerId, {
    required this.supportsLanguageModels,
    required this.supportsEmbeddingModels,
    required this.supportsImageModels,
    required this.supportsSpeechModels,
    required this.supportsTranscriptionModels,
  });

  @override
  ProviderSpecification get specification => _providerSpecification(
        providerId,
        const {
          ProviderModelFacet.language,
          ProviderModelFacet.embedding,
          ProviderModelFacet.image,
          ProviderModelFacet.speech,
          ProviderModelFacet.transcription,
        },
      );

  @override
  LanguageModel languageModel(String modelId) => throw UnimplementedError();

  @override
  EmbeddingModel embeddingModel(String modelId) => throw UnimplementedError();

  @override
  ImageModel imageModel(String modelId) => throw UnimplementedError();

  @override
  SpeechModel speechModel(String modelId) => throw UnimplementedError();

  @override
  TranscriptionModel transcriptionModel(String modelId) {
    throw UnimplementedError();
  }
}

final class _FacetOnlyProvider implements ProviderModelFacetSupport {
  @override
  final String providerId;

  const _FacetOnlyProvider(this.providerId);

  @override
  ProviderSpecification get specification => _providerSpecification(
        providerId,
        const {
          ProviderModelFacet.language,
          ProviderModelFacet.embedding,
          ProviderModelFacet.image,
          ProviderModelFacet.speech,
          ProviderModelFacet.transcription,
        },
      );

  @override
  bool get supportsLanguageModels => true;

  @override
  bool get supportsEmbeddingModels => true;

  @override
  bool get supportsImageModels => true;

  @override
  bool get supportsSpeechModels => true;

  @override
  bool get supportsTranscriptionModels => true;
}

final class _SpecificationLimitedProvider
    implements
        LanguageModelProvider,
        EmbeddingModelProvider,
        ImageModelProvider,
        SpeechModelProvider,
        TranscriptionModelProvider {
  @override
  final String providerId;

  const _SpecificationLimitedProvider(this.providerId);

  @override
  ProviderSpecification get specification => _providerSpecification(
        providerId,
        const {
          ProviderModelFacet.language,
        },
      );

  @override
  LanguageModel languageModel(String modelId) => throw UnimplementedError();

  @override
  EmbeddingModel embeddingModel(String modelId) => throw UnimplementedError();

  @override
  ImageModel imageModel(String modelId) => throw UnimplementedError();

  @override
  SpeechModel speechModel(String modelId) => throw UnimplementedError();

  @override
  TranscriptionModel transcriptionModel(String modelId) {
    throw UnimplementedError();
  }
}
