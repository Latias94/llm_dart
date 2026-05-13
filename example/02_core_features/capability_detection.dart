// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/anthropic.dart' as anthropic;
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/google.dart' as google;
import 'package:llm_dart/openai.dart' as openai;

const _stableExecutionCallOptions = core.CallOptions(
  timeout: Duration(seconds: 20),
);

/// Capability detection through concrete model profiles.
///
/// The current architecture follows the Vercel AI SDK style more closely:
/// choose a concrete provider facade, create a model, then inspect the model's
/// app-facing capability profile. Provider-specific native features stay in
/// typed model settings or typed invocation options.
Future<void> main() async {
  print('Capability Detection With Model Profiles\n');

  final profiles = loadExampleModelProfiles();
  printModelOverview(profiles);
  printScenarioRecommendations(profiles);
  printBoundaryGuidance();
  await demonstrateStableExecution(profiles);

  print(
      'Capability detection remains advisory; provider codecs still validate');
  print('the final request shape at runtime.');
}

List<core.ModelCapabilityProfile> loadExampleModelProfiles() {
  final models = <core.LanguageModel>[
    openai.openai(apiKey: 'demo-key').chatModel('gpt-4.1-mini'),
    openai.openai(apiKey: 'demo-key').chatModel('gpt-4o'),
    openai.openai(apiKey: 'demo-key').chatModel('o3-mini'),
    google.google(apiKey: 'demo-key').chatModel('gemini-2.5-flash'),
    anthropic.anthropic(apiKey: 'demo-key').chatModel('claude-sonnet-4-5'),
  ];

  return [
    for (final model in models)
      if (model case core.CapabilityDescribedModel(:final capabilityProfile))
        capabilityProfile,
  ];
}

void printModelOverview(List<core.ModelCapabilityProfile> profiles) {
  print('--- Concrete Model Profiles ---');

  for (final profile in profiles) {
    final features = _highSignalFeatures
        .where(profile.supports)
        .map(_featureLabel)
        .join(', ');

    print(
      '  ${profile.providerId.padRight(10)} ${profile.modelId.padRight(22)} '
      '${features.isEmpty ? 'no shared high-signal features' : features}',
    );
  }

  print('');
}

void printScenarioRecommendations(List<core.ModelCapabilityProfile> profiles) {
  print('--- Scenario Recommendations ---');

  const scenarios = [
    _CapabilityScenario(
      label: 'streaming chat',
      required: {
        core.ModelCapabilityFeatureIds.languageTextInput,
        core.ModelCapabilityFeatureIds.languageStreaming,
      },
    ),
    _CapabilityScenario(
      label: 'tool-using workflow',
      required: {
        core.ModelCapabilityFeatureIds.languageFunctionTools,
        core.ModelCapabilityFeatureIds.languageToolChoice,
      },
    ),
    _CapabilityScenario(
      label: 'structured output',
      required: {
        core.ModelCapabilityFeatureIds.languageStructuredOutput,
      },
    ),
    _CapabilityScenario(
      label: 'vision input',
      required: {
        core.ModelCapabilityFeatureIds.languageImageInput,
      },
    ),
    _CapabilityScenario(
      label: 'reasoning output',
      required: {
        core.ModelCapabilityFeatureIds.languageReasoningOutput,
      },
    ),
  ];

  for (final scenario in scenarios) {
    final matches = profiles.where(
      (profile) => profile.supportsAll(scenario.required),
    );
    print('  ${scenario.label}');
    print('    Required: ${scenario.required.map(_featureLabel).join(', ')}');
    print(
      '    Candidates: '
      '${matches.isEmpty ? 'none declared' : matches.map(_modelLabel).join(', ')}',
    );
  }

  print('');
}

void printBoundaryGuidance() {
  print('--- Boundary Guidance ---');
  print('  Capability profiles are model descriptions, not a global registry.');
  print('  Use them for UI gating, docs, and selection heuristics.');
  print('  Keep provider-native behavior in typed settings/options such as:');
  print('    - OpenAIChatModelSettings / OpenAIGenerateTextOptions');
  print('    - GoogleChatModelSettings / GoogleGenerateTextOptions');
  print('    - AnthropicChatModelSettings / AnthropicGenerateTextOptions');
  print('  Do not reintroduce a root provider registry or builder just to ask');
  print('  whether a concrete model supports a feature.');
  print('');
}

