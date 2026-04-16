// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/models/moderation_models.dart';
import 'package:llm_dart/providers/openai/openai.dart' as openai_compat;

/// Moderation remains a provider-owned compatibility surface.
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

  final provider = openai_compat.createOpenAIProvider(
    apiKey: apiKey,
    model: 'gpt-4o',
  );

  await demonstrateSingleInputPolicy(provider);
  await demonstrateBatchReviewQueue(provider);
  explainBoundary();

  print('\nContent moderation example completed.');
}

Future<void> demonstrateSingleInputPolicy(
  openai_compat.OpenAIProvider provider,
) async {
  print('=== Provider Signal -> App Policy ===\n');

  const samples = [
    'Welcome to our Flutter community. Please be respectful and constructive.',
    'Explain how to de-escalate an angry customer without insulting them.',
    'I am frustrated with this crash report and need help debugging it.',
  ];

  for (final sample in samples) {
    final response = await provider.moderate(
      const ModerationRequest(
        input: <String>[],
      ).copyWithInput(sample),
    );
    final result = response.results.first;
    final decision = AppModerationDecision.fromResult(result);

    print('Input: $sample');
    print('Decision: ${decision.action}');
    print('Reason: ${decision.reason}');
    print('Top signals: ${_topSignals(result).join(', ')}');
    print('');
  }
}

Future<void> demonstrateBatchReviewQueue(
  openai_compat.OpenAIProvider provider,
) async {
  print('=== Batch Review Queue ===\n');

  const samples = [
    'Please keep bug reports factual and reproducible.',
    'Summarize the incident without blaming the customer.',
    'Write a calm response to an upset user asking for a refund.',
    'Explain the platform safety rules in one paragraph.',
  ];

  final response = await provider.moderate(
    const ModerationRequest(
      input: samples,
    ),
  );

  final decisions = <AppModerationDecision>[];
  for (final result in response.results) {
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
    '• Keep UI labels, escalation rules, and audit logging in your app layer, '
    'not inside provider response parsing.',
  );
}

List<String> _topSignals(ModerationResult result) {
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

  factory AppModerationDecision.fromResult(ModerationResult result) {
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

extension on ModerationRequest {
  ModerationRequest copyWithInput(Object input) {
    return ModerationRequest(
      input: input,
      model: model,
    );
  }
}
