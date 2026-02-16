import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:mcp_dart/mcp_dart.dart' as mcp;

/// Shared (experimental) MCP connection surface used by tool bridges.
abstract class ExperimentalMcpConnection {
  /// Underlying MCP client. Exposed for advanced usage.
  ///
  /// This is still considered experimental and may change.
  mcp.Client get experimentalClient;

  /// Optional label used for tool name namespacing.
  String? get serverLabel;

  /// Close the connection.
  Future<void> close();

  /// Best-effort cancellation check for callers that provide [cancelToken].
  void throwIfCancelled(CancelToken? cancelToken);
}
