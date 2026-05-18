import 'dart:io';

const String _runtimeContinuationPath =
    'packages/llm_dart_ai/lib/src/model/generate_text_runner_support.dart';
const String _providerOptionsPath =
    'packages/llm_dart_provider/lib/src/common/provider_options.dart';

const List<String> _providerRequestCodecPaths = [
  'packages/llm_dart_openai/lib/src/openai_responses_codec.dart',
  'packages/llm_dart_google/lib/src/google_generate_content_codec.dart',
  'packages/llm_dart_anthropic/lib/src/anthropic_messages_codec.dart',
];

const String _anthropicCodeExecutionReplayPath =
    'packages/llm_dart_anthropic/lib/src/anthropic_code_execution_replay.dart';

final class ProviderReplayMetadataGuardResult {
  final List<String> violations;

  const ProviderReplayMetadataGuardResult({
    required this.violations,
  });

  bool get passed => violations.isEmpty;
}

Future<void> main() async {
  final result = await evaluateProviderReplayMetadataGuards();
  if (result.passed) {
    stdout.writeln(
      'provider replay metadata guard passed: runtime continuations and '
      'provider request codecs use explicit replay options.',
    );
    return;
  }

  for (final violation in result.violations) {
    stderr.writeln(violation);
  }
  exitCode = 1;
}

Future<ProviderReplayMetadataGuardResult> evaluateProviderReplayMetadataGuards({
  Directory? repoRoot,
}) async {
  final resolvedRepoRoot = repoRoot ?? Directory.current;
  final violations = <String>[];

  await _collectRuntimeContinuationViolations(
    repoRoot: resolvedRepoRoot,
    violations: violations,
  );
  await _collectProviderOptionsViolations(
    repoRoot: resolvedRepoRoot,
    violations: violations,
  );
  await _collectProviderRequestCodecViolations(
    repoRoot: resolvedRepoRoot,
    violations: violations,
  );
  await _collectAnthropicCodeExecutionReplayViolations(
    repoRoot: resolvedRepoRoot,
    violations: violations,
  );

  return ProviderReplayMetadataGuardResult(
    violations: List.unmodifiable(violations),
  );
}

Future<void> _collectProviderOptionsViolations({
  required Directory repoRoot,
  required List<String> violations,
}) async {
  final file = File.fromUri(repoRoot.uri.resolve(_providerOptionsPath));
  if (!file.existsSync()) {
    violations.add('provider replay metadata guard failed: '
        'missing $_providerOptionsPath.');
    return;
  }

  final source = await file.readAsString();
  if (!source.contains('providerReplayMetadataFromOptions')) {
    violations.add(
      '$_providerOptionsPath: replay metadata must expose the single '
      'providerReplayMetadataFromOptions extraction helper.',
    );
  }
  if (source.contains('mergeProviderReplayMetadata')) {
    violations.add(
      '$_providerOptionsPath: remove mergeProviderReplayMetadata; replay '
      'metadata extraction must stay a single explicit helper.',
    );
  }
}

Future<void> _collectRuntimeContinuationViolations({
  required Directory repoRoot,
  required List<String> violations,
}) async {
  final file = File.fromUri(repoRoot.uri.resolve(_runtimeContinuationPath));
  if (!file.existsSync()) {
    violations.add('provider replay metadata guard failed: '
        'missing $_runtimeContinuationPath.');
    return;
  }

  _collectProviderMetadataPromptPartViolations(
    path: _runtimeContinuationPath,
    source: await file.readAsString(),
    violations: violations,
  );
}

void _collectProviderMetadataPromptPartViolations({
  required String path,
  required String source,
  required List<String> violations,
}) {
  final constructors = [
    'TextPromptPart',
    'FilePromptPart',
    'ImagePromptPart',
    'ReasoningPromptPart',
    'ReasoningFilePromptPart',
    'CustomPromptPart',
    'ToolCallPromptPart',
    'ToolApprovalRequestPromptPart',
    'ToolResultPromptPart',
    'ToolApprovalResponsePromptPart',
  ];
  final constructorPattern = constructors.map(RegExp.escape).join('|');
  final pattern = RegExp(
    r'\b(' + constructorPattern + r')\s*\(([\s\S]*?)\)',
    multiLine: true,
  );

  for (final match in pattern.allMatches(source)) {
    final constructorName = match.group(1)!;
    final invocation = match.group(0)!;
    if (!invocation.contains('providerMetadata:')) {
      continue;
    }

    final line = _lineNumber(source, match.start);
    violations.add(
      '$path:$line: runtime continuation prompt part $constructorName must '
      'carry replay data through ProviderReplayPromptPartOptions, not '
      'providerMetadata constructor arguments.',
    );
  }
}

int _lineNumber(String source, int offset) {
  var line = 1;
  for (var index = 0; index < offset; index += 1) {
    if (source.codeUnitAt(index) == 10) {
      line += 1;
    }
  }
  return line;
}

Future<void> _collectProviderRequestCodecViolations({
  required Directory repoRoot,
  required List<String> violations,
}) async {
  for (final path in _providerRequestCodecPaths) {
    final file = File.fromUri(repoRoot.uri.resolve(path));
    if (!file.existsSync()) {
      violations.add('provider replay metadata guard failed: missing $path.');
      continue;
    }

    final lines = await file.readAsLines();
    for (var index = 0; index < lines.length; index += 1) {
      final line = lines[index];
      if (!line.contains('part.providerMetadata')) {
        continue;
      }

      violations.add(
        '$path:${index + 1}: request-side replay metadata must flow through '
        'ProviderReplayPromptPartOptions and providerOptions, not '
        'part.providerMetadata.',
      );
    }
  }
}

Future<void> _collectAnthropicCodeExecutionReplayViolations({
  required Directory repoRoot,
  required List<String> violations,
}) async {
  final file = File.fromUri(
    repoRoot.uri.resolve(_anthropicCodeExecutionReplayPath),
  );
  if (!file.existsSync()) {
    violations.add('provider replay metadata guard failed: '
        'missing $_anthropicCodeExecutionReplayPath.');
    return;
  }

  final source = await file.readAsString();
  if (!source.contains('ProviderReplayPromptPartOptions.fromMetadata')) {
    violations.add(
      '$_anthropicCodeExecutionReplayPath: Anthropic code execution prompt '
      'replay helpers must write replay metadata through '
      'ProviderReplayPromptPartOptions.',
    );
  }
  if (!source.contains('providerOptions: part.providerOptions')) {
    violations.add(
      '$_anthropicCodeExecutionReplayPath: Anthropic code execution prompt '
      'replay parsing must read replay metadata from providerOptions.',
    );
  }
}
