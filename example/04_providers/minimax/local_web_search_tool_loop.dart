import 'dart:io';

import 'dart:convert';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/models/tool_models.dart';
import 'package:llm_dart_minimax/llm_dart_minimax.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

/// MiniMax (Anthropic-compatible) example:
/// - MiniMax does not support provider-native `web_search_*` tools yet
/// - Use a local FunctionTool (`web_search`) + `llm_dart_ai` tool loop instead
///
/// This example implements a minimal web search tool using the DuckDuckGo
/// Instant Answer API, to demonstrate the pattern without introducing a
/// dedicated "tools package".
LocalTool _duckDuckGoWebSearchTool({Dio? dio}) {
  final client = dio ??
      Dio(
        BaseOptions(
          baseUrl: 'https://api.duckduckgo.com/',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

  return functionTool(
    name: 'web_search',
    description:
        'Search the web (DuckDuckGo Instant Answer) and return results.',
    parameters: const ParametersSchema(
      schemaType: 'object',
      properties: {
        'query': ParameterProperty(
          propertyType: 'string',
          description: 'The search query.',
        ),
        'maxResults': ParameterProperty(
          propertyType: 'integer',
          description: 'Maximum number of results to return.',
        ),
      },
      required: ['query'],
    ),
    handler: (toolCall, {cancelToken}) async {
      final args = jsonDecode(toolCall.function.arguments);
      if (args is! Map) {
        return {'error': 'Invalid arguments: expected an object.'};
      }

      final map = Map<String, dynamic>.from(args);
      final query = (map['query'] as String?)?.trim();
      if (query == null || query.isEmpty) {
        return {'error': 'Missing required argument: query'};
      }

      final maxResultsRaw = map['maxResults'];
      final maxResults = (maxResultsRaw is num) ? maxResultsRaw.toInt() : 5;
      final effectiveMaxResults = maxResults <= 0 ? 5 : maxResults;

      final resp = await withDioCancelToken(cancelToken, (dioCancelToken) {
        return client.get<dynamic>(
          '/',
          queryParameters: {
            'q': query,
            'format': 'json',
            'no_html': 1,
            'skip_disambig': 1,
            't': 'llm_dart',
          },
          options: Options(headers: {'user-agent': 'llm_dart_example/0.10.5'}),
          cancelToken: dioCancelToken,
        );
      });

      Map<String, dynamic>? json;
      final data = resp.data;
      if (data is Map<String, dynamic>) {
        json = data;
      } else if (data is String) {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          json = decoded;
        }
      }
      if (json == null) {
        return {'query': query, 'results': []};
      }

      final results = <Map<String, dynamic>>[];
      final related = json['RelatedTopics'];
      if (related is List) {
        void collect(List<dynamic> items) {
          for (final item in items) {
            if (item is! Map) continue;
            final map = Map<String, dynamic>.from(item);
            final topics = map['Topics'];
            if (topics is List) {
              collect(topics);
              continue;
            }
            final text = (map['Text'] as String?)?.trim();
            final url = (map['FirstURL'] as String?)?.trim();
            if (text == null || text.isEmpty || url == null || url.isEmpty) {
              continue;
            }
            final title = text.split(' - ').first.trim();
            final snippet = text.contains(' - ')
                ? text.substring(text.indexOf(' - ') + 3).trim()
                : null;
            results.add({
              'title': title.isEmpty ? text : title,
              'url': url,
              if (snippet != null && snippet.isNotEmpty) 'snippet': snippet,
            });
          }
        }

        collect(related);
      }

      final trimmed = results.take(effectiveMaxResults).toList(growable: false);
      return {
        'query': query,
        'results': trimmed,
      };
    },
  );
}

Future<void> main() async {
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

  final model = await LLMBuilder()
      .provider(minimaxProviderId)
      .apiKey(apiKey)
      .baseUrl(
          Platform.environment['MINIMAX_BASE_URL'] ?? minimaxAnthropicBaseUrl)
      .model(minimaxDefaultModel)
      .maxTokens(900)
      .build();

  final toolSet = ToolSet([
    _duckDuckGoWebSearchTool(),
  ]);

  final result = await runToolLoop(
    model: model,
    promptIr: Prompt(
      messages: [
        PromptMessage.user(
          'Use web_search to find 3 relevant sources about MiniMax Anthropic-compatible API, '
          'then summarize the key constraints in 5 bullets. Include URLs.',
        ),
      ],
    ),
    tools: toolSet.tools,
    toolHandlers: toolSet.handlers,
    maxSteps: 6,
  );

  stdout.writeln(result.finalResult.text ?? '(no text)');
  stdout.writeln('providerMetadata: ${result.finalResult.providerMetadata}');
}
