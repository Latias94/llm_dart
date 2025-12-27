import 'dart:convert';
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_core/models/tool_models.dart';
import 'package:llm_dart_minimax/llm_dart_minimax.dart';

/// MiniMax (Anthropic-compatible) example:
/// - Uses `llm_dart_minimax` (provider package) + `llm_dart_builder` (builder)
/// - Uses `llm_dart_ai` tool-loop APIs (recommended stable entrypoint)
/// - Demonstrates "tool approval interrupt" + manual resume
/// - Demonstrates provider-specific options via `providerOptions['minimax']`
Future<void> main() async {
  // For subpackage users, you must register the provider factory.
  registerMinimax();

  final apiKey = Platform.environment['MINIMAX_API_KEY'] ??
      Platform.environment['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('Missing API key.');
    stderr
        .writeln('Set `MINIMAX_API_KEY` (recommended) or `ANTHROPIC_API_KEY`.');
    exitCode = 1;
    return;
  }

  final baseUrl = Platform.environment['MINIMAX_BASE_URL'];

  final toolSet = ToolSet([
    functionTool(
      name: 'fetch_url',
      description: 'Fetch a URL and return a short text preview.',
      parameters: const ParametersSchema(
        schemaType: 'object',
        properties: {
          'url': ParameterProperty(
            propertyType: 'string',
            description: 'The URL to fetch (https://...)',
          ),
        },
        required: ['url'],
      ),
      needsApproval: (toolCall,
          {required messages, required stepIndex, cancelToken}) {
        // Vercel-style: "dangerous" tools can require explicit approval.
        // Here we always ask for approval before fetching any URL.
        return true;
      },
      handler: (toolCall, {cancelToken}) async {
        final args = jsonDecode(toolCall.function.arguments) as Map;
        final urlString = (args['url'] as String?) ?? '';
        final url = Uri.tryParse(urlString);
        if (url == null || !(url.isScheme('https') || url.isScheme('http'))) {
          return {'error': 'Invalid URL: $urlString'};
        }

        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 10);
        try {
          final request = await client.getUrl(url);
          request.followRedirects = false;
          request.headers.set('user-agent', 'llm_dart_minimax_example/1.0');

          final response = await request.close();
          final contentType = response.headers.contentType?.toString();

          // Read only a small preview to keep this tool safe and fast.
          const maxBytes = 16 * 1024;
          final bytes = <int>[];
          await for (final chunk in response) {
            bytes.addAll(chunk);
            if (bytes.length >= maxBytes) break;
          }

          final preview = utf8.decode(bytes, allowMalformed: true);
          return {
            'url': url.toString(),
            'statusCode': response.statusCode,
            'contentType': contentType,
            'preview': preview,
            'truncated': bytes.length >= maxBytes,
          };
        } finally {
          client.close(force: true);
        }
      },
    ),
  ]);

  // Step 1: force the model to request the tool call at least once (demo purpose).
  // Then `runToolLoopUntilBlockedWithToolSet` can stop before executing the tool.
  final modelForToolRequest = await LLMBuilder()
      .provider(minimaxProviderId)
      .apiKey(apiKey)
      .baseUrl(baseUrl ?? minimaxAnthropicBaseUrl)
      .model(minimaxDefaultModel)
      .maxTokens(800)
      .tools(toolSet.tools)
      .toolChoice(const SpecificToolChoice('fetch_url'))
      .providerOptions(minimaxProviderId, const {
    'cacheControl': {'type': 'ephemeral'},
    'extraHeaders': {'x-llm-dart-example': 'minimax-tool-approval'},
    'extraBody': {
      'metadata': {'user_id': 'llm_dart_example'},
    },
  }).build();

  final outcome = await runToolLoopUntilBlocked(
    model: modelForToolRequest,
    promptIr: Prompt(
      messages: [
        PromptMessage.user(
          'Fetch https://example.com with fetch_url, then summarize in 3 bullets.',
        ),
      ],
    ),
    tools: toolSet.tools,
    maxSteps: 3,
    toolHandlers: const {},
    toolApprovalChecks: toolSet.approvalChecks,
  );

  if (outcome case ToolLoopCompleted(:final result)) {
    stdout.writeln('Completed without tool approval interrupt.');
    stdout.writeln(result.finalResult.text ?? '(no text)');
    stdout.writeln('providerMetadata: ${result.finalResult.providerMetadata}');
    return;
  }

  final blocked = outcome as ToolLoopBlocked;
  stdout.writeln('Tool approval required.');
  stdout.writeln('Requested tool calls:');
  for (final call in blocked.state.toolCallsNeedingApproval) {
    stdout.writeln('- ${call.function.name}(${call.function.arguments})');
  }

  stdout.write('Approve and execute these tools? (y/N): ');
  final answer = stdin.readLineSync()?.trim().toLowerCase();
  final approved = answer == 'y' || answer == 'yes';
  if (!approved) {
    stdout.writeln('Denied. Exiting without executing tools.');
    return;
  }

  // Manual resume: execute tools locally, append ToolResultMessage, continue with a normal loop.
  final toolResults = await executeToolCalls(
    toolCalls: blocked.state.toolCalls,
    toolHandlers: toolSet.handlers,
  );

  final resumedMessages = [
    ...blocked.state.messages,
    ChatMessage.toolResult(
      results: encodeToolResultsAsToolCalls(
        toolCalls: blocked.state.toolCalls,
        toolResults: toolResults,
      ),
    ),
  ];

  // Step 2: continue normally.
  final modelAuto = await LLMBuilder()
      .provider(minimaxProviderId)
      .apiKey(apiKey)
      .baseUrl(baseUrl ?? minimaxAnthropicBaseUrl)
      .model(minimaxDefaultModel)
      .maxTokens(800)
      .tools(toolSet.tools)
      .toolChoice(const AutoToolChoice())
      .providerOptions(minimaxProviderId, const {
    'cacheControl': {'type': 'ephemeral'},
    'extraHeaders': {'x-llm-dart-example': 'minimax-tool-approval'},
    'extraBody': {
      'metadata': {'user_id': 'llm_dart_example'},
    },
  }).build();

  final finalResult = await runToolLoop(
    model: modelAuto,
    messages: resumedMessages,
    tools: toolSet.tools,
    toolHandlers: toolSet.handlers,
    maxSteps: 5,
  );

  stdout.writeln(
      '\nFinal answer:\n${finalResult.finalResult.text ?? '(no text)'}');
  stdout
      .writeln('providerMetadata: ${finalResult.finalResult.providerMetadata}');
}
