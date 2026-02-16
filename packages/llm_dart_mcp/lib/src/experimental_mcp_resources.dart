import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:mcp_dart/mcp_dart.dart' as mcp;

/// A lightweight wrapper for an MCP resource entry.
class ExperimentalMcpResource {
  final String uri;
  final String name;
  final String? description;
  final String? mimeType;

  const ExperimentalMcpResource({
    required this.uri,
    required this.name,
    this.description,
    this.mimeType,
  });

  factory ExperimentalMcpResource.fromMcp(mcp.Resource r) =>
      ExperimentalMcpResource(
        uri: r.uri,
        name: r.name,
        description: r.description,
        mimeType: r.mimeType,
      );
}

/// A lightweight wrapper for an MCP resource template entry.
class ExperimentalMcpResourceTemplate {
  final String uriTemplate;
  final String name;
  final String? description;
  final String? mimeType;

  const ExperimentalMcpResourceTemplate({
    required this.uriTemplate,
    required this.name,
    this.description,
    this.mimeType,
  });

  factory ExperimentalMcpResourceTemplate.fromMcp(mcp.ResourceTemplate t) =>
      ExperimentalMcpResourceTemplate(
        uriTemplate: t.uriTemplate,
        name: t.name,
        description: t.description,
        mimeType: t.mimeType,
      );
}

/// Best-effort conversion from MCP resource contents to llm_dart prompt parts.
List<PromptPart> experimentalResourceContentsToPromptParts(
  List<mcp.ResourceContents> contents, {
  int? maxBytesPerBlob,
  bool includeUriHeaders = false,
}) {
  final parts = <PromptPart>[];

  for (final c in contents) {
    if (includeUriHeaders) {
      parts.add(TextPart('MCP resource: ${c.uri}'));
    }

    switch (c) {
      case mcp.TextResourceContents(:final text):
        parts.add(TextPart(text));
        break;

      case mcp.BlobResourceContents(:final blob, :final mimeType):
        final bytes = base64Decode(blob);
        final limit = maxBytesPerBlob;
        if (limit != null && limit >= 0 && bytes.length > limit) {
          throw InvalidRequestError(
            'MCP resource blob exceeds maxBytesPerBlob ($limit). '
            'Got ${bytes.length} bytes.',
          );
        }

        parts.add(
          FilePart(
            mime: FileMime(mimeType ?? 'application/octet-stream'),
            data: bytes,
          ),
        );
        break;

      case mcp.UnknownResourceContents():
        parts.add(TextPart(jsonEncode(c.toJson())));
        break;
    }
  }

  return List<PromptPart>.unmodifiable(parts);
}
