import 'dart:io';

const Set<String> _allowedRootTopLevelDirectories = {
  'builder',
  'core',
  'models',
  'providers',
  'src',
};

const Set<String> _allowedRootTopLevelFiles = {
  'ai.dart',
  'anthropic.dart',
  'chat.dart',
  'core.dart',
  'deepseek.dart',
  'elevenlabs.dart',
  'google.dart',
  'groq.dart',
  'legacy.dart',
  'llm_dart.dart',
  'ollama.dart',
  'openai.dart',
  'openrouter.dart',
  'phind.dart',
  'transport.dart',
  'xai.dart',
};

const Set<String> _allowedRootSrcTopLevelDirectories = {
  'bootstrap',
  'compatibility',
  'config',
  'facade',
};

const Set<String> _allowedRootSrcTopLevelFiles = {};

const Set<String> _forbiddenRootModelFiles = {
  'assistant_models.dart',
  'google_tts_models.dart',
};

final RegExp _flutterImportPattern = RegExp(
  r'''^\s*(import|export)\s+['"]package:llm_dart_flutter/[^'"]+['"]''',
);

final RegExp _chatImportPattern = RegExp(
  r'''^\s*(import|export)\s+['"]package:llm_dart_chat/[^'"]+['"]''',
);

final RegExp _legacyImportPattern = RegExp(
  r'''^\s*(import|export)\s+['"]package:llm_dart/legacy\.dart['"]''',
);

final RegExp _topLevelImplementationPattern = RegExp(
  r'^\s*(abstract\s+|base\s+|final\s+|interface\s+|sealed\s+)?'
  r'(class|mixin|enum|extension|typedef)\s+',
);

const List<String> _expectedDefaultRootEntrypointDirectives = [
  'library;',
  "export 'ai.dart';",
];

const List<String> _expectedModernAggregatorEntrypointDirectives = [
  'library;',
  "export 'package:llm_dart_ai/llm_dart_ai.dart';",
  "export 'anthropic.dart';",
  "export 'core.dart';",
  "export 'elevenlabs.dart';",
  "export 'google.dart';",
  "export 'ollama.dart';",
  "export 'openai.dart';",
  "export 'transport.dart';",
  "export 'src/facade/ai.dart' show AI, anthropic, deepSeek, elevenLabs, google, groq, ollama, openRouter, openai, phind, xai;",
];

