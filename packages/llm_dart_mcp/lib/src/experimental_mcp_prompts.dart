import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:mcp_dart/mcp_dart.dart' as mcp;

/// A lightweight wrapper for an MCP prompt argument definition.
class ExperimentalMcpPromptArgument {
  final String name;
  final String? description;
  final bool required;

  const ExperimentalMcpPromptArgument({
    required this.name,
    this.description,
    required this.required,
  });

  factory ExperimentalMcpPromptArgument.fromMcp(mcp.PromptArgument a) =>
      ExperimentalMcpPromptArgument(
        name: a.name,
        description: a.description,
        required: a.required ?? false,
      );
}

/// A lightweight wrapper for an MCP prompt/template listing entry.
class ExperimentalMcpPrompt {
  final String name;
  final String? description;
  final List<ExperimentalMcpPromptArgument> arguments;

  const ExperimentalMcpPrompt({
    required this.name,
    this.description,
    this.arguments = const [],
  });

  factory ExperimentalMcpPrompt.fromMcp(mcp.Prompt p) => ExperimentalMcpPrompt(
        name: p.name,
        description: p.description,
        arguments: (p.arguments ?? const <mcp.PromptArgument>[])
            .map(ExperimentalMcpPromptArgument.fromMcp)
            .toList(growable: false),
      );
}

PromptRole _toPromptRole(mcp.PromptMessageRole role) {
  return switch (role) {
    mcp.PromptMessageRole.user => PromptRole.user,
    mcp.PromptMessageRole.assistant => PromptRole.assistant,
  };
}

PromptPart _contentToPromptPart(mcp.Content content) {
  switch (content) {
    case mcp.TextContent(:final text):
      return TextPart(text);

    case mcp.ImageContent(:final data, :final mimeType):
      final bytes = base64Decode(data);
      final mime = mimeType.toLowerCase();
      if (mime == 'image/png') {
        return ImagePart(mime: ImageMime.png, data: bytes);
      }
      if (mime == 'image/jpeg') {
        return ImagePart(mime: ImageMime.jpeg, data: bytes);
      }
      if (mime == 'image/gif') {
        return ImagePart(mime: ImageMime.gif, data: bytes);
      }
      if (mime == 'image/webp') {
        return ImagePart(mime: ImageMime.webp, data: bytes);
      }
      return FilePart(mime: FileMime(mimeType), data: bytes);

    case mcp.AudioContent(:final data, :final mimeType):
      return FilePart(mime: FileMime(mimeType), data: base64Decode(data));

    case mcp.EmbeddedResource(:final resource):
      // Represent embedded resources as best-effort prompt parts.
      switch (resource) {
        case mcp.TextResourceContents(:final text):
          return TextPart(text);
        case mcp.BlobResourceContents(:final blob, :final mimeType):
          return FilePart(
            mime: FileMime(mimeType ?? 'application/octet-stream'),
            data: base64Decode(blob),
          );
        case mcp.UnknownResourceContents():
          return TextPart(jsonEncode(resource.toJson()));
      }

    case mcp.UnknownContent():
      return TextPart(jsonEncode(content.toJson()));
  }
}

/// Best-effort conversion from MCP `prompts/get` messages to llm_dart prompt IR.
Prompt experimentalMcpPromptMessagesToPrompt(List<mcp.PromptMessage> messages) {
  final out = <PromptMessage>[];

  for (final m in messages) {
    out.add(
      PromptMessage(
        role: _toPromptRole(m.role),
        parts: [_contentToPromptPart(m.content)],
      ),
    );
  }

  return Prompt(messages: List<PromptMessage>.unmodifiable(out));
}
