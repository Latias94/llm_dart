library;

/// Options for the xAI Responses API `mcp` provider tool.
///
/// Mirrors Vercel AI SDK args shape for `xai.mcp`.
class XAIMcpToolOptions {
  final String? serverUrl;
  final String? serverLabel;
  final String? serverDescription;
  final List<String>? allowedTools;
  final Map<String, dynamic>? headers;
  final String? authorization;

  const XAIMcpToolOptions({
    this.serverUrl,
    this.serverLabel,
    this.serverDescription,
    this.allowedTools,
    this.headers,
    this.authorization,
  });

  Map<String, dynamic> toJson() => {
        if (serverUrl != null) 'serverUrl': serverUrl,
        if (serverLabel != null) 'serverLabel': serverLabel,
        if (serverDescription != null) 'serverDescription': serverDescription,
        if (allowedTools != null && allowedTools!.isNotEmpty)
          'allowedTools': allowedTools,
        if (headers != null && headers!.isNotEmpty) 'headers': headers,
        if (authorization != null) 'authorization': authorization,
      };
}