const Map<String, List<String>> _expectedFocusedRootEntrypointDirectives = {
  'lib/core.dart': [
    'library;',
    "export 'package:llm_dart_ai/llm_dart_ai.dart';",
    "export 'core/cancellation.dart' show CancellationHelper, TransportCancellation, TransportCancelledException;",
  ],
  'lib/transport.dart': [
    'library;',
    "export 'core.dart';",
    "export 'package:llm_dart_transport/llm_dart_transport.dart';",
  ],
  'lib/chat.dart': [
    'library;',
    "export 'core.dart';",
    "export 'transport.dart';",
    "export 'package:llm_dart_chat/llm_dart_chat.dart';",
    "export 'src/facade/ai.dart' show anthropic, deepSeek, google, groq, openRouter, openai, phind, xai;",
  ],
  'lib/anthropic.dart': [
    'library;',
    "export 'package:llm_dart_anthropic/llm_dart_anthropic.dart' hide anthropic;",
    "export 'src/facade/ai.dart' show anthropic;",
  ],
  'lib/google.dart': [
    'library;',
    "export 'package:llm_dart_google/llm_dart_google.dart' hide google;",
    "export 'src/facade/ai.dart' show google;",
  ],
  'lib/elevenlabs.dart': [
    'library;',
    "export 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart' hide elevenLabs;",
    "export 'src/facade/ai.dart' show elevenLabs;",
  ],
  'lib/ollama.dart': [
    'library;',
    "export 'package:llm_dart_ollama/llm_dart_ollama.dart' hide ollama;",
    "export 'src/facade/ai.dart' show ollama;",
  ],
  'lib/openai.dart': [
    'library;',
    "export 'package:llm_dart_openai/llm_dart_openai.dart' hide deepSeek, groq, openRouter, openai, phind, xai;",
    "export 'src/facade/ai.dart' show openai;",
  ],
  'lib/groq.dart': [
    'library;',
    "export 'package:llm_dart_openai/llm_dart_openai.dart' show GroqProfile, OpenAI, OpenAIChatModelSettings, OpenAIGenerateTextOptions, OpenAILanguageModel;",
    "export 'src/facade/ai.dart' show groq;",
  ],
  'lib/phind.dart': [
    'library;',
    "export 'package:llm_dart_openai/llm_dart_openai.dart' show OpenAI, OpenAIChatModelSettings, OpenAIGenerateTextOptions, OpenAILanguageModel, PhindProfile;",
    "export 'src/facade/ai.dart' show phind;",
  ],
  'lib/xai.dart': [
    'library;',
    "export 'package:llm_dart_openai/llm_dart_openai.dart' show OpenAI, OpenAIChatModelSettings, OpenAIGenerateTextOptions, OpenAILanguageModel, XAIProfile, XAIGenerateTextOptions, XAILiveSearchOptions, XAINewsSearchSource, XAIRssSearchSource, XAISearchMode, XAISearchSource, XAIWebSearchSource, XAIXSearchSource;",
    "export 'src/facade/ai.dart' show xai;",
  ],
  'lib/deepseek.dart': [
    'library;',
    "export 'package:llm_dart_openai/llm_dart_openai.dart' show DeepSeekGenerateTextOptions, DeepSeekProfile, OpenAI, OpenAIChatModelSettings, OpenAIGenerateTextOptions, OpenAILanguageModel;",
    "export 'src/facade/ai.dart' show deepSeek;",
  ],
  'lib/openrouter.dart': [
    'library;',
    "export 'package:llm_dart_openai/llm_dart_openai.dart' show OpenAI, OpenAIChatModelSettings, OpenAIGenerateTextOptions, OpenAILanguageModel, OpenRouterChatModelSettings, OpenRouterGenerateTextOptions, OpenRouterProfile, OpenRouterSearchMode, OpenRouterSearchOptions;",
    "export 'src/facade/ai.dart' show openRouter;",
  ],
};

