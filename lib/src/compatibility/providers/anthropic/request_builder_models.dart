part of 'request_builder.dart';

/// Data classes for better organization
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
  final Map<String, dynamic>? cacheControl;

  SystemMessageResult({
    required this.contentBlocks,
    required this.plainMessages,
    this.cacheControl,
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
