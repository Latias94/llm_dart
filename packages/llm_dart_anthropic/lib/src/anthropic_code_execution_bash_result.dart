import 'anthropic_code_execution_replay_result_core.dart';

final class AnthropicBashCodeExecutionResult
    extends AnthropicCodeExecutionResult {
  @override
  final String type;
  final String stdout;
  final String stderr;
  final int returnCode;
  @override
  final List<AnthropicExecutionFileHandle> fileHandles;

  const AnthropicBashCodeExecutionResult({
    required this.stdout,
    required this.stderr,
    required this.returnCode,
    required this.fileHandles,
    this.type = 'bash_code_execution_result',
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'type': type,
      'stdout': stdout,
      'stderr': stderr,
      'return_code': returnCode,
      'content': [
        for (final handle in fileHandles) handle.toJson(),
      ],
    };
  }
}

final class AnthropicBashCodeExecutionErrorResult
    extends AnthropicCodeExecutionResult {
  @override
  final String type;
  final String errorCode;

  const AnthropicBashCodeExecutionErrorResult({
    required this.errorCode,
    this.type = 'bash_code_execution_tool_result_error',
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'type': type,
      'error_code': errorCode,
    };
  }
}
