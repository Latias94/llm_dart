import 'package:llm_dart/models/moderation_models.dart';
import 'package:llm_dart/providers/openai/client.dart';
import 'package:llm_dart/providers/openai/config.dart';
import 'package:llm_dart/src/compatibility/providers/openai/moderation.dart';
import 'package:llm_dart/src/compatibility/providers/openai/openai_moderation_support.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI moderation compatibility shell', () {
    test('moderate keeps request shaping and response parsing', () async {
      final client = _FakeOpenAIClient(
        const OpenAIConfig(apiKey: 'test-key', model: 'gpt-4o'),
      )..response = _moderationResponseJson(
          flagged: false,
          categoryOverrides: const {
            'harassment': false,
          },
          scoreOverrides: const {
            'harassment': 0.05,
          },
        );
      final moderation = OpenAIModeration(client, client.config);

      final response = await moderation.moderate(
        const ModerationRequest(
          input: ['Hello world'],
          model: 'omni-moderation-latest',
        ),
      );

      expect(client.lastEndpoint, 'moderations');
      expect(client.lastBody, {
        'input': ['Hello world'],
        'model': 'omni-moderation-latest',
      });
      expect(response.model, 'omni-moderation-latest');
      expect(response.results, hasLength(1));
      expect(response.results.single.flagged, isFalse);
    });

    test('analyzeContent keeps analysis mapping and recommendations', () async {
      final client = _FakeOpenAIClient(
        const OpenAIConfig(apiKey: 'test-key', model: 'gpt-4o'),
      )..response = _moderationResponseJson(
          flagged: true,
          categoryOverrides: const {
            'harassment': true,
            'violence': true,
          },
          scoreOverrides: const {
            'harassment': 0.81,
            'violence': 0.55,
          },
        );
      final moderation = OpenAIModeration(client, client.config);

      final analysis = await moderation.analyzeContent('Aggressive message');

      expect(analysis.text, 'Aggressive message');
      expect(analysis.flagged, isTrue);
      expect(analysis.highestRiskCategory, 'harassment');
      expect(analysis.riskLevel, 'high');
      expect(
        analysis.recommendations,
        contains('Remove harassing language.'),
      );
      expect(
        analysis.recommendations,
        contains('Remove violent content.'),
      );
    });
  });

  group('OpenAI moderation support', () {
    const support = OpenAIModerationSupport();

    test('buildStats handles empty and all-safe batches safely', () {
      final emptyStats = support.buildStats(const [], const []);
      expect(emptyStats.totalTexts, 0);
      expect(emptyStats.flaggedTexts, 0);
      expect(emptyStats.safeTexts, 0);
      expect(emptyStats.flaggedPercentage, 0);
      expect(emptyStats.categoryBreakdown, isEmpty);
      expect(emptyStats.mostCommonViolation, 'none');

      final safeStats = support.buildStats(
        const ['hello', 'world'],
        [
          _result(flagged: false),
          _result(flagged: false),
        ],
      );
      expect(safeStats.totalTexts, 2);
      expect(safeStats.flaggedTexts, 0);
      expect(safeStats.safeTexts, 2);
      expect(safeStats.flaggedPercentage, 0);
      expect(safeStats.categoryBreakdown, isEmpty);
      expect(safeStats.mostCommonViolation, 'none');
    });

    test('buildStats aggregates flagged categories consistently', () {
      final stats = support.buildStats(
        const ['one', 'two', 'three'],
        [
          _result(
            flagged: true,
            categoryOverrides: const {'harassment': true},
          ),
          _result(
            flagged: true,
            categoryOverrides: const {'harassment': true, 'violence': true},
          ),
          _result(flagged: false),
        ],
      );

      expect(stats.totalTexts, 3);
      expect(stats.flaggedTexts, 2);
      expect(stats.safeTexts, 1);
      expect(stats.flaggedPercentage, closeTo(66.666, 0.01));
      expect(stats.categoryBreakdown['harassment'], 2);
      expect(stats.categoryBreakdown['violence'], 1);
      expect(stats.mostCommonViolation, 'harassment');
    });
  });
}

final class _FakeOpenAIClient extends OpenAIClient {
  Map<String, dynamic> response = const {};
  String? lastEndpoint;
  Map<String, dynamic>? lastBody;

  _FakeOpenAIClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    cancelToken,
  }) async {
    lastEndpoint = endpoint;
    lastBody = body;
    return response;
  }
}

Map<String, dynamic> _moderationResponseJson({
  required bool flagged,
  Map<String, bool>? categoryOverrides,
  Map<String, double>? scoreOverrides,
}) {
  final categories = {
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
    ...?categoryOverrides,
  };
  final scores = {
    'hate': 0.01,
    'hate/threatening': 0.01,
    'harassment': 0.01,
    'harassment/threatening': 0.01,
    'self-harm': 0.01,
    'self-harm/intent': 0.01,
    'self-harm/instructions': 0.01,
    'sexual': 0.01,
    'sexual/minors': 0.01,
    'violence': 0.01,
    'violence/graphic': 0.01,
    ...?scoreOverrides,
  };

  return {
    'id': 'modr_1',
    'model': 'omni-moderation-latest',
    'results': [
      {
        'flagged': flagged,
        'categories': categories,
        'category_scores': scores,
      },
    ],
  };
}

ModerationResult _result({
  required bool flagged,
  Map<String, bool>? categoryOverrides,
}) {
  final categories = ModerationCategories.fromJson({
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
    ...?categoryOverrides,
  });

  return ModerationResult(
    flagged: flagged,
    categories: categories,
    categoryScores: ModerationCategoryScores.fromJson({
      'hate': 0.01,
      'hate/threatening': 0.01,
      'harassment': 0.01,
      'harassment/threatening': 0.01,
      'self-harm': 0.01,
      'self-harm/intent': 0.01,
      'self-harm/instructions': 0.01,
      'sexual': 0.01,
      'sexual/minors': 0.01,
      'violence': 0.01,
      'violence/graphic': 0.01,
    }),
  );
}
