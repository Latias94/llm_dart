import 'anthropic_code_execution_replay_result_core.dart';

final class AnthropicProgrammaticCodeExecutionResult
    extends AnthropicCodeExecutionResult {
  @override
  final String type;
  final String stdout;
  final String stderr;
  final int returnCode;
  @override
  final List<AnthropicExecutionFileHandle> fileHandles;

  const AnthropicProgrammaticCodeExecutionResult({
    required this.stdout,
    required this.stderr,
    required this.returnCode,
    required this.fileHandles,
    this.type = 'code_execution_result',
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

final class AnthropicEncryptedCodeExecutionResult
    extends AnthropicCodeExecutionResult {
  @override
  final String type;
  final String encryptedStdout;
  final String stderr;
  final int returnCode;
  @override
  final List<AnthropicExecutionFileHandle> fileHandles;

  const AnthropicEncryptedCodeExecutionResult({
    required this.encryptedStdout,
    required this.stderr,
    required this.returnCode,
    required this.fileHandles,
    this.type = 'encrypted_code_execution_result',
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'type': type,
      'encrypted_stdout': encryptedStdout,
      'stderr': stderr,
      'return_code': returnCode,
      'content': [
        for (final handle in fileHandles) handle.toJson(),
      ],
    };
  }
}