const List<String> _expectedLegacyEntrypointDirectives = [
  'library;',
  "export 'src/facade/ai.dart' show AI;",
  "export 'src/bootstrap/root_registry_bootstrap.dart' show ensureRootRegistryBootstrap;",
  "export 'src/facade/legacy_builder_helpers.dart';",
  "export 'src/compatibility/providers/legacy_dio_client_overrides.dart' show createLegacyDioClientOverrides;",
  "export 'src/compatibility/providers/openai_family_compat_deepseek_config.dart' show createLegacyDeepSeekConfig;",
  "export 'src/compatibility/providers/openai_family_compat_groq_config.dart' show createLegacyGroqConfig;",
  "export 'src/compatibility/providers/openai_family_compat_phind_config.dart' show createLegacyPhindConfig;",
  "export 'src/compatibility/providers/openai_family_compat_support.dart' show createLegacyOpenAIConfig;",
  "export 'src/compatibility/providers/openai_family_compat_xai_config.dart' show createLegacyXAIConfig;",
  "export 'src/compatibility/providers/anthropic_config_adapter.dart' show createLegacyAnthropicConfig;",
  "export 'src/compatibility/providers/google_config_adapter.dart' show createLegacyGoogleConfig;",
  "export 'src/compatibility/providers/elevenlabs/config_adapter.dart' show createLegacyElevenLabsConfig;",
  "export 'src/compatibility/providers/ollama/config_adapter.dart' show createLegacyOllamaConfig;",
  "export 'src/compatibility/openai_compatible_provider_config.dart' show ConfigTransformer, HeadersTransformer, ModelCapabilityConfig, OpenAICompatibleProviderConfig, RequestBodyTransformer;",
  "export 'src/compatibility/web_search_presets.dart' show CompatWebSearchPresets;",
  "export 'core/capability.dart';",
  "export 'core/cancellation.dart';",
  "export 'core/llm_error.dart';",
  "export 'core/config.dart';",
  "export 'core/registry.dart';",
  "export 'core/openai_compatible_configs.dart';",
  "export 'core/tool_validator.dart';",
  "export 'core/web_search.dart';",
  "export 'package:llm_dart_transport/llm_dart_transport.dart' show StreamingTransportResponse, TransportClient, TransportException, TransportHttpException, TransportMethod, TransportNetworkException, TransportRequest, TransportResponse, TransportResponseFormatException, TransportResponseType, TransportTimeoutException;",
  "export 'models/chat_models.dart';",
  "export 'models/tool_models.dart';",
  "export 'models/audio_models.dart';",
  "export 'models/image_models.dart';",
  "export 'models/file_models.dart';",
  "export 'models/moderation_models.dart';",
  "export 'providers/openai/openai.dart';",
  "export 'providers/openai/client.dart';",
  "export 'providers/openai/chat.dart';",
  "export 'providers/openai/embeddings.dart';",
  "export 'providers/openai/audio.dart';",
  "export 'providers/openai/images.dart';",
  "export 'providers/openai/files.dart';",
  "export 'providers/openai/models.dart';",
  "export 'providers/openai/moderation.dart';",
  "export 'providers/openai/assistants.dart';",
  "export 'providers/openai/completion.dart';",
  "export 'providers/anthropic/anthropic.dart';",
  "export 'providers/anthropic/models.dart';",
  "export 'providers/google/google.dart';",
  "export 'providers/google/client.dart';",
  "export 'providers/google/chat.dart';",
  "export 'providers/google/embeddings.dart';",
  "export 'providers/google/tts.dart';",
  "export 'providers/deepseek/deepseek.dart';",
  "export 'providers/ollama/ollama.dart';",
  "export 'providers/xai/xai.dart';",
  "export 'providers/phind/phind.dart';",
  "export 'providers/groq/groq.dart';",
  "export 'providers/elevenlabs/elevenlabs.dart';",
  "export 'providers/factories/base_factory.dart';",
  "export 'builder/llm_builder.dart';",
  "export 'builder/http_config.dart';",
  "export 'core/tool_call_aggregator.dart';",
];

final class RootPackageBoundaryGuardResult {
  final List<String> violations;

  const RootPackageBoundaryGuardResult({
    required this.violations,
  });

  bool get passed => violations.isEmpty;
}

Future<RootPackageBoundaryGuardResult> evaluateRootPackageBoundaryGuards({
  Directory? repoRoot,
}) async {
  final resolvedRepoRoot = repoRoot ?? Directory.current;
  final libDir = Directory.fromUri(
    resolvedRepoRoot.uri.resolve('lib/'),
  );
  final violations = <String>[];

  if (!libDir.existsSync()) {
    violations.add(
      'root boundary guard failed: lib/ directory not found from '
      '${resolvedRepoRoot.path}',
    );
    return RootPackageBoundaryGuardResult(
      violations: List.unmodifiable(violations),
    );
  }

  await _collectLayoutViolations(
    repoRoot: resolvedRepoRoot,
    libDir: libDir,
    violations: violations,
  );
  await _collectDefaultRootEntrypointViolations(
    repoRoot: resolvedRepoRoot,
    violations: violations,
  );
  await _collectModernAggregatorEntrypointViolations(
    repoRoot: resolvedRepoRoot,
    violations: violations,
  );
  await _collectFocusedRootEntrypointViolations(
    repoRoot: resolvedRepoRoot,
    violations: violations,
  );
  await _collectLegacyEntrypointViolations(
    repoRoot: resolvedRepoRoot,
    violations: violations,
  );
  await _collectPublicEntrypointImplementationViolations(
    repoRoot: resolvedRepoRoot,
    libDir: libDir,
    violations: violations,
  );
  await _collectImportViolations(
    repoRoot: resolvedRepoRoot,
    libDir: libDir,
    violations: violations,
  );
  await _collectExampleImportViolations(
    repoRoot: resolvedRepoRoot,
    violations: violations,
  );

  return RootPackageBoundaryGuardResult(
    violations: List.unmodifiable(violations),
  );
}

