import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:mcp_dart/mcp_dart.dart' as mcp;

import 'experimental_mcp_connection.dart';

/// Experimental configuration for connecting to an MCP server over Streamable HTTP.
class ExperimentalMcpStreamableHttpConfig {
  /// MCP endpoint URL (Streamable HTTP transport).
  final Uri url;

  /// Optional label used for tool name namespacing.
  final String? serverLabel;

  /// Optional session ID. When null, the server may create one.
  final String? sessionId;

  /// Optional HTTP headers to send with MCP requests.
  final Map<String, String>? headers;

  const ExperimentalMcpStreamableHttpConfig({
    required this.url,
    this.serverLabel,
    this.sessionId,
    this.headers,
  });
}

/// Experimental MCP connection backed by a `mcp_dart` Streamable HTTP transport.
class ExperimentalMcpStreamableHttpConnection
    implements ExperimentalMcpConnection {
  final ExperimentalMcpStreamableHttpConfig config;
  final mcp.Client _client;
  final mcp.StreamableHttpClientTransport _transport;

  ExperimentalMcpStreamableHttpConnection._({
    required this.config,
    required mcp.Client client,
    required mcp.StreamableHttpClientTransport transport,
  })  : _client = client,
        _transport = transport;

  @override
  mcp.Client get experimentalClient => _client;

  @override
  String? get serverLabel => config.serverLabel;

  /// Close the connection.
  @override
  Future<void> close() async {
    // `mcp.Client.close()` closes the attached transport.
    await _client.close();
  }

  @override
  void throwIfCancelled(CancelToken? cancelToken) {
    if (cancelToken?.isCancelled == true) {
      throw CancelledError(cancelToken?.reason?.toString() ?? 'Cancelled');
    }
  }
}

/// Experimental: connect to an MCP server via Streamable HTTP transport.
Future<ExperimentalMcpStreamableHttpConnection>
    experimentalConnectMcpStreamableHttp({
  required ExperimentalMcpStreamableHttpConfig config,
  String clientName = 'llm_dart',
  String clientVersion = 'experimental',
  mcp.ClientCapabilities? capabilities,
}) async {
  final client = mcp.Client(
    mcp.Implementation(name: clientName, version: clientVersion),
    options: mcp.ClientOptions(
      capabilities: capabilities ?? const mcp.ClientCapabilities(),
    ),
  );

  final requestInit = <String, dynamic>{};
  final headers = config.headers;
  if (headers != null && headers.isNotEmpty) {
    requestInit['headers'] = headers;
  }

  final transport = mcp.StreamableHttpClientTransport(
    config.url,
    opts: mcp.StreamableHttpClientTransportOptions(
      sessionId: config.sessionId,
      requestInit: requestInit.isEmpty ? null : requestInit,
    ),
  );

  await client.connect(transport);

  return ExperimentalMcpStreamableHttpConnection._(
    config: config,
    client: client,
    transport: transport,
  );
}
