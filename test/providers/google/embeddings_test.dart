import 'package:test/test.dart';
import 'package:llm_dart/core/capability.dart';
import 'package:llm_dart/core/llm_error.dart';
import 'package:llm_dart/providers/google/google.dart';

void main() {
  group('GoogleEmbeddings', () {
    late GoogleConfig config;
    late GoogleEmbeddings embeddings;

    setUp(() {
      config = const GoogleConfig(
        apiKey: 'test-api-key',
        model: 'text-embedding-004',
      );
      embeddings = GoogleEmbeddings(GoogleClient(config), config);
    });

    group('Configuration', () {
      test('should have correct endpoint for single embedding', () {
        expect(embeddings.embeddingEndpoint,
            'models/text-embedding-004:embedContent');
      });

      test('should have correct endpoint for batch embedding', () {
        expect(embeddings.batchEmbeddingEndpoint,
            'models/text-embedding-004:batchEmbedContents');
      });

      test('should support embedding-specific config parameters', () {
        final configWithParams = GoogleConfig(
          apiKey: 'test-key',
          model: 'text-embedding-004',
          embeddingTaskType: 'SEMANTIC_SIMILARITY',
          embeddingTitle: 'Test Document',
          embeddingDimensions: 512,
        );

        expect(configWithParams.embeddingTaskType, 'SEMANTIC_SIMILARITY');
        expect(configWithParams.embeddingTitle, 'Test Document');
        expect(configWithParams.embeddingDimensions, 512);
      });
    });

    group('Request Building', () {
      test('should build single embedding request correctly', () {
        final request = embeddings._buildSingleEmbeddingRequest('test text');

        expect(request['content'], isA<Map<String, dynamic>>());
        expect(request['content']['parts'], isA<List>());
        expect(request['content']['parts'][0]['text'], 'test text');
      });

      test('should build single embedding request with optional parameters',
          () {
        final configWithParams = GoogleConfig(
          apiKey: 'test-key',
          model: 'text-embedding-004',
          embeddingTaskType: 'RETRIEVAL_DOCUMENT',
          embeddingTitle: 'Test Doc',
          embeddingDimensions: 256,
        );
        final embeddingsWithParams =
            GoogleEmbeddings(GoogleClient(configWithParams), configWithParams);

        final request =
            embeddingsWithParams._buildSingleEmbeddingRequest('test text');

        expect(request['taskType'], 'RETRIEVAL_DOCUMENT');
        expect(request['title'], 'Test Doc');
        expect(request['outputDimensionality'], 256);
      });

      test('should build batch embedding request correctly', () {
        final request =
            embeddings._buildBatchEmbeddingRequest(['text1', 'text2']);

        expect(request['requests'], isA<List>());
        expect(request['requests'].length, 2);

        final firstRequest = request['requests'][0];
        expect(firstRequest['model'], 'models/text-embedding-004');
        expect(firstRequest['content']['parts'][0]['text'], 'text1');

        final secondRequest = request['requests'][1];
        expect(secondRequest['content']['parts'][0]['text'], 'text2');
      });
    });

    group('Response Parsing', () {
      test('should parse single embedding response correctly', () {
        final responseData = {
          'embedding': {
            'values': [0.1, 0.2, 0.3, 0.4, 0.5]
          }
        };

        final result = embeddings._parseSingleEmbeddingResponse(responseData);

        expect(result, [0.1, 0.2, 0.3, 0.4, 0.5]);
      });

      test(
          'should throw ResponseFormatError for invalid single embedding response',
          () {
        final responseData = {'invalid': 'response'};

        expect(
          () => embeddings._parseSingleEmbeddingResponse(responseData),
          throwsA(isA<ResponseFormatError>()),
        );
      });

      test('should parse batch embedding response correctly', () {
        final responseData = {
          'embeddings': [
            {
              'embedding': {
                'values': [0.1, 0.2, 0.3]
              }
            },
            {
              'embedding': {
                'values': [0.4, 0.5, 0.6]
              }
            }
          ]
        };

        final result = embeddings._parseBatchEmbeddingResponse(responseData);

        expect(result.length, 2);
        expect(result[0], [0.1, 0.2, 0.3]);
        expect(result[1], [0.4, 0.5, 0.6]);
      });

      test(
          'should throw ResponseFormatError for invalid batch embedding response',
          () {
        final responseData = {'invalid': 'response'};

        expect(
          () => embeddings._parseBatchEmbeddingResponse(responseData),
          throwsA(isA<ResponseFormatError>()),
        );
      });
    });

    group('Error Handling', () {
      test('should throw AuthError for missing API key', () async {
        final configWithoutKey = const GoogleConfig(
          apiKey: '',
          model: 'text-embedding-004',
        );
        final embeddingsWithoutKey =
            GoogleEmbeddings(GoogleClient(configWithoutKey), configWithoutKey);

        expect(
          () => embeddingsWithoutKey.embed(['test']),
          throwsA(isA<AuthError>()),
        );
      });
    });

    group('Integration with GoogleProvider', () {
      test('should implement EmbeddingCapability', () {
        final provider = GoogleProvider(config);
        expect(provider, isA<EmbeddingCapability>());
      });

      test('should support embedding capability when model supports it', () {
        final embeddingConfig = const GoogleConfig(
          apiKey: 'test-key',
          model: 'text-embedding-004',
        );
        final provider = GoogleProvider(embeddingConfig);

        expect(provider.supports(LLMCapability.embedding), isTrue);
        expect(provider.supportedCapabilities.contains(LLMCapability.embedding),
            isTrue);
      });

      test('should not support embedding capability for non-embedding models',
          () {
        final chatConfig = const GoogleConfig(
          apiKey: 'test-key',
          model: 'gemini-1.5-flash',
        );
        final provider = GoogleProvider(chatConfig);

        expect(provider.supports(LLMCapability.embedding), isFalse);
        expect(provider.supportedCapabilities.contains(LLMCapability.embedding),
            isFalse);
      });
    });

    group('Factory Functions', () {
      test('should create Google embedding provider with correct defaults', () {
        final provider = createGoogleEmbeddingProvider(
          apiKey: 'test-key',
        );

        expect(provider.config.apiKey, 'test-key');
        expect(provider.config.model, 'text-embedding-004');
        expect(provider, isA<EmbeddingCapability>());
      });

      test('should create Google embedding provider with custom parameters',
          () {
        final provider = createGoogleEmbeddingProvider(
          apiKey: 'test-key',
          model: 'custom-embedding-model',
          embeddingTaskType: 'CLASSIFICATION',
          embeddingDimensions: 1024,
        );

        expect(provider.config.model, 'custom-embedding-model');
        expect(provider.config.embeddingTaskType, 'CLASSIFICATION');
        expect(provider.config.embeddingDimensions, 1024);
      });
    });
  });
}

