part of 'package:llm_dart_anthropic_compatible/request_builder.dart';

class ProcessedMessages {
  final List<Map<String, dynamic>> anthropicMessages;
  final List<Map<String, dynamic>> systemContentBlocks;
  final List<String> systemMessages;

  ProcessedMessages({
    required this.anthropicMessages,
    required this.systemContentBlocks,
    required this.systemMessages,
  });
}

class SystemMessageResult {
  final List<Map<String, dynamic>> contentBlocks;
  final List<String> plainMessages;

  SystemMessageResult({
    required this.contentBlocks,
    required this.plainMessages,
  });
}

class ProcessedTools {
  final List<Tool> tools;
  final Map<String, dynamic>? cacheControl;

  ProcessedTools({
    required this.tools,
    this.cacheControl,
  });
}

class ToolExtractionResult {
  final List<Tool> tools;
  final Map<String, dynamic>? cacheControl;

  ToolExtractionResult({
    required this.tools,
    this.cacheControl,
  });
}
