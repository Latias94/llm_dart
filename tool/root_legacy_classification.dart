enum RootLegacySurfaceStatus {
  keep,
  remove,
  document,
}

final class RootLegacySurfaceDecision {
  final String surface;
  final RootLegacySurfaceStatus status;
  final String replacement;
  final String? rootTopLevelFile;
  final String? rootTopLevelDirectory;
  final String? rootSrcTopLevelDirectory;
  final List<String> expectedDirectives;

  const RootLegacySurfaceDecision({
    required this.surface,
    required this.status,
    required this.replacement,
    this.rootTopLevelFile,
    this.rootTopLevelDirectory,
    this.rootSrcTopLevelDirectory,
    this.expectedDirectives = const [],
  });
}

const List<RootLegacySurfaceDecision> rootLegacySurfaceDecisions = [
  RootLegacySurfaceDecision(
    surface: 'default root facade',
    status: RootLegacySurfaceStatus.keep,
    replacement: 'provider-neutral package:llm_dart/ai.dart facade',
    rootTopLevelFile: 'llm_dart.dart',
    expectedDirectives: [
      'library;',
      "export 'ai.dart';",
    ],
  ),
  RootLegacySurfaceDecision(
    surface: 'modern AI facade',
    status: RootLegacySurfaceStatus.keep,
    replacement: 'provider-neutral core and transport composition',
    rootTopLevelFile: 'ai.dart',
    expectedDirectives: [
      'library;',
      "export 'core.dart';",
      "export 'transport.dart';",
    ],
  ),
  RootLegacySurfaceDecision(
    surface: 'focused core facade',
    status: RootLegacySurfaceStatus.keep,
    replacement: 'package:llm_dart_ai/app.dart',
    rootTopLevelFile: 'core.dart',
    expectedDirectives: [
      'library;',
      "export 'package:llm_dart_ai/app.dart';",
    ],
  ),
  RootLegacySurfaceDecision(
    surface: 'provider-authoring root facade',
    status: RootLegacySurfaceStatus.keep,
    replacement: 'package:llm_dart_ai/provider_authoring.dart',
    rootTopLevelFile: 'provider_authoring.dart',
    expectedDirectives: [
      'library;',
      "export 'package:llm_dart_ai/provider_authoring.dart';",
    ],
  ),
  RootLegacySurfaceDecision(
    surface: 'focused transport facade',
    status: RootLegacySurfaceStatus.keep,
    replacement: 'package:llm_dart_transport/llm_dart_transport.dart',
    rootTopLevelFile: 'transport.dart',
    expectedDirectives: [
      'library;',
      "export 'core.dart';",
      "export 'package:llm_dart_transport/llm_dart_transport.dart';",
    ],
  ),
  RootLegacySurfaceDecision(
    surface: 'focused chat facade',
    status: RootLegacySurfaceStatus.keep,
    replacement: 'package:llm_dart_chat/llm_dart_chat.dart',
    rootTopLevelFile: 'chat.dart',
    expectedDirectives: [
      'library;',
      "export 'core.dart';",
      "export 'transport.dart';",
      "export 'package:llm_dart_chat/llm_dart_chat.dart';",
    ],
  ),
  RootLegacySurfaceDecision(
    surface: 'legacy barrel',
    status: RootLegacySurfaceStatus.remove,
    replacement: 'focused root facades and direct provider packages',
    rootTopLevelFile: 'legacy.dart',
  ),
  RootLegacySurfaceDecision(
    surface: 'builder-era root directory',
    status: RootLegacySurfaceStatus.remove,
    replacement: 'model-first runtime helpers plus typed provider options',
    rootTopLevelDirectory: 'builder',
  ),
  RootLegacySurfaceDecision(
    surface: 'legacy model root directory',
    status: RootLegacySurfaceStatus.remove,
    replacement:
        'package-owned contracts from llm_dart_provider and llm_dart_ai',
    rootTopLevelDirectory: 'models',
  ),
  RootLegacySurfaceDecision(
    surface: 'legacy provider root directory',
    status: RootLegacySurfaceStatus.remove,
    replacement: 'direct provider packages',
    rootTopLevelDirectory: 'providers',
  ),
  RootLegacySurfaceDecision(
    surface: 'legacy root core subpaths',
    status: RootLegacySurfaceStatus.remove,
    replacement: 'package:llm_dart/core.dart',
    rootTopLevelDirectory: 'core',
  ),
  RootLegacySurfaceDecision(
    surface: 'root implementation internals',
    status: RootLegacySurfaceStatus.remove,
    replacement: 'owning workspace packages',
    rootTopLevelDirectory: 'src',
  ),
  RootLegacySurfaceDecision(
    surface: 'root bootstrap internals',
    status: RootLegacySurfaceStatus.remove,
    replacement: 'workspace bootstrap tooling and package-owned factories',
    rootSrcTopLevelDirectory: 'bootstrap',
  ),
  RootLegacySurfaceDecision(
    surface: 'root compatibility internals',
    status: RootLegacySurfaceStatus.remove,
    replacement: 'focused entrypoints and direct provider packages',
    rootSrcTopLevelDirectory: 'compatibility',
  ),
  RootLegacySurfaceDecision(
    surface: 'root config internals',
    status: RootLegacySurfaceStatus.remove,
    replacement: 'llm_dart_transport and typed provider settings',
    rootSrcTopLevelDirectory: 'config',
  ),
  RootLegacySurfaceDecision(
    surface: 'provider-facing PromptMessage input',
    status: RootLegacySurfaceStatus.document,
    replacement: 'ModelMessage messages for app-facing runtime calls',
  ),
  RootLegacySurfaceDecision(
    surface: 'generateObject and streamObject helpers',
    status: RootLegacySurfaceStatus.document,
    replacement:
        'thin wrappers over generateTextCall/streamTextCall plus OutputSpec',
  ),
];

final Set<String> rootLegacyAllowedTopLevelDirectories = {
  for (final decision in rootLegacySurfaceDecisions)
    if (decision.status == RootLegacySurfaceStatus.keep &&
        decision.rootTopLevelDirectory != null)
      decision.rootTopLevelDirectory!,
};

final Set<String> rootLegacyAllowedTopLevelFiles = {
  for (final decision in rootLegacySurfaceDecisions)
    if (decision.status == RootLegacySurfaceStatus.keep &&
        decision.rootTopLevelFile != null)
      decision.rootTopLevelFile!,
};

final Set<String> rootLegacyAllowedSrcTopLevelDirectories = {
  for (final decision in rootLegacySurfaceDecisions)
    if (decision.status == RootLegacySurfaceStatus.keep &&
        decision.rootSrcTopLevelDirectory != null)
      decision.rootSrcTopLevelDirectory!,
};

final Map<String, List<String>> rootLegacyExpectedEntrypointDirectives = {
  for (final decision in rootLegacySurfaceDecisions)
    if (decision.status == RootLegacySurfaceStatus.keep &&
        decision.rootTopLevelFile != null &&
        decision.expectedDirectives.isNotEmpty)
      'lib/${decision.rootTopLevelFile!}': decision.expectedDirectives,
};
