// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/openai.dart' as openai;

/// Moderation remains a provider-owned surface.
///
/// The stable architectural lesson is not "all providers share one moderation
/// contract". It is:
/// - keep provider moderation calls behind a provider boundary
/// - translate provider category signals into app-owned policy decisions
Future<void> main() async {
  print('Content Moderation Boundary Example\n');

  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Set OPENAI_API_KEY to run this example.');
    return;
  }

  final moderationClient = llm.openai(apiKey: apiKey).moderation(
        settings: const openai.OpenAIModerationSettings(
          defaultModel: 'omni-moderation-latest',
        ),
      );

  await demonstrateProviderSignalToAppPolicy(moderationClient);
  await demonstrateBatchReviewQueue(moderationClient);
  explainBoundary();

  print('\nContent moderation example completed.');
}

Future<void> demonstrateProviderSignalToAppPolicy(
  openai.OpenAIModerationClient moderationClient,
) async {
  print('=== Provider Signal -> App Policy ===\n');

  const samples = [
    'Welcome to our Flutter community. Please be respectful and constructive.',
    'Explain how to de-escalate an angry customer without insulting them.',
    'I am frustrated with this crash report and need help debugging it.',
  ];

  for (final sample in samples) {
    final result = await moderationClient.moderateText(sample);
    final decision = AppModerationDecision.fromResult(result);

    print('Input: $sample');
    print('Decision: ${decision.action}');
    print('Reason: ${decision.reason}');
    print('Top signals: ${_topSignals(result).join(', ')}');
    print('');
  }
}

Future<void> demonstrateBatchReviewQueue(
  openai.OpenAIModerationClient moderationClient,
) async {
  print('=== Batch Review Queue ===\n');

  const samples = [
    'Please keep bug reports factual and reproducible.',
    'Summarize the incident without blaming the customer.',
    'Write a calm response to an upset user asking for a refund.',
    'Explain the platform safety rules in one paragraph.',
  ];

  final results = await moderationClient.moderateTexts(samples);

  final decisions = <AppModerationDecision>[];
  for (final result in results) {
    decisions.add(AppModerationDecision.fromResult(result));
  }

  final allowCount =
      decisions.where((decision) => decision.action == 'allow').length;
  final reviewCount =
      decisions.where((decision) => decision.action == 'review').length;
  final blockCount =
      decisions.where((decision) => decision.action == 'block').length;

  print('Inputs: ${samples.length}');
  print('Allow: $allowCount');
  print('Review: $reviewCount');
  print('Block: $blockCount');
  print('');
}

void explainBoundary() {
  print('=== Boundary Notes ===\n');
  print(
    '• Moderation taxonomy, score meanings, and endpoint semantics are '
    'provider-owned and should not be treated as a stable cross-provider model.',
  );
  print(
    '• Application code should normalize raw provider output into its own '
    '`allow` / `review` / `block` policy.',
  );
  print(
    '• If you support multiple providers, normalize them into one app policy '
    'schema and keep the raw provider evidence for audit or debugging.',
  );
  print(
    '• Keep UI labels, escalation rules, and audit logging in your app layer, '
    'not inside provider response parsing.',
  );
}

List<String> _topSignals(openai.OpenAIModerationResult result) {
  final scores = <String, double>{
    'hate': result.categoryScores.hate,
    'harassment': result.categoryScores.harassment,
    'self-harm': result.categoryScores.selfHarm,
    'sexual': result.categoryScores.sexual,
    'violence': result.categoryScores.violence,
  }.entries.toList()
    ..sort((left, right) => right.value.compareTo(left.value));

  return scores
      .take(2)
      .map((entry) => '${entry.key}=${entry.value.toStringAsFixed(3)}')
      .toList(growable: false);
}

final class AppModerationDecision {
  final String action;
  final String reason;

  const AppModerationDecision({
    required this.action,
    required this.reason,
  });

  factory AppModerationDecision.fromResult(
    openai.OpenAIModerationResult result,
  ) {
    if (result.categories.sexualMinors ||
        result.categories.selfHarmInstructions ||
        result.categories.hateThreatening ||
        result.categories.violenceGraphic) {
      return const AppModerationDecision(
        action: 'block',
        reason: 'Critical provider category triggered.',
      );
    }

    if (result.flagged ||
        result.categoryScores.harassment > 0.15 ||
        result.categoryScores.violence > 0.15 ||
        result.categoryScores.selfHarm > 0.10) {
      return const AppModerationDecision(
        action: 'review',
        reason: 'Provider signal exceeded the app review threshold.',
      );
    }

    return const AppModerationDecision(
      action: 'allow',
      reason: 'No app review threshold was crossed.',
    );
  }
}
