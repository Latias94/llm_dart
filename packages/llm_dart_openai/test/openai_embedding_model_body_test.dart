import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_openai/src/embedding/openai_embedding_model_body.dart';
import 'package:llm_dart_openai/src/embedding/openai_embedding_model_request.dart';
import 'package:llm_dart_openai/src/embedding/openai_embedding_options.dart';
import 'package:llm_dart_openai/src/language/openai_generate_text_options.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI embedding body projection', () {
    test('maps embedding request and provider options to OpenAI JSON fields',
        () {
      final body = buildOpenAIEmbeddingRequestBody(
        modelId: 'text-embedding-3-small',
        request: EmbedRequest(
          values: ['hello', 'world'],
          dimensions: 256,
          callOptions: CallOptions(
            providerOptions: OpenAIEmbedOptions(
              encodingFormat: 'float',
              user: 'user_123',
            ),
          ),
        ),
        options: const OpenAIEmbedOptions(
          encodingFormat: 'float',
          user: 'user_123',
        ),
      );

      expect(
        body,
        {
          'model': 'text-embedding-3-small',
          'input': ['hello', 'world'],
          'dimensions': 256,
          'encoding_format': 'float',
          'user': 'user_123',
        },
      );
    });

    test('defaults encoding format to float', () {
      final body = buildOpenAIEmbeddingRequestBody(
        modelId: 'text-embedding-3-small',
        request: EmbedRequest(values: const ['hello']),
        options: null,
      );

      expect(
        body,
        {
          'model': 'text-embedding-3-small',
          'input': ['hello'],
          'encoding_format': 'float',
        },
      );
    });

    test('resolves embedding options from provider options bag', () {
      final options = resolveOpenAIEmbeddingProviderOptions(
        CallOptions(
          providerOptions: ProviderOptionsBag.forProvider('openai', {
            'encoding_format': 'base64',
            'user': 'user_bag',
          }),
        ),
      );
      final body = buildOpenAIEmbeddingRequestBody(
        modelId: 'text-embedding-3-small',
        request: EmbedRequest(values: const ['hello']),
        options: options,
      );

      expect(body['encoding_format'], 'base64');
      expect(body['user'], 'user_bag');
    });

    test('rejects language provider options for embedding models', () {
      expect(
        () => resolveOpenAIEmbeddingProviderOptions(
          const CallOptions(
            providerOptions: OpenAIGenerateTextOptions(user: 'user_123'),
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('OpenAIEmbedOptions for OpenAI-family embedding models'),
          ),
        ),
      );
    });
  });
}
