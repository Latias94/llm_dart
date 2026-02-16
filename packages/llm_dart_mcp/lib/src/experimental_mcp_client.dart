import 'package:llm_dart_ai/llm_dart_ai.dart' show ToolSchemas;
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:mcp_dart/mcp_dart.dart' as mcp;

import 'experimental_mcp_connection.dart';
import 'experimental_mcp_streamable_http.dart';
import 'experimental_mcp_stdio.dart';
import 'experimental_mcp_resources.dart';
import 'experimental_mcp_prompts.dart';
import 'experimental_mcp_tool_bridge.dart';

/// Experimental MCP client facade aligned with Vercel AI SDK ergonomics.
///
/// This wraps an [ExperimentalMcpConnection] and provides a `tools()` helper
/// that converts MCP tool definitions into local function tools.
class ExperimentalMcpClient {
  final ExperimentalMcpConnection _connection;
  ExperimentalMcpToolBridge? _cachedTools;

  ExperimentalMcpClient._(this._connection);

  /// Underlying connection for advanced usage.
  ExperimentalMcpConnection get connection => _connection;

  /// Returns a tool bridge that exposes MCP tools as local function tools.
  ///
  /// The result is cached per client instance.
  Future<ExperimentalMcpToolBridge> tools({
    ToolSchemas schemas = ToolSchemas.automatic,
    ExperimentalMcpToolBridgeOptions options =
        const ExperimentalMcpToolBridgeOptions(),
  }) async {
    final cached = _cachedTools;
    if (cached != null) return cached;

    final effectiveOptions = options.copyWith(
      inferOutputSchemaFromToolDefinitions: schemas == ToolSchemas.automatic,
    );

    final created = await experimentalCreateMcpToolBridge(
      connection: _connection,
      options: effectiveOptions,
    );
    _cachedTools = created;
    return created;
  }

  /// Lists available resources from the MCP server.
  Future<({List<ExperimentalMcpResource> resources, String? nextCursor})>
      listResources({
    String? cursor,
  }) async {
    final result = await _connection.experimentalClient.listResources(
      params: cursor == null
          ? null
          : mcp.ListResourcesRequestParams(cursor: cursor),
    );
    return (
      resources: result.resources
          .map(ExperimentalMcpResource.fromMcp)
          .toList(growable: false),
      nextCursor: result.nextCursor,
    );
  }

  /// Lists available resource templates from the MCP server.
  Future<
      ({
        List<ExperimentalMcpResourceTemplate> templates,
        String? nextCursor
      })> listResourceTemplates({
    String? cursor,
  }) async {
    final result = await _connection.experimentalClient.listResourceTemplates(
      params: cursor == null
          ? null
          : mcp.ListResourceTemplatesRequestParams(cursor: cursor),
    );
    return (
      templates: result.resourceTemplates
          .map(ExperimentalMcpResourceTemplate.fromMcp)
          .toList(growable: false),
      nextCursor: result.nextCursor,
    );
  }

  /// Reads an MCP resource and converts it to prompt parts (best-effort).
  Future<List<PromptPart>> readResourceAsPromptParts({
    required String uri,
    int? maxBytesPerBlob,
    bool includeUriHeaders = false,
  }) async {
    final result = await _connection.experimentalClient.readResource(
      mcp.ReadResourceRequestParams(uri: uri),
    );
    return experimentalResourceContentsToPromptParts(
      result.contents,
      maxBytesPerBlob: maxBytesPerBlob,
      includeUriHeaders: includeUriHeaders,
    );
  }

  /// Lists available prompts/templates from the MCP server.
  Future<({List<ExperimentalMcpPrompt> prompts, String? nextCursor})>
      listPrompts({
    String? cursor,
  }) async {
    final result = await _connection.experimentalClient.listPrompts(
      params:
          cursor == null ? null : mcp.ListPromptsRequestParams(cursor: cursor),
    );
    return (
      prompts: result.prompts
          .map(ExperimentalMcpPrompt.fromMcp)
          .toList(growable: false),
      nextCursor: result.nextCursor,
    );
  }

