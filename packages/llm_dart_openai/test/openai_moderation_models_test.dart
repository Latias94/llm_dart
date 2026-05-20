import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI moderation models', () {
    test('preserves category key order for booleans and scores', () {
      const categories = OpenAIModerationCategories(
        hate: true,
        hateThreatening: false,
        harassment: true,
        harassmentThreatening: false,
        selfHarm: false,
        selfHarmIntent: true,
        selfHarmInstructions: false,
        sexual: false,
        sexualMinors: false,
        violence: true,
        violenceGraphic: false,
      );
      const scores = OpenAIModerationCategoryScores(
        hate: 0.1,
        hateThreatening: 0.2,
        harassment: 0.3,
        harassmentThreatening: 0.4,
        selfHarm: 0.5,
        selfHarmIntent: 0.6,
        selfHarmInstructions: 0.7,
        sexual: 0.8,
        sexualMinors: 0.9,
        violence: 1.0,
        violenceGraphic: 1.1,
      );

      expect(categories.flaggedCategories, [
        'hate',
        'harassment',
        'self-harm/intent',
        'violence',
      ]);
      expect(categories.toJson().keys, [
        'hate',
        'hate/threatening',
        'harassment',
        'harassment/threatening',
        'self-harm',
        'self-harm/intent',
        'self-harm/instructions',
        'sexual',
        'sexual/minors',
        'violence',
        'violence/graphic',
      ]);
      expect(scores.toJson()['violence/graphic'], 1.1);
    });

    test('decodes moderation responses with path-aware category errors', () {
      expect(
        () => OpenAIModerationResponse.fromJson({
          'id': 'modr_123',
          'model': 'omni-moderation-latest',
          'results': [
            {
              'flagged': true,
              'categories': {
                ..._allCategoryBooleans(),
                'sexual/minors': 'false',
              },
              'category_scores': _allCategoryScores(),
            },
          ],
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('categories.sexual/minors'),
          ),
        ),
      );
    });

    test('round-trips moderation response models', () {
      final response = OpenAIModerationResponse.fromJson({
        'id': 'modr_123',
        'model': 'omni-moderation-latest',
        'results': [
          {
            'flagged': true,
            'categories': {
              ..._allCategoryBooleans(),
              'violence/graphic': true,
            },
            'category_scores': _allCategoryScores(),
          },
        ],
      });

      expect(response.id, 'modr_123');
      expect(response.results.single.categories.violenceGraphic, isTrue);
      expect(response.results.single.categoryScores.harassment, 0.0);
      expect(response.toJson(), {
        'id': 'modr_123',
        'model': 'omni-moderation-latest',
        'results': [
          {
            'flagged': true,
            'categories': {
              ..._allCategoryBooleans(),
              'violence/graphic': true,
            },
            'category_scores': _allCategoryScores(),
          },
        ],
      });
    });
  });
}

Map<String, bool> _allCategoryBooleans() {
  return {
    'hate': false,
    'hate/threatening': false,
    'harassment': false,
    'harassment/threatening': false,
    'self-harm': false,
    'self-harm/intent': false,
    'self-harm/instructions': false,
    'sexual': false,
    'sexual/minors': false,
    'violence': false,
    'violence/graphic': false,
  };
}

Map<String, double> _allCategoryScores() {
  return {
    'hate': 0.0,
    'hate/threatening': 0.0,
    'harassment': 0.0,
    'harassment/threatening': 0.0,
    'self-harm': 0.0,
    'self-harm/intent': 0.0,
    'self-harm/instructions': 0.0,
    'sexual': 0.0,
    'sexual/minors': 0.0,
    'violence': 0.0,
    'violence/graphic': 0.0,
  };
}
