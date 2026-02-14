import 'package:llm_dart_core/llm_dart_core.dart';

import 'content_part.dart';

List<ContentPart> buildContentPartsBestEffort({
  required String? text,
  required String? thinking,
  List<LLMStreamPart> sources = const <LLMStreamPart>[],
  List<LLMFilePart> files = const <LLMFilePart>[],
  List<ToolCall> toolCalls = const <ToolCall>[],
  List<ToolResult> toolResults = const <ToolResult>[],
}) {
  final out = <ContentPart>[];

  final thinkingText = thinking;
  if (thinkingText != null && thinkingText.trim().isNotEmpty) {
    out.add(ReasoningContentPart(thinkingText));
  }

  final textValue = text;
  if (textValue != null && textValue.isNotEmpty) {
    out.add(TextContentPart(textValue));
  }

  for (final s in sources) {
    if (s is LLMSourceUrlPart) {
      out.add(
        SourceUrlContentPart(
          sourceId: s.sourceId,
          url: s.url,
          title: s.title,
          providerMetadata: s.providerMetadata,
        ),
      );
    } else if (s is LLMSourceDocumentPart) {
      out.add(
        SourceDocumentContentPart(
          sourceId: s.sourceId,
          mediaType: s.mediaType,
          title: s.title,
          filename: s.filename,
          providerMetadata: s.providerMetadata,
        ),
      );
    }
  }

  for (final f in files) {
    out.add(FileContentPart(f));
  }

  final resultsByCallId = <String, List<ToolResult>>{};
  for (final r in toolResults) {
    (resultsByCallId[r.toolCallId] ??= <ToolResult>[]).add(r);
  }

  for (final call in toolCalls) {
    out.add(ToolCallContentPart(call));
    final results = resultsByCallId.remove(call.id);
    if (results == null) continue;
    for (final r in results) {
      out.add(r.isError ? ToolErrorContentPart(r) : ToolResultContentPart(r));
    }
  }

  // Any extra results that don't have a matching tool call in the last step.
  for (final entry in resultsByCallId.entries) {
    for (final r in entry.value) {
      out.add(r.isError ? ToolErrorContentPart(r) : ToolResultContentPart(r));
    }
  }

  return List<ContentPart>.unmodifiable(out);
}