Future<void> _collectLayoutViolations({
  required Directory repoRoot,
  required Directory libDir,
  required List<String> violations,
}) async {
  final topLevelDirectories = <String>{};
  final topLevelFiles = <String>{};

  await for (final entity in libDir.list()) {
    if (entity is Directory) {
      topLevelDirectories.add(
          entity.uri.pathSegments.lastWhere((segment) => segment.isNotEmpty));
      continue;
    }

    if (entity is File) {
      topLevelFiles.add(entity.uri.pathSegments.last);
    }
  }

  final unexpectedRootDirectories = topLevelDirectories
      .difference(_allowedRootTopLevelDirectories)
      .toList()
    ..sort();
  if (unexpectedRootDirectories.isNotEmpty) {
    violations.add(
      'lib/: unexpected top-level directories: '
      '${unexpectedRootDirectories.join(', ')}. Allowed directories: '
      '${_sorted(_allowedRootTopLevelDirectories).join(', ')}.',
    );
  }

  final unexpectedRootFiles =
      topLevelFiles.difference(_allowedRootTopLevelFiles).toList()..sort();
  if (unexpectedRootFiles.isNotEmpty) {
    violations.add(
      'lib/: unexpected top-level public entry files: '
      '${unexpectedRootFiles.join(', ')}. Allowed files: '
      '${_sorted(_allowedRootTopLevelFiles).join(', ')}.',
    );
  }

  final modelsDir = Directory.fromUri(libDir.uri.resolve('models/'));
  if (modelsDir.existsSync()) {
    final forbiddenModelFiles = <String>[];
    await for (final entity in modelsDir.list()) {
      if (entity is! File) {
        continue;
      }
      final name = entity.uri.pathSegments.last;
      if (_forbiddenRootModelFiles.contains(name)) {
        forbiddenModelFiles.add(name);
      }
    }
    forbiddenModelFiles.sort();
    if (forbiddenModelFiles.isNotEmpty) {
      violations.add(
        'lib/models/: provider-specific model files must stay with their '
        'provider: ${forbiddenModelFiles.join(', ')}.',
      );
    }
  }

  final srcDir = Directory.fromUri(libDir.uri.resolve('src/'));
  if (!srcDir.existsSync()) {
    violations.add('lib/src/: directory is missing.');
    return;
  }

  final srcTopLevelDirectories = <String>{};
  final srcTopLevelFiles = <String>{};

  await for (final entity in srcDir.list()) {
    if (entity is Directory) {
      srcTopLevelDirectories.add(
        entity.uri.pathSegments.lastWhere((segment) => segment.isNotEmpty),
      );
      continue;
    }

    if (entity is File) {
      srcTopLevelFiles.add(entity.uri.pathSegments.last);
    }
  }

  final unexpectedSrcDirectories = srcTopLevelDirectories
      .difference(_allowedRootSrcTopLevelDirectories)
      .toList()
    ..sort();
  if (unexpectedSrcDirectories.isNotEmpty) {
    violations.add(
      'lib/src/: unexpected top-level directories: '
      '${unexpectedSrcDirectories.join(', ')}. Allowed directories: '
      '${_sorted(_allowedRootSrcTopLevelDirectories).join(', ')}.',
    );
  }

  final unexpectedSrcFiles = srcTopLevelFiles
      .difference(_allowedRootSrcTopLevelFiles)
      .toList()
    ..sort();
  if (unexpectedSrcFiles.isNotEmpty) {
    violations.add(
      'lib/src/: unexpected top-level files: '
      '${unexpectedSrcFiles.join(', ')}. Allowed files: '
      '${_sorted(_allowedRootSrcTopLevelFiles).join(', ')}.',
    );
  }
}

