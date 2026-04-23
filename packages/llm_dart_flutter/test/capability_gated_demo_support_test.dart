import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/capability_gated_demo_support.dart';

void main() {
  group('capability-gated demo support', () {
    test('builds a reasoning-first policy for gpt-5.4', () {
      final preset = capabilityGatedDemoPresets.firstWhere(
        (preset) => preset.id == 'openai-gpt-5.4',
      );

      final policy = buildChatComposerPolicy(preset.profile);

      expect(policy.routeLabel, 'responses');
      expect(policy.canAttachImages, isTrue);
      expect(policy.canAttachFiles, isTrue);
      expect(policy.canUseStructuredOutput, isTrue);
      expect(policy.canShowReasoningPanel, isTrue);
      expect(policy.canShowSourcesPanel, isFalse);
      expect(policy.providerBadges, contains('Responses lifecycle'));
    });

    test('recognizes xAI source-aware routing and badges', () {
      final preset = capabilityGatedDemoPresets.firstWhere(
        (preset) => preset.id == 'xai-grok-3',
      );

      final policy = buildChatComposerPolicy(preset.profile);

      expect(
        preset.profile.supports(ModelCapabilityFeatureIds.languageSourceOutput),
        isTrue,
      );
      expect(policy.canShowSourcesPanel, isTrue);
      expect(policy.providerBadges, contains('xAI live search'));
    });

    test('suggests a fallback when source output is missing', () {
      final selected = capabilityGatedDemoPresets.firstWhere(
        (preset) => preset.id == 'openai-gpt-4.1-mini',
      );

      final fallback = suggestFallbackPreset(
        selected: selected,
        candidates: capabilityGatedDemoPresets,
        requiredFeatures: sourceBackedAnswerFeatureIds,
      );

      expect(fallback, isNotNull);
      expect(
        fallback!.profile.supports(
          ModelCapabilityFeatureIds.languageSourceOutput,
        ),
        isTrue,
      );
    });

    test('builds an inferred multimodal policy for Ollama vision chat', () {
      final preset = capabilityGatedDemoPresets.firstWhere(
        (preset) => preset.id == 'ollama-llama3.2-vision',
      );

      final policy = buildChatComposerPolicy(preset.profile);

      expect(policy.routeLabel, 'chat');
      expect(policy.canAttachImages, isTrue);
      expect(policy.canAttachFiles, isFalse);
      expect(policy.canUseStructuredOutput, isTrue);
      expect(policy.canShowReasoningPanel, isFalse);
      expect(
        policy.providerBadges,
        contains('Ollama auto tool selection'),
      );
    });
  });
}
