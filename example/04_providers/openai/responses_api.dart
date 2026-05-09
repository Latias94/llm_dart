// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/core/capability.dart' as compat_core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/models/chat_models.dart' as compat_chat;
import 'package:llm_dart/openai.dart' as openai;
import 'package:llm_dart/providers/openai/openai.dart' as openai_compat;

/// OpenAI Responses examples with a stable-first split.
///
/// 1. Most app-facing usage should stay on `openai(...).chatModel(...)`
///    plus shared `core.generateTextCall(...)` / `core.streamTextCall(...)`.
/// 2. Only raw response lifecycle APIs such as `getResponse()` and
///    `continueConversation()` should fall back to the narrower OpenAI
///    provider-owned compatibility surface.
Future<void> main() async {
  print('=== OpenAI Responses API Examples ===\n');

  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Please set OPENAI_API_KEY environment variable');
    return;
  }

  await stableBasicResponsesBackedExample(apiKey);
  await stableBuiltInWebSearchExample(apiKey);
  await stableFileSearchExample(apiKey);
  await stableReasoningExample(apiKey);
  await stableStreamingExample(apiKey);
  await providerLifecycleBoundaryExample(apiKey);
  await providerBackgroundBoundaryExample(apiKey);
}

Future<void> stableBasicResponsesBackedExample(String apiKey) async {
  print('--- Stable Example 1: Responses-Backed Text Generation ---');

  try {
    final model = _responsesModel(
      apiKey,
      'gpt-4.1',
    );

    final result = await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text(
          'Explain the difference between Responses-backed OpenAI chat '
          'transport and the older Chat Completions mental model.',
        ),
      ],
      options: const core.GenerateTextOptions(
        maxOutputTokens: 500,
      ),
      callOptions: const core.CallOptions(
        providerOptions: openai.OpenAIGenerateTextOptions(
          verbosity: 'medium',
        ),
      ),
    );

    print('Response: ${result.text}');
    print('Response ID: ${result.responseId ?? 'unknown'}');
    _printUsage(result);
    print('');
  } catch (error) {
    print('Error in stable basic example: $error\n');
  }
}

Future<void> stableBuiltInWebSearchExample(String apiKey) async {
  print('--- Stable Example 2: Web Search via Model Settings ---');

  try {
    final model = _responsesModel(
      apiKey,
      'gpt-4.1',
      builtInTools: const [
        openai.OpenAIWebSearchTool(),
      ],
    );

    final result = await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text(
          'What are the latest developments in AI this week?',
        ),
      ],
      options: const core.GenerateTextOptions(
        maxOutputTokens: 500,
      ),
    );

    print('Web-search response: ${result.text}');
    print('Response ID: ${result.responseId ?? 'unknown'}');
    _printUsage(result);
    print('');
  } catch (error) {
    print('Error in web search example: $error\n');
  }
}

Future<void> stableFileSearchExample(String apiKey) async {
  print('--- Stable Example 3: File Search via Model Settings ---');

  try {
    final model = _responsesModel(
      apiKey,
      'gpt-4.1',
      builtInTools: const [
        openai.OpenAIFileSearchTool(
          vectorStoreIds: ['vs_example123'],
          parameters: {'max_num_results': 20},
        ),
      ],
    );

    final result = await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text(
          'Search for information about machine learning in the uploaded documents.',
        ),
      ],
      options: const core.GenerateTextOptions(
        maxOutputTokens: 400,
      ),
    );

    print('File-search response: ${result.text}');
    print('Response ID: ${result.responseId ?? 'unknown'}');
    _printUsage(result);
    print('');
  } catch (error) {
    print(
      'Error in file search example (expected without a real vector store): '
      '$error\n',
    );
  }
}

Future<void> stableReasoningExample(String apiKey) async {
  print('--- Stable Example 4: Reasoning with Typed Provider Options ---');

  try {
    final model = _responsesModel(
      apiKey,
      'o3-mini',
    );

    final result = await core.generateTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text(
          'How much wood would a woodchuck chuck if a woodchuck could chuck '
          'wood? Think step by step, then answer plainly.',
        ),
      ],
      options: const core.GenerateTextOptions(
        maxOutputTokens: 1200,
      ),
      callOptions: const core.CallOptions(
        providerOptions: openai.OpenAIGenerateTextOptions(
          reasoningEffort: openai.OpenAIReasoningEffort.high,
          verbosity: 'high',
        ),
      ),
    );

    print('Response: ${result.text}');
    print(
      'Reasoning text: ${_truncate(result.reasoningText ?? '<not exposed>')}',
    );
    _printUsage(result);
    print('');
  } catch (error) {
    print('Error in reasoning example: $error\n');
  }
}