Future<void> _collectDefaultRootEntrypointViolations({
  required Directory repoRoot,
  required List<String> violations,
}) async {
  final rootEntrypoint =
      File.fromUri(repoRoot.uri.resolve('lib/llm_dart.dart'));
  if (!rootEntrypoint.existsSync()) {
    violations.add('lib/llm_dart.dart: default root entrypoint is missing.');
    return;
  }

  final directives = await _readPublicDirectives(rootEntrypoint);

  if (_listEquals(directives, _expectedDefaultRootEntrypointDirectives)) {
    return;
  }

  violations.add(
    'lib/llm_dart.dart: default root entrypoint must only export ai.dart. '
    'Found directives: ${directives.join(' ')}. Expected directives: '
    '${_expectedDefaultRootEntrypointDirectives.join(' ')}.',
  );
}

Future<void> _collectModernAggregatorEntrypointViolations({
  required Directory repoRoot,
  required List<String> violations,
}) async {
  final entrypoint = File.fromUri(repoRoot.uri.resolve('lib/ai.dart'));
  if (!entrypoint.existsSync()) {
    violations.add('lib/ai.dart: modern aggregator entrypoint is missing.');
    return;
  }

  final directives = await _readPublicDirectives(entrypoint);
  if (_listEquals(directives, _expectedModernAggregatorEntrypointDirectives)) {
    return;
  }

  violations.add(
    'lib/ai.dart: modern aggregator entrypoint must only compose stable '
    'root entrypoints and optional AI namespace. Found directives: '
    '${directives.join(' ')}. Expected directives: '
    '${_expectedModernAggregatorEntrypointDirectives.join(' ')}.',
  );
}

Future<void> _collectFocusedRootEntrypointViolations({
  required Directory repoRoot,
  required List<String> violations,
}) async {
  for (final entry in _expectedFocusedRootEntrypointDirectives.entries) {
    final entrypoint = File.fromUri(repoRoot.uri.resolve(entry.key));
    if (!entrypoint.existsSync()) {
      violations.add('${entry.key}: focused root entrypoint is missing.');
      continue;
    }

    final directives = await _readPublicDirectives(entrypoint);
    if (_listEquals(directives, entry.value)) {
      continue;
    }

    violations.add(
      '${entry.key}: focused root entrypoint must only export its '
      'package-owned surface. Found directives: ${directives.join(' ')}. '
      'Expected directives: ${entry.value.join(' ')}.',
    );
  }
}

Future<void> _collectLegacyEntrypointViolations({
  required Directory repoRoot,
  required List<String> violations,
}) async {
  final entrypoint = File.fromUri(repoRoot.uri.resolve('lib/legacy.dart'));
  if (!entrypoint.existsSync()) {
    violations.add('lib/legacy.dart: legacy entrypoint is missing.');
    return;
  }

  final directives = await _readPublicDirectives(entrypoint);
  if (_listEquals(directives, _expectedLegacyEntrypointDirectives)) {
    return;
  }

  violations.add(
    'lib/legacy.dart: legacy entrypoint is frozen as an explicit '
    'compatibility shell. Update the M6 legacy export inventory and this '
    'guard intentionally before changing exports. Found directives: '
    '${directives.join(' ')}. Expected directives: '
    '${_expectedLegacyEntrypointDirectives.join(' ')}.',
  );
}

Future<void> _collectPublicEntrypointImplementationViolations({
  required Directory repoRoot,
  required Directory libDir,
  required List<String> violations,
}) async {
  await for (final entity in libDir.list()) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }

    final relativePath = _displayPath(repoRoot, entity);
    final lines = await entity.readAsLines();
    var inDirective = false;

    for (var index = 0; index < lines.length; index += 1) {
      final trimmed = lines[index].trim();
      if (trimmed.isEmpty ||
          trimmed.startsWith('//') ||
          trimmed == 'library;') {
        continue;
      }

      if (inDirective) {
        if (trimmed.endsWith(';')) {
          inDirective = false;
        }
        continue;
      }

      if (trimmed.startsWith('import ') || trimmed.startsWith('export ')) {
        if (!trimmed.endsWith(';')) {
          inDirective = true;
        }
        continue;
      }

      if (!_topLevelImplementationPattern.hasMatch(lines[index])) {
        continue;
      }

      violations.add(
        '$relativePath:${index + 1}: root public entrypoints must stay as '
        'facades or explicit compatibility barrels; move implementation '
        'declarations to the owning package or root compatibility internals.',
      );
    }
  }
}

