import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'openai_custom_part.dart';

final class OpenAICustomPartSummaryField {
  final String label;
  final String value;

  const OpenAICustomPartSummaryField({
    required this.label,
    required this.value,
  });
}

final class OpenAICustomPartSummary {
  final OpenAICustomPart part;
  final String title;
  final String subtitle;
  final String? previewText;
  final List<OpenAICustomPartSummaryField> fields;

  const OpenAICustomPartSummary({
    required this.part,
    required this.title,
    required this.subtitle,
    required this.previewText,
    required this.fields,
  });

  String get kind => part.kind;

  factory OpenAICustomPartSummary.fromPart(OpenAICustomPart part) {
    return switch (part) {
      OpenAIImageGenerationCallCustomPart() =>
        _buildImageGenerationCallSummary(part),
      OpenAIImageGenerationPartialCustomPart() =>
        _buildImageGenerationPartialSummary(part),
      OpenAIMcpListToolsCustomPart() => _buildMcpListToolsSummary(part),
      OpenAICodeInterpreterCallCustomPart() =>
        _buildCodeInterpreterCallSummary(part),
      OpenAIToolSearchCallCustomPart() => _buildToolSearchCallSummary(part),
      OpenAIToolSearchOutputCustomPart() => _buildToolSearchOutputSummary(part),
    };
  }

  static OpenAICustomPartSummary? tryParsePromptPart(PromptPart part) {
    final parsed = OpenAICustomPart.tryParsePromptPart(part);
    return parsed == null ? null : OpenAICustomPartSummary.fromPart(parsed);
  }

  static OpenAICustomPartSummary? tryParseContentPart(ContentPart part) {
    final parsed = OpenAICustomPart.tryParseContentPart(part);
    return parsed == null ? null : OpenAICustomPartSummary.fromPart(parsed);
  }

  static OpenAICustomPartSummary? tryParseEvent(
      LanguageModelStreamEvent event) {
    final parsed = OpenAICustomPart.tryParseEvent(event);
    return parsed == null ? null : OpenAICustomPartSummary.fromPart(parsed);
  }

  static List<OpenAICustomPartSummary> parsePromptParts(
    Iterable<PromptPart> parts,
  ) {
    return parseTypedParts(parts, tryParsePromptPart);
  }

  static List<OpenAICustomPartSummary> parseContentParts(
    Iterable<ContentPart> parts,
  ) {
    return parseTypedParts(parts, tryParseContentPart);
  }

  static List<OpenAICustomPartSummary> parseEvents(
    Iterable<LanguageModelStreamEvent> events,
  ) {
    return parseTypedParts(events, tryParseEvent);
  }
}

OpenAICustomPartSummary _buildImageGenerationCallSummary(
  OpenAIImageGenerationCallCustomPart part,
) {
  final bytes = part.decodeImageBytes();
  return OpenAICustomPartSummary(
    part: part,
    title: 'Image Generation',
    subtitle: 'Generated Image',
    previewText:
        bytes == null ? 'Image payload unavailable' : 'Image available',
    fields: List<OpenAICustomPartSummaryField>.unmodifiable([
      if (part.itemId != null)
        OpenAICustomPartSummaryField(label: 'Item ID', value: part.itemId!),
      OpenAICustomPartSummaryField(
        label: 'Has Image',
        value: part.hasImage ? 'Yes' : 'No',
      ),
      if (bytes != null)
        OpenAICustomPartSummaryField(
          label: 'Bytes',
          value: '${bytes.length}',
        ),
    ]),
  );
}

OpenAICustomPartSummary _buildImageGenerationPartialSummary(
  OpenAIImageGenerationPartialCustomPart part,
) {
  final bytes = part.decodeImageBytes();
  return OpenAICustomPartSummary(
    part: part,
    title: 'Image Generation',
    subtitle: 'Partial Image',
    previewText: bytes == null
        ? 'Streaming image preview unavailable'
        : 'Streaming image preview',
    fields: List<OpenAICustomPartSummaryField>.unmodifiable([
      if (part.itemId != null)
        OpenAICustomPartSummaryField(label: 'Item ID', value: part.itemId!),
      if (part.outputIndex != null)
        OpenAICustomPartSummaryField(
          label: 'Output Index',
          value: '${part.outputIndex}',
        ),
      OpenAICustomPartSummaryField(
        label: 'Has Image',
        value: part.hasImage ? 'Yes' : 'No',
      ),
      if (bytes != null)
        OpenAICustomPartSummaryField(
          label: 'Bytes',
          value: '${bytes.length}',
        ),
    ]),
  );
}

