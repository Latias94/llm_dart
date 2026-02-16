/// Stable MCP (Model Context Protocol) client helpers.
///
/// This file provides Vercel AI SDK-style ergonomics while keeping the
/// implementation in `llm_dart_mcp` experimental for now.
library;

import 'package:llm_dart_core/llm_dart_core.dart';

import 'src/experimental_mcp_client.dart';
import 'src/experimental_mcp_stdio.dart';
import 'src/experimental_mcp_streamable_http.dart';

/// MCP client facade.
///
/// Type alias for the current experimental implementation.
typedef McpClient = ExperimentalMcpClient;

/// Stdio transport configuration.
typedef McpStdioConfig = ExperimentalMcpStdioConfig;

/// Streamable HTTP transport configuration.
typedef McpStreamableHttpConfig = ExperimentalMcpStreamableHttpConfig;

/// Transport configuration for creating an MCP client.
sealed class McpTransportConfig {
  const McpTransportConfig();
}

final class McpStdioTransportConfig extends McpTransportConfig {
  final McpStdioConfig config;
  const McpStdioTransportConfig(this.config);
}

final class McpStreamableHttpTransportConfig extends McpTransportConfig {
  final McpStreamableHttpConfig config;
  const McpStreamableHttpTransportConfig(this.config);
}

/// Configuration for [createMcpClient].
final class McpClientConfig {
  final McpTransportConfig transport;
  final String clientName;
  final String clientVersion;
  final CancelToken? cancelToken;

  const McpClientConfig({
    required this.transport,
    this.clientName = 'llm_dart',
    this.clientVersion = 'experimental',
    this.cancelToken,
  });
}

/// Create an MCP client using a transport config (stdio or streamable HTTP).
Future<McpClient> createMcpClient(McpClientConfig cfg) {
  return switch (cfg.transport) {
    McpStdioTransportConfig(:final config) => createMcpStdioClient(
        config: config,
        clientName: cfg.clientName,
        clientVersion: cfg.clientVersion,
        cancelToken: cfg.cancelToken,
      ),
    McpStreamableHttpTransportConfig(:final config) =>
      createMcpStreamableHttpClient(
        config: config,
        clientName: cfg.clientName,
        clientVersion: cfg.clientVersion,
        cancelToken: cfg.cancelToken,
      ),
  };
}

/// Create an MCP client connected via stdio.
Future<McpClient> createMcpStdioClient({
  required McpStdioConfig config,
  String clientName = 'llm_dart',
  String clientVersion = 'experimental',
  CancelToken? cancelToken,
}) {
  return experimentalCreateMcpStdioClient(
    config: config,
    clientName: clientName,
    clientVersion: clientVersion,
    cancelToken: cancelToken,
  );
}

/// Create an MCP client connected via Streamable HTTP.
Future<McpClient> createMcpStreamableHttpClient({
  required McpStreamableHttpConfig config,
  String clientName = 'llm_dart',
  String clientVersion = 'experimental',
  CancelToken? cancelToken,
}) {
  return experimentalCreateMcpStreamableHttpClient(
    config: config,
    clientName: clientName,
    clientVersion: clientVersion,
    cancelToken: cancelToken,
  );
}