Future<void> _collectImportViolations({
  required Directory repoRoot,
  required Directory libDir,
  required List<String> violations,
}) async {
  await for (final entity in libDir.list(recursive: true)) {
    if (entity is! File) {
      continue;
    }

    final relativePath = _displayPath(repoRoot, entity);
    if (!relativePath.endsWith('.dart')) {
      continue;
    }

    final lines = await entity.readAsLines();
    for (var index = 0; index < lines.length; index += 1) {
      final line = lines[index];
      if (_flutterImportPattern.hasMatch(line)) {
        violations.add(
          '$relativePath:${index + 1}: root package must not import or export '
          'package:llm_dart_flutter/...; Flutter adapters stay outside the root package.',
        );
      }

      if (_chatImportPattern.hasMatch(line) &&
          relativePath != 'lib/chat.dart') {
        violations.add(
          '$relativePath:${index + 1}: only lib/chat.dart may import or export '
          'package:llm_dart_chat/...; keep the pure chat runtime on the focused '
          'chat entrypoint instead of widening the root surface.',
        );
      }
    }
  }
}

Future<void> _collectExampleImportViolations({
  required Directory repoRoot,
  required List<String> violations,
}) async {
  final exampleDir = Directory.fromUri(repoRoot.uri.resolve('example/'));
  if (!exampleDir.existsSync()) {
    return;
  }

  await for (final entity in exampleDir.list(recursive: true)) {
    if (entity is! File) {
      continue;
    }

    final relativePath = _displayPath(repoRoot, entity);
    if (!relativePath.endsWith('.dart')) {
      continue;
    }

    final lines = await entity.readAsLines();
    for (var index = 0; index < lines.length; index += 1) {
      if (!_legacyImportPattern.hasMatch(lines[index])) {
        continue;
      }

      violations.add(
        '$relativePath:${index + 1}: examples must use focused stable, '
        'builder, model, or provider-owned entrypoints instead of '
        'package:llm_dart/legacy.dart.',
      );
    }
  }
}

String _displayPath(Directory repoRoot, File file) {
  final repoPath = repoRoot.absolute.path.replaceAll('\\', '/');
  final filePath = file.absolute.path.replaceAll('\\', '/');
  if (filePath.startsWith('$repoPath/')) {
    return filePath.substring(repoPath.length + 1);
  }
  return filePath;
}

List<String> _sorted(Set<String> values) {
  return values.toList()..sort();
}

Future<List<String>> _readPublicDirectives(File file) async {
  final directives = <String>[];
  var pendingDirective = '';

  for (final rawLine in await file.readAsLines()) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('///') || line.startsWith('//')) {
      continue;
    }

    pendingDirective =
        pendingDirective.isEmpty ? line : '$pendingDirective $line';

    if (line.endsWith(';')) {
      directives.add(pendingDirective);
      pendingDirective = '';
    }
  }

  if (pendingDirective.isNotEmpty) {
    directives.add(pendingDirective);
  }

  return directives;
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) {
    return false;
  }

  for (var index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }

  return true;
}

Future<void> main() async {
  final result = await evaluateRootPackageBoundaryGuards();

  if (result.passed) {
    stdout.writeln(
      'root boundary guard passed: root entrypoints, lib/src layout, and '
      'chat/flutter/example boundary imports match the frozen policy.',
    );
    return;
  }

  stderr.writeln(
    'root boundary guard found ${result.violations.length} violation(s):',
  );
  for (final violation in result.violations) {
    stderr.writeln(violation);
  }
  exitCode = 1;
}
