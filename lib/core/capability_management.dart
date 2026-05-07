part of 'capability.dart';

/// Capability interface for model listing
abstract class ModelListingCapability {
  /// Get available models from the provider
  Future<List<AIModel>> models({TransportCancellation? cancelToken});
}

/// File management capability for uploading and managing files
abstract class FileManagementCapability {
  /// Upload a file
  Future<FileObject> uploadFile(FileUploadRequest request);

  /// List files
  Future<FileListResponse> listFiles([FileListQuery? query]);

  /// Retrieve file metadata
  Future<FileObject> retrieveFile(String fileId);

  /// Delete a file
  Future<FileDeleteResponse> deleteFile(String fileId);

  /// Get file content
  Future<List<int>> getFileContent(String fileId);
}

/// Content moderation capability
abstract class ModerationCapability {
  /// Moderate content for policy violations
  Future<ModerationResponse> moderate(ModerationRequest request);
}

/// Tool execution capability for providers that support client-side tool execution
abstract class ToolExecutionCapability {
  /// Execute multiple tools in parallel and return results
  Future<List<ToolResult>> executeToolsParallel(
    List<ToolCall> toolCalls, {
    ParallelToolConfig? config,
  }) async {
    final results = <ToolResult>[];
    final effectiveConfig = config ?? const ParallelToolConfig();

    for (final toolCall in toolCalls) {
      try {
        final result = await executeTool(toolCall);
        results.add(result);
      } catch (e) {
        results.add(ToolResult.error(
          toolCallId: toolCall.id,
          errorMessage: 'Tool execution failed: $e',
        ));
        if (!effectiveConfig.continueOnError) break;
      }
    }
    return results;
  }

  /// Execute a single tool call
  Future<ToolResult> executeTool(ToolCall toolCall);

  /// Register a tool executor function
  void registerToolExecutor(
    String toolName,
    Future<ToolResult> Function(ToolCall toolCall) executor,
  );

  /// Get registered tool executors
  Map<String, Future<ToolResult> Function(ToolCall toolCall)> get toolExecutors;
}