OpenAICustomPartSummary _buildMcpListToolsSummary(
  OpenAIMcpListToolsCustomPart part,
) {
  final previewNames = part.toolNames.take(3).join(', ');
  return OpenAICustomPartSummary(
    part: part,
    title: part.serverLabel ?? 'MCP',
    subtitle: 'Available Tools',
    previewText: previewNames.isEmpty ? null : previewNames,
    fields: List<OpenAICustomPartSummaryField>.unmodifiable([
      if (part.itemId != null)
        OpenAICustomPartSummaryField(label: 'Item ID', value: part.itemId!),
      if (part.serverLabel != null)
        OpenAICustomPartSummaryField(
          label: 'Server',
          value: part.serverLabel!,
        ),
      OpenAICustomPartSummaryField(
        label: 'Tool Count',
        value: '${part.toolCount}',
      ),
      OpenAICustomPartSummaryField(
        label: 'Has Error',
        value: part.hasError ? 'Yes' : 'No',
      ),
    ]),
  );
}

OpenAICustomPartSummary _buildCodeInterpreterCallSummary(
  OpenAICodeInterpreterCallCustomPart part,
) {
  return OpenAICustomPartSummary(
    part: part,
    title: 'Code Interpreter',
    subtitle: 'Execution',
    previewText: part.logs.isEmpty ? part.code : part.logs.first,
    fields: List<OpenAICustomPartSummaryField>.unmodifiable([
      if (part.itemId != null)
        OpenAICustomPartSummaryField(label: 'Item ID', value: part.itemId!),
      if (part.containerId != null)
        OpenAICustomPartSummaryField(
          label: 'Container',
          value: part.containerId!,
        ),
      OpenAICustomPartSummaryField(
        label: 'Outputs',
        value: '${part.outputCount}',
      ),
    ]),
  );
}

OpenAICustomPartSummary _buildToolSearchCallSummary(
  OpenAIToolSearchCallCustomPart part,
) {
  return OpenAICustomPartSummary(
    part: part,
    title: 'Tool Search',
    subtitle: part.providerExecuted ? 'Server Execution' : 'Client Execution',
    previewText: part.arguments?.toString(),
    fields: List<OpenAICustomPartSummaryField>.unmodifiable([
      if (part.itemId != null)
        OpenAICustomPartSummaryField(label: 'Item ID', value: part.itemId!),
      if (part.callId != null)
        OpenAICustomPartSummaryField(label: 'Call ID', value: part.callId!),
      OpenAICustomPartSummaryField(
        label: 'Execution',
        value: part.execution,
      ),
    ]),
  );
}

OpenAICustomPartSummary _buildToolSearchOutputSummary(
  OpenAIToolSearchOutputCustomPart part,
) {
  final previewNames = part.toolNames.take(3).join(', ');
  return OpenAICustomPartSummary(
    part: part,
    title: 'Tool Search',
    subtitle: 'Loaded Tools',
    previewText: previewNames.isEmpty ? null : previewNames,
    fields: List<OpenAICustomPartSummaryField>.unmodifiable([
      if (part.itemId != null)
        OpenAICustomPartSummaryField(label: 'Item ID', value: part.itemId!),
      if (part.callId != null)
        OpenAICustomPartSummaryField(label: 'Call ID', value: part.callId!),
      OpenAICustomPartSummaryField(
        label: 'Execution',
        value: part.execution,
      ),
      OpenAICustomPartSummaryField(
        label: 'Tool Count',
        value: '${part.toolCount}',
      ),
    ]),
  );
}
