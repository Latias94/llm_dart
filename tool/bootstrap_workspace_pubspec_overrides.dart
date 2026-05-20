import 'dart:io';

final class WorkspacePackageDescriptor {
  final String name;
  final Directory directory;
  final Set<String> dependencyNames;

  const WorkspacePackageDescriptor({
    required this.name,
    required this.directory,
    required this.dependencyNames,
  });
}

final class WorkspaceOverrideWrite {
  final String packageName;
  final File file;
  final List<String> dependencyNames;

  const WorkspaceOverrideWrite({
    required this.packageName,
    required this.file,
    required this.dependencyNames,
  });
}

final class WorkspaceBootstrapResult {
  final List<WorkspaceOverrideWrite> writes;

  const WorkspaceBootstrapResult({
    required this.writes,
  });

  bool get wroteAnyFiles => writes.isNotEmpty;
}

const List<String> publishableWorkspacePackages = [
  'llm_dart_provider',
  'llm_dart_ai',
  'llm_dart_core',
  'llm_dart_transport',
  'llm_dart_provider_utils',
  'llm_dart_chat',
  'llm_dart_openai',
  'llm_dart_google',
  'llm_dart_anthropic',
  'llm_dart_ollama',
  'llm_dart_elevenlabs',
  'llm_dart_flutter',
  'llm_dart',
];

Future<WorkspaceBootstrapResult> generateWorkspacePubspecOverrides({
  Directory? repoRoot,
}) async {
  final resolvedRepoRoot = (repoRoot ?? Directory.current).absolute;
  final workspacePackages = await _discoverWorkspacePackages(resolvedRepoRoot);
  final packagesByName = {
    for (final package in workspacePackages) package.name: package,
  };
  final writes = <WorkspaceOverrideWrite>[];

  for (final package in workspacePackages) {
    final dependencyNames = _collectWorkspaceDependencyClosure(
      package: package,
      packagesByName: packagesByName,
    ).toList()
      ..sort();

    if (dependencyNames.isEmpty) {
      continue;
    }

    final content = _buildOverridesContent(
      repoRoot: resolvedRepoRoot,
      package: package,
      dependencyNames: dependencyNames,
      packagesByName: packagesByName,
    );
    final file = File.fromUri(
      package.directory.uri.resolve('pubspec_overrides.yaml'),
    );
    final previousContent =
        file.existsSync() ? await file.readAsString() : null;
    if (previousContent != content) {
      await file.writeAsString(content);
    }

    writes.add(
      WorkspaceOverrideWrite(
        packageName: package.name,
        file: file,
        dependencyNames: List.unmodifiable(dependencyNames),
      ),
    );
  }

  return WorkspaceBootstrapResult(
    writes: List.unmodifiable(writes),
  );
}

Set<String> _collectWorkspaceDependencyClosure({
  required WorkspacePackageDescriptor package,
  required Map<String, WorkspacePackageDescriptor> packagesByName,
}) {
  final dependencyNames = <String>{};
  final pending = package.dependencyNames
      .where(packagesByName.containsKey)
      .where((dependencyName) => dependencyName != package.name)
      .toList();

  while (pending.isNotEmpty) {
    final dependencyName = pending.removeLast();
    if (!dependencyNames.add(dependencyName)) {
      continue;
    }

    final dependency = packagesByName[dependencyName];
    if (dependency == null) {
      continue;
    }

    pending.addAll(
      dependency.dependencyNames
          .where(packagesByName.containsKey)
          .where((nestedName) => nestedName != package.name)
          .where((nestedName) => !dependencyNames.contains(nestedName)),
    );
  }

  return dependencyNames;
}

