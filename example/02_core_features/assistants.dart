// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/providers/openai/openai.dart' as openai_compat;

/// Assistants remain a provider-owned lifecycle boundary.
///
/// This example shows two different paths:
/// - the stable shared path for assistant-like app behavior
/// - the explicit OpenAI compatibility path for persisted assistant objects
///
/// New chat apps should usually start from `AI.openai(...).chatModel(...)`.
/// Only drop to the compatibility provider surface when you truly need the
/// provider-owned assistant lifecycle.
Future<void> main() async {
  print('Assistants Boundary Example\n');

  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Set OPENAI_API_KEY to run this example.');
    return;
  }

  await demonstrateStableAssistantLikePath(apiKey);
  await demonstrateOpenAIAssistantBoundary(apiKey);
  explainBoundary();

  print('\nAssistants example completed.');
}

Future<void> demonstrateStableAssistantLikePath(String apiKey) async {
  print('=== Stable Assistant-Like Path ===\n');

  final model = llm.AI.openai(apiKey: apiKey).chatModel('gpt-4.1-mini');
  final result = await core.generateTextCall(
    model: model,
    prompt: [
      core.SystemPromptMessage.text(
        'You are a release copilot. Keep answers brief, structured, and action-oriented.',
      ),
      core.UserPromptMessage.text(
        'Summarize today\'s release checklist for a Flutter chat app. '
        'Include testing, rollout, and rollback notes.',
      ),
    ],
    options: const core.GenerateTextOptions(
      temperature: 0.2,
      maxOutputTokens: 300,
    ),
  );

  print(result.text);
  print('');
}

Future<void> demonstrateOpenAIAssistantBoundary(String apiKey) async {
  print('=== Provider-Owned OpenAI Assistant Lifecycle Boundary ===\n');

  final assistantClient = openai_compat.createOpenAIProvider(
    apiKey: apiKey,
    model: 'gpt-4o',
  );

  openai_compat.Assistant? assistant;

  try {
    assistant = await assistantClient.createAssistant(
      const openai_compat.CreateAssistantRequest(
        model: 'gpt-4o',
        name: 'Release Ops Copilot',
        description: 'Temporary example assistant for release coordination.',
        instructions:
            'Help the team review rollout, verification, and rollback tasks.',
        tools: [
          openai_compat.CodeInterpreterTool(),
          openai_compat.FileSearchTool(maxNumResults: 3),
        ],
        metadata: {
          'example': 'core_features_assistants',
          'lifecycle': 'temporary',
        },
      ),
    );

    print('Created assistant: ${assistant.id}');
    print('Name: ${assistant.name}');
    print('Model: ${assistant.model}');
    print('Tools: ${_toolList(assistant.tools)}');

    final listResponse = await assistantClient.listAssistants(
      const openai_compat.ListAssistantsQuery(
        limit: 5,
        order: 'desc',
      ),
    );
    print('Recent assistants returned: ${listResponse.data.length}');

    final retrieved = await assistantClient.retrieveAssistant(assistant.id);
    print('Retrieved metadata: ${retrieved.metadata}');

    final updated = await assistantClient.modifyAssistant(
      assistant.id,
      const openai_compat.ModifyAssistantRequest(
        name: 'Release Ops Copilot (updated)',
        metadata: {
          'example': 'core_features_assistants',
          'lifecycle': 'updated-temporary',
        },
      ),
    );
    print('Updated assistant name: ${updated.name}');
  } finally {
    if (assistant != null) {
      final deleted = await assistantClient.deleteAssistant(assistant.id);
      print('Deleted temporary assistant: ${deleted.deleted}');
    }
  }

  print('');
}

void explainBoundary() {
  print('=== Boundary Notes ===\n');
  print(
    '• The stable shared facade does not currently define a cross-provider '
    'assistant lifecycle contract.',
  );
  print(
    '• OpenAI assistant objects, tool resources, and stored lifecycle state '
    'remain provider-owned compatibility APIs.',
  );
  print(
    '• For most Flutter chat apps, prefer normal chat models, app-owned '
    'conversation history, tool replay, and structured outputs before '
    'reaching for assistants.',
  );
  print(
    '• Only introduce assistant IDs, stored threads, or provider-managed '
    'workspaces when product requirements truly need them, and keep that '
    'logic isolated behind an OpenAI-specific application boundary.',
  );
}

String _toolList(List<openai_compat.AssistantTool> tools) {
  if (tools.isEmpty) {
    return '<none>';
  }

  return tools.map((tool) => tool.type.value).join(', ');
}