Future<void> demonstrateStableExecution(
  List<core.ModelCapabilityProfile> profiles,
) async {
  print('--- Optional Stable Execution ---');

  final selected = _selectStableModelFromEnvironment(profiles);
  if (selected == null) {
    print('  No matching API key was found for the execution demo.');
    print('  Capability inspection above works without credentials.\n');
    return;
  }

  print('  Selected model: ${selected.modelLabel}');

  try {
    final result = await core.generateTextCall(
      model: selected.model,
      messages: [
        core.SystemModelMessage.text(
          'You are a concise architecture assistant. Respond in one paragraph.',
        ),
        core.UserModelMessage.text(
          'Explain why capability metadata helps selection but cannot replace runtime validation.',
        ),
      ],
      options: const core.GenerateTextOptions(maxOutputTokens: 120),
      callOptions: _stableExecutionCallOptions,
    );

    print('  Response: ${_truncate(result.text)}');
  } catch (error) {
    print('  Stable call failed: $error');
    print('  This is why capability profiles stay advisory.');
  }

  print('');
}

_SelectedModel? _selectStableModelFromEnvironment(
  List<core.ModelCapabilityProfile> profiles,
) {
  for (final profile in profiles) {
    if (!profile.supports(core.ModelCapabilityFeatureIds.languageTextInput)) {
      continue;
    }

    switch (profile.providerId) {
      case 'openai':
        final apiKey = Platform.environment['OPENAI_API_KEY'];
        if (apiKey != null && apiKey.isNotEmpty) {
          return _SelectedModel(
            modelLabel: _modelLabel(profile),
            model: openai.openai(apiKey: apiKey).chatModel(profile.modelId),
          );
        }
      case 'anthropic':
        final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
        if (apiKey != null && apiKey.isNotEmpty) {
          return _SelectedModel(
            modelLabel: _modelLabel(profile),
            model:
                anthropic.anthropic(apiKey: apiKey).chatModel(profile.modelId),
          );
        }
      case 'google':
        final apiKey = Platform.environment['GOOGLE_API_KEY'];
        if (apiKey != null && apiKey.isNotEmpty) {
          return _SelectedModel(
            modelLabel: _modelLabel(profile),
            model: google.google(apiKey: apiKey).chatModel(profile.modelId),
          );
        }
    }
  }

  return null;
}

String _modelLabel(core.ModelCapabilityProfile profile) {
  return '${profile.providerId}/${profile.modelId}';
}

String _featureLabel(String featureId) {
  return switch (featureId) {
    core.ModelCapabilityFeatureIds.languageStreaming => 'streaming',
    core.ModelCapabilityFeatureIds.languageFunctionTools => 'function tools',
    core.ModelCapabilityFeatureIds.languageToolChoice => 'tool choice',
    core.ModelCapabilityFeatureIds.languageStructuredOutput =>
      'structured output',
    core.ModelCapabilityFeatureIds.languageReasoningOutput =>
      'reasoning output',
    core.ModelCapabilityFeatureIds.languageTextInput => 'text input',
    core.ModelCapabilityFeatureIds.languageImageInput => 'image input',
    core.ModelCapabilityFeatureIds.languageFileInput => 'file input',
    core.ModelCapabilityFeatureIds.languageSourceOutput => 'source output',
    _ => featureId,
  };
}

String _truncate(String text, {int maxLength = 220}) {
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= maxLength) {
    return normalized;
  }

  return '${normalized.substring(0, maxLength)}...';
}

const _highSignalFeatures = [
  core.ModelCapabilityFeatureIds.languageStreaming,
  core.ModelCapabilityFeatureIds.languageFunctionTools,
  core.ModelCapabilityFeatureIds.languageToolChoice,
  core.ModelCapabilityFeatureIds.languageStructuredOutput,
  core.ModelCapabilityFeatureIds.languageReasoningOutput,
  core.ModelCapabilityFeatureIds.languageImageInput,
  core.ModelCapabilityFeatureIds.languageFileInput,
  core.ModelCapabilityFeatureIds.languageSourceOutput,
];

final class _CapabilityScenario {
  final String label;
  final Set<String> required;

  const _CapabilityScenario({
    required this.label,
    required this.required,
  });
}

final class _SelectedModel {
  final String modelLabel;
  final core.LanguageModel model;

  const _SelectedModel({
    required this.modelLabel,
    required this.model,
  });
}
