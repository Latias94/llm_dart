part of 'tool_models.dart';

/// Tool execution result that can be returned to the model
class ToolResult {
  /// The ID of the tool call this result corresponds to
  final String toolCallId;

  /// The result content (can be text, JSON, or error message)
  final String content;

  /// Whether this result represents an error
  final bool isError;

  /// Optional metadata about the execution
  final Map<String, dynamic>? metadata;

  const ToolResult({
    required this.toolCallId,
    required this.content,
    this.isError = false,
    this.metadata,
  });

  /// Create a successful tool result
  factory ToolResult.success({
    required String toolCallId,
    required String content,
    Map<String, dynamic>? metadata,
  }) =>
      ToolResult(
        toolCallId: toolCallId,
        content: content,
        isError: false,
        metadata: metadata,
      );

  /// Create an error tool result
  factory ToolResult.error({
    required String toolCallId,
    required String errorMessage,
    Map<String, dynamic>? metadata,
  }) =>
      ToolResult(
        toolCallId: toolCallId,
        content: errorMessage,
        isError: true,
        metadata: metadata,
      );

  Map<String, dynamic> toJson() => {
        'tool_call_id': toolCallId,
        'content': content,
        'is_error': isError,
        if (metadata != null) 'metadata': metadata,
      };

  factory ToolResult.fromJson(Map<String, dynamic> json) => ToolResult(
        toolCallId: json['tool_call_id'] as String,
        content: json['content'] as String,
        isError: json['is_error'] as bool? ?? false,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

/// Parallel tool execution configuration
class ParallelToolConfig {
  /// Maximum number of tools to execute in parallel
  final int maxParallel;

  /// Timeout for individual tool execution
  final Duration? toolTimeout;

  /// Whether to continue execution if one tool fails
  final bool continueOnError;

  const ParallelToolConfig({
    this.maxParallel = 5,
    this.toolTimeout,
    this.continueOnError = true,
  });

  Map<String, dynamic> toJson() => {
        'max_parallel': maxParallel,
        if (toolTimeout != null) 'tool_timeout_ms': toolTimeout!.inMilliseconds,
        'continue_on_error': continueOnError,
      };

  factory ParallelToolConfig.fromJson(Map<String, dynamic> json) =>
      ParallelToolConfig(
        maxParallel: json['max_parallel'] as int? ?? 5,
        toolTimeout: json['tool_timeout_ms'] != null
            ? Duration(milliseconds: json['tool_timeout_ms'] as int)
            : null,
        continueOnError: json['continue_on_error'] as bool? ?? true,
      );
}