Future<List<WorkspacePackageDescriptor>> _discoverWorkspacePackages(
  Directory repoRoot,
) async {
  final descriptors = <WorkspacePackageDescriptor>[];
  final rootPubspec = File.fromUri(repoRoot.uri.resolve('pubspec.yaml'));
  if (!rootPubspec.existsSync()) {
    throw StateError('workspace bootstrap failed: pubspec.yaml not found.');
  }

  descriptors.add(await _readWorkspacePackage(repoRoot));

  final packagesDir = Directory.fromUri(repoRoot.uri.resolve('packages/'));
  if (!packagesDir.existsSync()) {
    throw StateError(
        'workspace bootstrap failed: packages/ directory missing.');
  }

  final childDirectories = await packagesDir
      .list()
      .where((entity) => entity is Directory)
      .cast<Directory>()
      .toList()
    ..sort((left, right) => left.path.compareTo(right.path));

  for (final directory in childDirectories) {
    final pubspecFile = File.fromUri(directory.uri.resolve('pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      continue;
    }
    descriptors.add(await _readWorkspacePackage(directory));
  }

  return List.unmodifiable(descriptors);
}

Future<WorkspacePackageDescriptor> _readWorkspacePackage(
    Directory directory) async {
  final pubspecFile = File.fromUri(directory.uri.resolve('pubspec.yaml'));
  final lines = await pubspecFile.readAsLines();
  final packageName = _readPubspecName(lines);
  if (packageName == null) {
    throw StateError(
      'workspace bootstrap failed: ${pubspecFile.path} is missing a top-level `name:`.',
    );
  }

  final dependencyNames = <String>{
    ..._readTopLevelSectionKeys(lines, sectionName: 'dependencies'),
    ..._readTopLevelSectionKeys(lines, sectionName: 'dev_dependencies'),
  };

  return WorkspacePackageDescriptor(
    name: packageName,
    directory: directory.absolute,
    dependencyNames: Set<String>.unmodifiable(dependencyNames),
  );
}

String _buildOverridesContent({
  required Directory repoRoot,
  required WorkspacePackageDescriptor package,
  required List<String> dependencyNames,
  required Map<String, WorkspacePackageDescriptor> packagesByName,
}) {
  final buffer = StringBuffer()
    ..writeln(
      '# Generated by dart tool/bootstrap_workspace_pubspec_overrides.dart.',
    )
    ..writeln('# Do not edit by hand. This file is ignored by git.')
    ..writeln('dependency_overrides:');

  for (final dependencyName in dependencyNames) {
    final dependency = packagesByName[dependencyName]!;
    final relativePath = _relativeWorkspacePath(
      repoRoot: repoRoot,
      fromDirectory: package.directory,
      toDirectory: dependency.directory,
    );
    buffer
      ..writeln('  $dependencyName:')
      ..writeln('    path: $relativePath');
  }

  return buffer.toString();
}

String _relativeWorkspacePath({
  required Directory repoRoot,
  required Directory fromDirectory,
  required Directory toDirectory,
}) {
  final fromRelativeSegments = _relativeToRepoRoot(repoRoot, fromDirectory);
  final toRelativeSegments = _relativeToRepoRoot(repoRoot, toDirectory);
  var commonPrefixLength = 0;
  while (commonPrefixLength < fromRelativeSegments.length &&
      commonPrefixLength < toRelativeSegments.length &&
      fromRelativeSegments[commonPrefixLength] ==
          toRelativeSegments[commonPrefixLength]) {
    commonPrefixLength += 1;
  }

  final parentSegments = List.filled(
    fromRelativeSegments.length - commonPrefixLength,
    '..',
  );
  final childSegments = toRelativeSegments.sublist(commonPrefixLength);
  final combinedSegments = [...parentSegments, ...childSegments];
  if (combinedSegments.isEmpty) {
    return '.';
  }
  return combinedSegments.join('/');
}

List<String> _relativeToRepoRoot(Directory repoRoot, Directory directory) {
  final repoPath = _normalizePath(repoRoot.absolute.path);
  final directoryPath = _normalizePath(directory.absolute.path);
  if (directoryPath == repoPath) {
    return const [];
  }

  final prefix = '$repoPath/';
  if (!directoryPath.startsWith(prefix)) {
    throw StateError(
      'workspace bootstrap failed: ${directory.path} is outside ${repoRoot.path}.',
    );
  }

  final relativePath = directoryPath.substring(prefix.length);
  return relativePath.split('/');
}

String _normalizePath(String value) {
  return value.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
}

String? _readPubspecName(List<String> lines) {
  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }

    if (!line.startsWith('name:')) {
      continue;
    }

    final name = line.substring('name:'.length).trim();
    if (name.isEmpty) {
      return null;
    }
    return name;
  }

  return null;
}

Set<String> _readTopLevelSectionKeys(
  List<String> lines, {
  required String sectionName,
}) {
  final keys = <String>{};
  var inSection = false;

  for (final rawLine in lines) {
    final line = rawLine.replaceAll('\t', '  ');
    final trimmed = line.trim();

    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }

    if (!line.startsWith(' ')) {
      if (trimmed == '$sectionName:') {
        inSection = true;
        continue;
      }

      if (inSection) {
        break;
      }
    }

    if (!inSection) {
      continue;
    }

    final match = RegExp(r'^  ([A-Za-z0-9_]+):(?:\s|$)').firstMatch(line);
    if (match != null) {
      keys.add(match.group(1)!);
    }
  }

  return keys;
}

Future<void> main() async {
  final result = await generateWorkspacePubspecOverrides();

  if (!result.wroteAnyFiles) {
    stdout.writeln(
      'workspace bootstrap wrote no pubspec_overrides.yaml files because no '
      'workspace package requires local overrides.',
    );
    return;
  }

  stdout.writeln(
    'workspace bootstrap wrote ${result.writes.length} '
    'pubspec_overrides.yaml file(s):',
  );
  for (final write in result.writes) {
    stdout.writeln(
      '- ${write.file.path.replaceAll('\\', '/')} '
      '(${write.dependencyNames.join(', ')})',
    );
  }
}
