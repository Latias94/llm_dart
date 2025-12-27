import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

/// Tests for Google provider thinking functionality
///
/// This test suite verifies that Google's thinking implementation correctly
/// handles the 'thought' boolean flag according to Google API documentation.
void main() {
  group('Google Thinking Tests', () {
    test('GoogleChatResponse correctly separates thinking and text content',
        () {
      // Mock response with both thinking and regular content
      final mockResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': 'Let me think about this problem step by step.',
                  'thought': true, // This is thinking content
                },
                {
                  'text': 'Based on my analysis, here is the answer.',
                  'thought': false, // This is regular content
                },
                {
                  'text': 'Additional regular content without thought flag.',
                  // No 'thought' field defaults to false
                },
              ],
            },
          },
        ],
        'usageMetadata': {
          'promptTokenCount': 10,
          'candidatesTokenCount': 20,
          'totalTokenCount': 30,
          'thoughtsTokenCount': 15,
        },
      };

      final response = GoogleChatResponse(mockResponse);

      // Verify thinking content extraction
      expect(response.thinking, isNotNull);
      expect(response.thinking,
          equals('Let me think about this problem step by step.'));

      // Verify text content excludes thinking
      expect(response.text, isNotNull);
      expect(
          response.text,
          equals(
              'Based on my analysis, here is the answer.\nAdditional regular content without thought flag.'));

      // Verify usage info includes reasoning tokens
      expect(response.usage, isNotNull);
      expect(response.usage!.reasoningTokens, equals(15));
    });

    test('GoogleChatResponse handles response with only thinking content', () {
      final mockResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': 'This is pure thinking content.',
                  'thought': true,
                },
                {
                  'text': 'More thinking content.',
                  'thought': true,
                },
              ],
            },
          },
        ],
      };

      final response = GoogleChatResponse(mockResponse);

      // Should have thinking content
      expect(response.thinking,
          equals('This is pure thinking content.\nMore thinking content.'));

      // Should have no regular text content
      expect(response.text, isNull);
    });

    test('GoogleChatResponse handles response with only regular content', () {
      final mockResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': 'This is regular content.',
                  'thought': false,
                },
                {
                  'text': 'More regular content.',
                  // No thought field defaults to false
                },
              ],
            },
          },
        ],
      };

      final response = GoogleChatResponse(mockResponse);

      // Should have no thinking content
      expect(response.thinking, isNull);

      // Should have regular text content
      expect(response.text,
          equals('This is regular content.\nMore regular content.'));
    });

    test('GoogleChatResponse handles empty or malformed responses', () {
      // Test empty response
      final emptyResponse = GoogleChatResponse({});
      expect(emptyResponse.thinking, isNull);
      expect(emptyResponse.text, isNull);

      // Test response with empty candidates
      final emptyCandidatesResponse = GoogleChatResponse({
        'candidates': [],
      });
      expect(emptyCandidatesResponse.thinking, isNull);
      expect(emptyCandidatesResponse.text, isNull);

      // Test response with empty parts
      final emptyPartsResponse = GoogleChatResponse({
        'candidates': [
          {
            'content': {
              'parts': [],
            },
          },
        ],
      });
      expect(emptyPartsResponse.thinking, isNull);
      expect(emptyPartsResponse.text, isNull);
    });

    test('GoogleConfig does not maintain a model capability matrix', () {
      final models = [
        'gemini-2.5-flash',
        'gemini-2.5-pro',
        'gemini-2.5-flash-lite-preview',
        'gemini-2.0-flash-thinking-exp',
        'gemini-1.5-flash',
      ];

      for (final model in models) {
        final config = GoogleConfig(apiKey: 'test', model: model);
        expect(config.supportsReasoning, isTrue);
      }
    });

    test('toString includes thinking content when present', () {
      final mockResponseWithThinking = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': 'Let me analyze this.',
                  'thought': true,
                },
                {
                  'text': 'Here is my answer.',
                  'thought': false,
                },
              ],
            },
          },
        ],
      };

      final response = GoogleChatResponse(mockResponseWithThinking);
      final stringRepresentation = response.toString();

      expect(stringRepresentation, contains('Thinking: Let me analyze this.'));
      expect(stringRepresentation, contains('Here is my answer.'));
    });

    test('toString handles response without thinking content', () {
      final mockResponseWithoutThinking = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': 'Just regular content.',
                  'thought': false,
                },
              ],
            },
          },
        ],
      };

      final response = GoogleChatResponse(mockResponseWithoutThinking);
      final stringRepresentation = response.toString();

      expect(stringRepresentation, isNot(contains('Thinking:')));
      expect(stringRepresentation, equals('Just regular content.'));
    });
  });
}