  /// Retrieves an MCP prompt/template and converts it to llm_dart prompt IR.
  Future<Prompt> getPromptAsPrompt({
    required String name,
    Map<String, String>? arguments,
  }) async {
    final result = await _connection.experimentalClient.getPrompt(
      mcp.GetPromptRequestParams(name: name, arguments: arguments),
    );
    return experimentalMcpPromptMessagesToPrompt(result.messages);
  }

  /// Streams all resources, following `nextCursor` until exhaustion.
  Stream<ExperimentalMcpResource> streamResources({
    String? cursor,
    int? maxPages,
  }) async* {
    var current = cursor;
    var pages = 0;

    while (true) {
      if (maxPages != null && pages >= maxPages) {
        throw InvalidRequestError('maxPages exceeded while listing resources.');
      }

      final page = await listResources(cursor: current);
      pages++;

      for (final r in page.resources) {
        yield r;
      }

      final next = page.nextCursor;
      if (next == null || next.trim().isEmpty) break;
      current = next;
    }
  }

  /// Streams all resource templates, following `nextCursor` until exhaustion.
  Stream<ExperimentalMcpResourceTemplate> streamResourceTemplates({
    String? cursor,
    int? maxPages,
  }) async* {
    var current = cursor;
    var pages = 0;

    while (true) {
      if (maxPages != null && pages >= maxPages) {
        throw InvalidRequestError(
          'maxPages exceeded while listing resource templates.',
        );
      }

      final page = await listResourceTemplates(cursor: current);
      pages++;

      for (final t in page.templates) {
        yield t;
      }

      final next = page.nextCursor;
      if (next == null || next.trim().isEmpty) break;
      current = next;
    }
  }

  /// Streams all prompts, following `nextCursor` until exhaustion.
  Stream<ExperimentalMcpPrompt> streamPrompts({
    String? cursor,
    int? maxPages,
  }) async* {
    var current = cursor;
    var pages = 0;

    while (true) {
      if (maxPages != null && pages >= maxPages) {
        throw InvalidRequestError('maxPages exceeded while listing prompts.');
      }

      final page = await listPrompts(cursor: current);
      pages++;

      for (final p in page.prompts) {
        yield p;
      }

      final next = page.nextCursor;
      if (next == null || next.trim().isEmpty) break;
      current = next;
    }
  }

  /// Close the underlying connection.
  Future<void> close() => _connection.close();
}

/// Experimental: create an MCP client connected via stdio.
Future<ExperimentalMcpClient> experimentalCreateMcpStdioClient({
  required ExperimentalMcpStdioConfig config,
  String clientName = 'llm_dart',
  String clientVersion = 'experimental',
  CancelToken? cancelToken,
}) async {
  if (cancelToken?.isCancelled == true) {
    throw CancelledError(cancelToken?.reason?.toString() ?? 'Cancelled');
  }

  final conn = await experimentalConnectMcpStdio(
    config: config,
    clientName: clientName,
    clientVersion: clientVersion,
  );
  return ExperimentalMcpClient._(conn);
}

/// Experimental: create an MCP client connected via Streamable HTTP.
Future<ExperimentalMcpClient> experimentalCreateMcpStreamableHttpClient({
  required ExperimentalMcpStreamableHttpConfig config,
  String clientName = 'llm_dart',
  String clientVersion = 'experimental',
  CancelToken? cancelToken,
}) async {
  if (cancelToken?.isCancelled == true) {
    throw CancelledError(cancelToken?.reason?.toString() ?? 'Cancelled');
  }

  final conn = await experimentalConnectMcpStreamableHttp(
    config: config,
    clientName: clientName,
    clientVersion: clientVersion,
  );
  return ExperimentalMcpClient._(conn);
}
