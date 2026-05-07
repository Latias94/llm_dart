// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/core/capability.dart' as compat_core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/models/chat_models.dart' as compat_chat;
import 'package:llm_dart/openai.dart' as openai;
import 'package:llm_dart/providers/openai/openai.dart' as openai_compat;

/// Migration-boundary demo for the old `buildOpenAIResponses()` helper.
///
/// This file keeps the old name so users searching for that helper land on the
/// right migration guidance:
/// - new app-facing code should stay on `AI.openai(...).chatModel(...)`
/// - raw response lifecycle APIs belong to the narrower OpenAI provider-owned
///   compatibility surface
///
/// If migration code still uses `buildOpenAIResponses()`, treat it as a frozen
/// convenience alias for the direct provider configuration shown below.
Future<void> main() async {
  print('OpenAI Responses Boundary Demo\n');

  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Please set OPENAI_API_KEY environment variable');
    return;
  }

  await demonstrateStableFirstAlternative(apiKey);
  await demonstrateDirectCompatibilityEquivalent(apiKey);
  await demonstrateGuardrails(apiKey);

  print('OpenAI Responses boundary demo completed!');
}

Future<void> demonstrateStableFirstAlternative(String apiKey) async {
  print('--- Stable-First Alternative ---');

  try {
    final model = llm.AI
        .openai(
          apiKey: apiKey,
        )
        .chatModel(
          'gpt-4o',
          settings: const openai.OpenAIChatModelSettings(
            useResponsesApi: true,
            builtInTools: [
              openai.OpenAIWebSearchTool(),
            ],
          ),
        );

    final result = await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text(
          'Give me a short update on recent AI model releases.',
        ),
      ],
      options: const core.GenerateTextOptions(
        maxOutputTokens: 300,
      ),
    );

    print('Stable response: ${result.text}');
    print('Stable response ID: ${result.responseId ?? 'unknown'}');
    print('If this is enough, do not drop to the raw compatibility provider.');
    print('');
  } catch (error) {
    print('Error in stable-first example: $error\n');
  }
}

Future<void> demonstrateDirectCompatibilityEquivalent(String apiKey) async {
  print('--- Direct Compatibility Equivalent ---');

  try {
    final provider = _createResponsesProvider(
      apiKey,
      model: 'gpt-4o',
      builtInTools: const [
        openai_compat.OpenAIWebSearchTool(),
      ],
    );

    print(
      'This is the provider-owned equivalent of the old builder convenience helper.',
    );
    print(
      'Provider supports Responses API: ${provider.supportsResponsesApi}',
    );

    final responses = provider.responses!;
    final response = await responses.chat([
      compat_chat.ChatMessage.user(
        'Summarize the benefits of renewable energy.',
      ),
    ]);

    print('Lifecycle response: ${_truncate(response.text ?? '<no text>')}');

    final responseId = _responseIdOf(response);
    if (responseId != null) {
      final fetched = await responses.getResponse(responseId);
      print('Fetched by ID: ${_truncate(fetched.text ?? '<no text>')}');
    }

    print(
      'This path is for provider-specific response lifecycle management, '
      'not normal Flutter chat flows.',
    );
    print('');
  } catch (error) {
    print('Error in lifecycle boundary example: $error\n');
  }
}

Future<void> demonstrateGuardrails(String apiKey) async {
  print('--- Guardrails ---');

  try {
    final standardProvider = openai_compat.createOpenAIProvider(
      apiKey: apiKey,
      model: 'gpt-4o-mini',
    );
    final responsesProvider = _createResponsesProvider(
      apiKey,
      model: 'gpt-4o',
    );

    print(
      'Standard OpenAIProvider exposes Responses API: '
      '${standardProvider.supportsResponsesApi}',
    );
    print(
      'Responses-enabled OpenAIProvider exposes Responses API: '
      '${responsesProvider.supportsResponsesApi}',
    );
    print(
        'Standard provider.responses == null: ${standardProvider.responses == null}');
    print(
      'Responses-enabled provider.responses != null: '
      '${responsesProvider.responses != null}',
    );
  } catch (error) {
    print('Capability comparison failed: $error');
  }

  print(
    'Guardrail: the stable `LanguageModel` path intentionally does not expose '
    'raw response lifecycle CRUD. Use it only when you need normal app-facing '
    'generation and streaming.',
  );
  print('');
}

openai_compat.OpenAIProvider _createResponsesProvider(
  String apiKey, {
  required String model,
  List<openai_compat.OpenAIBuiltInTool> builtInTools = const [],
}) {
  return openai_compat.OpenAIProvider(
    openai_compat.OpenAIConfig(
      apiKey: apiKey,
      model: model,
      useResponsesAPI: true,
      builtInTools: builtInTools,
    ),
  );
}

String? _responseIdOf(compat_core.ChatResponse response) {
  if (response is openai_compat.OpenAIResponsesResponse) {
    return response.responseId;
  }

  return null;
}

String _truncate(String text, {int maxLength = 120}) {
  if (text.length <= maxLength) {
    return text;
  }

  return '${text.substring(0, maxLength)}...';
}