Future<void> stableStreamingExample(String apiKey) async {
  print('--- Stable Example 5: Streaming on Shared Events ---');

  try {
    final model = _responsesModel(
      apiKey,
      'gpt-4.1',
      builtInTools: const [
        openai.OpenAIWebSearchTool(),
      ],
    );

    print('Streaming response:');
    final stream = core.streamTextCall(
      model: model,
      prompt: [
        core.UserPromptMessage.text(
          'Tell me about the latest AI research papers.',
        ),
      ],
      options: const core.GenerateTextOptions(
        maxOutputTokens: 500,
      ),
    );

    await for (final event in stream) {
      switch (event) {
        case core.ResponseMetadataEvent(:final responseId):
          print('[response=$responseId]');
        case core.TextDeltaEvent(:final delta):
          stdout.write(delta);
        case core.ToolInputStartEvent(:final toolName):
          print('\n[tool-input-start $toolName]');
        case core.ToolCallEvent(:final toolCall):
          print('\n[tool-call ${toolCall.toolName}]');
        case core.FinishEvent():
          print('\n[stream completed]');
        case core.ErrorEvent(:final error):
          print('\n[error] $error');
        default:
          break;
      }
    }

    print('\n');
  } catch (error) {
    print('Error in streaming example: $error\n');
  }
}

Future<void> providerLifecycleBoundaryExample(String apiKey) async {
  print('--- Boundary Example 6: Raw Response Lifecycle ---');

  try {
    print('ℹ️  This section is OpenAI-specific and intentionally not part of');
    print('    the shared stable model contract.');

    final provider = _createResponsesProvider(
      apiKey,
      model: 'gpt-4o',
      builtInTools: const [
        openai_compat.OpenAIWebSearchTool(),
      ],
    );

    final responses = provider.responses!;
    final response1 = await responses.chat([
      compat_chat.ChatMessage.user(
        'My name is Alice. Tell me about quantum computing.',
      ),
    ]);

    print('First response: ${_truncate(response1.text ?? '<no text>')}');

    final responseId = _responseIdOf(response1);
    if (responseId == null) {
      print('No response ID returned; lifecycle demo skipped.\n');
      return;
    }

    print('Response ID: $responseId');

    final continued = await responses.continueConversation(
      responseId,
      [
        compat_chat.ChatMessage.user(
          'Remember my name and explain it in simpler terms.',
        ),
      ],
    );
    print('Continued response: ${_truncate(continued.text ?? '<no text>')}');

    final fetched = await responses.getResponse(responseId);
    print('Fetched by ID: ${_truncate(fetched.text ?? '<no text>')}');

    final inputItems = await responses.listInputItems(responseId);
    print('Input item count: ${inputItems.data.length}');
    print('');
  } catch (error) {
    print('Error in lifecycle boundary example: $error\n');
  }
}

Future<void> providerBackgroundBoundaryExample(String apiKey) async {
  print('--- Boundary Example 7: Background Processing ---');

  try {
    print(
        'ℹ️  Background response jobs are also OpenAI-specific lifecycle APIs.');

    final provider = _createResponsesProvider(
      apiKey,
      model: 'gpt-4o',
      builtInTools: const [
        openai_compat.OpenAIWebSearchTool(),
      ],
    );

    final responses = provider.responses!;
    final background = await responses.chatWithToolsBackground(
      [
        compat_chat.ChatMessage.user(
          'Write a detailed analysis of renewable energy trends.',
        ),
      ],
      null,
    );

    final responseId = _responseIdOf(background);
    print('Background response ID: ${responseId ?? 'unknown'}');

    if (responseId == null) {
      print('');
      return;
    }

    await Future<void>.delayed(const Duration(seconds: 2));

    try {
      final polled = await responses.getResponse(responseId);
      print('Polled response: ${_truncate(polled.text ?? '<no text>')}');
    } catch (pollError) {
      print('Polling did not complete yet: $pollError');
      try {
        await responses.cancelResponse(responseId);
        print('Background response cancelled.');
      } catch (cancelError) {
        print('Could not cancel background response: $cancelError');
      }
    }

    print('');
  } catch (error) {
    print('Error in background boundary example: $error\n');
  }
}

core.LanguageModel _responsesModel(
  String apiKey,
  String modelId, {
  List<openai.OpenAIBuiltInTool> builtInTools = const [],
}) {
  return llm
      .openai(
        apiKey: apiKey,
      )
      .chatModel(
        modelId,
        settings: openai.OpenAIChatModelSettings(
          useResponsesApi: true,
          builtInTools: builtInTools,
        ),
      );
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

void _printUsage(core.GenerateTextCallResult<dynamic> result) {
  if (result.usage case final usage?) {
    print(
      'Usage: total=${usage.totalTokens}, '
      'input=${usage.inputTokens}, '
      'output=${usage.outputTokens}, '
      'reasoning=${usage.reasoningTokens}',
    );
    return;
  }

  print('Usage: <unavailable>');
}

String _truncate(String text, {int maxLength = 140}) {
  if (text.length <= maxLength) {
    return text;
  }

  return '${text.substring(0, maxLength)}...';
}