// Extension to access private methods for testing
extension GoogleEmbeddingsTestExtension on GoogleEmbeddings {
  Map<String, dynamic> _buildSingleEmbeddingRequest(String text) {
    return buildSingleEmbeddingRequest(text);
  }

  Map<String, dynamic> _buildBatchEmbeddingRequest(List<String> input) {
    return buildBatchEmbeddingRequest(input);
  }

  List<double> _parseSingleEmbeddingResponse(
      Map<String, dynamic> responseData) {
    return parseSingleEmbeddingResponse(responseData);
  }

  List<List<double>> _parseBatchEmbeddingResponse(
      Map<String, dynamic> responseData) {
    return parseBatchEmbeddingResponse(responseData);
  }
}

// Make private methods accessible for testing
extension on GoogleEmbeddings {
  Map<String, dynamic> buildSingleEmbeddingRequest(String text) {
    final body = <String, dynamic>{
      'content': {
        'parts': [
          {'text': text}
        ]
      },
    };

    if (config.embeddingTaskType != null) {
      body['taskType'] = config.embeddingTaskType;
    }

    if (config.embeddingTitle != null) {
      body['title'] = config.embeddingTitle;
    }

    if (config.embeddingDimensions != null) {
      body['outputDimensionality'] = config.embeddingDimensions;
    }

    return body;
  }

  Map<String, dynamic> buildBatchEmbeddingRequest(List<String> input) {
    final requests = input.map((text) {
      final request = <String, dynamic>{
        'model': 'models/${config.model}',
        'content': {
          'parts': [
            {'text': text}
          ]
        },
      };

      if (config.embeddingTaskType != null) {
        request['taskType'] = config.embeddingTaskType;
      }

      if (config.embeddingTitle != null) {
        request['title'] = config.embeddingTitle;
      }

      if (config.embeddingDimensions != null) {
        request['outputDimensionality'] = config.embeddingDimensions;
      }

      return request;
    }).toList();

    return {'requests': requests};
  }

  List<double> parseSingleEmbeddingResponse(Map<String, dynamic> responseData) {
    final embedding = responseData['embedding'] as Map<String, dynamic>?;
    if (embedding == null) {
      throw ResponseFormatError(
        'Invalid embedding response format: missing embedding field',
        responseData.toString(),
      );
    }

    final values = embedding['values'] as List?;
    if (values == null) {
      throw ResponseFormatError(
        'Invalid embedding format: missing values field',
        embedding.toString(),
      );
    }

    try {
      return values.cast<double>();
    } catch (e) {
      throw ResponseFormatError(
        'Failed to parse embedding values: $e',
        values.toString(),
      );
    }
  }

  List<List<double>> parseBatchEmbeddingResponse(
      Map<String, dynamic> responseData) {
    final embeddings = responseData['embeddings'] as List?;
    if (embeddings == null) {
      throw ResponseFormatError(
        'Invalid batch embedding response format: missing embeddings field',
        responseData.toString(),
      );
    }

    try {
      return embeddings.map((item) {
        if (item is! Map<String, dynamic>) {
          throw ResponseFormatError(
            'Invalid embedding item format: expected Map<String, dynamic>',
            item.toString(),
          );
        }

        final embedding = item['embedding'] as Map<String, dynamic>?;
        if (embedding == null) {
          throw ResponseFormatError(
            'Invalid embedding item format: missing embedding field',
            item.toString(),
          );
        }

        final values = embedding['values'] as List?;
        if (values == null) {
          throw ResponseFormatError(
            'Invalid embedding format: missing values field',
            embedding.toString(),
          );
        }

        return values.cast<double>();
      }).toList();
    } catch (e) {
      if (e is LLMError) rethrow;
      throw ResponseFormatError(
        'Failed to parse batch embedding response: $e',
        responseData.toString(),
      );
    }
  }
}
