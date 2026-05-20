import 'dart:io';

const String _openAISrcPath = 'packages/llm_dart_openai/lib/src';

const Set<String> _expectedCapabilityDirectories = {
  'assistants',
  'chat_completions',
  'common',
  'custom_parts',
  'embedding',
  'files',
  'image',
  'language',
  'moderation',
  'provider',
  'responses',
  'speech',
  'tools',
  'transcription',
};

final class OpenAIProviderLayoutGuardResult {
  final List<String> violations;

  const OpenAIProviderLayoutGuardResult({
    required this.violations,
  });

  bool get passed => violations.isEmpty;
}

Future<void> main() async {
  final result = await evaluateOpenAIProviderLayoutGuard();
  if (result.passed) {
    stdout.writeln(
      'openai provider layout guard passed: implementation files live in '
      'route/capability directories.',
    );
    return;
  }

  for (final violation in result.violations) {
    stderr.writeln(violation);
  }
  exitCode = 1;
}

Future<OpenAIProviderLayoutGuardResult> evaluateOpenAIProviderLayoutGuard({
  Directory? repoRoot,
}) async {
  final resolvedRepoRoot = repoRoot ?? Directory.current;
  final src = Directory.fromUri(resolvedRepoRoot.uri.resolve(_openAISrcPath));
  final violations = <String>[];

  if (!src.existsSync()) {
    return OpenAIProviderLayoutGuardResult(
      violations: [
        'openai provider layout guard failed: missing $_openAISrcPath.'
      ],
    );
  }

  final entries = src.listSync();
  final flatFiles = entries
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .map((file) => file.uri.pathSegments.last)
      .toList()
    ..sort();
  if (flatFiles.isNotEmpty) {
    violations.add(
      '$_openAISrcPath: OpenAI provider implementation files must live in '
      'route/capability directories, found flat files: ${flatFiles.join(', ')}.',
    );
  }

  final directories = entries
      .whereType<Directory>()
      .map((directory) => directory.uri.pathSegments
          .where((segment) => segment.isNotEmpty)
          .last)
      .toSet();
  final missing =
      _expectedCapabilityDirectories.difference(directories).toList()..sort();
  if (missing.isNotEmpty) {
    violations.add(
      '$_openAISrcPath: missing expected OpenAI route/capability directories: '
      '${missing.join(', ')}.',
    );
  }

  return OpenAIProviderLayoutGuardResult(
    violations: List.unmodifiable(violations),
  );
}
