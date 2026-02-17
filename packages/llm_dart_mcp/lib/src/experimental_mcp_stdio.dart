import 'dart:io';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:mcp_dart/mcp_dart.dart' as mcp;

import 'experimental_mcp_connection.dart';

/// Experimental configuration for connecting to an MCP server over stdio.
class ExperimentalMcpStdioConfig {
  /// Optional label used for tool name namespacing.
  final String? serverLabel;

  /// Executable command to run.
  final String command;

  /// Command line arguments.
  final List<String> args;

  /// Optional environment variables for the server process.
  final Map<String, String>? environment;

  /// Optional working directory for the server process.
  final String? workingDirectory;

  const ExperimentalMcpStdioConfig({
    required this.command,
    this.args = const <String>[],
    this.environment,
    this.workingDirectory,
    this.serverLabel,
  });
}

/// Experimental MCP connection backed by a `mcp_dart` stdio transport.
class ExperimentalMcpStdioConnection implements ExperimentalMcpConnection {
  final ExperimentalMcpStdioConfig config;
  final mcp.Client _client;
  final mcp.StdioClientTransport _transport;

  ExperimentalMcpStdioConnection._({
    required this.config,
    required mcp.Client client,
    required mcp.StdioClientTransport transport,
  })  : _client = client,
        _transport = transport;

  /// Underlying MCP client. Exposed for advanced usage.
  ///
  /// This is still considered experimental and may change.
  @override
  mcp.Client get experimentalClient => _client;

  /// Underlying MCP transport. Exposed for advanced usage.
  mcp.StdioClientTransport get experimentalTransport => _transport;

  @override
  String? get serverLabel => config.serverLabel;

  /// Close the connection and terminate the server process.
  @override
  Future<void> close() async {
    // `mcp.Client.close()` closes the attached transport.
    await _client.close();
  }

  /// Best-effort cancellation check for callers that provide [cancelToken].
  @override
  void throwIfCancelled(CancelToken? cancelToken) {
    if (cancelToken?.isCancelled == true) {
      throw CancelledError(cancelToken?.reason?.toString() ?? 'Cancelled');
    }
  }
}

/// Experimental: connect to an MCP server via stdio.
Future<ExperimentalMcpStdioConnection> experimentalConnectMcpStdio({
  required ExperimentalMcpStdioConfig config,
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

  final transport = mcp.StdioClientTransport(
    mcp.StdioServerParameters(
      command: config.command,
      args: config.args,
      environment: config.environment,
      // mcp_dart's stdio client transport requires ProcessStartMode.normal to
      // have stdin/stdout pipes available. Using inheritStdio breaks stdout.
      stderrMode: ProcessStartMode.normal,
      workingDirectory: config.workingDirectory,
    ),
  );

  await client.connect(transport);

  return ExperimentalMcpStdioConnection._(
    config: config,
    client: client,
    transport: transport,
  );
}
